use strict;
use warnings;
package Math::Shape::Rectangle;
$Math::Shape::Rectangle::VERSION = '0.15';
use 5.008;
use Carp;
use Math::Shape::Vector;
use Math::Shape::Utils;
use Math::Shape::Line;
use Math::Shape::LineSegment;
use Math::Shape::Range;

# ABSTRACT: an axis-aligned 2d rectangle


sub new {
    croak 'incorrect number of args' unless @_ == 5;
    my ($class, $x, $y, $l, $h) = @_;
    bless { origin => Math::Shape::Vector->new($x, $y),
            size   => Math::Shape::Vector->new($l, $h),
          }, $class;
}


sub clamp
{
    croak 'clamp must be called with a Math::Shape::Vector object' unless $_[1]->isa('Math::Shape::Vector');
    my ($self, $vector) = @_;

    my $clamp_x = clamp_on_range($vector->{x}, $self->{origin}->{x}, $self->{origin}->{x} + $self->{size}->{x});
    my $clamp_y = clamp_on_range($vector->{y}, $self->{origin}->{y}, $self->{origin}->{y} + $self->{size}->{y});
    Math::Shape::Vector->new($clamp_x, $clamp_y);
}


sub corner
{
    croak 'Incorrect number of arguments for corner(). Requires a number between 0 and 3.' unless @_ == 2;
    my ($self, $nr) = @_;

    my $corner;
    my $mod = $nr % 4;

    if ($mod == 0)
    {
        $corner = Math::Shape::Vector->new(
            $self->{origin}{x} + $self->{size}{x},
            $self->{origin}{y},
        );
    }
    elsif ($mod == 1)
    {
        $corner = Math::Shape::Vector->new(
            $self->{origin}{x},,
            $self->{origin}{y},
        );
        $corner->add_vector($self->{size});
    }
    elsif ($mod == 2)
    {
        $corner = Math::Shape::Vector->new(
            $self->{origin}{x},
            $self->{origin}{y} + $self->{size}{y},
        );
    }
    elsif ($mod == 3)
    {
        $corner = Math::Shape::Vector->new(
            $self->{origin}{x},
            $self->{origin}{y},
        );
    }
    else
    {
        croak 'corner() not called with a number between 0 and 3';
    }
}


sub separating_axis
{
    croak 'separating_axis() requires a Math::Shape::LineSegment object as an argument' unless $_[1]->isa('Math::Shape::LineSegment');
    my ($self, $axis) = @_;

    my $n = $axis->{start}->subtract_vector($axis->{end});
    my $point0 = $self->corner(0);
    my $point1 = $self->corner(1);
    my $point2 = $self->corner(2);
    my $point3 = $self->corner(3);

    my $r_edge_a = Math::Shape::LineSegment->new(
        $point0->{x},
        $point0->{y},
        $point1->{x},
        $point1->{y},
    );
    my $r_edge_range_a = $r_edge_a->project($n);
    my $r_edge_b = Math::Shape::LineSegment->new(
        $point2->{x},
        $point2->{y},
        $point3->{x},
        $point3->{y},
    );
    my $r_edge_range_b = $r_edge_b->project($n);
    my $r_projection = $r_edge_range_a->hull($r_edge_range_b);
    my $axis_range = $axis->project($n);
    $axis_range->is_overlapping($r_projection)
        ? 0 : 1;
}


sub enlarge
{
    croak 'enlarge() must be called with a Math::Shape::Vector object' unless $_[1]->isa('Math::Shape::Vector');
    my ($self, $v) = @_;

    my $size = Math::Shape::Vector->new(
        maximum($self->{origin}{x} + $self->{size}{x}, $v->{x}),
        maximum($self->{origin}{y} + $self->{size}{y}, $v->{y}),
    );

    my $origin = Math::Shape::Vector->new(
        minimum($self->{origin}{x}, $v->{x}),
        minimum($self->{origin}{y}, $v->{y}),
    );
    my $enlarged_size = $size->subtract_vector($origin);

    Math::Shape::Rectangle->new(
        $origin->{x},
        $origin->{y},
        $enlarged_size->{x},
        $enlarged_size->{y},
    );
}


sub collides {
    my ($self, $other_obj) = @_;

    if ($other_obj->isa('Math::Shape::Rectangle'))
    {
        my $a_left   = $self->{origin}{x};
        my $a_right  = $a_left + $self->{size}{x};
        my $b_left   = $other_obj->{origin}->{x};
        my $b_right  = $b_left + $other_obj->{size}{x};
        my $a_bottom = $self->{origin}{y};
        my $a_top    = $a_bottom + $self->{size}{y};
        my $b_bottom = $other_obj->{origin}{y};
        my $b_top    = $b_bottom + $other_obj->{size}{y};

        # overlap returns 1 / 0 already, so no need to use ternary to force 1/0 response
        overlap($a_left, $a_right, $b_left, $b_right)
        && overlap($a_bottom, $a_top, $b_bottom, $b_top);
    }
    elsif ($other_obj->isa('Math::Shape::Vector'))
    {
        my $left    = $self->{origin}{x};
        my $right   = $left + $self->{size}{x};
        my $bottom  = $self->{origin}{y};
        my $top     = $bottom + $self->{size}{y};

        # use ternary here as Perl will return undef if false, but we need 0
        $left <= $other_obj->{x}
            && $bottom <= $other_obj->{y}
            && $other_obj->{x} <= $right
            && $other_obj->{y} <= $top
            ? 1 : 0;
    }
    elsif ($other_obj->isa('Math::Shape::Line'))
    {
        my $n = $other_obj->{direction}->rotate_90;
        my $c1 =  $self->{origin};
        my $c2 =  $c1->add_vector($self->{size});
        my $c3 =  Math::Shape::Vector->new($c2->{x}, $c1->{y});
        my $c4 =  Math::Shape::Vector->new($c1->{x}, $c2->{y});
        $c1 = $c1->subtract_vector($other_obj->{base});
        $c2 = $c2->subtract_vector($other_obj->{base});
        $c3 = $c3->subtract_vector($other_obj->{base});
        $c4 = $c4->subtract_vector($other_obj->{base});

        my $dp1 = $n->dot_product($c1);
        my $dp2 = $n->dot_product($c2);
        my $dp3 = $n->dot_product($c3);
        my $dp4 = $n->dot_product($c4);

        # use ternary here as Perl will return undef if false, but we need 0
        ($dp1 * $dp2 <= 0)
            || ($dp2 * $dp3 <= 0)
            || ($dp3 * $dp4 <= 0)
            ? 1 : 0;
    }
    elsif ($other_obj->isa('Math::Shape::LineSegment'))
    {
        # convert LineSegment into an infinite line and test for collision
        my $base = $other_obj->{start};
        my $direction = $other_obj->{end}->subtract_vector($other_obj->{start});
        my $s_line = Math::Shape::Line->new($base->{x}, $base->{y}, $direction->{x}, $direction->{y});
        return 0 unless $self->collides($s_line);

        # convert both objects to ranges and check for overlap along x axis
        my $r_range_x = Math::Shape::Range->new(
            $self->{origin}{x},
            $self->{origin}{x} + $self->{size}{x},
        );
        my $s_range_x = Math::Shape::Range->new(
            $other_obj->{start}{x},
            $other_obj->{end}{x},
        );
        $s_range_x = $s_range_x->sort;
        return 0 unless $s_range_x->is_overlapping($r_range_x);

        # convert both objects to ranges and check for overlap along y axis
        my $r_range_y = Math::Shape::Range->new(
            $self->{origin}{y},
            $self->{origin}{y} + $self->{size}{y},
        );
        my $s_range_y = Math::Shape::Range->new(
            $other_obj->{start}{y},
            $other_obj->{end}{y},
        );
        $s_range_y = $s_range_y->sort;
        return 0 unless $s_range_y->is_overlapping($r_range_y);
    }
    elsif ($other_obj->isa('Math::Shape::OrientedRectangle'))
    {
        # get rectangular hull of oriented rectangle
        # if no collision with hull, we're good
        my $or_hull = $other_obj->hull;
        return 0 unless $self->collides($or_hull);

        # if oriented rectangle edge 0 is a separating axis, we're good
        my $or_edge_0 = $other_obj->get_edge(0);
        return 0 if $self->separating_axis($or_edge_0);

        # if oriented rectangle edge 1 is a separating axis, we're good
        my $or_edge_1 = $other_obj->get_edge(1);
        return 0 if $self->separating_axis($or_edge_1);

        # must be collision
        1;
    }
    elsif ($other_obj->isa('Math::Shape::Circle'))
    {
        # if it's a circle use the circle's collision method
        $other_obj->collides($self);
    }
    else
    {
        croak 'collides must be called with a Math::Shape::Vector library object';
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Math::Shape::Rectangle - an axis-aligned 2d rectangle

=head1 VERSION

version 0.15

=head1 METHODS

=head2 new

Constructor, requires 4 values: the x,y values for the origin and the x,y values for the size.

    my $rectangle = Math::Shape::Rectangle->new(1, 1, 2, 4);
    my $width = $rectangle->{size}->{x}; # 2

=head2 clamp

Takes a vector object and returns a new vector object whose x & y coordinates are "clamped" to the size of the rectangle. Requires a L<Math::Shape::Vector> object as an argument.

    my $clamped_vector = $rectangle->clamp($vector);

=head2 corner

Returns a L<Math::Shape::Vector> object representing a corner point of the rectangle. Requires a number between 0 and 3.

    my $corner = $rectangle->corner(2); # get the 3rd corner

=head2 separating_axis

Boolean method that returns 1 if the axis is outside of the rectangle, or 0 if not. Requires a L<Math::Shape::LineSegment> object as an argument.

=head2 enlarge

Returns a new rectangle object increased to the size of a vector. Requires a L<Math::Shape::Vector> object as an argument.

    my $larger_rectangle = $rectangle->enlarge($vector);

=head2 collides

Boolean method returns 1 if the rectangle collides with another object, else returns 0. Requires another L<Math::Shape::Vector> library object as an argument.

    my $is_collision = $rectangle->collides($other_rectangle);

    my $circle = Math::Shape::Circle->new(54, 19, 30);
    if ($rectangle->collides($circle))
    {
        ...
    }

=head1 AUTHOR

David Farrell <dfarrell@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by David Farrell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
