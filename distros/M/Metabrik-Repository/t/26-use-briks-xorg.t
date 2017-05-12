use Test;
BEGIN { plan(tests => 4) }

ok(sub { eval("use Metabrik::Xorg::Screenshot"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Xorg::Xlsclients"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Xorg::Xwininfo"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Xorg::Xrandr"); $@ ? 0 : 1 }, 1, $@);
