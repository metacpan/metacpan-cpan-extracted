use strict;
use warnings;
use Test::More;
use Path::Tiny;
use lib 'lib', 't/lib';
use Mail::DKIM2::Verifier;
use DKIM2TestKeys;

# A host writing Authentication-Results needs the signatures the verifier
# saw -- header.d and header.i come from the top one. These accessors are
# the supported way to get them; the object hash is not.

my $raw = path('tests/expected/chain-hop2-mailing-list.eml')->slurp;
$raw =~ s/\r?\n/\r\n/g;

my $v = Mail::DKIM2::Verifier->new(
    SkipTimestampCheck => 1,
    PubkeyCallback     => DKIM2TestKeys::pubkey_callback(),
)->load($raw);
is($v->result, 'pass', 'two-hop chain verifies');

my @sigs = $v->signatures;
is(scalar @sigs, 2, 'signatures() returns both hops');
isa_ok($sigs[0], 'Mail::DKIM2::Signature');
is_deeply([map { $_->sequence } @sigs], [1, 2], '  ... in ascending i= order');

my $top = $v->top_signature;
is($top->sequence, 2, 'top_signature() is the highest i=');
ok($top->domain, '  ... with a domain for header.d');
is($top, $sigs[-1], '  ... and is the last of signatures()');

my $none = Mail::DKIM2::Verifier->new->load("Subject: x\r\n\r\nbody\r\n");
is($none->result, 'none', 'unsigned message is none');
is_deeply([$none->signatures], [], '  ... with no signatures');
is($none->top_signature, undef, '  ... and no top signature');

done_testing;
