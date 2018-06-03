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

# Evil in the sense that these caused a bug in FLAT::NFA::as_dfa to rear its ugly head ...
my @EVIL = qw/a* a*+b a*+b* a*&b a*&b*/;
foreach my $evil (@EVIL) {
    my $PRE = FLAT::Regex::WithExtraOps->new($evil);
    my $DFA = $PRE->as_pfa->as_nfa->as_dfa->as_min_dfa->trim_sinks;
    isa_ok($DFA, 'FLAT::DFA::Minimal');
    can_ok($DFA, qw/set_equivalence_classes get_equivalence_classes/);
    ok(ref $DFA->get_equivalence_classes eq 'ARRAY', q{Equivalence class for minimal DFA is an array ref});
    # default depth
    my $next = $DFA->new_acyclic_string_generator();
    while (my $string = $next->()) {
        ok($DFA->is_valid_string($string), "string '$string'");
    }
    # deeper
    $next = $DFA->new_deepdft_string_generator(10);
    while (my $string = $next->()) {
        ok($DFA->is_valid_string($string), "string '$string'");
    }
}

for (1 .. 100) {
    my $PRE = FLAT::Regex::Util::random_pre(4);
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
