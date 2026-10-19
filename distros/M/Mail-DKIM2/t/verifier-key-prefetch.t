#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/lib";
use Path::Tiny;
use JSON qw(decode_json);
use Net::DNS;
use Mail::DKIM2::Verifier;
use DKIM2TestKeys;

# The Verifier asks for every signature's public key as soon as it has the
# header fields, all at once and in the background, and reads the answers
# when it checks the signatures -- after the body. An answer that settles
# nothing (no reply in time, SERVFAIL) is asked again the ordinary way, so
# the verdicts are those of one query at a time.

# A resolver with Net::DNS's background calls, answering from dns.json and
# logging every call.
package BgResolver {
    use Net::DNS;
    sub new {
        my ($class, %o) = @_;
        return bless { log => [], %o }, $class;
    }
    # rcode: per name, a true answer either way. all_rcode: every answer
    # in the background only.
    sub _answer {
        my ($self, $fqdn, $bg) = @_;
        my $p = Net::DNS::Packet->new($fqdn, 'TXT', 'IN');
        $p->header->qr(1);
        my $rcode = $self->{rcode}{$fqdn} // ($bg && $self->{all_rcode});
        if ($rcode) {
            $p->header->rcode($rcode);
            return $p;
        }
        my ($sel, $dom) = $fqdn =~ /\A(.*)\._domainkey\.(.*)\z/;
        my $e = $self->{dns}{$dom}{"${sel}._domainkey"};
        if ($e && $e->[0]) {
            $p->push(answer => Net::DNS::RR->new(
                name => $fqdn, type => 'TXT', txtdata => [unpack '(a255)*', $e->[0][1]]));
        } else {
            $p->header->rcode('NXDOMAIN');
        }
        return $p;
    }
    sub bgsend {
        my ($self, $fqdn, $type) = @_;
        push @{$self->{log}}, ['bgsend', $fqdn];
        return { fqdn => $fqdn };
    }
    sub bgbusy { return $_[0]{hang} ? 1 : 0 }
    sub bgread {
        my ($self, $h) = @_;
        push @{$self->{log}}, ['bgread', $h->{fqdn}];
        return undef if $self->{timeout};
        return $self->_answer($h->{fqdn}, 1);
    }
    # As Net::DNS's query(): the reply if it has answers, else undef and
    # the rcode as the error.
    sub query {
        my ($self, $fqdn) = @_;
        push @{$self->{log}}, ['query', $fqdn];
        my $p = $self->{query_rcode}
            ? do { my $q = Net::DNS::Packet->new($fqdn, 'TXT');
                   $q->header->rcode($self->{query_rcode}); $q }
            : $self->_answer($fqdn);
        return $p if $p->header->ancount;
        $self->{err} = $p->header->rcode;
        return undef;
    }
    sub errorstring { $_[0]{err} }
    sub calls { my ($self, $what) = @_; return [ map { $_->[1] } grep { $_->[0] eq $what } @{$self->{log}} ] }
}

my $dns = decode_json(path(DKIM2TestKeys::dns_json())->slurp);
(my $raw = path("$FindBin::Bin/../tests/expected/chain-hop6-unchanged-re-sign.eml")->slurp_raw)
    =~ s/\r?\n/\r\n/g;
my $hdr_end = index($raw, "\r\n\r\n") + 4;

# The key names the signatures need, each once.
my %names;
for my $field ($raw =~ /^DKIM2-Signature:(.*?\r\n)(?=\S)/msg) {
    my $sig = Mail::DKIM2::Signature->parse($field);
    $names{$sig->selector($_) . '._domainkey.' . $sig->domain} = 1 for 0 .. $sig->sig_count - 1;
}
my @names = sort keys %names;
cmp_ok(scalar @names, '<', 6, 'six signatures, fewer key names (one is used twice)');

sub run {
    my (%o) = @_;
    my $res = BgResolver->new(dns => $dns, %{ delete $o{resolver} || {} });
    my $v = Mail::DKIM2::Verifier->new(SkipTimestampCheck => 1, Resolver => $res, %o);
    $v->PRINT(substr($raw, 0, $hdr_end));
    my @at_eoh = sort @{ $res->calls('bgsend') };
    $v->PRINT(substr($raw, $hdr_end));
    $v->CLOSE;
    return ($v, $res, \@at_eoh);
}

{
    my ($v, $res, $at_eoh) = run();
    is_deeply($at_eoh, \@names, 'every key asked for once, by the end of the headers');
    is($v->result, 'pass', 'the chain verifies on the prefetched keys');
    is_deeply($res->calls('query'), [], 'no key asked for again');
    is_deeply([sort @{ $res->calls('bgread') }], \@names, 'each answer read once');
}

{
    my ($v, $res) = run(PubkeyCallback => DKIM2TestKeys::pubkey_callback());
    is_deeply($res->calls('bgsend'), [], 'a PubkeyCallback fetches the keys itself: no prefetch');
    is($v->result, 'pass', '... and the chain verifies');
}

{
    my ($v, $res) = run(resolver => { timeout => 1 });
    is($v->result, 'pass', 'no answer in time: asked again the ordinary way, and verifies');
    is_deeply([sort @{ $res->calls('query') }], \@names, '... with one query per key');
}

{
    no warnings "once";
    local $Mail::DKIM2::Verifier::PREFETCH_WAIT = 0.05;
    my ($v, $res) = run(resolver => { hang => 1 });
    is($v->result, 'pass', 'an answer still not in by the deadline: asked again');
    is_deeply([sort @{ $res->calls('query') }], \@names, '... once per key');
}

{
    my ($v, $res) = run(resolver => { all_rcode => 'SERVFAIL' });
    is($v->result, 'pass', 'SERVFAIL in the background: asked again, and verifies');
    my ($v2) = run(resolver => { all_rcode => 'SERVFAIL', query_rcode => 'SERVFAIL' });
    my ($v3) = run(resolver => { timeout => 1, query_rcode => 'SERVFAIL' });
    is($v2->result_detail, $v3->result_detail, 'SERVFAIL both ways: the ordinary temperror');
    is($v2->result, 'temperror', '... which is a temperror');
}

{
    my $first = (grep { /test5/ } @names)[0];
    my ($v, $res) = run(resolver => { rcode => { $first => 'NXDOMAIN' } });
    my ($v2) = run(resolver => { timeout => 1, rcode => { $first => 'NXDOMAIN' } });
    is($v->result_detail, $v2->result_detail, 'NXDOMAIN in the background: the verdict of NXDOMAIN');
    is_deeply($res->calls('query'), [], '... without asking again');
}

done_testing;
