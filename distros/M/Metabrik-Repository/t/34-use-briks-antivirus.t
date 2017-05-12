use Test;
BEGIN { plan(tests => 1) }

ok(sub { eval("use Metabrik::Antivirus::Clamav"); $@ ? 0 : 1 }, 1, $@);
