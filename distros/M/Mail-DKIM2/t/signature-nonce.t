use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Mail::DKIM2::Signature;
use Carp;

my $sig = Mail::DKIM2::Signature->new(
    Sequence   => 1,
    Domain     => 'example.com',
    Timestamp  => 1000000,
    Signatures => [['sel', 'rsa-sha256', '']],
);

# nonce of exactly 64 chars must be accepted
eval { $sig->nonce('a' x 64) };
is($@, '', 'nonce of 64 chars accepted');
is($sig->nonce, 'a' x 64, 'nonce stored correctly');

# nonce exceeding 64 chars must be rejected
eval { $sig->nonce('a' x 65) };
like($@, qr/64|too long|nonce/i, 'nonce > 64 chars dies');

# nonce of 1 char must be accepted
eval { $sig->nonce('x') };
is($@, '', 'nonce of 1 char accepted');

done_testing;
