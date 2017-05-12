use strict;
use warnings;
package Math::Shape::Line;
$Math::Shape::Line::VERSION = '0.15';
use 5.008;
use Carp;
use Math::Shape::Vector;

# ABSTRACT: a 2d vector-based infinite line


sub new {
    croak 'incorrect number of args' unless @_ == 5;
    my ($class, $x1, $y1, $x2, $y2) = @_;
    bless { base        => Math::Shape::Vector->new($x1, $y1),
            direction   => Math::Shape::Vector->new($x2, $y2),
          }, $class;
}


sub is_equivalent
{
    croak 'must pass a line object' unless $_[1]->isa('Math::Shape::Line');
    unless( $_[0]->{direction}->is_parallel($_[1]->{direction}) )
    {
        0;
    }
    else
    {
        my $base = $_[0]->{base}->subtract_vector($_[1]->{base});
        $base->is_parallel($_[0]->{direction});
    }
}


sub on_one_side
{
    croak 'project not called with argument of type Math::Shape::Line' unless $_[1]->isa('Math::Shape::LineSegment');
    my ($self, $segment) = @_;

    my $vector_d1 = $segment->{start}->subtract_vector($self->{base});
    my $vector_d2 = $segment->{end}->subtract_vector($self->{base});
    my $vector_n = $self->{direction}->rotate_90;

    $vector_n->dot_product($vector_d1) * $vector_n->dot_product($vector_d2) 
        > 0 ? 1 : 0;
}



sub collides
{
    my ($self, $other_obj) = @_;

    if ($other_obj->isa('Math::Shape::Line'))
    {
        if($self->{direction}->is_parallel($other_obj->{direction}))
        {
            $self->is_equivalent($other_obj);
        }
        else
        {
            1;
        }
    }
    elsif ($other_obj->isa('Math::Shape::LineSegment'))
    {
        $self->on_one_side($other_obj) ? 0 : 1;
    }
    elsif ($other_obj->isa('Math::Shape::OrientedRectangle'))
    {
        $other_obj->collides($self);
    }
    elsif ($other_obj->isa('Math::Shape::Circle'))
    {
        $other_obj->collides($self);
    }
    elsif ($other_obj->isa('Math::Shape::Rectangle'))
    {
        $other_obj->collides($self);
    }
    elsif ($other_obj->isa('Math::Shape::Vector'))
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

Math::Shape::Line - a 2d vector-based infinite line

=head1 VERSION

version 0.15

=head1 METHODS

=head2 new

Constructor, requires 4 values: the x,y values for the base and direction vectors.

    my $line = Math::Shape::Line->new(1, 2, 3, 4);

=head2 is_equivalent

Boolean method returns 1 if the line is equivalent to another line object. Lines are equivalent when they are parallel and the base vector of one line occurs along the other line. Requires a Math::Shape::Line object as an argument.

    if ($line->is_equivalent($other_line)
    {
        ...
    }

=head2 one_one_side

Boolean method that returns 1 if both points of a LineSegment object are on the same side of the line. Requires a L<Math::Shape::LineSegment> object as an argument.

=head2 collides

Boolean method that returns 1 if the line collides with another L<Math::Shape::Vector> library object or not or 0 if not. Requires a Math::Shape::Vectorlibrary object as an argument

    my $l1 = Math::Shape::Line(4, 2);
    my $l2 = Math::Shape::Line(4, 2);

    $l1->collides($l2); # 1

=head1 AUTHOR

David Farrell <dfarrell@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by David Farrell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
