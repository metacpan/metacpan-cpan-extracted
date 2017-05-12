use Test;
BEGIN { plan(tests => 1) }

ok(sub { eval("use Metabrik::Password::Mirai"); $@ ? 0 : 1 }, 1, $@);
