use strict;
use warnings;
package Math::Shape::OrientedRectangle;
$Math::Shape::OrientedRectangle::VERSION = '0.15';
use 5.008;
use Carp;
use Math::Shape::Vector;
use Math::Shape::Utils;
use Math::Shape::Line;
use Math::Shape::LineSegment;
use Math::Shape::Rectangle;
use Math::Shape::Circle;

# ABSTRACT: a 2d oriented rectangle


sub new {
    croak 'incorrect number of args' unless @_ == 6;
    my ($class, $x_1, $y_1, $x_2, $y_2, $rotation) = @_;
    bless { center      => Math::Shape::Vector->new($x_1, $y_1),
            half_extend => Math::Shape::Vector->new($x_2, $y_2),
            rotation    => $rotation,
          }, $class;
}


sub get_edge {
    croak 'incorrect number of args' unless @_ == 2;
    my ($self, $edge_number) = @_;

    my $a = Math::Shape::Vector->new(
        $self->{half_extend}->{x},
        $self->{half_extend}->{y});

    my $b = Math::Shape::Vector->new(
        $self->{half_extend}->{x},
        $self->{half_extend}->{y});

    my $mod = $edge_number % 4;

       if ($mod == 0)
    {
        $a->{x} = - $a->{x};
    }
    elsif ($mod == 1)
    {
        $b->{y} = - $b->{y};
    }
    elsif ($mod == 2)
    {
        $a->{y} = - $a->{y};
        $b = $b->negate;
    }
     else
    {
        $a->negate;
        $b->{x} = - $b->{x};
    }

    $a = $a->rotate($self->{rotation});
    $a = $a->add_vector($self->{center});
    $b = $b->rotate($self->{rotation});
    $b = $b->add_vector($self->{center});

    Math::Shape::LineSegment->new($a->{x}, $a->{y}, $b->{x}, $b->{y});
}


sub axis_is_separating
{
    croak 'collides must be called with a Math::Shape::LineSegment object'
        unless $_[1]->isa('Math::Shape::LineSegment');
    my ($self, $axis) = @_;

    my $edge_0 = $self->get_edge(0);
    my $edge_2 = $self->get_edge(2);

    my $n_vector = $axis->{start}->subtract_vector($axis->{end});

    my $axis_range = $axis->project($n_vector);
    my $range_0    = $edge_0->project($n_vector);
    my $range_2    = $edge_2->project($n_vector);
    my $projection = $range_0->hull($range_2);

    $axis_range->is_overlapping($projection) ? 0 : 1;
}


sub corner
{
    croak 'incorrect number of args' unless @_ == 2;
    my ($self, $nr) = @_;

    my $mod = $nr % 4;
    my $v;

    if ($mod == 0)
    {
        $v = Math::Shape::Vector->new(
            - $self->{half_extend}{x},
            $self->{half_extend}{y},
        );
    }
    elsif ($mod == 1)
    {
        $v = Math::Shape::Vector->new(
            $self->{half_extend}{x},
            $self->{half_extend}{y},
        );
    }
    elsif ($mod == 2)
    {
        $v = Math::Shape::Vector->new(
            $self->{half_extend}{x},
            - $self->{half_extend}{y},
        );
    }
    elsif ($mod == 3)
    {
        $v = Math::Shape::Vector->new(
            $self->{half_extend}{x},
            $self->{half_extend}{y},
        );
        $v = $v->negate;
    }
    else
    {
        croak 'corner() should be called with a number between 0-3';
    }
    my $c = $v->rotate($self->{rotation});
    $c->add_vector($self->{center});
}



sub hull
{
    my $self = shift;

    # create a rectangle at the same center point as $self
    my $h = Math::Shape::Rectangle->new(
        $self->{center}{x},
        $self->{center}{y},
        0,
        0,
    );

    # enlarge the rectangle by every corner vector of $self
    for (0..3)
    {
        my $corner = $self->corner($_);
        $h = $h->enlarge($corner);
    }

    # return the hull
    $h;
}


sub circle_hull
{
    my $self = shift;

    Math::Shape::Circle->new(
        $self->{center}->{x},
        $self->{center}->{y},
        $self->{half_extend}->length,
    );
}


sub collides {
    my ($self, $other_obj) = @_;

    if ($other_obj->isa('Math::Shape::OrientedRectangle'))
    {
        my $edge = $self->get_edge(0);
        return 0 if $other_obj->axis_is_separating($edge);

        $edge = $self->get_edge(1);
        return 0 if $other_obj->axis_is_separating($edge);

        $edge = $other_obj->get_edge(0);
        return 0 if $self->axis_is_separating($edge);

        $edge = $other_obj->get_edge(1);
        return 0 if $self->axis_is_separating($edge);

        1;
    }
    elsif ($other_obj->isa('Math::Shape::Vector'))
    {
        # convert into rectangle and use rectangle's collides() method
        my $size = $self->{half_extend}->multiply(2);
        my $lr = Math::Shape::Rectangle->new(
            0,
            0,
            $size->{x},
            $size->{y},
        );

        my $lp = $other_obj->subtract_vector($self->{center});
        $lp = $lp->rotate(- $self->{rotation});
        $lp = $lp->add_vector($self->{half_extend});
        $lr->collides($lp);
    }
    elsif ($other_obj->isa('Math::Shape::Line'))
    {
        my $size = $self->{center}->multiply(2);
        my $lr = Math::Shape::Rectangle->new(
            0,
            0,
            $size->{x},
            $size->{y},
        );

        my $base = $other_obj->{base}->subtract_vector($self->{center});
        $base = $base->rotate(- $self->{rotation});
        $base = $base->add_vector($self->{half_extend});
        my $direction = $other_obj->{direction}->rotate(- $self->{rotation});

        my $ll = Math::Shape::Line->new(
            $base->{x},
            $base->{y},
            $direction->{x},
            $direction->{y},
        );

        $lr->collides($ll);
    }
    elsif ($other_obj->isa('Math::Shape::LineSegment'))
    {
        my $size = $self->{half_extend}->multiply(2);
        my $lr = Math::Shape::Rectangle->new(
            0,
            0,
            $size->{x},
            $size->{y},
        );

        my $ls_p1 = $other_obj->{start}->subtract_vector($self->{center});
        $ls_p1 = $ls_p1->rotate(- $self->{rotation});
        $ls_p1 = $ls_p1->add_vector($self->{half_extend});

        my $ls_p2 = $other_obj->{end}->subtract_vector($self->{center});
        $ls_p2 = $ls_p2->rotate(- $self->{rotation});
        $ls_p2 = $ls_p2->add_vector($self->{half_extend});

        my $ls = Math::Shape::LineSegment->new(
            $ls_p1->{x},
            $ls_p1->{y},
            $ls_p2->{x},
            $ls_p2->{y},
        );

        $lr->collides($ls);
    }
    # call the other objects collides() method
    elsif ($other_obj->isa('Math::Shape::Rectangle'))
    {
        $other_obj->collides($self);
    }
    elsif ($other_obj->isa('Math::Shape::Circle'))
    {
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

Math::Shape::OrientedRectangle - a 2d oriented rectangle

=head1 VERSION

version 0.15

=head1 METHODS

=head2 new

Constructor, requires 5 values: the x,y values for the center and the x,y values for the half_extend vector and a rotation number.

    my $OrientedRectangle = Math::Shape::OrientedRectangle->new(1, 1, 2, 4, 45);
    my $width = $OrientedRectangle->{rotation}; # 45

=head2 get_edge

Returns a L<Math::Shape::LineSegment> object for a given edge of the rectangle. Requires a number for the edge of the rectangle to return (0-3).

    my $segment= $oriented_rectangle->get_edge(1);

=head2 axis_is_separating

Boolean method that returns 1 if the axis is separating. Requires a Math::Shape::LineSegment object (for the axis) as an argment.

=head2 corner

Returns a L<Math::Shape::Vector> object representing a corner of the rectangle. Requires a number between 0-3 for the corner.

    my $corner = $OrientedRectangle->corner(2);

=head2 hull

Returns a L<Math::Shape::Rectangle> object representing the hull of the oriented rectangle.

=head2 circle_hull

Returns a new L<Math::Shape::Circle> object representing the hull of the oriented rectangle.

=head2 collides

Boolean method returns 1 if the OrientedRectangle collides with another L<Math::Shape::Vector> library object, else returns 0. Requires a L<Math::Shape::Vector> library object as an argument.

    if($OrientedRectangle->collides($other_OrientedRectangle))
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
