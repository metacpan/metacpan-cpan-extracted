use strict;
use warnings;
use Test::More;
use IO::Socket::INET ();
use EV;
use EV::cares qw(:all);

my $server = IO::Socket::INET->new(
    LocalAddr => '127.0.0.1', LocalPort => 0, Proto => 'udp',
) or plan skip_all => "cannot bind local DNS socket: $!";

sub wire_name { join('', map { pack('C', length $_) . $_ } split /\./, $_[0]) . "\0" }

my $reply;
my $watcher = EV::io $server->fileno, EV::READ, sub {
    my $peer = recv($server, my $query, 65535, 0);
    return unless defined $peer;
    my $end = 12;
    $end += 1 + ord(substr($query, $end, 1)) while ord(substr($query, $end, 1));
    $end += 5;
    my $type = unpack('n', substr($query, $end - 4, 2));
    my @rr = $reply->($type);
    my $response = pack('nnnnnn', unpack('n', $query), 0x8180, 1, scalar @rr, 0, 0)
        . substr($query, 12, $end - 12);
    for my $rr (@rr) {
        my ($rtype, $rdata, $owner) = @$rr;
        $response .= (defined $owner ? wire_name($owner) : "\xc0\x0c")
            . pack('nnNn', $rtype, C_IN, 120, length $rdata) . $rdata;
    }
    send($server, $response, 0, $peer) == length($response) or die "send: $!";
};

sub resolver {
    EV::cares->new(servers => '127.0.0.1:' . $server->sockport,
                  timeout => 0.2, tries => 1, qcache => 0, @_);
}

sub search_records {
    my ($r, $type) = @_;
    my @got;
    $r->search('wire.test.', $type, sub { @got = @_ });
    ok($r->wait_idle(2), "type $type drained");
    is(shift @got, ARES_SUCCESS, "type $type succeeded");
    return @got;
}

{
    my $old_server = IO::Socket::INET->new(
        LocalAddr => '127.0.0.1', LocalPort => 0, Proto => 'udp',
    ) or die "old server socket: $!";
    my $r = resolver(servers => '127.0.0.1:' . $old_server->sockport,
                     udp_max_queries => 1, tries => 2);
    my @got;
    $reply = sub { [T_A, pack('C4', 192, 0, 2, 1)] };
    $r->query("move$_.test.", C_IN, T_A, sub { push @got, $_[0] }) for 1 .. 32;
    $r->set_servers('127.0.0.1:' . $server->sockport);
    ok($r->wait_idle(2), 'server update drains in-flight queries');
    is(scalar @got, 32, 'server update delivers every callback once');
    is(scalar(grep { $_ == ARES_SUCCESS } @got), 32, 'queries move to the new server');

    $r = resolver(servers => '127.0.0.1:' . $old_server->sockport,
                  udp_max_queries => 1);
    my (@ended, $destroyed);
    for (1 .. 32) {
        $r->query("expire$_.test.", C_IN, T_A, sub {
            push @ended, $_[0];
            unless ($destroyed++) { $r->destroy }
        });
    }
    $r->set_servers('127.0.0.1:' . $server->sockport);
    my $expired;
    my $guard = EV::timer 2, 0, sub { $expired = 1 };
    EV::run(EV::RUN_ONCE) until @ended == 32 || $expired;
    is(scalar @ended, 32, 'destroy during server update delivers every callback once');
    ok($r->is_destroyed, 'destroy during server update safely releases the channel');
}

for my $mode (qw(cancel destroy drop)) {
    my $r = resolver(udp_max_queries => 1);
    my (@got, $acted);
    $reply = sub { [T_A, pack('C4', 192, 0, 2, 1)] };
    for my $i (0 .. 47) {
        $r->query("teardown$i.test.", C_IN, T_A, sub {
            push @got, $_[0];
            if ($i == 16) {
                $acted = 1;
                if ($mode eq 'drop') { undef $r }
                else { $r->$mode() }
            }
        });
    }
    my $expired;
    my $guard = EV::timer 3, 0, sub { $expired = 1 };
    EV::run(EV::RUN_ONCE) until @got == 48 || $expired;
    ok($acted, "$mode ran from an overflow socket callback");
    is(scalar @got, 48, "$mode delivers every callback");
    my $status = $mode eq 'cancel' ? ARES_ECANCELLED : ARES_EDESTRUCTION;
    ok(grep({ $_ == $status } @got), "$mode tears down pending overflow sockets");
}

{
    my $r = resolver(udp_max_queries => 1);
    $reply = sub { [T_A, pack('C4', 192, 0, 2, 1)] };
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    for my $round (1 .. 2) {
        my @got;
        for my $i (0 .. 47) {
            $r->query("burst$i.test.", C_IN, T_A, sub { $got[$i] = $_[0] });
        }
        ok($r->wait_idle(3), "socket burst $round drained");
        is(scalar(grep { defined $_ && $_ == ARES_SUCCESS } @got), 48,
           "socket burst $round delivered every reply");
        is($r->active_queries, 0, 'burst leaves no pending callbacks');
    }
    is_deeply(\@warnings, [], 'socket bursts need no overflow warnings');
}

{
    my $r = resolver;
    $reply = sub { [T_TXT, "\3one\3two"], [T_TXT, "\5three"] };
    is_deeply([search_records($r, T_TXT)], ['onetwo', 'three'],
              'TXT segments join within each record');
    $reply = sub { [T_MX, pack('n', 10) . wire_name('mail.test')] };
    is_deeply([search_records($r, T_MX)], [{ priority => 10, host => 'mail.test' }],
              'MX data parsed locally');
}

for my $reordered (0, 1) {
    my $r = resolver;
    $reply = sub {
        my @cnames = (
            [T_CNAME, wire_name('MiDdLe.test')],
            [T_CNAME, wire_name('final.test'), 'middle.test'],
        );
        @cnames = reverse @cnames if $reordered;
        return (@cnames, [T_A, pack('C4', 192, 0, 2, 2), 'final.test']);
    };
    my @got;
    $r->getaddrinfo('wire.test.', undef, { family => AF_INET, flags => ARES_AI_CANONNAME | ARES_AI_NOSORT, ttl => 1 },
                   sub { @got = @_ });
    ok($r->wait_idle(2), 'CNAME chain drained');
    is(shift @got, ARES_SUCCESS, 'CNAME chain succeeded');
    is($got[0]{addr}, '192.0.2.2', 'CNAME chain address');
    is($got[0]{canonname}, 'final.test', 'CNAME chain returns final canonical name');
}

{
    my %data = (
        T_DS() => [pack('nCC', 123, 8, 2) . "\x01\x02", {
            key_tag => 123, algorithm => 8, digest_type => 2, digest => "\x01\x02",
        }],
        T_DNSKEY() => [pack('nCC', 257, 3, 8) . "\x03\x04", {
            flags => 257, protocol => 3, algorithm => 8, public_key => "\x03\x04",
        }],
        T_RRSIG() => [pack('nCCNNNn', T_A, 8, 2, 120, 2000000000, 1900000000, 123)
                     . wire_name('signer.test') . "\x05\x06", {
            type_covered => T_A, algorithm => 8, labels => 2, original_ttl => 120,
            sig_expiration => 2000000000, sig_inception => 1900000000, key_tag => 123,
            signer_name => 'signer.test', signature => "\x05\x06",
        }],
    );
    $reply = sub { my ($type) = @_; [$type, $data{$type}[0]] };
    for my $type (T_DS, T_DNSKEY, T_RRSIG) {
        my $r = resolver(qcache => 300);
        is_deeply([search_records($r, $type)], [$data{$type}[1]], "DNSSEC type $type fields");
        my @got;
        $r->search('wire.test.', $type, sub { @got = @_ });
        $r->wait_idle(2);
        is_deeply(\@got, [ARES_SUCCESS, $data{$type}[1]], "DNSSEC type $type cached fields");
    }
    my $uncached = resolver();
    for my $type (T_DS, T_DNSKEY, T_RRSIG) {
        is_deeply([search_records($uncached, $type)], [$data{$type}[1]],
                  "mixed DNSSEC type $type works with qcache disabled");
    }
    $reply = sub {
        [T_RRSIG, pack('nCCNNNn', T_A, 8, 0, 120, 2000000000, 1900000000, 123)
                  . "\0signature"];
    };
    my ($root) = search_records(resolver(), T_RRSIG);
    is($root->{signer_name}, '', 'root signer name is empty');
    is($root->{signature}, 'signature', 'root signature bytes preserved');
}

done_testing;
