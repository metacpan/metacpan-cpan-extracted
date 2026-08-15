use v5.26;
use warnings;
use Feature::Compat::Class;

# ABSTRACT: Fixed Size FIFO/Queue for rolling averages

package MIDI::Stream::FIFO;
class MIDI::Stream::FIFO;

our $VERSION = '0.006';

use List::Util qw/ reduce /;

field $length :param = 24;
field @members;

field $average;

method add( $member ) {
    undef $average;
    unshift @members, $member;
    splice @members, $length if @members > $length;
}

method average {
    return 0 unless @members;
    $average //= ( reduce { $a + $b } @members ) / @members;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MIDI::Stream::FIFO - Fixed Size FIFO/Queue for rolling averages

=head1 VERSION

version 0.006

=head1 AUTHOR

John Barrett <john@jbrt.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by John Barrett.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
