use Test;
BEGIN { plan(tests => 2) }

ok(sub { eval("use Metabrik::Format::Latex"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Format::Number"); $@ ? 0 : 1 }, 1, $@);
