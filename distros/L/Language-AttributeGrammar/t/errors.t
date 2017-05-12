use strict;
use warnings;

use Test::More tests => 8;
use Test::Exception;

my $m; BEGIN { use_ok($m = 'Language::AttributeGrammar') }

sub mkg { $m->new(shift) }
sub mko { my $c = shift; bless { @_ }, $c }
sub apply { mkg(shift)->apply(@_) }

# supress emission of crap the user doesn't care about
$::RD_ERRORS = undef;
$::RD_WARN = undef;

throws_ok {
    mkg('syntax error b{{{ {lkjahdtkjhat #%$!%^!#*^#!^!'); # i really hope that's not perl ;-)
} qr/Parse error.*errors\.t/, "bad grammer makes a syntax error";

throws_ok {
    apply('Foo: $/.gorch = { $<doesnt_exist> }', mko("Foo"), 'gorch');
} qr/doesnt_exist.*line 1.*errors\.t/i, "can't access in-existent field in node";

throws_ok {
    apply('Foo: $/.gorch = { $/.doesnt_exist }', mko("Foo"), 'gorch');
} qr/doesnt_exist.*line 1.*errors\.t/i, "can't call undefined function/attr";

throws_ok {
    apply('Cons: $/.length = { $<tail>.length }', mko(Cons => tail => mko(Cons => tail => mko('Nil'))), 'length');
} qr/Nil.*errors\.t/i, "no visitor defined";

throws_ok {
    apply('Cons: $<tail>.depth = { 1 + $/.depth }  Nil:', mko(Cons => tail => mko(Cons => tail => mko("Nil"))), 'depth');
} qr/depth/i, "in-existent attribute (lack of root)";

throws_ok {
    apply(<<'EOG', mko(Cons => tail => mko(Cons => tail => mko("Nil"))), 'length');
ROOT: $/.depth = { 0 }
Cons: $<tail>.depth = { 1 + $/.depth }
Nil:  $/.depth  = { 0 }
   |  $/.length = { $/.depth }
EOG
} qr/depth.*line 3.*errors\.t/i, "nonlinear attribute";

throws_ok {
    apply(<<'EOG', mko(Cons => tail => mko(Cons => tail => mko('Nil'))), 'b');
ROOT: $/.b      = { $/.a }
Cons: $<tail>.b = { $/.b }
    | $/.a      = { $<tail>.a }
Nil:  $/.a      = { $/.b }
EOG
} qr/infinite loop/i;

# vim: ft=perl :
