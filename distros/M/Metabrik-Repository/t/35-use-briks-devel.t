use Test;
BEGIN { plan(tests => 4) }

ok(sub { eval("use Metabrik::Devel::Git"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Devel::Mercurial"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Devel::Mojo"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Devel::Subversion"); $@ ? 0 : 1 }, 1, $@);
