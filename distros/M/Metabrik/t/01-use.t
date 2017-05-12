use Test;
BEGIN { plan(tests => 5) }

ok(sub { eval("use Metabrik"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Core::Context"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Core::Global"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Core::Log"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Core::Shell"); $@ ? 0 : 1 }, 1, $@);
