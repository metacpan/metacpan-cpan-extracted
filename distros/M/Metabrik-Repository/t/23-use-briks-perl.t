use Test;
BEGIN { plan(tests => 1) }

ok(sub { eval("use Metabrik::Perl::Module"); $@ ? 0 : 1 }, 1, $@);
