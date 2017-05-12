use Test;
BEGIN { plan(tests => 8) }

ok(sub { eval("use Metabrik::Database::Cwe"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Database::Keystore"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Database::Nvd"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Database::Ripe"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Database::Rir"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Database::Sinfp3"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Database::Vfeed"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Database::Cvesearch"); $@ ? 0 : 1 }, 1, $@);
