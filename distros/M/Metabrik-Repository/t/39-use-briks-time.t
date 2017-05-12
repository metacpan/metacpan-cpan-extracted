use Test;
BEGIN { plan(tests => 1) }

ok(sub { eval("use Metabrik::Time::Universal"); $@ ? 0 : 1 }, 1, $@);
