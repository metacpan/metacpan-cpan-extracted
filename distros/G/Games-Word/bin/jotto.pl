#!/usr/bin/env perl
use strict;
use warnings;
use Games::Word qw/shared_letters/;
use Games::Word::Wordlist;
# PODNAME: jotto.pl

my $wl = Games::Word::Wordlist->new('/usr/share/dict/words');
$wl->remove_words($wl->words_like(qr/^(.{0,4}|.{6,})$/));
$wl->remove_words($wl->words_like(qr/[^a-z]/));
my $word = $wl->random_word;
my $guesses = 0;
while (1) {
    print "Guess a word: ";
    my $guess = <>;
    chomp $guess;

    if ($guess eq '.') {
        print "The word was $word\n";
        exit;
    }
    if (length $guess != 5) {
        print "Word must be 5 letters long.\n";
        next;
    }
    if (!$wl->is_word($guess)) {
        print "$guess is not a word.\n";
        next;
    }
    $guesses++;
    last if $guess eq $word;

    my $correct = shared_letters $word, $guess;
    printf "You got $correct letter%s correct.\n", $correct == 1 ? "" : "s";
}
print "You win in $guesses guesses!\n";

__END__
=pod

=head1 NAME

jotto.pl

=head1 VERSION

version 0.06

=head1 AUTHOR

Jesse Luehrs <doy at tozt dot net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Jesse Luehrs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

