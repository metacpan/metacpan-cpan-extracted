package List::Range::Search::Liner;
use strict;
use warnings;

use Class::Accessor::Lite ro => [qw/ranges/];

sub new {
    my ($class, $set) = @_;
    return bless {
        ranges => $set->ranges,
    } => $class;
}

sub find {
    my ($self, $value) = @_;

    for my $range (@{ $self->{ranges} }) {
        return $range if $range->includes($value)
    }

    # not found
    return undef; ## no critic
}

1;
__END__

=pod

=encoding utf-8

=head1 NAME

List::Range::Search::Liner - liner search for the ranges

=head1 SYNOPSIS

    use List::Range;
    use List::Range::Set;
    use List::Range::Search::Liner;

    my $seeker = List::Range::Search::Liner->new(
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

List::Range::Search::Liner search value from a set by liner search algorithm.

=head1 METHODS

=head2 List::Range::Search::Liner->new($set)

Create a new List::Range::Search::Liner object.

=head2 $seeker->find($value)

Find the range included the C<$value> from the set.

=head1 SEE ALSO

L<List::Range> L<List::Range::Set> L<List::Range::Search::Binary>

=head1 LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

karupanerura E<lt>karupa@cpan.orgE<gt>

=cut
