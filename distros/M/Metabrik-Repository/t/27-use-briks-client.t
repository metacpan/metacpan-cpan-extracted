use Test;
BEGIN { plan(tests => 26) }

ok(sub { eval("use Metabrik::Client::Dns"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Client::Elasticsearch"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Client::Elasticsearch::Cluster"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Client::Elasticsearch::Indices"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Client::Elasticsearch::Tasks"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Client::Elasticsearch::Query"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Client::Openssh"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Client::Redis"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Client::Rest"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Client::Rsync"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Client::Splunk"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Client::Ssh"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Client::Ssl"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Client::Tcp"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Client::Tcpdump"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Client::Twitter"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Client::Udp"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Client::Whois"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Client::Www"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Client::Mongodb"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Client::Smbclient"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Client::Mysql"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Client::Sqlite"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Client::Telnet"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Client::Imap"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Client::Kafka"); $@ ? 0 : 1 }, 1, $@);
