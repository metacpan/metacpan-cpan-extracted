use Test;
BEGIN { plan(tests => 4) }

ok(sub { eval("use Metabrik::Crypto::Aes"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Crypto::Gpg"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Crypto::Letsencrypt"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Metabrik::Crypto::X509"); $@ ? 0 : 1 }, 1, $@);
