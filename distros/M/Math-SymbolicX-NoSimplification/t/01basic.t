use strict;
use warnings;
use Test::More tests => 5;

use_ok('Math::Symbolic');
use_ok('Math::SymbolicX::NoSimplification');

my $f = Math::Symbolic->parse_from_string('2+3');
my $f_s = $f->simplify();

ok($f->is_identical($f_s), "Doesn't simplify.");

Math::SymbolicX::NoSimplification::do_simplify();

$f = Math::Symbolic->parse_from_string('2+3');
$f_s = $f->simplify();

ok(!$f->is_identical($f_s), "Does simplify.");

Math::SymbolicX::NoSimplification::dont_simplify();

$f = Math::Symbolic->parse_from_string('2+3');
$f_s = $f->simplify();

ok($f->is_identical($f_s), "Doesn't simplify.");

