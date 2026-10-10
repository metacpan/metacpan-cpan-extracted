use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use DKIM2SignedFixture;
use Mail::DKIM2::Common qw(parse_mime fold_header);
use Mail::DKIM2::DSN;
use Mail::DKIM2::Gate;
use Mail::DKIM2::MessageInstance;
use Mail::DKIM2::MessageStore;
use Mail::DKIM2::Signature;
use Mail::DKIM2::Signer;
use Mail::DKIM2::Validate;
use Mail::DKIM2::Verifier;

# Mail::DKIM2 CONVENTIONS: an option a constructor or class method does not
# know is a croak naming it, never a silently ignored setting (review R9:
# Signature->new(Domian => ...) built a signature with no domain, and
# calculate(..., Algz => ['sha512']) computed SHA-256).

my $msg = DKIM2SignedFixture::signed();
my $plain = $DKIM2SignedFixture::BODY;

my @cases = (
    [ 'Signature->new' => sub { Mail::DKIM2::Signature->new(Domian => 'example.com') }, 'Domian' ],
    [ 'Signer->new' => sub { Mail::DKIM2::Signer->new(Domian => 'example.com') }, 'Domian' ],
    [ 'Verifier->new' => sub { Mail::DKIM2::Verifier->new(SkipTimestampChek => 1) }, 'SkipTimestampChek' ],
    [ 'MessageInstance->calculate' => sub {
        Mail::DKIM2::MessageInstance->calculate($plain, undef, Algz => ['sha512']) }, 'Algz' ],
    [ 'MessageInstance->verify' => sub {
        Mail::DKIM2::MessageInstance->verify($msg, IgnorePrefix => ['x-']) }, 'IgnorePrefix' ],
    [ 'MessageInstance->chain_verifies' => sub {
        Mail::DKIM2::MessageInstance->chain_verifies($msg, Bogus => 1) }, 'Bogus' ],
    [ 'MessageInstance->undo' => sub {
        Mail::DKIM2::MessageInstance->undo(parse_mime($msg), HeaderOnly => 1) }, 'HeaderOnly' ],
    [ 'Gate->check' => sub { Mail::DKIM2::Gate->check($msg, SigningDomian => 'x') }, 'SigningDomian' ],
    [ 'DSN->generate' => sub { Mail::DKIM2::DSN->generate(Message => $msg, Bogus => 1) }, 'Bogus' ],
    [ 'DSN->authenticate' => sub { Mail::DKIM2::DSN->authenticate(Message => $msg, Bogus => 1) }, 'Bogus' ],
    [ 'DSN->propagate' => sub { Mail::DKIM2::DSN->propagate(Message => $msg, Bogus => 1) }, 'Bogus' ],
    [ 'MessageStore->new' => sub { Mail::DKIM2::MessageStore->new(directroy => '/tmp') }, 'directroy' ],
    [ 'Validate::report' => sub { Mail::DKIM2::Validate::report($msg, DnsPth => 'x') }, 'DnsPth' ],
    [ 'fold_header' => sub { fold_header('Subject: x', 72, delimiter_only => 1) }, 'delimiter_only' ],
);

for my $c (@cases) {
    my ($name, $code, $opt) = @$c;
    eval { $code->() };
    like($@, qr/unknown option \Q$opt\E\b/, "$name: unknown option $opt croaks");
    like($@, qr/ at \Q$0\E line \d+/, "$name: reported at the caller's line")
        or diag $@;
}

# The known options still work.
ok(Mail::DKIM2::Signature->new(Domain => 'example.com')->domain, 'Signature->new(Domain)');
ok(Mail::DKIM2::MessageInstance->calculate($plain, undef, Algs => ['sha512']),
    'calculate(Algs)');

done_testing;
