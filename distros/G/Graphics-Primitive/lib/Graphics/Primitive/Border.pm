package Graphics::Primitive::Border;
use Moose;
use MooseX::Storage;

with 'MooseX::Clone';
with Storage (format => 'JSON', io => 'File');

use Graphics::Color;
use Graphics::Primitive::Brush;

has 'bottom' => (
    is => 'rw',
    isa => 'Graphics::Primitive::Brush',
    default => sub {
        Graphics::Primitive::Brush->new
    },
    traits => [qw(Clone)]
);
has 'color' => (
    is => 'rw',
    isa => 'Graphics::Color',
    trigger => sub {
        my ($self, $newval) = @_;
        $self->bottom->color($newval);
        $self->left->color($newval);
        $self->right->color($newval);
        $self->top->color($newval);
    },
    predicate => 'has_color'
);
has 'left' => (
    is => 'rw',
    isa => 'Graphics::Primitive::Brush',
    default => sub {
        Graphics::Primitive::Brush->new
    },
    traits => [qw(Clone)]
);
has 'right' => (
    is => 'rw',
    isa => 'Graphics::Primitive::Brush',
    default => sub {
        Graphics::Primitive::Brush->new
    },
    traits => [qw(Clone)]
);
has 'top' => (
    is => 'rw',
    isa => 'Graphics::Primitive::Brush',
    default => sub {
        Graphics::Primitive::Brush->new
    },
    traits => [qw(Clone)]
);
has 'width' => (
    is => 'rw',
    isa => 'Int',
    trigger => sub {
        my ($self, $newval) = @_;
        $self->bottom->width($newval);
        $self->left->width($newval);
        $self->right->width($newval);
        $self->top->width($newval);
    },
    predicate => 'has_width'
);

__PACKAGE__->meta->make_immutable;

sub BUILD {
    my ($self) = @_;

    if($self->has_width) {
        my $w = $self->width;
        $self->bottom->width($w);
        $self->left->width($w);
        $self->right->width($w);
        $self->top->width($w);
    }
    if($self->has_color) {
        my $c = $self->color;
        $self->bottom->color($c);
        $self->left->color($c);
        $self->right->color($c);
        $self->top->color($c);
    }
}

# sub color {
#     my ($self, $c) = @_;
# 
#     $self->bottom->color($c);
#     $self->left->color($c);
#     $self->right->color($c);
#     $self->top->color($c);
# }

sub dash_pattern {
    my ($self, $d) = @_;

    $self->bottom->dash_pattern($d);
    $self->left->dash_pattern($d);
    $self->right->dash_pattern($d);
    $self->top->dash_pattern($d);
}

sub equal_to {
    my ($self, $other) = @_;

    unless($self->top->equal_to($other->top)) {
        return 0;
    }
    unless($self->right->equal_to($other->right)) {
        return 0;
    }
    unless($self->bottom->equal_to($other->bottom)) {
        return 0;
    }
    unless($self->left->equal_to($other->left)) {
        return 0;
    }

    return 1;
}

sub homogeneous {
    my ($self) = @_;

    my $b = $self->top;
    unless($self->bottom->equal_to($b) && $self->left->equal_to($b)
        && $self->right->equal_to($b)) {
            return 0;
    }
    return 1;
}

sub not_equal_to {
    my ($self, $other) = @_;

    return !$self->equal_to($other);
}

# sub width {
#     my ($self, $w) = @_;
# 
#     $self->bottom->width($w);
#     $self->left->width($w);
#     $self->right->width($w);
#     $self->top->width($w);
# }

no Moose;
1;
__END__

=head1 NAME

Graphics::Primitive::Border - Line around components

=head1 DESCRIPTION

Graphics::Primitive::Border describes the border to be rendered around a
component.

=head1 SYNOPSIS

  use Graphics::Primitive::Border;

  my $border = Graphics::Primitive::Border->new;

=head1 METHODS

=head2 new

Creates a new Graphics::Primitiver::Border.  Borders are composed of 4
brushes, one for each of the 4 sides.  See the documentation for
L<Graphics::Primitive::Brush> for more information.  Note that you can
provide a C<width> and C<color> argument to the constructor and it will create
brushes of that width for each side.

=head2 bottom

The brush representing the bottom border.

=head2 clone

Close this border.

=head2 color

Set the Color on all 4 borders to the one supplied.  Shortcut for setting it
with each side.

=head2 dash_pattern

Set the dash pattern on all 4 borders to the one supplied. Shortcut for
setting it with each side.

=head2 equal_to ($other)

Returns 1 if this border is equal to the one provided, else returns 0.

=head2 homogeneous

Returns 1 if all of this border's sides are the same.  Allows for driver
optimizations.

=head2 left

The brush representing the left border.

=head2 not_equal_to

Opposite of C<equal_to>.

=head2 right

The brush representing the right border.

=head2 top

The brush representing the top border.

=head2 width

Set the width on all 4 borders to the one supplied.  Shortcut for setting it
with each side.

=head1 AUTHOR

Cory Watson, C<< <gphat@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008-2010 by Cory G Watson.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.