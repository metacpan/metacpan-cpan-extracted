use Test;
BEGIN { plan(tests => 1) }

ok(sub { eval("use Metabrik::Repository"); $@ ? 0 : 1 }, 1, $@);
