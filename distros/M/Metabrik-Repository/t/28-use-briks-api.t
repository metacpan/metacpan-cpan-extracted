use Test;
BEGIN { plan(tests => 7) }

ok(sub { eval("use Metabrik::Api::Bluecoat"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Api::Shodan"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Api::Splunk"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Api::Virustotal"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Api::Cvesearch"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Api::Abuseipdb"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Api::Geonames"); $@ ? 0 : 1 }, 1, $@);
