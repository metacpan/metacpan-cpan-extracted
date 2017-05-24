package Lab::Moose::Instrument::VNASweep;

use Moose::Role;
use Moose::Util::TypeConstraints;
use MooseX::Params::Validate;
use Lab::Moose::Instrument qw/
    timeout_param getter_params precision_param
    /;

use Carp;
use PDL::Lite;
use PDL::Core qw/pdl cat/;
use namespace::autoclean;

our $VERSION = '3.543';

with qw(
    Lab::Moose::Instrument::Common

    Lab::Moose::Instrument::SCPI::Format

    Lab::Moose::Instrument::SCPI::Instrument

    Lab::Moose::Instrument::SCPI::Sense::Average
    Lab::Moose::Instrument::SCPI::Sense::Bandwidth
    Lab::Moose::Instrument::SCPI::Sense::Frequency
    Lab::Moose::Instrument::SCPI::Sense::Sweep

    Lab::Moose::Instrument::SCPI::Source::Power

    Lab::Moose::Instrument::SCPI::Initiate

    Lab::Moose::Instrument::SCPIBlock
);

requires qw/sparam_sweep_data sparam_catalog/;

sub _get_data_columns {
    my ( $self, $catalog, $freq_array, $points ) = @_;

    $freq_array = pdl $freq_array;
    $points     = pdl $points;

    my $num_rows = $freq_array->nelem();
    if ( $num_rows != $self->cached_sense_sweep_points() ) {
        croak
            "length of frequency array not equal to number of configured points";
    }

    my $num_columns = @{$catalog};

    my $num_points = $points->nelem();

    if ( $num_points != $num_columns * $num_rows ) {
        croak "$num_points != $num_columns * $num_rows";
    }

    # One pdl for each column. Will cat these before we return.
    my @data_columns;

    for my $col_index ( 0 .. $num_columns / 2 - 1 ) {

        my $start = $col_index * $num_rows * 2;
        my $stop = $start + 2 * ( $num_rows - 1 );

        my $real = $points->slice( [ $start,     $stop,     2 ] );
        my $im   = $points->slice( [ $start + 1, $stop + 1, 2 ] );

        push @data_columns, $real, $im;
    }

    return cat( $freq_array, @data_columns );
}

=head1 NAME

Lab::Moose::Instrument::VNASweep - Role for network analyzer sweeps.

=head1 METHODS

=head2 sparam_sweep

 my $data = $vna->sparam_sweep(timeout => 10, average => 10, precision => 'double');

Perform a single sweep, and return the resulting data as a 2D PDL. The first
dimension runs over the sweep points. E.g. if only the S11 parameter is
measured, the resulting PDL has dimensions N x 3:

 [
  [freq1, freq2, freq3, ..., freqN],
  [Re(S11)_1, Re(S11)_2, ..., Re(S11)_N],
  [Im(S11)_1, Im(S11)_2, ..., Im(S11)_N],
 ]
 
This method accepts a hash with the following options:

=over

=item B<timeout>

timeout for the sweep operation. If this is not given, use the connection's
default timeout.

=item B<average>

Setting this to C<$N>, the method will perform C<$N> sweeps and the
returned data will consist of the average values.

=item B<precision>

floating point type. Has to be 'single' or 'double'. Defaults to 'single'.

=back

=cut

=head1 REQUIRED METHODS

The following methods are required for role consumption.

=head2 sparam_catalog

 my $array_ref = $vna->sparam_catalog();

Return an arrayref of available S-parameter names. Example result:
C<['Re(s11)', 'Im(s11)', 'Re(s21)', 'Im(s21)']>.

=head2 sparam_sweep_data

 my $binary_string = $vna->sparam_sweep_data(timeout => $timeout)

Return binary SCPI data block of S-parameter values. This string contains
the C<sparam_catalog> values of each frequency point. The floats must be in
native byte order. 

=cut

sub sparam_sweep {
    my ( $self, %args ) = validated_hash(
        \@_,
        timeout_param(),
        type => { isa => enum( ['frequency'] ), default => 'frequency' },
        average => { isa => 'Int', default => 1 },
        precision_param()
    );

    my $average_count = delete $args{average};
    my $precision     = delete $args{precision};

    # Not used so far.
    my $sweep_type = delete $args{type};

    my $catalog = $self->sparam_catalog();

    my $freq_array = $self->sense_frequency_linear_array();

    # Ensure single sweep mode.
    if ( $self->cached_initiate_continuous() ) {
        $self->initiate_continuous( value => 0 );
    }

    # Set average and sweep count.

    if ( $self->cached_sense_average_count() != $average_count ) {
        $self->sense_average_count( value => $average_count );
    }

    if ( $self->cached_sense_sweep_count() != $average_count ) {
        $self->sense_sweep_count( value => $average_count );
    }

    # Ensure correct data format
    $self->set_data_format_precision( precision => $precision );

    # Query measured traces.

    # Get data.
    my $num_cols = @{$catalog};

    my $binary = $self->sparam_sweep_data(%args);

    my $points_ref = $self->block_to_array(
        binary    => $binary,
        precision => $precision
    );

    return $self->_get_data_columns( $catalog, $freq_array, $points_ref );
}

=head1 CONSUMED ROLES

=over

=item L<Lab::Moose::Instrument::Common>

=item L<Lab::Moose::Instrument::SCPI::Format>

=item L<Lab::Moose::Instrument::SCPI::Instrument>

=item L<Lab::Moose::Instrument::SCPI::Sense::Average>

=item L<Lab::Moose::Instrument::SCPI::Sense::Frequency>

=item L<Lab::Moose::Instrument::SCPI::Sense::Sweep>

=item L<Lab::Moose::Instrument::SCPI::Initiate>

=item L<Lab::Moose::Instrument::SCPIBlock>

=back

=cut

1;
