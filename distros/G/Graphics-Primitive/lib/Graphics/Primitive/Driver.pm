package Graphics::Primitive::Driver;
use Moose::Role;

requires qw(
    _draw_arc _draw_bezier _draw_canvas _draw_circle _draw_component
    _draw_ellipse _draw_line _draw_path _draw_polygon _draw_rectangle
    _draw_textbox _do_fill _do_stroke _finish_page _resize data
    get_textbox_layout reset write
);

has 'height' => (
    is => 'rw',
    isa => 'Num'
);
has 'width' => (
    is => 'rw',
    isa => 'Num'
);

sub draw {
    my ($self, $comp) = @_;

    if($comp->page) {
        # FIRST_PAGE is a little protection to ensure that we don't call
        # show page on the first page, as that would mean we'd have an
        # empty first page all the time.
        if($self->{FIRST_PAGE}) {
            $self->_finish_page;
        } else {
            $self->{FIRST_PAGE} = 1;
        }
        $self->_resize($comp->width, $comp->height);
    }

    die('Components must be objects.') unless ref($comp);
    # The order of this is important, since isa will return true for any
    # superclass...
    # TODO Check::ISA
    if($comp->isa('Graphics::Primitive::Canvas')) {
        $self->_draw_canvas($comp);
    } elsif($comp->isa('Graphics::Primitive::Image')) {
        $self->_draw_image($comp);
    } elsif($comp->isa('Graphics::Primitive::TextBox')) {
        $self->_draw_textbox($comp);
    } elsif($comp->isa('Graphics::Primitive::Component')) {
        $self->_draw_component($comp);
    }

    if($comp->isa('Graphics::Primitive::Container')) {
        if($comp->can('components')) {
            foreach my $subcomp (@{ $comp->components }) {
                $self->draw($subcomp);
            }
        }
    }
}

sub finalize {
    my ($self, $comp) = @_;

    $comp->finalize($self);

    if($comp->isa('Graphics::Primitive::Container')) {
        foreach my $c (@{ $comp->components }) {
            next unless defined($c) && defined($c)
                && $c->visible;
            $self->finalize($c);
        }
    }
}

sub prepare {
    my ($self, $comp) = @_;

    unless(defined($self->width)) {
        $self->width($comp->width);
    }
    unless(defined($self->height)) {
        $self->height($comp->height);
    }

    $comp->prepare($self);

    # TODO Check::ISA
    if($comp->isa('Graphics::Primitive::Container')) {
        foreach my $c (@{ $comp->components }) {
            next unless defined($c) && $c->visible;
            $self->prepare($c);
        }
    }
}

no Moose;
1;
__END__

=head1 NAME

Graphics::Primitive::Driver - Role for driver implementations

=head1 DESCRIPTION

What good is a library agnostic intermediary representation of graphical
components if you can't feed them to a library specific implementation that
turns them into drawings? Psht, none!

To write a driver for Graphics::Primitive implement this role.

=head1 SYNOPSIS

  my $c = Graphics::Primitive::Component->new({
    origin => Geometry::Primitive::Point->new({
        x => $x, y => $y
    }),
    width => 500, height => 350
  });

=head1 CANVASES

When a path is added to the internal list via I<do>, it is stored in the
I<paths> attribute as a hashref.  The hashref has two keys: B<path> and B<op>.
The path is, well, the path.  The op is the operation provided to I<do>.  As
canvases are just lists of paths you should consult the next section as well.

=head1 PATHS AND HINTING

Paths are lists of primitives.  Primitives are all descendants of
L<Geometry::Shape> and therefore have I<point_start> and I<point_end>.  These
two attributes allow the chaining of primitives.  To draw a path you should
iterate over the primitives, drawing each.

When you pull each path from the arrayref you should pull it's accompanying
hints via I<get_hint> (the indexes match).  The hint may provide you with
additional information:

=head2 PRIMITIVE HINTS

=over 4

=item I<contiguous>

True if this primitive is contiguous with the previous one.  Example: Used to
determine if a new sub-path is needed for the Cairo driver.

=back

=head2 OPERATION HINTS

=over 4

=item I<preserve>

=back

=head1 WARNING

Only this class or the driver itself should call methods starting with an
underscore, as this interface may change.

=head1 METHODS

=over 4

=item I<_do_stroke ($strokeop)>

Perform a stroke.

=item I<_do_fill ($fillop)>

Perform a fill.

=item I<_draw_arc ($arc)>

Draw an arc.

=item I<_draw_canvas ($canvas)>

Draw a canvas.

=item I<_draw_component ($comp)>

Draw a component.

=item I<_draw_line ($line)>

Draw a line.

=item I<_draw_rectangle ($rect)>

Draw a rectangle.

=item I<_draw_textbox>

Draw a textbox.

=item I<_resize ($width, $height)>

Resize the current working surface to the size specified.

=item I<_finish_page>

Finish the current 'page' and start a new one.  Some drivers that are not
paginated may need to emulate this behaviour.

=item I<data>

Retrieve the results of this driver's operations.

=item I<draw>

Draws the given Graphics::Primitive::Component.  If the component is a
container then all components therein are drawn, recursively.

=item I<get_text_bounding_box>

Given a L<Font|Graphics::Primitive::Font> and a string, returns a bounding box
of the rendered text.

=item I<finalize>

Finalize the supplied component and any child components, recursively.

=item I<prepare>

Prepare the supplied component and any child components, recursively.

=item I<write>

Write out the results of this driver's operations to the specified file.

=back

=head1 AUTHOR

Cory Watson, C<< <gphat@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008-2010 by Cory G Watson.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.