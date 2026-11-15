use strict;
use warnings;
use Test::More;
use MIME::Base64;
use lib 'lib';
use Mail::DKIM2;
use Mail::DKIM2::Verifier;

# One message's DNS lookups are waited for no longer than
# $Mail::DKIM2::Verifier::LOOKUP_BUDGET seconds in all: a message can name
# many keys under nameservers that never answer, each worth the resolver's
# whole timeout. Past the budget the lookups not yet made fail at once, as
# a DNS failure (TEMPERROR). No clock is waited on here: the resolver moves
# the verifier's clock on by what each question "took".

my $clock = 1000;
{
    no warnings 'redefine';
    *Mail::DKIM2::Verifier::_now = sub { $clock };
}

{
    package SlowResolver;
    sub new { my ($c, %a) = @_; bless { asked => [], %a }, $c }
    sub query { my ($s, $name) = @_; push @{ $s->{asked} }, $name; $clock += $s->{takes}; return }
    sub errorstring { 'query timed out' }
}

my $msg = "From: Alice <alice\@d1.example>\r\nTo: x\@d2.example\r\nSubject: s\r\n\r\nbody\r\n";
my $mi  = Mail::DKIM2::MessageInstance->calculate($msg);
my $sig = "DKIM2-Signature: i=1; m=1; t=" . time() . "; d=d1.example; mf="
    . encode_base64('<a@d1.example>', '') . "; rt=" . encode_base64('<a@d2.example>', '') . "; s="
    . join(',', map { "s$_:ed25519-sha256:" . encode_base64('x' x 64, '') } 1 .. 8);
my $message = join("\r\n", $sig, $mi->as_header, $msg);

sub verify {
    my ($takes) = @_;
    my $r = SlowResolver->new(takes => $takes);
    my $v = Mail::DKIM2::Verifier->new(Resolver => $r)->load($message);
    return ($v, scalar @{ $r->{asked} });
}

{
    my ($v, $asked) = verify(1);
    is($asked, 8, 'eight one-second lookups are all made');
    is($v->result, 'temperror', '... and the result is temperror');
}
{
    my ($v, $asked) = verify(5);
    is($asked, 4, 'five-second lookups stop after four: 20 seconds');
    is($v->result, 'temperror', '... and the result is still temperror');
    like($v->result_detail, qr/^temperror \(TEMPERROR: DKIM2-Signature i=1 public key \S+ could not be fetched\)$/,
         '... in the text a DNS failure has');
}
{
    local $Mail::DKIM2::Verifier::LOOKUP_BUDGET = 7;
    my ($v, $asked) = verify(5);
    is($asked, 2, 'the budget can be changed');
}
{
    my ($v, $asked) = verify(5);
    my $p = eval { $v->fetch_domain_policy('d1.example') };
    like($@, qr/^TEMPERROR: DNS lookup for _domainkey\.d1\.example failed: this message's lookups have taken 20 s/,
         'a policy lookup past the budget fails the same way');
}

done_testing;
