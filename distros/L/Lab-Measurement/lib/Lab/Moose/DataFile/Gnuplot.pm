package Lab::Moose::DataFile::Gnuplot;
$Lab::Moose::DataFile::Gnuplot::VERSION = '3.613';
#ABSTRACT: Text based data file ('Gnuplot style')

use 5.010;
use warnings;
use strict;

use Moose;
use MooseX::Params::Validate;
use Moose::Util::TypeConstraints 'enum';
use PDL::Core qw/topdl/;
use Data::Dumper;
use Carp;
use Scalar::Util 'looks_like_number';
use Lab::Moose::Plot;
use Lab::Moose::DataFile::Read;
use List::Util 'any';
use namespace::autoclean;

extends 'Lab::Moose::DataFile';

has columns => (
    is       => 'ro',
    isa      => 'ArrayRef[Str]',
    required => 1,
);

has num_data_rows => (
    is       => 'ro',
    isa      => 'Int',
    default  => 0,
    writer   => '_num_data_rows',
    init_arg => undef
);

has num_blocks => (
    is       => 'ro',
    isa      => 'Int',
    default  => 0,
    writer   => '_num_blocks',
    init_arg => undef,
);

has precision => (
    is      => 'ro',
    isa     => enum( [ 1 .. 17 ] ),
    default => 10,
);

has plots => (
    is       => 'ro',
    isa      => 'ArrayRef',
    default  => sub { [] },
    init_arg => undef
);

sub BUILD {
    my $self    = shift;
    my @columns = @{ $self->columns() };
    if ( @columns == 0 ) {
        croak "need at least one column";
    }
    $self->log_comment( comment => join( "\t", @columns ) );
}


sub log {
    my $self = shift;
    $self->_log_bare(@_);
    $self->refresh_plots( refresh => 'point' );
}

# Log of one row of data. Do not trigger plots.
sub _log_bare {

    # We do not use MooseX::Params::Validate for performance reasons.
    my $self = shift;
    my %args;

    if ( ref $_[0] eq 'HASH' ) {
        %args = %{ $_[0] };
    }
    else {
        %args = @_;
    }

    my @columns = @{ $self->columns() };

    my $line = "";

    while ( my ( $idx, $column ) = each(@columns) ) {
        my $value = delete $args{$column};
        if ( not defined $value ) {
            croak "missing value for column '$column'";
        }
        if ( not looks_like_number($value) ) {
            croak "value '$value' for column '$column' isn't numeric";
        }
        my $precision = $self->precision();
        $line .= sprintf( "%.${precision}g", $value );
        if ( $idx != $#columns ) {
            $line .= "\t";
        }
    }
    $line .= "\n";

    if ( keys %args ) {
        croak "unknown colums in log call: ", join( ' ', keys %args );
    }

    my $fh = $self->filehandle();
    print {$fh} $line;

    my $num = $self->num_data_rows;
    $self->_num_data_rows( ++$num );
}


sub log_block {
    my $self = shift;
    my ( $prefix, $block, $add_newline ) = validated_list(
        \@_,
        prefix      => { isa => 'HashRef[Num]', optional => 1 },
        block       => {},
        add_newline => { isa => 'Bool',         default  => 1 }
    );

    $block = topdl($block);

    my @dims = $block->dims();

    if ( @dims == 1 ) {
        $block = $block->dummy(1);
        @dims  = $block->dims();
    }
    elsif ( @dims != 2 ) {
        croak "log_block needs 1D or 2D piddle";
    }

    my $num_prefix_cols = $prefix ? ( keys %{$prefix} ) : 0;
    my $num_block_cols = $dims[1];

    my @columns = @{ $self->columns() };

    my $num_cols = @columns;

    if ( $num_prefix_cols + $num_block_cols != $num_cols ) {
        croak "need $num_cols columns, got $num_prefix_cols prefix columns"
            . " and $num_block_cols block columns";
    }

    my $num_rows = $dims[0];
    for my $i ( 0 .. $num_rows - 1 ) {
        my %log;

        # Add prefix columns to %log.
        for my $j ( 0 .. $num_prefix_cols - 1 ) {
            my $name = $columns[$j];
            $log{$name} = $prefix->{$name};
        }

        # Add block columns to %log.
        for my $j ( 0 .. $num_block_cols - 1 ) {
            my $name = $columns[ $j + $num_prefix_cols ];
            $log{$name} = $block->at( $i, $j );
        }
        $self->_log_bare(%log);
    }

    if ($add_newline) {
        $self->new_block();
    }
}


sub new_block {
    my $self = shift;
    my $fh   = $self->filehandle;
    print {$fh} "\n";
    $self->_num_blocks( $self->num_blocks + 1 );
    $self->refresh_plots( refresh => 'block' );
}


sub log_comment {
    my $self = shift;
    my ($comment) = validated_list(
        \@_,
        comment => { isa => 'Str' }
    );
    my @lines = split( "\n", $comment );
    my $fh = $self->filehandle();
    for my $line (@lines) {
        print {$fh} "# $line\n";
    }
}


sub _add_2d_plot {
    my ( $self, %args ) = validated_hash(
        \@_,
        x                => { isa => 'Str' },
        y                => { isa => 'Str' },
        terminal         => { isa => 'Str', optional => 1 },
        terminal_options => { isa => 'HashRef', optional => 1 },
        plot_options     => { isa => 'HashRef', default => {} },
        curve_options    => { isa => 'HashRef', default => {} },
        refresh          => { isa => 'Str', default => 'point' },
    );

    my $x_column = delete $args{x};
    my $y_column = delete $args{y};

    my %default_plot_options = (
        xlabel => $x_column,
        ylabel => $y_column,
        title  => $self->path(),
        grid   => 1,
    );
    $args{plot_options} = { %default_plot_options, %{ $args{plot_options} } };

    my %default_curve_options = (
        with => 'points',
    );
    $args{curve_options}
        = { %default_curve_options, %{ $args{curve_options} } };

    for my $column ( $x_column, $y_column ) {
        if ( not any { $column eq $_ } @{ $self->columns } ) {
            croak "column $column does not exist";
        }
    }

    if ( $x_column eq $y_column ) {
        croak "need different columns for x and y";
    }

    my $plot = Lab::Moose::Plot->new(%args);

    my $plots   = $self->plots();
    my $refresh = $args{refresh};
    push @{$plots}, {
        plot    => $plot,
        x       => $x_column,
        y       => $y_column,
        refresh => $refresh
    };
}

sub _add_pm3d_plot {
    my ( $self, %args ) = validated_hash(
        \@_,
        x                => { isa => 'Str' },
        y                => { isa => 'Str' },
        z                => { isa => 'Str' },
        terminal         => { isa => 'Str', optional => 1 },
        terminal_options => { isa => 'HashRef', optional => 1 },
        plot_options     => { isa => 'HashRef', default => {} },
        curve_options    => { isa => 'HashRef', default => {} },
        refresh          => { isa => 'Str', default => 'block' },
    );

    my $x_column = delete $args{x};
    my $y_column = delete $args{y};
    my $z_column = delete $args{z};

    my %default_plot_options = (
        pm3d    => 'implicit map corners2color c1',
        surface => 0,
        xlabel  => $x_column,
        ylabel  => $y_column,
        title   => $self->path(),
        grid    => 1,
        clut    => 'sepia',

        #        border => '4095 front linetype -1 linewidth 1.000');
    );
    my %default_curve_options = ();

    $args{plot_options} = { %default_plot_options, %{ $args{plot_options} } };
    $args{curve_options}
        = { %default_curve_options, %{ $args{curve_options} } };

    for my $column ( $x_column, $y_column, $z_column ) {
        if ( not any { $column eq $_ } @{ $self->columns } ) {
            croak "column $column does not exist";
        }
    }

    my %col_unequal_test
        = map { $_ => 1 } ( $x_column, $y_column, $z_column );
    if ( ( keys %col_unequal_test ) != 3 ) {
        croak "columns $x_column, $y_column, $z_column must not be equal";
    }

    my $plot    = Lab::Moose::Plot->new(%args);
    my $refresh = $args{refresh};
    my $plots   = $self->plots();
    push @{$plots}, {
        plot    => $plot,
        x       => $x_column,
        y       => $y_column,
        z       => $z_column,
        refresh => $refresh,
    };
}

sub add_plot {
    my ( $self, %args ) = validated_hash(
        \@_,
        type               => { isa => 'Str', default  => 'points' },
        hard_copy          => { isa => 'Str', optional => 1 },
        hard_copy_terminal => { isa => 'Str', optional => 1 },
        MX_PARAMS_VALIDATE_ALLOW_EXTRA => 1,
    );

    my $type               = delete $args{type};
    my $hard_copy          = delete $args{hard_copy};
    my $hard_copy_terminal = delete $args{hard_copy_terminal};

    my $plot_generator_sub;
    if ( $type =~ /points?/i ) {
        $plot_generator_sub = '_add_2d_plot';
    }
    elsif ( $type =~ /pm3d/i ) {
        $plot_generator_sub = '_add_pm3d_plot';
    }
    else {
        croak "unknown plot type '$type'";
    }

    $self->$plot_generator_sub(%args);

    # add hard copy plot
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

        $self->$plot_generator_sub(
            terminal => $terminal,
            terminal_options =>
                { output => $hard_copy_file->path(), enhanced => 0 },
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
    my ( $x, $y, $z ) = ( $plot->{x}, $plot->{y}, $plot->{z} );

    my ($x_index) = grep { $column_names->[$_] eq $x } 0 .. $#{$column_names};

    my ($y_index) = grep { $column_names->[$_] eq $y } 0 .. $#{$column_names};

    my $num_columns = @{ $self->columns() };
    if ( defined $z ) {
        if ( $self->num_blocks < 2 ) {
            return;
        }
        my ($z_index)
            = grep { $column_names->[$_] eq $z } 0 .. $#{$column_names};
        my @pixel_fields = read_gnuplot_format(
            type        => 'maps',
            fh          => $self->filehandle(),
            num_columns => $num_columns,
        );
        $plot->{plot}->splot(
            data => [ @pixel_fields[ $x_index, $y_index, $z_index ] ],
        );
    }
    else {
        if ( $self->num_data_rows() < 2 ) {
            return;
        }
        my @columns = read_gnuplot_format(
            type        => 'columns',
            fh          => $self->filehandle(),
            num_columns => $num_columns
        );

        $plot->{plot}->plot(
            data => [ $columns[$x_index], $columns[$y_index] ],
        );
    }
}


sub refresh_plots {
    my $self = shift;
    my ($refresh) = validated_list(
        \@_,
        refresh => { isa => 'Str', optional => 1 },
    );

    my @plots = @{ $self->plots() };

    my @indices;

    if ( defined $refresh ) {
        for my $index ( 0 .. $#plots ) {
            my $plot = $plots[$index];
            if ( defined $plot->{refresh} and $plot->{refresh} eq $refresh ) {
                push @indices, $index;
            }
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

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::DataFile::Gnuplot - Text based data file ('Gnuplot style')

=head1 VERSION

version 3.613

=head1 SYNOPSIS

 use Lab::Moose;

 my $folder = datafolder();

 # datafile with two simple 2D plots:

 my $file = datafile(
     type => 'Gnuplot',
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

 # datafile with pm3d plot
 my $datafile = datafile(
     type => 'Gnuplot',
     folder => datafolder(),
     filename => 'data.dat',
     columns => [qw/x y z/],
 );

 $datafile->add_plot(
     type => 'pm3d',
     x => 'x',
     y => 'y',
     z => 'z',
     hard_copy => 'data.png',
 );
     
 
 for my $x (0..100) {
     for my $y (0..100) {
         $datafile->log(x => $x, y => $y, z => rand());
     }
     $datafile->new_block();
 }

=head1 METHODS

=head2 new

Supports the following attributtes in addition to the L<Lab::Moose::DataFile>
requirements:

=over

=item * columns

(mandatory) arrayref of column names

=item * precision 

The numbers are formatted with a C<%.${precision}g> format specifier. Default
is 10.

=back

=head2 log

 $file->log(column1 => $value1, column2 => $value2, ...);

Log one line of data.

=head2 log_block

 $file->log_block(
     prefix => {column1 => $value1, ...},
     block => $block,
     add_newline => 0
 );

Log a 1D or 2D PDL or array ref. The first dimension runs over the datafile
rows. You can add prefix columns, which will be the same for each line in the
block. E.g. when using a spectrum analyzer inside a voltage sweep, one would
log the returned PDL prefixed with the sweep voltage.

=head2 new_block

 $file->new_block()

print "\n" to the datafile.

=head2 log_comment

 $file->log_comment(comment => $string);

log a comment string, which will be prefixed with '#'. If C<$string> contains
newline characters, several lines of comments will be written.

=head2 add_plot

 $file->add_plot(
     type => 'pm3d',
     x => 'x-column',
     y => 'y-column',
     z => 'z-column',
     plot_options => {grid => 1},
     hard_copy => 'myplot.png',
     hard_copy_terminal => 'svg',
 );

Add a new live plot to the datafile. Options:

=over

=item * type

Supported types: C<points (default), pm3d>.

=item * x (mandatory)

Name of the column which is used for the x-axis.

=item * y (mandatory)

Name of the column which is used for the y-axis.

=item * z (mandatory for 3d plot)

Name of the column which is used tor the cb-axis in a pm3d plot.

=item * terminal

gnuplot terminal. Default is qt.

=item * terminal_options

HashRef of terminal options. For the qt and x11 terminals, this defaults to
C<< {persist => 1, raise => 0} >>.

=item * plot_options

HashRef of plotting options (See L<PDL::Graphics::Gnuplot> for the complete
list). Those are appended to the default plot options.

=item * curve_options

HashRef of curve options (See L<PDL::Graphics::Gnuplot> for the complete
list).

=item * refresh

Set this to a string, if you need to refresh the plot manually with the
C<refresh_plots> option. Multiple plots can share the same refresh handle
string. 

Predefined refresh types:

=over

=item * 'point'

Default for 2D plots. Replot for each new row.

=item * 'block'

Default for 3D plots. Replot when finishing a block.

=back

=item * hard_copy        

Create a copy of the plot in the data folder. Default: do not create hard copy.

=item * hard_copy_terminal

Terminal for hard_copy option. Use png terminal by default. The 'output'
terminal option must be supported.

=back

=head2 refresh_plots

 $file->refresh_plots(refresh => $refresh_type);
 # or
 $file->refresh_plots();

Call C<refresh_plot> for each plot with hanle C<$handle>.

If the C<handle> argument is not given, refresh all plots.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by the Lab::Measurement team; in detail:

  Copyright 2016       Simon Reinhardt
            2017       Andreas K. Huettel, Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
