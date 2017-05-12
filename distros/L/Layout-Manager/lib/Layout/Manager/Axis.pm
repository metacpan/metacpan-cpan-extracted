package Layout::Manager::Axis;
use Moose;

extends 'Layout::Manager';

override('do_layout', sub {
    my ($self, $container) = @_;

    return 0 if $container->prepared && $self->_check_container($container);

    my $bbox = $container->inside_bounding_box;

    my $cwidth = $bbox->width;
    my $cheight = $bbox->height;

    my %edges = (
        north => { components => [], width => $cwidth, height => 0 },
        south => { components => [], width => $cwidth, height => 0 },
        east => { components => [], width => 0, height => $cheight },
        west => { components => [], width => 0, height => $cheight },
        center => { components => [], width => $cwidth, height => $cheight }
    );

    # This loop takes each component and adds it's width and height to the
    # 'edge' on which is positioned.  At the end will know how much width and
    # height we need for each edge.
    for(my $i = 0; $i < scalar(@{ $container->components }); $i++) {

        my $comp = $container->get_component($i);

        next unless defined($comp) && $comp->visible;

        # Set each component to it's minimum size for now
        $comp->width($comp->minimum_width);
        $comp->height($comp->minimum_height);

        my $args = lc(substr($container->get_constraint($i), 0, 1));

        if($comp->can('do_layout')) {
            $self->_layout_container($comp);
        }

        if(($args) eq 'c') {

            push(@{ $edges{center}->{components} }, $comp);
        } elsif($args eq 'n') {

            push(@{ $edges{north}->{components} }, $comp);
            $edges{north}->{height} += $comp->minimum_height;
            $edges{east}->{height} -= $comp->minimum_height;
            $edges{west}->{height} -= $comp->minimum_height;
            $edges{center}->{height} -= $comp->minimum_height;

        } elsif($args eq 's') {

            push(@{ $edges{south}->{components} }, $comp);
            $edges{south}->{height} += $comp->minimum_height;
            $edges{east}->{height} -= $comp->minimum_height;
            $edges{west}->{height} -= $comp->minimum_height;
            $edges{center}->{height} -= $comp->minimum_height;
        } elsif($args eq 'e') {

            push(@{ $edges{east}->{components} }, $comp);
            $edges{east}->{width} += $comp->minimum_width;
            $edges{north}->{width} -= $comp->minimum_width;
            $edges{south}->{width} -= $comp->minimum_width;
            $edges{center}->{width} -= $comp->minimum_width;
        } elsif($args eq 'w') {

            push(@{ $edges{west}->{components} }, $comp);
            $edges{west}->{width} += $comp->minimum_width;
            $edges{north}->{width} -= $comp->minimum_width;
            $edges{south}->{width} -= $comp->minimum_width;
            $edges{center}->{width} -= $comp->minimum_width;
        } else {

            die("Unknown direction '$args' for component $comp.");
        }
    }

    # Relayout the west
    my $x = $bbox->origin->x;
    my $y = $bbox->origin->y + $edges{north}->{height};
    foreach my $comp (@{ $edges{west}->{components} }) {
        $comp->origin->x($x);
        $comp->origin->y($y);
        $comp->height($edges{center}->{height});
        if($comp->can('do_layout')) {
            $comp->do_layout($comp);
        }
        $x += $comp->width;
    }

    # Relayout the east
    $x = $bbox->origin->x + $bbox->width;
    $y = $bbox->origin->y + $edges{north}->{height};
    foreach my $comp (@{ $edges{east}->{components} }) {

        $x -= $comp->width;

        $comp->origin->x($x);
        $comp->origin->y($y);
        $comp->height($edges{center}->{height});
        if($comp->can('do_layout')) {
            $comp->do_layout($comp);
        }
    }

    # Relayout the south
    $x = $bbox->origin->x + $edges{west}->{width};
    $y = $bbox->origin->y + $cheight;
    foreach my $comp (@{ $edges{south}->{components} }) {

        $y -= $comp->height;

        $comp->origin->x($x);
        $comp->origin->y($y);
        $comp->width($edges{center}->{width});
        if($comp->can('do_layout')) {
            $comp->do_layout($comp);
        }
    }

    # Relayout the north
    $x = $bbox->origin->x + $edges{west}->{width};
    $y = $bbox->origin->y;
    foreach my $comp (@{ $edges{north}->{components} }) {

        $comp->origin->x($x);
        $comp->origin->y($y);
        $comp->width($edges{center}->{width});
        if($comp->can('do_layout')) {
            $comp->do_layout($comp);
        }
        $y += $comp->width;
    }

    # Relayout the center
    $x = $bbox->origin->x + $edges{west}->{width};
    $y = $bbox->origin->y + $edges{north}->{height};
    my $ccount = scalar(@{ $edges{center}->{components} });
    # Skip this if there are no center components.
    if($ccount) {
        my $per = $edges{center}->{height} / $ccount;
        my $i = 0;
        foreach my $comp (@{ $edges{center}->{components} }) {

            $comp->origin->x($x);
            $comp->origin->y($y + ($i * $per));
            $comp->width($edges{center}->{width});
            $comp->height($per);
            if($comp->can('do_layout')) {
                $comp->do_layout($comp);
            }

            $i++;
        }
    }

    # foreach my $comp (@{ $container->components }) {
    #     $comp->prepared(1) if defined($comp);
    # }

    $container->prepared(1);
    return 1;
});

sub _layout_container {
    my ($self, $comp) = @_;

    $comp->do_layout($comp, $self);
    if($comp->minimum_width > $comp->width) {
        $comp->width = $comp->minimum_width;
    }
    if($comp->minimum_height > $comp->height) {
        $comp->height = $comp->minimum_height;
    }
}

sub _geassign {
    $_[1] = $_[2] if $_[2] > $_[1];
};

__PACKAGE__->meta->make_immutable;

no Moose;

1;
__END__
=head1 NAME

Layout::Manager::Axis - Compass-like resizing managers

=head1 DESCRIPTION

Axis is I<very> similar to L<Compass|Layout::Manager::Compass> with one
exception:  Components added to the east and west consume space on the
sides of of the north and south.  

Components at the north and south are resized when east and west components
are added.

  +--------------------------------+
  |  x  |        north       |  x  |
  +-----+--------------------+-----+
  |     |                    |     |
  |  w  |                    |  e  |
  |  e  |       center       |  a  |
  |  s  |                    |  s  |
  |  t  |                    |  t  |
  |     |                    |     |
  +-----+--------------------+-----+
  |  x  |      south         |  x  |
  +--------------------------------+

The B<x> boxes above will effectively be dead-space.  No components will
occupy those areas.

Why, you ask?  Some components (such as axes on a chart, for which this
manager is named) need to be the B<exact> same hight or with as the center
component. If the chart area is represented by the center area and an axis
is positioned to the west, it needs to know how big the center is to
accurately draw tick marks.

=head1 SYNOPSIS

  $cont->add_component($comp1, 'north');
  $cont->add_component($comp2, 'east');

  my $lm = Layout::Manager::Axis->new;
  $lm->do_layout($cont);


=head1 POSITIONING

When you add a component with I<add_component> the second argument should be
one of: north, south, east, west or center.  Case doesn't matter.  You can
also just provide the first letter of the word and it will do the same thing.

=head1 METHODS

=head2 do_layout

Size and position the components in this layout.

=head1 AUTHOR

Cory Watson, C<< <gphat@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 - 2010 Cory G Watson

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
