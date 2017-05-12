use Test;
BEGIN { plan(tests => 6) }

ok(sub { eval("use Metabrik::Audit::Dns"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Audit::Drupal"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Audit::Elasticsearch"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Audit::Https"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Audit::Smtp"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Audit::Twiki"); $@ ? 0 : 1 }, 1, $@);
