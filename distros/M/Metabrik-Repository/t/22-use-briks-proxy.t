use Test;
BEGIN { plan(tests => 2) }

ok(sub { eval("use Metabrik::Proxy::Http"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Proxy::Ssh2tcp"); $@ ? 0 : 1 }, 1, $@);
