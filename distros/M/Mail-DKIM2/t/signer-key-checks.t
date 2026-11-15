use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Mail::DKIM2;
use Mail::DKIM2::Common qw(fold_header load_private_key signature_algorithm
                           signature_algorithm_for_key);

# The Signer signs only with an algorithm this library implements and the
# key it was given can sign with (-09 sections 3.2, 3.3), and never with an
# RSA key under 1024 bits.

my $keys = "$FindBin::Bin/data/keys";
my $rsa  = "$keys/sel1._domainkey.test1.dkim2.com.pem";
my $ed   = "$keys/ed25519._domainkey.test1.dkim2.com.pem";
my $weak = "$keys/rsa512._domainkey.test1.dkim2.com.pem";

my $message = "From: a\@test1.dkim2.com\r\nSubject: x\r\n\r\nbody\r\n";
$message = fold_header('Message-Instance: '
    . Mail::DKIM2::MessageInstance->calculate($message)->as_string) . "\r\n" . $message;

sub signer {
    return Mail::DKIM2::Signer->new(
        Domain => 'test1.dkim2.com', Selector => 'sel1',
        MailFrom => '<a@test1.dkim2.com>', RcptTo => ['<b@example.net>'], @_);
}

subtest 'the algorithm defaults to the key\'s' => sub {
    is(signer(KeyFile => $rsa)->load($message)->signature->algorithm, 'rsa-sha256', 'RSA key');
    my $s = signer(KeyFile => $ed)->load($message);
    is($s->result, 'signed', 'an Ed25519 key signs with no Algorithm given');
    is($s->signature->algorithm, 'ed25519-sha256', 'as ed25519-sha256');
    is(signer(Key => load_private_key($ed))->load($message)->signature->algorithm,
        'ed25519-sha256', 'a key object too');
};

subtest 'a wrong algorithm is a mistake in the call' => sub {
    for my $alg (qw(mldsa44 RSA-SHA256 rsa-sha1 ed25519)) {
        ok(!eval { signer(KeyFile => $rsa, Algorithm => $alg); 1 }, "Algorithm $alg croaks");
        like($@, qr/unsupported Algorithm \Q$alg\E/, 'saying so');
    }
    ok(!eval { signer(KeyFile => $ed, Algorithm => 'rsa-sha256'); 1 },
        'rsa-sha256 with an Ed25519 key croaks');
    like($@, qr/needs a Crypt::PK::RSA key/, 'naming the key it needs');
    ok(!eval { signer(KeyFile => $rsa, Algorithm => 'ed25519-sha256'); 1 },
        'ed25519-sha256 with an RSA key croaks');
    ok(!eval { signer(Key => 'not a key'); 1 }, 'a Key that is not a key object croaks');
};

subtest 'an RSA key under 1024 bits does not sign' => sub {
    my $s = signer(KeyFile => $weak);
    ok(eval { $s->load($message); 1 }, 'no exception from load');
    is($s->result, 'fail', 'result is fail');
    is($s->details, 'signing key is shorter than 1024 bits', 'details say why');
    ok(!eval { $s->as_string; 1 }, 'and there is no signature to take');
};

subtest 'the registry' => sub {
    is(signature_algorithm('rsa-sha256')->{key_class}, 'Crypt::PK::RSA', 'rsa-sha256');
    is(signature_algorithm('ed25519-sha256')->{key_class}, 'Crypt::PK::Ed25519', 'ed25519-sha256');
    is(signature_algorithm('mldsa44'), undef, 'mldsa44 is not implemented');
    is(signature_algorithm(undef), undef, 'undef');
    is(signature_algorithm_for_key(load_private_key($rsa)), 'rsa-sha256', 'RSA key');
    is(signature_algorithm_for_key('x'), undef, 'not a key');
};

subtest 'a calculated null body Recipe is unrecoverable' => sub {
    my $prev = "From: a\@test1.dkim2.com\r\n\r\n" . join('', map { "line $_\r\n" } 1 .. 5);
    $prev = fold_header('Message-Instance: '
        . Mail::DKIM2::MessageInstance->calculate($prev)->as_string) . "\r\n" . $prev;
    (my $cur = $prev) =~ s/\r\n\r\n.*/\r\n\r\nnew\r\n/s;
    my $mi = Mail::DKIM2::MessageInstance->calculate($cur, $prev, MaxRecipeLiterals => 1);
    ok($mi->unrecoverable, 'as calculated');
    ok(Mail::DKIM2::MessageInstance->parse($mi->as_string)->unrecoverable, 'and as parsed');
    my $by_hand = Mail::DKIM2::MessageInstance->calculate($cur, $prev, BodyRecipe => 'null');
    ok($by_hand->unrecoverable, 'BodyRecipe null too');
    is($by_hand->as_string, $mi->as_string, 'the same field');
};

done_testing;
