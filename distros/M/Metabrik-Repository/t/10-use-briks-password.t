use Test;
BEGIN { plan(tests => 2) }

ok(sub { eval("use Metabrik::Password::Mirai"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Password::Rockyou"); $@ ? 0 : 1 }, 1, $@);
