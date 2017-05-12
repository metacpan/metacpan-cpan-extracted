use Test;
BEGIN { plan(tests => 4) }

ok(sub { eval("use Metabrik::Shell::Command"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Shell::History"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Shell::Rc"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Shell::Script"); $@ ? 0 : 1 }, 1, $@);
