use Test;
BEGIN { plan(tests => 4) }

ok(sub { eval("use Metabrik::Email::Mbox"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Email::Message"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Email::Send"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Email::Imap"); $@ ? 0 : 1 }, 1, $@);
