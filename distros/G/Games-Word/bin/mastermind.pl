#!/usr/bin/env perl
use strict;
use warnings;
use Games::Word qw/random_string_from shared_letters
                   shared_letters_by_position/;
# PODNAME: mastermind.pl

my $word = random_string_from "abcdefg", 5;
while (1) {
    print "Guess? ";
    my $guess = <>;
    chomp $guess;
    last if $guess eq $word;
    my $gears = shared_letters_by_position $guess, $word;
    my $tumblers = shared_letters($guess, $word) - $gears;
    printf "You hear $tumblers tumbler%s and $gears gear%s.\n",
           $tumblers == 1 ? '' : 's',
           $gears    == 1 ? '' : 's';
}
print "You see the drawbridge open.\n";

__END__
=pod

=head1 NAME

mastermind.pl

=head1 VERSION

version 0.06

=head1 AUTHOR

Jesse Luehrs <doy at tozt dot net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Jesse Luehrs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

