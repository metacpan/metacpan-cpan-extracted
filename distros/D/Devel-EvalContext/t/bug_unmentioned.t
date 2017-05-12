use strict; use warnings;
use Test::More tests => 4;
use Devel::EvalContext;

our $CommVar;

my $cxt = Devel::EvalContext->new;

$cxt->run(q{my $a = 5; $::CommVar = $a});
ok($CommVar == 5);
$cxt->run(q{my $b = 6; $::CommVar = $b});
ok($CommVar == 6);
$cxt->run(q{$::CommVar = "$a $b"});
is($CommVar, "5 6");

$cxt = Devel::EvalContext->new;
$cxt->run(q{my @a = (1, 2, 3); my %b = (a => 1, b => 2, c => 3);});
$cxt->run(q{my $c = 7;});
$cxt->run(q{$::CommVar = "@a @b{qw(a b c)} $c"});
is($CommVar, "1 2 3 1 2 3 7");
