package Lab::Moose::DataFile::Gnuplot::2D;

use 5.010;
use warnings;
use strict;

use Moose;
use MooseX::Params::Validate;
use Moose::Util::TypeConstraints 'enum';
use Data::Dumper;
use Carp;
use Scalar::Util 'looks_like_number';
use Lab::Moose::Plot;
use Lab::Moose::DataFile::Read 'read_2d_gnuplot_format';
use List::Util 'any';
use namespace::autoclean;

our $VERSION = '3.543';

extends 'Lab::Moose::DataFile::Gnuplot';

=head1 NAME

Lab::Moose::DataFile::Gnuplot::2D - 2D data file with live plotting support.

=head1 SYNOPSIS

 use Lab::Moose;

 my $folder = datafolder();
 
 my $file = datafile(
     type => 'Gnuplot::2D',
     folder => $folder,
     filename => 'gnuplot-file.dat',
     columns => [qw/time voltage temp/]
     );

  $file->add_plot(
     x => 'time',
     y => 'voltage',
     curve_options => {with => 'points'},
     hard_copy => 'gnuplot-file-T-V.png',
  );
   
  $file->add_plot(
      x => 'time',
      y => 'temp',
      hard_copy => 'gnuplot-file-T-Temp.png',
  );

 $file->log(time => 1, voltage => 2, temp => 3);

=head1 DESCRIPTION

This submodule of L<Lab::Moose::DataFile::Gnuplot> provides live plotting of 2D
data with gnuplot. It requires L<PDL::Graphics::Gnuplot> installed.

=cut

# Refresh plots.
after [qw/log log_block/] => sub {
    my $self = shift;

    if ( $self->num_data_rows() < 2 ) {
        return;
    }

    my @plots = @{ $self->plots() };
    my @indices = grep { not defined $plots[$_]->{handle} } ( 0 .. $#plots );
    for my $index (@indices) {
        $self->_refresh_plot( index => $index );
    }
};

has plots => (
    is       => 'ro',
    isa      => 'ArrayRef',
    default  => sub { [] },
    init_arg => undef
);

=head1 METHODS

This module inherits all methods of L<Lab::Moose::DataFile::Gnuplot>.

=head2 add_plot

 $file->add_plot(
     x => 'x-column',
     y => 'y-column',
     plot_options => {grid => 1, xlabel => 'voltage', ylabel => 'current'},
     curve_options => {with => 'points'},
     hard_copy => 'myplot.png',
     hard_copy_terminal => 'svg',
 );

Add a new live plot to the datafile. Options:

=over

=item * x (mandatory)

Name of the column which is used for the x-axis.

=item * y (mandatory)

Name of the column which is used for the y-axis.

=item * terminal

gnuplot terminal. Default is qt.

=item * terminal_options

HashRef of terminal options. For the qt and x11 terminals, this defaults to
C<< {persist => 1, raise => 0} >>.

=item * plot_options

HashRef of plotting options (See L<PDL::Graphics::Gnuplot> for the complete
list).

=item * curve_options

HashRef of curve options (See L<PDL::Graphics::Gnuplot> for the complete
list).

=item * handle

Set this to a string, if you need to refresh the plot manually with the
C<refresh_plots> option. Multiple plots can share the same handle string.

=item * hard_copy        

Create a copy of the plot in the data folder.

=item * hard_copy_terminal

Terminal for hard_copy option. Use png terminal by default. The 'output'
terminal option must be supported.

=back

=cut

sub add_plot {
    my ( $self, %args ) = validated_hash(
        \@_,
        x                  => { isa => 'Str' },
        y                  => { isa => 'Str' },
        terminal           => { isa => 'Str', optional => 1 },
        terminal_options   => { isa => 'HashRef', optional => 1 },
        plot_options       => { isa => 'HashRef', optional => 1 },
        curve_options      => { isa => 'HashRef', optional => 1 },
        handle             => { isa => 'Str', optional => 1 },
        hard_copy          => { isa => 'Str', optional => 1 },
        hard_copy_terminal => { isa => 'Str', optional => 1 },
    );
    my $plots = $self->plots();

    my $x_column = delete $args{x};
    my $y_column = delete $args{y};

    for my $column ( $x_column, $y_column ) {
        if ( not any { $column eq $_ } @{ $self->columns } ) {
            croak "column $column does not exist";
        }
    }

    if ( $x_column eq $y_column ) {
        croak "need different columns for x and y";
    }

    my $refresh = delete $args{refresh};
    my $plot    = Lab::Moose::Plot->new(%args);

    my $handle = $args{handle};

    push @{$plots}, {
        plot   => $plot,
        x      => $x_column,
        y      => $y_column,
        handle => $handle
    };

    # add hard copy plot
    my $hard_copy = delete $args{hard_copy};
    if ( defined $hard_copy ) {
        my $hard_copy_file = Lab::Moose::DataFile->new(
            folder   => $self->folder(),
            filename => $hard_copy,
        );

        delete $args{terminal};
        delete $args{terminal_options};

        my $hard_copy_terminal = delete $args{hard_copy_terminal};
        my $terminal
            = defined($hard_copy_terminal) ? $hard_copy_terminal : 'png';

        $self->add_plot(
            x                => $x_column,
            y                => $y_column,
            terminal         => $terminal,
            terminal_options => { output => $hard_copy_file->path() },
            %args,
        );
    }
}

sub _refresh_plot {
    my $self = shift;
    my ($index) = validated_list(
        \@_,
        index => { isa => 'Int' },
    );

    my $plots = $self->plots();
    my $plot  = $plots->[$index];

    if ( not defined $plot ) {
        croak "no plot with name at index $index";
    }

    my $column_names = $self->columns();
    my ( $x, $y ) = ( $plot->{x}, $plot->{y} );

    my ($x_index) = grep { $column_names->[$_] eq $x } 0 .. $#{$column_names};

    my ($y_index) = grep { $column_names->[$_] eq $y } 0 .. $#{$column_names};

    my $data_columns = read_2d_gnuplot_format( fh => $self->filehandle() );

    $plot->{plot}->plot(
        data => [ $data_columns->[$x_index], $data_columns->[$y_index] ],
    );
}

=head2 refresh_plots

 $file->refresh_plots(handle => $handle);
 $file->refresh_plots();

Call C<refresh_plot> for each plot with hanle C<$handle>.

If the C<handle> argument is not given, refresh all plots.

=cut

sub refresh_plots {
    my $self = shift;
    my ($handle) = validated_list(
        \@_,
        handle => { isa => 'Str', optional => 1 },
    );

    my @plots = @{ $self->plots() };

    my @indices;

    if ( defined $handle ) {
        for my $index ( 0 .. $#plots ) {
            my $plot = $plots[$index];
            if ( defined $plot->{handle} and $plot->{handle} eq $handle ) {
                push @indices, $index;
            }
        }

        if ( !@indices ) {
            croak "no plot with handle $handle";
        }
    }

    else {
        @indices = ( 0 .. $#plots );
    }

    for my $index (@indices) {
        $self->_refresh_plot( index => $index );
    }
}

__PACKAGE__->meta->make_immutable();

1;
