package Layout::Manager::Compass;
use Moose;

extends 'Layout::Manager';

override('do_layout', sub {
    my ($self, $container) = @_;

    return 0 if $container->prepared && $self->_check_container($container);

    super;

    my $bbox = $container->inside_bounding_box;

    my $bboxoy = $bbox->origin->y;
    my $bboxox = $bbox->origin->x;

    my $coheight = $container->outside_height;
    my $cowidth = $container->outside_width;
    my $cwidth = $bbox->width;
    my $cheight = $bbox->height;

    my %edges = (
        north => { components => [], width => 0, height => 0 },
        south => { components => [], width => 0, height => 0 },
        east => { components => [], width => 0, height => 0 },
        west => { components => [], width => 0, height => 0 },
        center => { components => [], width => 0, height => 0 }
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

        if(($args) eq 'c') {

            push(@{ $edges{center}->{components} }, $comp);
            $edges{center}->{height} += $comp->minimum_height;
            $self->_geassign($edges{center}->{width}, $comp->minimum_width);
        } elsif($args eq 'n') {

            push(@{ $edges{north}->{components} }, $comp);
            $edges{north}->{height} += $comp->minimum_height;
            $self->_geassign($edges{north}->{width}, $comp->minimum_width);
        } elsif($args eq 's') {

            push(@{ $edges{south}->{components} }, $comp);
            $edges{south}->{height} += $comp->minimum_height;
            $self->_geassign($edges{south}->{width}, $comp->minimum_width);
        } elsif($args eq 'e') {

            push(@{ $edges{east}->{components} }, $comp);
            $self->_geassign($edges{east}->{height}, $comp->minimum_height);
            $edges{east}->{width} += $comp->minimum_width;
        } elsif($args eq 'w') {

            push(@{ $edges{west}->{components} }, $comp);
            $self->_geassign($edges{west}->{height}, $comp->minimum_height);
            $edges{west}->{width} += $comp->minimum_width;
        } else {

            die("Unknown direction '$args' for component $comp.");
        }
    }

    # Resize the container to the bare minimum that we expect to need, if
    # it's not already that big...
    if(!$cheight) {
        $self->_geassign($cheight, $edges{north}->{height}
            + $edges{south}->{height} + $container->outside_height
        );

        my $sheight = $edges{east}->{height};
        $self->_geassign($sheight, $edges{west}->{height});
        $self->_geassign($sheight, $edges{center}->{height});
        $self->_geassign($cheight, $cheight + $sheight);
    }
    $self->_geassign($cwidth, $edges{east}->{width} + $edges{west}->{width}
        + $edges{center}->{width});

    # Each of these loops iterate over their respective edge and 'fit' each
    # component in the order they were added.  First they set either a height
    # or width (whatever they can).  If the component is a container, then
    # that container will be laid out.  After that adjustments will be made
    # to the container (if necessary) and the component will be positioned.

    ### NORTH ####
    my $yaccum = $bboxoy;
    $edges{north}->{height} = 0;
    foreach my $comp (@{ $edges{north}->{components} }) {
        $comp->width($cwidth);
        my $co = $comp->origin;
        $co->x($bboxox);
        $co->y($yaccum);

        # Give a sub-container a chance to size itself since we've given
        # it all the information we can.
        # TODO Check::ISA
        if($comp->can('do_layout')) {
            $self->_layout_container($comp);
        }

        $self->_geassign($cheight, $comp->height);
        $self->_geassign($cwidth, $comp->width);

        $edges{north}->{height} += $comp->height;
        $yaccum += $comp->height;
    }

    ### SOUTH ####
    $yaccum = $bboxoy + $cheight;
    $edges{south}->{height} = 0;
    foreach my $comp (@{ $edges{south}->{components} }) {
        $comp->width($cwidth) if $cwidth;
        $comp->origin->x($bboxox);

        # Give a sub-container a chance to size itself since we've given
        # it all the information we can.
        # TODO Check::ISA
        if($comp->can('do_layout')) {
            $self->_layout_container($comp);
        }

        $self->_geassign($cheight, $comp->height);
        $self->_geassign($cwidth, $comp->width);

        $edges{south}->{height} += $comp->height;
        $comp->origin->y($yaccum - $comp->height);
        $yaccum -= $comp->height;
    }

    # Compass layout uses a minimum of height and width for the 4 edges and
    # then allocates all leftover space equally to items in the center.
    my $cen_height = $cheight - $edges{north}->{height} - $edges{south}->{height};
    my $cen_width = $cwidth - $edges{east}->{width} - $edges{west}->{width};

    $self->_geassign($cen_height, $edges{east}->{height});
    $self->_geassign($cen_height, $edges{west}->{height});

    ### EAST ###
    # Prime our x position
    my $xaccum  = $bboxox + $cwidth;
    # Reset the east width, since we're about to do it for reals
    $edges{east}->{width} = 0;
    foreach my $comp (@{ $edges{east}->{components} }) {
        # If the size we have available in the east slot is greater than the
        # minimum height of the component then we'll resize.
        $comp->height($cen_height);# if $cen_height;
        $comp->origin->y($bboxoy + $edges{north}->{height});

        if($comp->can('do_layout')) {
            $self->_layout_container($comp);
        }

        $self->_geassign($cheight, $comp->height);
        $self->_geassign($cwidth, $comp->width);
        $edges{east}->{width} += $comp->width;
        $xaccum -= $comp->width;

        $comp->origin->x($xaccum);
    }

    ### WEST ###
    $xaccum = $bboxox;
    $edges{west}->{width} = 0;
    foreach my $comp (@{ $edges{west}->{components} }) {
        $comp->height($cen_height);# if $cen_height;
        $comp->origin->y($bboxoy + $edges{north}->{height});

        # Give a sub-container a chance to size itself since we've given
        # it all the information we can.
        # TODO Check::ISA
        if($comp->can('do_layout')) {
            $self->_layout_container($comp);
        }

        $self->_geassign($cheight, $comp->height);
        $self->_geassign($cwidth, $comp->width);
        $edges{west}->{width} += $comp->width;
        $comp->origin->x($xaccum);
        $xaccum += $comp->width;
    }

    my $ccount = scalar(@{ $edges{center}->{components} });
    if($ccount) {
        my $per_height = $cen_height / $ccount;

        my $i = 1;
        foreach my $comp (@{ $edges{center}->{components}}) {
            $comp->height($per_height);
            $comp->width($cen_width) if $cen_width;

            $comp->origin->x($bboxox + $edges{west}->{width});
            $comp->origin->y($bboxoy + $edges{north}->{height} + ($per_height * ($i - 1)));

            # TODO Check::ISA
            if($comp->can('do_layout')) {
                $self->_layout_container($comp);
            }

            $i++;
        }
    }

    # Our 'side' width is the bigger of the south/north (they will be equal if
    # they both exist...)
    my $side_width = $edges{north}->{width};
    $self->_geassign($side_width, $edges{south}->{width});
    $self->_geassign($side_width, $edges{center}->{width}
        + $edges{east}->{width} + $edges{west}->{width});

    $cheight += $coheight;

    # Increase the minimum height and width of the container to accomodate
    # the laid out components.
    $container->minimum_width($side_width);
    $container->minimum_height($cheight);

    # If the width and height of the container are not sufficient, expand
    # them.
    if($container->width < $container->minimum_width) {
        $container->width($container->minimum_width);
    }
    if($container->height < $container->minimum_height) {
        $container->height($container->minimum_height);
    }

    $container->prepared(1);
    return 1;
});

sub _layout_container {
    my ($self, $comp) = @_;

    $comp->do_layout($comp, $self);
    if($comp->minimum_width > $comp->width) {
        $comp->width($comp->minimum_width);
    }
    if($comp->minimum_height > $comp->height) {
        $comp->height($comp->minimum_height);
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

Layout::Manager::Compass - Compass based layout

=head1 DESCRIPTION

Layout::Manager::Compass is a layout manager that takes hints based on the
four cardinal directions (north, east, south and west) plus a center area that
takes up all remaining space (vertically).

In other words, the center area will expand to take up all space that is NOT
used by components placed at the edges.  Components at the north and south
edges will take up the full width of the container.

  +--------------------------------+
  |              north             |
  +-----+--------------------+-----+
  |     |                    |     |
  |  w  |                    |  e  |
  |  e  |       center       |  a  |
  |  s  |                    |  s  |
  |  t  |                    |  t  |
  |     |                    |     |
  +-----+--------------------+-----+
  |              south             |
  +--------------------------------+

Components are placed in the order they are added.  If two items are added
to the 'north' position then the first item will be rendered above the
second.  The height of the north edge will equal the height of both components
combined.

Items in the center split the available space, heightwise.  Two center
components will each take up 50% of the available height and 100% of the
available width.

Compass is basically an implementation of Java's
L<BorderLayout|http://java.sun.com/docs/books/tutorial/uiswing/layout/border.html>

=head1 SYNOPSIS

  $cont->add_component($comp1, 'north');
  $cont->add_component($comp2, 'east');

  my $lm = Layout::Manager::Compass->new;
  $lm->do_layout($cont);

=head1 POSITIONING

When you add a component with I<add_component> the second argument should be
one of: B<north>, B<south>, B<east>, B<west> or B<center>.  Case doesn't
matter.  You can also just provide the first letter of the word and it will do
the same thing.

=head1 METHODS

=head2 do_layout

Size and position the components in this layout.

=head1 AUTHOR

Cory Watson, C<< <gphat@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 - 2010 Cory G Watson

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.