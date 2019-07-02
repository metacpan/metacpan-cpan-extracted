package Lab::Moose::Instrument::DisplayXY;
$Lab::Moose::Instrument::DisplayXY::VERSION = '3.682';
#ABSTRACT: Display with y vs x traces Role for Lab::Moose::Instrument

use 5.010;

use PDL::Core qw/pdl cat nelem sclr/;
use PDL::NiceSlice;
use PDL::Graphics::Gnuplot;

use Carp;
use Moose::Role;
use Lab::Moose;
use Lab::Moose::Plot;
use MooseX::Params::Validate;
use Lab::Moose::Instrument qw/
    timeout_param
    precision_param
    validated_getter
    validated_setter
    validated_channel_getter
    validated_channel_setter
    /;

requires qw(
    get_StartX
    get_StopX
    get_Xpoints_number
    get_traceX
    get_traceY
    get_traceXY
    get_NameX
    get_UnitX
    get_NameY
    get_UnitY
    get_log_header
    get_plot_title
    display_trace
);

has plotXY => (
    is        => 'ro',
    isa       => 'Lab::Moose::Plot',
    init_arg  => undef,
    writer    => '_plotXY',
    predicate => 'has_plotXY'
);

has xlabel => (
    is        => 'rw',
    isa       => 'Str',
    init_arg  => undef,
    predicate => 'has_xlabel'
);

has ylabel => (
    is        => 'rw',
    isa       => 'Str',
    init_arg  => undef,
    predicate => 'has_ylabel'
);

has datafolder => (
    is        => 'rw',
    isa       => 'Lab::Moose::DataFolder',
    init_arg  => undef,
    predicate => 'has_datafolder'
);

has filename => (
    is        => 'rw',
    isa       => 'Str',
    init_arg  => undef,
    predicate => 'has_filename'
);

has datafile => (
    is        => 'rw',
    isa       => 'Lab::Moose::DataFile',
    init_arg  => undef,
    predicate => 'has_datafile'
);


sub get_traceXY {
    my ( $self, %args ) = @_;

    my $traceY = $self->get_traceY(%args);
    my $traceX = $self->get_traceX(%args);

    return cat( $traceX, $traceY );
}


sub get_traceX {
    my ( $self, %args ) = @_;
    my $trace = delete $args{trace};

    my $start      = $self->get_StartX(%args);
    my $stop       = $self->get_StopX(%args);
    my $num_points = $self->get_Xpoints_number(%args);
    my $traceX     = pdl linspaced_array( $start, $stop, $num_points );
    return $traceX;
}

sub linspaced_array {
    my ( $start, $stop, $num_points ) = @_;

    my $num_intervals = $num_points - 1;

    if ( $num_intervals == 0 ) {

        # Return a single point.
        return [$start];
    }

    my @result;

    for my $i ( 0 .. $num_intervals ) {
        my $f = $start + ( $stop - $start ) * ( $i / $num_intervals );
        push @result, $f;
    }

    return \@result;
}


sub get_xlabel_based_on_traceXY {
    my ( $self, %args ) = @_;
    my $traceXY = $args{traceXY};
    if ( !$self->has_xlabel ) {
        if ( $traceXY ( 0, 0 ) == $traceXY ( -1, 0 ) ) {

            # zero span
            $self->xlabel( "Counts of zero span at" . " "
                    . $self->get_NameX() . " "
                    . sclr( $traceXY ( 0, 0 ) ) . " "
                    . $self->get_UnitX() );
        }
        else {
            $self->xlabel( $self->get_NameX(%args) . " ("
                    . $self->get_UnitX(%args)
                    . ")" );
        }
    }
    return $self->xlabel;

}

sub get_ylabel {
    my ( $self, %args ) = @_;
    if ( !$self->has_ylabel ) {
        $self->ylabel( $self->get_NameY() . " (" . $self->get_UnitY() . ")" );
    }
    return $self->ylabel;
}


sub get_traces_data {
    my ( $self, %args ) = @_;
    my @traces = @{ delete $args{traces} };    # arrays are tricky
    my $all_traces;
    for my $tr (@traces) {
        my $data;
        if ( !defined $all_traces ) {

            # first time
            $data = $self->get_traceXY( trace => $tr, %args );
            $all_traces = $data;
        }
        else {
            # acquire and add/glue only Y values
            $data = $self->get_traceY( trace => $tr, %args );
            $all_traces = $all_traces->glue( 1, $data );
        }
    }
    return $all_traces;
}


sub display_trace_data {
    my ( $self, %args ) = @_;
    my $trace   = delete $args{trace};
    my $traceXY = delete $args{traceXY};

    if ( !$self->has_plotXY ) {
        my $plotXY = Lab::Moose::Plot->new();
        $self->_plotXY($plotXY);
    }
    my $plotXY = $self->plotXY();

    my $plot_function = 'plot';
    if ( $plotXY->gpwin->{replottable} ) {

        # this makes multiple traces on the same plot possible
        $plot_function = 'replot';
    }

    my $x = $traceXY ( :, 0 );
    my $y = $traceXY ( :, 1 );
    if ( $x ( 0, 0 ) == $x ( -1, 0 ) ) {

        # zero span
        $x = PDL::Basic::xvals($x);    # replacing X with its indexes
    }
    my @data = [ $x, $y ];

    my %plot_options = (
        xlab =>
            $self->get_xlabel_based_on_traceXY( traceXY => $traceXY, %args ),
        ylab  => $self->get_ylabel(%args),
        title => $self->get_plot_title(%args),
    );

    my %curve_options = (
        with   => 'lines',
        legend => $self->trace_num_to_name( trace => $trace ),
    );
    $plotXY->$plot_function(
        plot_options  => \%plot_options,
        curve_options => \%curve_options,
        data          => @data,
    );
    return $traceXY;
}


sub display_trace {
    my ( $self, %args ) = @_;
    my $trace = delete $args{trace};
    my $traceXY = $self->display_traces( %args, traces => [$trace] );
    return $traceXY;
}


sub display_traces {
    my ( $self, %args ) = @_;
    my $all_traces = $self->get_traces_data(%args);
    my @traces     = @{ delete $args{traces} };       # arrays are tricky
    my $x          = $all_traces ( :, 0 );
    my $traceXY;
    my $cnt = 0;
    for my $tr (@traces) {
        $cnt++;
        my $y = $all_traces ( :, $cnt );
        my $data = $x;
        $data = $data->glue( 1, $y );
        $self->display_trace_data( %args, trace => $tr, traceXY => $data );
    }
    return $all_traces;
}


sub trace_num_to_name {
    my ( $self, %args ) = @_;
    my $trace = delete $args{trace};
    my $name  = "trace" . $trace;
    return $name;
}

sub log_traces {
    my ( $self, %args ) = @_;
    my $all_traces = $self->get_traces_data(%args);
    my @traces     = @{ delete $args{traces} };       # arrays are tricky
    my @columns    = $self->get_NameX(%args);
    push @columns,
        ( map { $self->trace_num_to_name( trace => $_ ) } @traces );

    if ( not $self->has_datafolder() ) {
        $self->datafolder( datafolder() );
    }
    my $datafolder = $self->datafolder();

    if ( not $self->has_filename() ) {
        $self->filename('data.dat');
    }
    my $filename = $self->filename();

    if ( not $self->has_datafile() ) {
        $self->datafile(
            datafile(
                type     => 'Gnuplot',
                folder   => $datafolder,
                filename => $filename,
                columns  => [@columns]
            )
        );
    }
    my $datafile = $self->datafile();

    my $header = $self->get_log_header(%args);
    $datafile->log_comment( comment => $header );

    $datafile->log_block(
        block => $all_traces,
    );

    return $all_traces;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Instrument::DisplayXY - Display with y vs x traces Role for Lab::Moose::Instrument

=head1 VERSION

version 3.682

=head1 DESCRIPTION

Basic commands to grab and display XY traces

=head1 NAME

Lab::Moose::Instrument::DisplayXY - Role of Generic XY display

=head1 METHODS

Driver assuming this role must implements the following high-level method:

=head2 C<get_traceXY>

 $data = $sa->traceXY(timeout => 10, trace => 2);

Perform a single sweep and return the resulting spectrum as a 2D PDL:

 [
  [x1, x2, x3, ..., xN],
  [y1, y2, y3, ..., yN],
 ]

I.e. the first dimension runs over the sweep points.

This method accepts a hash with the following options:

=over

=item B<timeout>

timeout for the sweep operation. If this is not given, use the connection's
default timeout.

=item B<trace>

number of the trace (1..3) and similar.

=back

=head2 get_traceX

 $data = $sa->traceX(timeout => 10);

Return X points of a trace in a 1D PDL:

=head2 get_traceY

 $data = $inst->get_traceY(timeout => 1, trace => 2, precision => 'single');

Return Y points of a given trace in a 1D PDL:

=over

=item B<timeout>

timeout for the sweep operation. If this is not given, use the connection's
default timeout.

=item B<trace>

number of the trace 1, 2, 3 and so on. Defaults to 1.
It is hardware depended and validated by C<validate_trace_papam>,
which need to be implemented by a specific instrument driver.

=item B<precision>

floating point type. Has to be 'single' or 'double'. Defaults to 'single'.

=back

=head2 get_traces_data

 $inst->get_traces_data(timeout => 1, traces => [1, 2, 3], precision => 'single');

Return the traces data as a 2D PDL in order of appearance in C<traces> array.

 [
  [x_1,  x_2,  x_3,  ..., x_N],
  [y1_1, y1_2, y1_3, ..., y1_N],
  [y2_1, y2_2, y2_3, ..., y2_N],
  [y3_1, y3_2, y3_3, ..., y3_N],
  .............................
 ]

=head2 display_trace_data

 $inst->display_trace_data(timeout => 1, trace => 2, traceXY => $data,  precision => 'single');

Display a given trace data. C<traceXY> is 2D pdl with trace X and Y values

 [
  [x_1, x_2, x_3, ..., x_N],
  [y_1, y_2, y_3, ..., y_N],
 ]

=head2 display_trace

 $inst->display_trace(timeout => 1, trace => 2, precision => 'single');

Displays a single trace data on a computer screen. It adds a new trace to the plot.

The function internally calls C<display_traces>, so it is equivalent to

 $inst->display_traces(timeout => 1, traces => [ 2 ], precision => 'single');

Return the trace data as a 2D PDL in order of appearance in C<traces> array.

 [
  [x_1, x_2, x_3, ..., x_N],
  [y_1, y_2, y_3, ..., y_N]
 ]

=head2 display_traces

 $inst->display_traces(timeout => 1, traces => [1, 2, 3], precision => 'single');

Displays required traces data on a computer screen. It adds plots if called several times.

Return the traces data as a 2D PDL in order of appearance in C<traces> array.

 [
  [x_1,  x_2,  x_3,  ..., x_N],
  [y1_1, y1_2, y1_3, ..., y1_N],
  [y2_1, y2_2, y2_3, ..., y2_N],
  [y3_1, y3_2, y3_3, ..., y3_N],
  .............................
 ]

=head2 get_StartX and get_StopX 

Returns start and stop values of X.

=head2 get_Xpoints_number

Returns number of points in the trace.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by the Lab::Measurement team; in detail:

  Copyright 2018       Eugeniy E. Mikhailov, Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
