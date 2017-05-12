use strict;
use warnings;
package Math::Shape::LineSegment;
$Math::Shape::LineSegment::VERSION = '0.15';
use 5.008;
use Carp;
use Math::Shape::Vector;
use Math::Shape::Range;
use Math::Shape::Line;

# ABSTRACT: a 2d vector line segment; a line with start and end points


sub new {
    croak 'incorrect number of args' unless @_ == 5;
    my ($class, $x1, $y1, $x2, $y2) = @_;
    bless { start => Math::Shape::Vector->new($x1, $y1),
            end   => Math::Shape::Vector->new($x2, $y2),
          }, $class;
}


sub project
{
    croak 'project not called with argument of type Math::Shape::Vector' unless $_[1]->isa('Math::Shape::Vector');
    my ($self, $vector) = @_;
    my $unit_vector = $vector->convert_to_unit_vector;

    my $range = Math::Shape::Range->new(
        $unit_vector->dot_product($self->{start}),
        $unit_vector->dot_product($self->{end}),
    );

    $range->sort;
}


sub collides
{
    my ($self, $other_obj) = @_;

    if ($other_obj->isa('Math::Shape::LineSegment'))
    {
        my $vector_a = $self->{end}->subtract_vector($self->{start});
        my $axis_a = Math::Shape::Line->new(
            $self->{start}->{x},
            $self->{start}->{y},
            $vector_a->{x},
            $vector_a->{y});

        return 0 if $axis_a->on_one_side($other_obj);

        my $vector_b = $other_obj->{end}->subtract_vector($other_obj->{start});
        my $axis_b = Math::Shape::Line->new(
            $other_obj->{start}->{x},
            $other_obj->{start}->{y},
            $vector_b->{x},
            $vector_b->{y});

        return 0 if $axis_b->on_one_side($self);

        if ($axis_a->{direction}->is_parallel($axis_b->{direction}))
        {
            my $range_a = $self->project($axis_a->{direction});
            my $range_b = $other_obj->project($axis_a->{direction});
            return $range_a->is_overlapping($range_b);
        }

        1;
    }
    elsif ($other_obj->isa('Math::Shape::Vector'))
    {
        $other_obj->collides($self);
    }
    elsif ($other_obj->isa('Math::Shape::Line'))
    {
        $other_obj->collides($self);
    }
    elsif ($other_obj->isa('Math::Shape::OrientedRectangle'))
    {
        $other_obj->collides($self);
    }
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

Math::Shape::LineSegment - a 2d vector line segment; a line with start and end points

=head1 VERSION

version 0.15

=head1 METHODS

=head2 new

Constructor, requires 4 values: the x,y values for the start and end points

    my $line = Math::Shape::Line->new(1, 2, 3, 4);

=head2 project

Projects the segment onto a vector and returns a L<Math::Shape::Range> object. Requires a Math::Shape::Vector object as an argument. This method is mainly used in collision detection.

    my $vector = Math::Shape::Vector->new(5, 9);
    my $range = $line->project($vector);

=head2 collides

Boolean method that returns 1 if the vector collides with another L<Math::Shape::Vector> library object or not or 0 if not. Requires a Math::Shape::Vectorlibrary object as an argument

=head1 AUTHOR

David Farrell <dfarrell@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by David Farrell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
