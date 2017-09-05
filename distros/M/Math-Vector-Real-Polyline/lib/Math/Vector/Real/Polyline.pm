package Math::Vector::Real::Polyline;

our $VERSION = '0.01';

use strict;
use warnings;

use Math::Vector::Real;

our $debug = 0;

sub as_string;
use overload '""' => \&as_string;

sub new {
    my $class = shift;
    my $self = [map V(@$_), @_];
    bless $self, $class;
}

sub dist2_to_point {
    my $self = shift;
    my $p = V(shift);
    return unless @$self;
    my $min_d2 = $self->[0]->dist2($p);

    for my $i (1..$#$self) {
        my $d2 = $p->dist2_to_segment($self->[$i-1], $self->[$i]);
        $min_d2 = $d2 if $d2 < $min_d2;
    }

    $min_d2;
}

sub dist2_to_segment {
    my ($self, $a, $b) = @_;
    my $min_d2 = $self->[0]->dist2($a);
    for my $i (1..$#$self) {
        my $d2 = Math::Vector::Real->dist2_between_segments($a, $b,
                                                            $self->[$i - 1], $self->[$i]);
        $min_d2 = $d2 if $d2 < $min_d2;
    }
    $min_d2;
}

sub _dist2_to_polyline_brute_force {
    my ($self, $other, $min_d2) = @_;

    for my $i (1..$#$self) {
        my $s0 = $self->[$i - 1];
        my $s1 = $self->[$i];
        for my $j (1..$#$other) {
            my $d2 = Math::Vector::Real->dist2_between_segments($s0, $s1,
                                                                $other->[$j-1], $other->[$j]);
            $min_d2 = $d2 if $d2 < $min_d2;
        }
    }
    $min_d2;
}

my $cutoff = 5;

sub _dump_queue {
    my $min_d2 = shift;
    printf "Queue size: %d, min_d2: %f\n", scalar(@_), $min_d2;
    for (@_) {
        my $a = Math::Vector::Real::Polyline->new(@{$_->[0]});
        my $b = Math::Vector::Real::Polyline->new(@{$_->[1]});
        my $d2 = $_->[2];
        print "  a: $a b: $b d2: $d2\n";
    }
}

sub dist2_to_polyline {
    my $self = shift;
    my $other = shift;
    return unless @$self and @$other;
    return $other->dist2_to_point($self->[0]) if @$self == 1;
    return $self->dist2_to_point($other->[0]) if @$other == 1;

    my $min_d2 = $self->[0]->dist2($other->[0]);
    my @queue = [$self, $other, 0];

    while (@queue) {
        $debug and _dump_queue($min_d2, @queue);
        my ($a, $b, $bb_d2) = @{pop @queue};
        last if $bb_d2 >= $min_d2;

        if (@$a <= $cutoff or @$b <= $cutoff) {
            $min_d2 = _dist2_to_polyline_brute_force($a, $b, $min_d2);
        }
        else {
            my $a_half = int(@$a / 2);
            my $a0 = [@{$a}[0..$a_half]];
            my $a1 = [@{$a}[$a_half..$#$a]];
            my $b_half = int(@$b / 2);
            my $b0 = [@{$b}[0..$b_half]];
            my $b1 = [@{$b}[$b_half..$#$b]];
            for my $pair ([$a0, $b0], [$a0, $b1], [$a1, $b0], [$a1, $b1]) {
                my $bb_d2 = Math::Vector::Real->dist2_between_boxes(Math::Vector::Real->box(@{$pair->[0]}),
                                                                    Math::Vector::Real->box(@{$pair->[1]}));
                next if $bb_d2 > $min_d2;
                $pair->[2] = $bb_d2;
                my $i;

                for ($i = $#queue; $i >= 0; $i--) {
                    my $pivot = $queue[$i];
                    last if $bb_d2 <= $pivot->[2];
                    $queue[$i + 1] = $pivot
                }
                $queue[$i + 1] = $pair;
            }
        }
    }
    return $min_d2;
}

sub dist_to_polyline { sqrt(&dist2_to_polyline) }

sub as_string {
    my $self = shift;
    return '['.join('-', @$self).']';
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Math::Vector::Real::Polyline - Algorithms related to polylines.

=head1 SYNOPSIS

  use Math::Vector::Real::Polyline;

  my $poly1 = Math::Vector::Polyline->new(@vectors1);
  my $poly2 = Math::Vector::Polyline->new(@vectors2);

  my $d = $poly1->dist_to_polyline(@poly2);
  printf "The distance between %s and %s is %f",
         $poly1, $poly2, $d;


=head1 DESCRIPTION

This module implements several algorithms related to polygonal chains
or polylines.

Note that the module can handle polylines in spaces of any dimension
(not just 2D).

=head2 API

=over 4

=item $p = Math::Vector::Polyline->new(@vectors)

Creates a new polyline object.

=item $d2 = $p->dist2_to_point($v)

Returns the square of the distance from the polyline to the given
point.

=item $d2 = $p->dist2_to_segment($a, $b)

Returns the square of the distance from the polyline to the segment
with the given vertices.

=item $d2 = $p->dist2_to_polyline($p1)

Returns the square of the distance between both polylines.

=back

=head1 SEE ALSO

L<Math::Vector::Real>.

L<Polygonal Chain at Wikipedia|https://en.wikipedia.org/wiki/Polygonal_chain>.

L<The StarOverflow post that started it|https://stackoverflow.com/questions/45861488/distance-between-two-polylines>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Salvador FandiE<ntilde>o
E<lt>sfandino@yahoo.comE<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
