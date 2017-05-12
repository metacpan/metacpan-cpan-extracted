use Test;
BEGIN { plan(tests => 1) }

ok(sub { eval("use Metabrik::Terminal::Control"); $@ ? 0 : 1 }, 1, $@);
