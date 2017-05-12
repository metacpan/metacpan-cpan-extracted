package List::Range::Search::Binary;
use strict;
use warnings;

use Class::Accessor::Lite ro => [qw/ranges/];

sub new {
    my ($class, $set, $opt) = @_;
    $opt ||= {};

    my $ranges = $class->_normalize($set->ranges, $opt);
    return bless {
        ranges => $ranges,
    } => $class;
}

sub _normalize {
    my ($class, $ranges, $opt) = @_;
    my $sorted = $opt->{no_sort} ? $ranges : [
        sort { $a->lower <=> $b->lower || $a->upper <=> $b->upper } @$ranges
    ];
    return $opt->{no_verify} ? $sorted : $class->_verify($sorted);
}

sub _verify {
    my ($class, $ranges) = @_;
    for my $i (0..$#{$ranges}-1) {
        my $before = $ranges->[$i];
        my $after  = $ranges->[$i+1];
        die "Binary search does not support to search in the crossed ranges"
            if $after->lower <= $before->upper;
    }
    return $ranges;
}

sub find {
    my ($self, $value) = @_;

    my @ranges = @{ $self->{ranges} };
    while (@ranges) {
        my $point = int($#ranges / 2);
        my $range = $ranges[$point];
        if ($value < $range->lower) {
            splice @ranges, $point;
        }
        elsif ($value > $range->upper) {
            splice @ranges, 0, $point + 1;
        }
        else {
            # includes
            return $range;
        }
    }

    # not found
    return undef; ## no critic
}

1;
__END__

=pod

=encoding utf-8

=head1 NAME

List::Range::Search::Binary - binary search for the ranges

=head1 SYNOPSIS

    use List::Range;
    use List::Range::Set;
    use List::Range::Search::Binary;

    my $seeker = List::Range::Search::Binary->new(
        List::Range::Set->new('MySet' => [
            List::Range->new(name => "A",              upper =>  0),
            List::Range->new(name => "B", lower =>  1, upper => 10),
            List::Range->new(name => "C", lower => 11, upper => 20),
            List::Range->new(name => "D", lower => 21, upper => 30),
            List::Range->new(name => "E", lower => 31, upper => 40),
            List::Range->new(name => "F", lower => 41, upper => 50),
        ])
    );

    $seeker->find(0);  # => List::Range<name="A">
    $seeker->find(1);  # => List::Range<name="B">
    $seeker->find(11); # => List::Range<name="C">
    $seeker->find(31); # => List::Range<name="E">
    $seeker->find(50); # => List::Range<name="F">
    $seeker->find(51); # => undef

=head1 DESCRIPTION

List::Range::Search::Binary search value from a set by binary search algorithm.

=head1 METHODS

=head2 List::Range::Search::Binary->new($set)

Create a new List::Range::Set object.

=head2 $seeker->find($value)

Find the range included the C<$value> from the set.

=head1 SEE ALSO

L<List::Range> L<List::Range::Set> L<List::Range::Search::Liner>

=head1 LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

karupanerura E<lt>karupa@cpan.orgE<gt>

=cut
