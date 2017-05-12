#!/usr/bin/perl

use 5.006;

use strict;
use warnings;
no  warnings 'syntax';

use Test::More 0.88;

our $r = eval "require Test::NoWarnings; 1";

BEGIN {
    use_ok ('Games::Word::Wordlist::SGB') or
        BAIL_OUT ("Loading of 'Games::Word::Wordlist::SGB' failed");
}

ok defined $Games::Word::Wordlist::SGB::VERSION, "VERSION is set";

my $obj = Games::Word::Wordlist::SGB -> new;

isa_ok ($obj, 'Games::Word::Wordlist::SGB');
isa_ok ($obj, 'Games::Word::Wordlist');

is ($obj -> words, 5757, 'Correct number of words');

foreach my $word (qw [aargh which faxes pupal zowie pearl]) {
    ok  $obj -> is_word ($word), "$word in list";
}

foreach my $word (qw [buffy one perl cobol python parrot]) {
    ok !$obj -> is_word ($word), "$word not in list";
}

Test::NoWarnings::had_no_warnings () if $r;

done_testing;
