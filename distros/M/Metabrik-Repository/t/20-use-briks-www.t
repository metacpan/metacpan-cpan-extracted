use Test;
BEGIN { plan(tests => 2) }

ok(sub { eval("use Metabrik::Www::Shorten"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Www::Google"); $@ ? 0 : 1 }, 1, $@);
