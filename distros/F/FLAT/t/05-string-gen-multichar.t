BEGIN {
    unshift @INC, '../lib';
}

use Test::More 'no_plan';
use strict;
use warnings;
use FLAT;
use FLAT::DFA;
use FLAT::NFA;
use FLAT::PFA;
use FLAT::Regex::WithExtraOps;
use FLAT::Regex::Util;

my $length     = 1;
my $symbol_len = 1;
for my $i (1 .. 20) {
    if ($i % 20 == 0) {
      $length++;
      $symbol_len++;
    }
    my $PRE = FLAT::Regex::Util::random_pre($length, $symbol_len);
    my $DFA = $PRE->as_pfa->as_nfa->as_dfa->as_min_dfa->trim_sinks;
    # default depth
    my $next = $DFA->new_acyclic_string_generator();
    while (my $string = $next->()) {
        ok($DFA->is_valid_string($string), "string '$string'");
    }
    # a little deeper
    $next = $DFA->new_deepdft_string_generator(2);
    while (my $string = $next->()) {
        ok($DFA->is_valid_string($string), "string '$string'");
    }
}
