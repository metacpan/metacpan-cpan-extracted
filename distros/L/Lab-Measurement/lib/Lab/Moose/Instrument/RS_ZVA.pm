package Lab::Moose::Instrument::RS_ZVA;

use 5.010;
use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Params::Validate;
use Lab::Moose::Instrument qw/validated_getter/;
use Carp;
use namespace::autoclean;

our $VERSION = '3.543';

extends 'Lab::Moose::Instrument';

with qw(
    Lab::Moose::Instrument::VNASweep

    Lab::Moose::Instrument::SCPI::Calculate::Data
);

sub BUILD {
    my $self = shift;
    $self->clear();
    $self->cls();
}

sub sparam_catalog {
    my $self = shift;

    my $catalog = $self->cached_calculate_data_call_catalog();
    my @complex_catalog;

    for my $sparam ( @{$catalog} ) {
        push @complex_catalog, "Re($sparam)", "Im($sparam)";
    }

    return \@complex_catalog;
}

sub sparam_sweep_data {
    my ( $self, %args ) = validated_getter( \@_ );

    my $byte_order = $self->cached_format_border();
    if ( $byte_order ne 'SWAP' ) {
        carp 'setting network byteorder to little endian.';
        $self->format_border( value => 'SWAP' );
    }

    # Start single sweep.
    $self->initiate_immediate();

    # Wait until single sweep is finished.
    $self->wai();

    return $self->calculate_data_call( format => 'SDATA', %args );
}

=head1 NAME

Lab::Moose::Instrument::RS_ZVA - Rohde & Schwarz ZVA Vector Network Analyzer

=head1 SYNOPSIS

 my $data = $zva->sparam_sweep(timeout => 10);
 my $matrix = $data->matrix;

=cut

=head1 METHODS

See L<Lab::Moose::Instrument::VNASweep> for the high-level C<sparam_sweep> and
C<sparam_catalog> methods.

=cut

__PACKAGE__->meta->make_immutable();

1;
