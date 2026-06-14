use Test2::V0;
use File::Slurper qw/read_binary/;
use Dist::Zilla::Plugin::SigStore::SignRelease;

my $bundle_name = 't/data/Net-CIDR-Set-0.22.tar.gz.sigstore.json';

my $bundle      = Dist::Zilla::Plugin::SigStore::SignRelease->_load_bundle($bundle_name);

ok(!$bundle->{mediaType}, "No vnd.dev.sigstore.bundle.v0.3+json as expected");

ok($bundle->{cert}, "Found cert as expected");

my $der         = Dist::Zilla::Plugin::SigStore::SignRelease->_get_der_from_bundle ($bundle);
ok(defined $der, "Found a der file maybe");

my $x509        = Dist::Zilla::Plugin::SigStore::SignRelease->_get_x509_from_der($der);

isa_ok ($x509, 'Crypt::OpenSSL::X509');

my $extensions  = $x509->extensions_by_oid();

my $identity    = Dist::Zilla::Plugin::SigStore::SignRelease->_decode_oid_value($extensions, '2.5.29.17');

like ($identity, qr/github\@rrwo\.uk\.eu\.org/, "Found expected user identity");

my $issuer      = Dist::Zilla::Plugin::SigStore::SignRelease->_decode_oid_value($extensions, '1.3.6.1.4.1.57264.1.1');

like ($issuer, qr/https:\/\/github\.com\/login\/oauth/, "Found the expected issuer");

done_testing();
