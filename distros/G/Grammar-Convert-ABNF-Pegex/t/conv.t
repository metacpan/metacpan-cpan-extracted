#!/usr/bin/env perl

use v5.10;

use strict;
use warnings;

use Test::More;

use Grammar::Convert::ABNF::Pegex;

my %tests = (
    "A = (B C) / *D\n" => 'A: (B C) | D*',
    "A = B / C / D\n"  => 'A: B | C | D',
    "A = B C\n"        => 'A: (B C)',
);

for my $rule ( sort keys %tests ) {
    my $conv = Grammar::Convert::ABNF::Pegex->new( abnf => $rule );
    is $conv->pegex, $tests{$rule} . "\n", $rule;
}

done_testing();
