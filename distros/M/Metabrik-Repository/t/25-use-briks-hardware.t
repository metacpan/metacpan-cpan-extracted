use Test;
BEGIN { plan(tests => 3) }

ok(sub { eval("use Metabrik::Hardware::Battery"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Hardware::Fan"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Hardware::Temperature"); $@ ? 0 : 1 }, 1, $@);
