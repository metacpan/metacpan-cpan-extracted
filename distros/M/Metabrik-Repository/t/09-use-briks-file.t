use Test;
BEGIN { plan(tests => 18) }

ok(sub { eval("use Metabrik::File::Compress"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::File::Csv"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::File::Dump"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::File::Find"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::File::Hash"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::File::Ini"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::File::Json"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::File::Ole"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::File::Pcap"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::File::Psv"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::File::Raw"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::File::Read"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::File::Readelf"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::File::Text"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::File::Tsv"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::File::Type"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::File::Write"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::File::Xml"); $@ ? 0 : 1 }, 1, $@);
