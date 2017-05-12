use Test;
BEGIN { plan(tests => 1) }

ok(sub { eval("use Metabrik::Convert::Number"); $@ ? 0 : 1 }, 1, $@);
