#!perl

use Test::More tests => 5;

BEGIN { require_ok('Devel::CountOps'); }
pass('and it continues to work');

my $a = ${^_OPCODES_RUN};
ok($a > 0, "opcode count starts positive");

my $b = ${^_OPCODES_RUN};
ok($b > $a, "opcode count increases");

my $c = ${^_OPCODES_RUN};
$::cow = "bar";
my $d = ${^_OPCODES_RUN};
$::cow = "bar";
$::calf = "bar";
$::calf = "bar";
my $e = ${^_OPCODES_RUN};

ok(($e - $d) > ($d - $c), "more code makes a larger jump");
