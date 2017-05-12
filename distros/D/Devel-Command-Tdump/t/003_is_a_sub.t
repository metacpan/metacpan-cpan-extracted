use Test::More tests=>4;

use Devel::Command::Tdump;

ok(Devel::Command::Tdump::is_a_sub('ok'), "ok is a sub");
ok(! Devel::Command::Tdump::is_a_sub('blortch'), "blortch is not a sub");
ok(! Devel::Command::Tdump::is_a_sub('_bad'), '_bad is not a sub');
ok(! Devel::Command::Tdump::is_a_sub('_bogus_sort'), 
   "_bogus_sort is a sub, but we're pretending it isn't");
