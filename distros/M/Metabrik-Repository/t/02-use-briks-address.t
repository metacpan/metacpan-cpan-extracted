use Test;
BEGIN { plan(tests => 1) }

ok(sub { eval("use Metabrik::Address::Generate"); $@ ? 0 : 1 }, 1, $@);
