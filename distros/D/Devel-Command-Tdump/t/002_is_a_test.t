use Test::More tests=>2;

use Devel::Command::Tdump;
my $map = {'ok' => 1};

ok(Devel::Command::Tdump::is_a_test("ok()", $map), "ok found as expected");
ok(!Devel::Command::Tdump::is_a_test("bad()", $map), "bad not found as expected");
