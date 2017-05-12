package Layout::Manager::Grid;
use Moose;

extends 'Layout::Manager';

use Carp qw(croak);
use List::Util qw(max);

has 'rows' => (
    is => 'rw',
    isa => 'Int',
    required => 1
);

has 'columns' => (
    is => 'rw',
    isa => 'Int',
    required => 1
);

override('do_layout', sub {
    my ($self, $container) = @_;

    my $bbox = $container->inside_bounding_box;

    my $cwidth = $bbox->width;
    my $cheight = $bbox->height;

    my @row_maxes;
    my @col_maxes;

    # If either the width or height is undefined, we'll need to compute it.
    for(my $i = 0; $i < scalar(@{ $container->components }); $i++) {
        my $comp = $container->get_component($i);

        # Skip invisible shit
        next unless defined($comp) && $comp->visible;

        my $cons = $container->get_constraint($i);

        # Set defaults for width
        unless(exists($cons->{width})) {
            $cons->{width} = 1;
        }

        # Set defaults for height
        unless(exists($cons->{height})) {
            $cons->{height} = 1;
        }

        # Calculate the minumum width and height this component would
        # consume in a row & column
        my $mw = $comp->minimum_width / $cons->{width};
        my $mh = $comp->minimum_height / $cons->{height};

        # Check the minumum height for this component against every row
        # in which it appears.  The for uses the height to check the
        # inital row (0) then each (..) row (height - 1).  So row 5 with
        # a height of 2 will check 5 and 6!  THis same method is used for
        # columns below.
        for(0..$cons->{height} - 1) {
            unless(defined($row_maxes[$cons->{row} + $_])) {
                # If it hasn't been defined yet, set it
                $row_maxes[$cons->{row} + $_] = $mh;
                next;
            }
            $row_maxes[$cons->{row} + $_] = $mh if ($mh > $row_maxes[$cons->{row} + $_]);
        }

        # Check the minumum width for this component against every column
        # in which it appears
        for(0..$cons->{width} - 1) {
            unless(defined($col_maxes[$cons->{column} + $_])) {
                $col_maxes[$cons->{column} + $_] = $mw;
                next;
            }
            $col_maxes[$cons->{column} + $_] = $mw if ($mw > $col_maxes[$cons->{column} + $_]);
        }
    }

    # Find out how big of a height we need based on the heights of our rows.
    my $heightfromrowmax = 0;
    for(@row_maxes) { $heightfromrowmax += $_; }

    if($cheight && !scalar(@row_maxes)) {
        # If the height was set (and there's no rowmaxes), build a sham "max
        # rows" list using the height of a row
        my $ch = $cheight / $self->rows;
        @row_maxes = map({ $ch  } (0..$self->rows));
    } elsif($cheight && ($cheight > $heightfromrowmax)) {
        # If the container height is greater than the sum of the biggest rows,
        # add an equal amount to each row so we grow to fill it.
        my $diff = ($cheight - $heightfromrowmax) / $self->rows;
        
        for(my $i = 0; $i < $self->rows; $i++) {
            $row_maxes[$i] += $diff;
        }
    } else {
        my $ch = 0;
        foreach my $h (@row_maxes) {
            $ch += $h if defined($h);
        }
        # If the height wasn't set, set the container's height to the total
        # of all rows
        $cheight = $container->outside_height + $ch;
        $container->minimum_height($cheight);
    }

    if($cwidth) {
        # If the width was already set, build a sham "max cols" list using the
        # width of a column
        my $cw = $cwidth / $self->columns;
        @col_maxes = map({ $cw } (0..$self->columns));
    } else {
        my $cw = 0;
        foreach my $w (@col_maxes) {
            $cw += $w;
        }
        # If the width wasn't set, set the container's width to the total of
        # all cols
        $cwidth = $container->outside_width + $cw;
        $container->minimum_width($cwidth);
    }

    my $ox = $bbox->origin->x;
    my $oy = $bbox->origin->y;

    for(my $i = 0; $i < scalar(@{ $container->components }); $i++) {
        my $comp = $container->get_component($i);

        next unless defined($comp) && $comp->visible;

        my $cons = $container->get_constraint($i);
        croak('Constraint must be a hashref containing row and column.')
            unless (ref($cons) eq 'HASH' && (exists($cons->{row}) && (exists($cons->{column}))));

        my $co = $comp->origin;

        my $row = $cons->{row};
        $row = $self->rows if $row > $self->rows;
        my $col = $cons->{column};
        $col = $self->columns if $col > $self->columns;

        my $width = 1;
        if(exists($cons->{width})) {
            $width = $cons->{width};
        }
        my $height = 1;
        if(exists($cons->{height})) {
            $height = $cons->{height};
        }

        my $x = $ox;
        # Find the X location for this component by adding up each column
        # width from 0 to the current column
        for(0..$col - 1) {
            $x += $col_maxes[$_];
        }

        # Find the Y location for this component by adding up each row height
        # from 0 to the current row
        my $y = $oy;
        for(0..$row - 1) {
            $y += $row_maxes[$_];
        }

        # Find the component's width by adding the widths of the all the cells
        # the component appears in.
        my $cell_width = 0;
        for($col..$col + $width - 1) {
            $cell_width += $col_maxes[$_];
        }

        # Find the component's height by adding the heights of the all the
        # cells the component appears in.
        my $cell_height = 0;
        for($row..$row + $height - 1) {
            $cell_height += $row_maxes[$_];
        }

        $co->x($x);
        $co->y($y);
        $comp->width($cell_width);
        $comp->height($cell_height);
    }

    super;

    return 1;
});

__PACKAGE__->meta->make_immutable;

no Moose;

1;
__END__
=head1 NAME

Layout::Manager::Grid - Simple grid-based layout manager.

=head1 DESCRIPTION

Layout::Manager::Grid is a layout manager places components into evenly
divided cells.

When you instantiate a Grid manager, you must supply it with a count of how
many rows and columns it will have.  For example, a Grid with 1 column and
2 rows would look like:

  +--------------------------------+
  |                                |
  |           component 1          |
  |                                |
  +--------------------------------+
  |                                |
  |           component 2          |
  |                                |
  +--------------------------------+

The container is divided into as many <rows> * <columns> cells, with each
taking up an equal amount of space.  A grid with 3 columns and 2 rows would
create 6 cells that consume 33% of the width and 50% of the height.

Components are placed by specifying the cell they reside in via the row and 
column number.

  $container->add_component($comp, { row => 0, column => 3 });

  $container->add_component($comp, { row => 0, column => 2, height => 2 });
  
Optionally, you may choose to override the default C<width> or C<height> of 1.
Setting it to a something else will cause the component to consume that many
rows or columns worth of space.

Grid is similar to Java's
L<GridLayout|http://java.sun.com/docs/books/tutorial/uiswing/layout/grid.html>.

=head1 SYNOPSIS

  $cont->add_component($comp1, { row => 0, column => 1 });
  $cont->add_component($comp2, { row => 0, column => 2 });

  my $lm = Layout::Manager::Grid->new(rows => 1, columns => 2);
  $lm->do_layout($con);

=head2 DYNAMIC SIZING

If the container that the Grid is manging does not have one or both of it's
dimensions set, Grid will compute the appropriate sizes.  The simple way for
me to avoid writing a long explanation is to say it works similar to HTML
tables.  Rows will become as big as their biggest consituent, as will
columns.  It is common to add a Grid-managed component to a scene with only
one of it's dimensions set.

=head1 ATTRIBUTES

=head2 columns

The number of columns in this Grid.

=head2 rows

The number of rows in this Grid.

=head1 METHODS

=head2 do_layout

Size and position the components in this layout.

=head1 AUTHOR

Cory Watson, C<< <gphat@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 - 2010 Cory G Watson

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.