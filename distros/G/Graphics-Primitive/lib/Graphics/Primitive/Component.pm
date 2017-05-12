package Graphics::Primitive::Component;
use Moose;
use MooseX::Storage;

use overload ('""' => 'to_string');

with Storage('format' => 'JSON', 'io' => 'File');

use Forest::Tree;
use Graphics::Primitive::Border;
use Graphics::Primitive::Insets;
use Geometry::Primitive::Point;
use Geometry::Primitive::Rectangle;

has 'background_color' => (
    is => 'rw',
    isa => 'Graphics::Color',
    trigger => sub { my ($self) = @_; $self->prepared(0); }
);
has 'border' => (
    is => 'rw',
    isa => 'Graphics::Primitive::Border',
    default => sub { Graphics::Primitive::Border->new },
    trigger => sub { my ($self) = @_; $self->prepared(0); }
);
has 'callback' => (
    traits => ['Code'],
    is => 'rw',
    isa => 'CodeRef',
    predicate => 'has_callback',
    handles => {
        fire_callback => 'execute'
    }
);
has 'class' => ( is => 'rw', isa => 'Str' );
has 'color' => (
    is => 'rw', isa => 'Graphics::Color',
    trigger => sub { my ($self) = @_; $self->prepared(0); },
    trigger => sub { my ($self) = @_; $self->prepared(0); }
);
has 'height' => (
    is => 'rw',
    isa => 'Num',
    default => sub { 0 },
    trigger => sub { my ($self) = @_; $self->prepared(0); if($self->height < $self->minimum_height) { $self->height($self->minimum_height); } }
);
has 'margins' => (
    is => 'rw',
    isa => 'Graphics::Primitive::Insets',
    default => sub { Graphics::Primitive::Insets->new },
    coerce => 1,
    trigger => sub { my ($self) = @_; $self->prepared(0); }
);
has 'minimum_height' => (
    is => 'rw',
    isa => 'Num',
    default => sub { 0 },
    trigger => sub { my ($self) = @_; $self->prepared(0); }
);
has 'minimum_width' => (
    is => 'rw',
    isa => 'Num',
    default => sub { 0 },
    trigger => sub { my ($self) = @_; $self->prepared(0); }
);
has 'name' => ( is => 'rw', isa => 'Str' );
has 'origin' => (
    is => 'rw',
    isa => 'Geometry::Primitive::Point',
    default =>  sub { Geometry::Primitive::Point->new( x => 0, y => 0 ) },
    trigger => sub { my ($self) = @_; $self->prepared(0); }
);
has 'padding' => (
    is => 'rw',
    isa => 'Graphics::Primitive::Insets',
    default => sub { Graphics::Primitive::Insets->new },
    coerce => 1,
    trigger => sub { my ($self) = @_; $self->prepared(0); }
);
has 'page' => ( is => 'rw', isa => 'Bool', default => sub { 0 } );
has 'parent' => (
    is => 'rw',
    isa => 'Maybe[Graphics::Primitive::Component]',
    weak_ref => 1
);
has 'prepared' => ( is => 'rw', isa => 'Bool', default => sub { 0 } );
has 'visible' => ( is => 'rw', isa => 'Bool', default => sub { 1 } );
has 'width' => (
    is => 'rw',
    isa => 'Num',
    default => sub { 0 },
    trigger => sub { my ($self) = @_; $self->prepared(0); if($self->width < $self->minimum_width) { $self->width($self->minimum_width); } }
);

sub get_tree {
    my ($self) = @_;

    return Forest::Tree->new(node => $self);
}

sub inside_width {
    my ($self) = @_;

    my $w = $self->width;

    my $padding = $self->padding;
    my $margins = $self->margins;
    my $border = $self->border;

    $w -= $padding->left + $padding->right;
    $w -= $margins->left + $margins->right;

    $w -= $border->left->width + $border->right->width;

    $w = 0 if $w < 0;

    return $w;
}

sub minimum_inside_width {
    my ($self) = @_;

    my $w = $self->minimum_width;

    my $padding = $self->padding;
    my $margins = $self->margins;
    my $border = $self->border;

    $w -= $padding->left + $padding->right;
    $w -= $margins->left + $margins->right;

    $w -= $border->left->width + $border->right->width;

    $w = 0 if $w < 0;

    return $w;
}

sub inside_height {
    my ($self) = @_;

    my $h = $self->height;

    my $padding = $self->padding;
    my $margins = $self->margins;
    my $border = $self->border;

    $h -= $padding->bottom + $padding->top;
    $h -= $margins->bottom + $margins->top;
    $h -= $border->top->width + $border->bottom->width;

    $h = 0 if $h < 0;

    return $h;
}

sub minimum_inside_height {
    my ($self) = @_;

    my $h = $self->minimum_height;

    my $padding = $self->padding;
    my $margins = $self->margins;
    my $border = $self->border;

    $h -= $padding->bottom + $padding->top;
    $h -= $margins->bottom + $margins->top;
    $h -= $border->top->width + $border->bottom->width;

    $h = 0 if $h < 0;

    return $h;
}

sub inside_bounding_box {

    my ($self) = @_;

    my $padding = $self->padding;
    my $margins = $self->margins;
    my $border = $self->border;

    my $rect = Geometry::Primitive::Rectangle->new(
        origin => Geometry::Primitive::Point->new(
            x => $padding->left + $border->left->width + $margins->left,
            y => $padding->top + $border->right->width + $margins->top
        ),
        width => $self->inside_width,
        height => $self->inside_height
    );
}

sub outside_width {
    my $self = shift();

    my $padding = $self->padding;
    my $margins = $self->margins;
    my $border = $self->border;

    my $w = $padding->left + $padding->right;
    $w += $margins->left + $margins->right;
    $w += $border->left->width + $border->right->width;

    return $w;
}

sub outside_height {
    my $self = shift();

    my $padding = $self->padding;
    my $margins = $self->margins;
    my $border = $self->border;

    my $w = $padding->top + $padding->bottom;
    $w += $margins->top + $margins->bottom;
    $w += $border->bottom->width + $border->top->width;

    return $w;
}

sub finalize {
    my ($self) = @_;

    $self->fire_callback($self) if $self->has_callback;
}

sub prepare {
    my ($self, $driver) = @_;

    return if $self->prepared;

    unless($self->minimum_width) {
        $self->minimum_width($self->outside_width);
    }
    unless($self->minimum_height) {
        $self->minimum_height($self->outside_height);
    }
}

sub to_string {
    my ($self) = @_;

    my $buff = defined($self->name) ? $self->name : ref($self);
    $buff .= ': '.$self->origin->to_string;
    $buff .= ' ('.$self->width.'x'.$self->height.')';
    return $buff;
}

__PACKAGE__->meta->make_immutable;

no Moose;
1;
__END__

=head1 NAME

Graphics::Primitive::Component - Base graphical unit

=head1 DESCRIPTION

A Component is an entity with a graphical representation.

=head1 SYNOPSIS

  my $c = Graphics::Primitive::Component->new({
    origin => Geometry::Primitive::Point->new({
        x => $x, y => $y
    }),
    width => 500, height => 350
  });

=head1 LIFECYCLE

=over 4

=item B<prepare>

Most components do the majority of their setup in the B<prepare>.  The goal of
prepare is to establish it's minimum height and width so that it can be
properly positioned by a layout manager.

  $driver->prepare($comp);

=item B<layout>

This is not a method of Component, but a phase introduced by the use of
L<Layout::Manager>.  If the component is a container then each of it's
child components (even the containers) will be positioned according to the
minimum height and width determined during B<prepare>.  Different layout
manager implementations have different rules, so consult the documentation
for each for details.  After this phase has completed the origin, height and
width should be set for all components.

  $lm->do_layout($comp);

=item B<finalize>

This final phase provides and opportunity for the component to do any final
changes to it's internals before being passed to a driver for drawing.
An example might be a component that draws a fleuron at it's extremities.
Since the final height and width isn't known until this phase, it was
impossible for it to position these internal components until now.  It may
even defer creation of this components until now.

B<It is not ok to defer all action to the finalize phase.  If you do not
establish a minimum hieght and width during prepare then the layout manager
may not provide you with enough space to draw.>

    $driver->finalize($comp);

=item B<draw>

Handled by L<Graphics::Primitive::Driver>.

   $driver->draw($comp);

=back

=head1 METHODS

=head2 Constructor

=over 4

=item I<new>

Creates a new Component.

=back

=head2 Instance Methods

=over 4

=item I<background_color>

Set this component's background color.

=item I<border>

Set this component's border, which should be an instance of
L<Border|Graphics::Primitive::Border>.

=item I<callback>

Optional callback that is fired at the beginning of the C<finalize> phase.
This allows you to add some sort of custom code that can modify the component
just before it is rendered.  The only argument is the component itself.

Note that changing the position or the dimensions of the component will B<not>
re-layout the scene.  You may have weird results of you manipulate the
component's dimensions here.

=item I<class>

Set/Get this component's class, which is an abitrary string.
Graphics::Primitive has no internal use for this attribute but provides it for
outside use.

=item I<color>

Set this component's foreground color.

=item I<fire_callback>

Method to execute this component's C<callback>.

=item I<get_tree>

Get a tree for this component.  Since components are -- by definiton -- leaf
nodes, this tree will only have the one member at it's root.

=item I<has_callback>

Predicate that tells if this component has a C<callback>.

=item I<height>

Set this component's height.

=item I<inside_bounding_box>

Returns a L<Rectangle|Geometry::Primitive::Rectangle> that defines the edges
of the 'inside' box for this component.  This box is relative to the origin
of the component.

=item I<inside_height>

Get the height available in this container after taking away space for
padding, margin and borders.

=item I<inside_width>

Get the width available in this container after taking away space for
padding, margin and borders.

=item I<margins>

Set this component's margins, which should be an instance of
L<Insets|Graphics::Primitive::Insets>.  Margins are the space I<outside> the
component's bounding box, as in CSS.  The margins should be outside the
border.

=item I<maximum_height>

Set/Get this component's maximum height.  Used to inform a layout manager.

=item I<maximum_width>

Set/Get this component's maximum width.  Used to inform a layout manager.

=item I<minimum_height>

Set/Get this component's minimum height.  Used to inform a layout manager.

=item I<minimum_inside_height>

Get the minimum height available in this container after taking away space for
padding, margin and borders.

=item I<minimum_inside_width>

Get the minimum width available in this container after taking away space for
padding, margin and borders.

=item I<minimum_width>

Set/Get this component's minimum width.  Used to inform a layout manager.

=item I<name>

Set this component's name.  This is not required, but may inform consumers
of a component.  Pay attention to that library's documentation.

=item I<origin>

Set/Get the origin point for this component.

=item I<outside_height>

Get the height consumed by padding, margin and borders.

=item I<outside_width>

Get the width consumed by padding, margin and borders.

=item I<finalize>

Method provided to give component one last opportunity to put it's contents
into the provided space.  Called after prepare.

=item I<padding>

Set this component's padding, which should be an instance of
L<Insets|Graphics::Primitive::Insets>.  Padding is the space I<inside> the
component's bounding box, as in CSS.  This padding should be between the
border and the component's content.

=item I<page>

If true then this component represents stand-alone page.  This informs the
driver that this component (and any children) are to be renderered on a single
surface.  This only really makes sense in formats that have pages such as PDF
of PostScript.

=item I<prepare>

Method to prepare this component for drawing.  This is an empty sub and is
meant to be overridden by a specific implementation.

=item I<preferred_height>

Set/Get this component's preferred height.  Used to inform a layout manager.

=item I<preferred_width>

Set/Get this component's preferred width.  Used to inform a layout manager.

=item I<to_string>

Get a string representation of this component in the form of:

  $name $x,$y ($widthx$height)

=item I<visible>

Set/Get this component's visible flag.

=item I<width>

Set/Get this component's width.

=back

=head1 AUTHOR

Cory Watson, C<< <gphat@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-geometry-primitive at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Geometry-Primitive>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2008-2009 by Cory G Watson.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
