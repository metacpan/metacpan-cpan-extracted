# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl FLAT-FA.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 16;
use lib qw(../lib);
BEGIN { use_ok('FLAT::Legacy::FA') };
BEGIN { use_ok('FLAT::Legacy::FA::DFA') };
BEGIN { use_ok('FLAT::Legacy::FA::NFA') };
BEGIN { use_ok('FLAT::Legacy::FA::PFA') };
BEGIN { use_ok('FLAT::Legacy::FA::RE') };
BEGIN { use_ok('FLAT::Legacy::FA::PRE') };

isa_ok(FLAT::Legacy::FA::DFA->new(),'FLAT::Legacy::FA::DFA');
isa_ok(FLAT::Legacy::FA::NFA->new(),'FLAT::Legacy::FA::NFA');
isa_ok(FLAT::Legacy::FA::PFA->new(),'FLAT::Legacy::FA::PFA');
isa_ok(FLAT::Legacy::FA::RE->new(),'FLAT::Legacy::FA::RE');
isa_ok(FLAT::Legacy::FA::PRE->new(),'FLAT::Legacy::FA::PRE');

my $pre = FLAT::Legacy::FA::PRE->new();
$pre->set_pre("010|10&01");
my $pfa = $pre->to_pfa();
isa_ok($pfa,'FLAT::Legacy::FA::PFA');
my $nfa = $pfa->to_nfa();
isa_ok($nfa,'FLAT::Legacy::FA::NFA');
my $dfa = $nfa->to_dfa();
isa_ok($dfa,'FLAT::Legacy::FA::DFA');
my @removed = $dfa->minimize();
isa_ok($dfa,'FLAT::Legacy::FA::DFA');
ok(($#removed+1) >= 0,'FLAT::Legacy::FA::DFA->minimize() returns int >= 0');
