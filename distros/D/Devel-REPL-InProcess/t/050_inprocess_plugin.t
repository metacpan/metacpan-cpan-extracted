#!/usr/bin/perl

use t::lib::Test;

my $repl1 = Devel::REPL->new;
my $repl2 = Devel::REPL->new;
$repl2->load_plugin('InProcess');

my $foo = 7;

# sanity
eq_or_diff($repl1->eval('1'), '1');
eq_or_diff($repl2->eval('1'), '1');

# can see lexicals
isa_ok($repl1->eval('$foo'), 'Devel::REPL::Error');
eq_or_diff($repl2->eval('$foo'), '7');

done_testing();
