#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/lib";
use Path::Tiny;
use Crypt::Digest::SHA256 ();
use Crypt::Digest::SHA512 ();
use Mail::DKIM2::Digest;
use Mail::DKIM2::Verifier;
use DKIM2TestKeys;

# Message hashes go through Mail::DKIM2::Digest: OpenSSL's (through
# Net::SSLeay, several times quicker where the CPU has SHA instructions)
# when it is there, CryptX's otherwise. Both give the same digests.

my @inputs = ('', 'abc', "line\r\n" x 1000, join('', map { chr } 0 .. 255) x 300);
my %cryptx = (sha256 => 'Crypt::Digest::SHA256', sha512 => 'Crypt::Digest::SHA512');

my @backends = ('cryptx');
push @backends, 'openssl' if Mail::DKIM2::Digest::openssl_available();
note 'backends here: ' . join(', ', @backends) . '; default ' . Mail::DKIM2::Digest::backend();

for my $backend (@backends) {
    local $Mail::DKIM2::Digest::BACKEND = $backend;
    is(Mail::DKIM2::Digest::backend(), $backend, "$backend: chosen");
    for my $alg (qw(sha256 sha512)) {
        for my $in (@inputs) {
            my $want = $cryptx{$alg}->new->add($in)->digest;
            is(Mail::DKIM2::Digest::digest_data($alg, $in), $want,
               "$backend $alg one-shot, " . length($in) . ' bytes');
            my $d = Mail::DKIM2::Digest->new($alg);
            my $cut = length($in) < 7 ? length($in) : 7;
            $d->add(substr($in, 0, $cut))->add(substr($in, $cut));
            is($d->digest, $want, "$backend $alg in pieces, " . length($in) . ' bytes');
        }
    }
    eval { Mail::DKIM2::Digest->new('md5') };
    like($@, qr/unsupported hash algorithm: md5/, "$backend: an unknown algorithm croaks");
}

SKIP: {
    skip 'OpenSSL digests not available (Net::SSLeay)', 1 unless @backends > 1;
    # The verifier's verdicts are the same whichever does the hashing.
    my %verdicts;
    for my $backend (@backends) {
        local $Mail::DKIM2::Digest::BACKEND = $backend;
        for my $f (sort(path("$FindBin::Bin/../tests/expected")->children(qr/\.eml\z/))) {
            my $v = Mail::DKIM2::Verifier->new(SkipTimestampCheck => 1,
                PubkeyCallback => DKIM2TestKeys::pubkey_callback());
            $v->load($f->slurp_raw);
            $verdicts{$backend}{$f->basename} = $v->result_detail;
        }
    }
    is_deeply($verdicts{openssl}, $verdicts{cryptx}, 'the verifier: same verdicts either way');
}

done_testing;
