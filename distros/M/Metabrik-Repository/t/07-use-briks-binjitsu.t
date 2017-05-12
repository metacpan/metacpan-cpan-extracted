use Test;
BEGIN { plan(tests => 2) }

ok(sub { eval("use Metabrik::Binjitsu::Checksec"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Binjitsu::Pattern"); $@ ? 0 : 1 }, 1, $@);
