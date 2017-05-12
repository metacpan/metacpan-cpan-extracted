use Test;
BEGIN { plan(tests => 1) }

ok(sub { eval("use Metabrik::Identify::Ssh"); $@ ? 0 : 1 }, 1, $@);
