use Test;
BEGIN { plan(tests => 2) }

ok(sub { eval("use Metabrik::Brik::Search"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Brik::Tool"); $@ ? 0 : 1 }, 1, $@);
