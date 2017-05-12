package Layout::Manager::Flow;
use Moose;

extends 'Layout::Manager';

use Moose::Util::TypeConstraints;

enum 'Layout::Manager::Flow::Anchors', [qw(north south east west)];

has 'anchor' => (
    is => 'rw',
    isa => 'Layout::Manager::Flow::Anchors',
    default => sub { 'north' }
);

has 'expand' => (
    is => 'rw',
    isa => 'Bool',
    default => sub { 1 }
);

has 'used' => (
    is => 'rw',
    isa => 'ArrayRef',
    default => sub { [0, 0] }
);

has 'wrap' => (
    is => 'rw',
    isa => 'Bool',
    default => sub { 0 }
);

override('do_layout', sub {
    my ($self, $container) = @_;

    my $bbox = $container->inside_bounding_box;

    my $cwidth = $bbox->width;
    my $cheight = $bbox->height;

    my $ox = $bbox->origin->x;
    my $oy = $bbox->origin->y;

    my $anch = $self->anchor;

    my @lines;
    my $yused = $oy;
    my $xused = $ox;

    my $line = 0;
    foreach my $comp (@{ $container->components }) {

        next unless defined($comp) && $comp->visible;

        $comp->width($comp->minimum_width);
        $comp->height($comp->minimum_height);

        # If we aren't wrapping, expand to fill the whole space
        if(($anch eq 'north') || ($anch eq 'south')) {
            unless($self->wrap) {
                $comp->width($cwidth) if $cwidth;
            }
        } else {
            unless($self->wrap) {
                $comp->height($cheight) if $cheight;
            }
        }

        my $comp_height = $comp->height;
        my $comp_width = $comp->width;

        unless(defined($lines[$line])) {
            $lines[$line] = {
                tallest => $comp_height || 0,
                widest => $comp_width || 0,
                height => 0,
                width => 0,
                components => []
            };
        }

        # Keep up with the tallest component we find
        if(!($lines[$line]->{tallest}) || $comp_height > $lines[$line]->{tallest}) {
            $lines[$line]->{tallest} = $comp_height;
        }
        # Keep up with the widest component we find
        if(!($lines[$line]->{widest}) || $comp_width > $lines[$line]->{widest}) {
            $lines[$line]->{widest} = $comp_width;
        }

        my $co = $comp->origin;

        if($anch eq 'north') {

            # No wrapping
            $co->x($ox);
            $co->y($oy + $lines[$line]->{height});
            $lines[$line]->{height} += $comp_height;
            unless($lines[$line]->{width}) {
                $lines[$line]->{width} = $comp_width;
            }
        } elsif($anch eq 'south') {

            # No wrapping
            $co->x($ox);
            $co->y($oy + $cheight - $comp_height - $lines[$line]->{height});
            $lines[$line]->{height} += $comp_height;
            unless($lines[$line]->{width}) {
                $lines[$line]->{width} = $comp_width;
            }
        } elsif($anch eq 'east') {

            if(
                # It doesn't matter if we are supposed to wrap if we have
                # no width, we'll make this thing as big as it needs to be
                ($cwidth > 0) &&
                # if we are wrapping
                ($self->wrap) &&
                # and the current component would overflow...
                ($lines[$line]->{width} + $comp_width > $cwidth) &&
                scalar(@{ $lines[$line]->{components} })
            ) {
                # We've been asked to wrap and this component is too wide
                # to fit.  Move down by the height of the tallest component
                # then reset the tallest variable.
                $yused += $lines[$line]->{tallest};
                $co->x($cwidth - $comp_width - $ox);
                $co->y($oy + $yused);

                $line++;

                $lines[$line]->{width} = $ox + $comp_width;
                $lines[$line]->{tallest} = $comp_height;
            } else {
                $co->x($ox + $cwidth - $comp_width - $lines[$line]->{width});
                $co->y($yused);
                $lines[$line]->{width} += $comp_width;
            }
        } else {

            # WEST
            if(
                # It doesn't matter if we are supposed to wrap if we have
                # no width, we'll make this thing as big as it needs to be
                ($cwidth > 0) &&
                # if we are wrapping
                ($self->wrap) &&
                # and the current component would overflow...
                ($lines[$line]->{width} + $comp_width > $cwidth) &&
                scalar(@{ $lines[$line]->{components} })
            ) {
                # We've been asked to wrap and this component is too wide
                # to fit.  Move down by the height of the tallest component
                # then reset the tallest variable.
                $yused += $lines[$line]->{tallest};
                $co->x($ox);
                $co->y($yused);

                $line++;
                $lines[$line]->{width} = $ox + $comp_width;
                $lines[$line]->{tallest} = $comp_height;
            } else {
                $co->x($ox + $lines[$line]->{width});
                $co->y($yused);
                $lines[$line]->{width} += $comp_width;
            }
        }
        push(@{ $lines[$line]->{components} }, $comp);
    }


    my $fwidth = 0;
    my $fheight = 0;

    foreach my $l (@lines) {
        unless($l->{height}) {
            $l->{height} = $l->{tallest};
        }
        $fheight += $l->{height};
        if($l->{width} > $fwidth) {
            $fwidth = $l->{width};
        }
    }
    $self->used([$fwidth, $fheight]);

    $container->minimum_width($fwidth + $container->outside_width);
    $container->minimum_height($fheight + $container->outside_height);

    # Size our container, now that everything is done.
    if($container->width < $container->minimum_width) {
        $container->width($container->minimum_width);
    }
    if($container->height < $container->minimum_height) {
        $container->height($container->minimum_height);
    }

    super;

    return 1;
});

__PACKAGE__->meta->make_immutable;

no Moose;

1;
__END__
=head1 NAME

Layout::Manager::Flow - Directional layout manager

=head1 DESCRIPTION

Layout::Manager::Flow is a layout manager that anchors components in one of
the four cardinal directions.

When you instantiate a Flow manager, you may supply it with an anchor value
which may be one of north, south, east or west.  The example below shows
how the default anchor value of north works when you add two components.

                 north
  +--------------------------------+
  |           component 1          |
  +--------------------------------+
  |           component 2          |
  +--------------------------------+
  |                                |
  |                                |
  |                                |
  +--------------------------------+

Components are placed in the order they are added.  If two items are added
with a 'north' anchor then the first item will be rendered above the
second.  Components will be expanded to take up all space perpendicular to
their anchor.  North and south will expand widths while east and west will
expand heights.

Flow is similar to Java's
L<FlowLayout|http://java.sun.com/docs/books/tutorial/uiswing/layout/flow.html>.
It does not, however, center components.  This features may be added in the
future if they are needed.

=head1 SYNOPSIS

  $cont->add_component($comp1);
  $cont->add_component($comp2);

  my $lm = Layout::Manager::Flow->new(anchor => 'north');
  $lm->do_layout($cont);

=head1 ATTRIBUTES

=head2 anchor

The direction this manager is anchored.  Valid values are north, south, east
and west.

=head2 used

Returns the amount of space used an arrayref in the form of C<[ $width, $height ]>.

=head2 wrap

If set to a true value, then component will be 'wrapped' when they do not
fit.  B<This currently only works for East and West anchored layouts.>

=head1 METHODS

=head2 do_layout

Size and position the components in this layout.

=head1 AUTHOR

Cory Watson, C<< <gphat@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 by Cory G Watson

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
