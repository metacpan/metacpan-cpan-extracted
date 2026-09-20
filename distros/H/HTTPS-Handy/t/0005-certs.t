######################################################################
#
# t/0005-certs.t - Certificate generation and PEM handling.
#
#   Generates a P-256 key and a self-signed certificate with the pure
#   Perl code in HTTPS::Handy, writes them as PEM, reads them back, and
#   checks that the key still works and that the certificate carries
#   the matching public key.
#
######################################################################

use strict;
BEGIN { $INC{'warnings.pm'} = '' if $] < 5.006 }; use warnings; local $^W=1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/../lib";
use File::Spec ();

###############################################################################
# Embedded test harness (no Test::More dependency)
###############################################################################
my ($PASS, $FAIL, $T) = (0, 0, 0);
sub ok   { my ($c, $n) = @_; $T++; $c ? ($PASS++, print "ok $T - $n\n") : ($FAIL++, print "not ok $T - $n\n") }
sub is   { my ($g, $e, $n) = @_; $T++; defined($g) && ("$g" eq "$e") ? ($PASS++, print "ok $T - $n\n") : ($FAIL++, print "not ok $T - $n  (got='${\(defined $g ? $g : 'undef')}', exp='$e')\n") }
sub plan_skip { print "1..0 # SKIP $_[0]\n"; exit 0 }

use HTTPS::Handy;

my $cert_dir = File::Spec->catdir(File::Spec->tmpdir, "https_handy_unit_certs_$$");

# --- _generate_self_signed ------------------------------------------------

my ($cert, $key) = HTTPS::Handy::_generate_self_signed(
    cert_dir => $cert_dir,
    log      => 0,
);

ok(-f $cert, 'self-signed certificate file created');
ok(-f $key,  'self-signed key file created');
ok((-s $cert) > 0, 'self-signed certificate file is non-empty');
ok((-s $key)  > 0, 'self-signed key file is non-empty');

# Calling again with the same cert_dir must reuse the existing
# certificate rather than regenerating it (documented behaviour).
my $mtime_before = (stat($cert))[9];
select undef, undef, undef, 1.1;  # ensure mtime would differ if regenerated
my ($cert2, $key2) = HTTPS::Handy::_generate_self_signed(
    cert_dir => $cert_dir,
    log      => 0,
);
is($cert2, $cert, '_generate_self_signed: same cert path on second call');
is((stat($cert2))[9], $mtime_before,
   '_generate_self_signed: existing certificate is reused, not regenerated');

# --- PEM structure ---------------------------------------------------------

sub _slurp_file {
    my ($path) = @_;
    local *FH;
    open(FH, "<$path") or return '';
    binmode FH;
    local $/;
    my $data = <FH>;
    close FH;
    return defined $data ? $data : '';
}

my $cert_pem = _slurp_file($cert);
my $key_pem  = _slurp_file($key);

ok(($cert_pem =~ /-----BEGIN CERTIFICATE-----/) ? 1 : 0, 'certificate PEM header');
ok(($cert_pem =~ /-----END CERTIFICATE-----/)   ? 1 : 0, 'certificate PEM footer');
ok(($key_pem  =~ /-----BEGIN EC PRIVATE KEY-----/) ? 1 : 0, 'key PEM header');

my @chain = HTTPS::Handy::X509::pem_blocks($cert_pem, 'CERTIFICATE');
is(scalar(@chain), 1, 'one certificate in the file');

# --- Reading the context back ----------------------------------------------

my $ctx = HTTPS::Handy::_load_context($cert, $key);
ok(ref($ctx) eq 'HASH', '_load_context returns a hash reference');
ok(ref($ctx->{'cert_chain'}) eq 'ARRAY', '_load_context: certificate chain');
is($ctx->{'key'}{'type'}, 'ec', '_load_context: the key is an elliptic curve key');
ok(defined $ctx->{'key'}{'d'}, '_load_context: the private number is present');
is(length(HTTPS::Handy::BigInt::b_to_bin($ctx->{'key'}{'x'}, 32)), 32,
   '_load_context: the public point is 32 bytes wide per coordinate');
is(HTTPS::Handy::EC::is_on_curve($ctx->{'key'}{'x'}, $ctx->{'key'}{'y'}), 1,
   '_load_context: the public point lies on the curve');

# --- The certificate carries the key that belongs to it --------------------

my $pub = HTTPS::Handy::TLS::cert_public_key($chain[0]);
ok(defined $pub, 'public key extracted from the certificate');
is($pub->{'type'}, 'ec', 'the certificate holds an elliptic curve key');
is(HTTPS::Handy::BigInt::b_to_hex($pub->{'x'}),
   HTTPS::Handy::BigInt::b_to_hex($ctx->{'key'}{'x'}),
   'certificate and private key share the same public point');

# --- The key pair actually works -------------------------------------------

# The private number times G must give back the point in the certificate
my ($gx, $gy) = HTTPS::Handy::EC::mul_generator($ctx->{'key'}{'d'});
is(HTTPS::Handy::BigInt::b_to_hex($gx),
   HTTPS::Handy::BigInt::b_to_hex($pub->{'x'}),
   'private number times the generator gives the certified point');

my $sig = HTTPS::Handy::X509::sign_data($ctx->{'key'}, 'sign me');
my ($tag, $body) = HTTPS::Handy::X509::der_next($sig, 0);
is($tag, 0x30, 'the ECDSA signature is a DER sequence');
my ($t1, $r, $next) = HTTPS::Handy::X509::der_next($body, 0);
my ($t2, $s) = HTTPS::Handy::X509::der_next($body, $next);
is($t1, 0x02, 'signature: r is an integer');
is($t2, 0x02, 'signature: s is an integer');
ok(length($r) >= 20 && length($r) <= 33, 'signature: r is the right size');
ok(length($s) >= 20 && length($s) <= 33, 'signature: s is the right size');

unlink $cert, $key;
rmdir $cert_dir;

print "1..$T\n";
exit($FAIL ? 1 : 0);
