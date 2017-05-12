#!/usr/bin/perl

use 5.006;

use strict;
use warnings;
no  warnings 'syntax';

use Test::More 0.88;

our $r = eval "require Test::NoWarnings; 1";

BEGIN {
    use_ok ('Games::Word::Wordlist::Enable') or
        BAIL_OUT ("Loading of 'Games::Word::Wordlist::Enable' failed");
}

ok defined $Games::Word::Wordlist::Enable::VERSION, "VERSION is set";


my $obj = Games::Word::Wordlist::Enable -> new;

isa_ok ($obj, 'Games::Word::Wordlist::Enable');

is ($obj -> words, 173528, 'Correct number of words');

foreach my $word (qw [one two three four five six seven]) {
    ok  $obj -> is_word ($word),           "$word in list";
    ok !$obj -> is_word (ucfirst $word), "\u$word not in list";
}

foreach my $word (qw [aap noot mies wim zus]) {
    ok !$obj -> is_word ($word), "$word not in list";
}


Test::NoWarnings::had_no_warnings () if $r;

done_testing;
