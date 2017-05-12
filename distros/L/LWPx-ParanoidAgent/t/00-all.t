#!/usr/bin/perl
#

use strict;
use LWPx::ParanoidAgent;
use Time::HiRes qw(time);
use Test::More 'no_plan';
use Net::DNS;
use IO::Socket::INET;

my ($t1, $td);
my $delta = sub { printf " %.03f secs\n", $td; };

my $ua = LWPx::ParanoidAgent->new;
ok((ref $ua) =~ /LWPx::ParanoidAgent/);

my $mock_resolver = MockResolver->new;

# Record pointing to localhost:
{
    my $packet = Net::DNS::Packet->new;
    $packet->push(answer => Net::DNS::RR->new("localhost-fortest.danga.com. 86400 A 127.0.0.1"));
    $mock_resolver->set_fake_record("localhost-fortest.danga.com", $packet);
}

# CNAME to blocked destination:
{
    my $packet = Net::DNS::Packet->new;
    $packet->push(answer => Net::DNS::RR->new("bradlj-fortest.danga.com 300 IN CNAME brad.lj"));
    $mock_resolver->set_fake_record("bradlj-fortest.danga.com", $packet);
}

$ua->resolver($mock_resolver);

my ($HELPER_IP, $HELPER_PORT) = ("127.66.74.70", 9001);

unless (bind_local()) {
    diag "Can't bind to $HELPER_IP. Bailing out";
    exit;
}

my $child_pid = fork;
unless ($child_pid) {
    web_server_mode();
}
END {
    if ($child_pid) {
        print STDERR "Killing child pid: $child_pid\n";
        kill 9, $child_pid;
    }
}
select undef, undef, undef, 0.5;

my $HELPER_SERVER = "http://$HELPER_IP:$HELPER_PORT";


$ua->whitelisted_hosts(
                       $HELPER_IP,
                       );

$ua->blocked_hosts(
                   qr/\.lj$/,
                   "1.2.3.6",
                   );

my $res;

# hostnames pointing to internal IPs
$res = $ua->get("http://localhost-fortest.danga.com/");
ok(! $res->is_success);
like($res->status_line, qr/Suspicious DNS results/);
$ua->resolver(Net::DNS::Resolver->new);

# random IP address forms
$res = $ua->get("http://0x7f.1/");
ok(! $res->is_success && $res->status_line =~ /blocked/);
$res = $ua->get("http://0x7f.0xffffff/");
ok(! $res->is_success && $res->status_line =~ /blocked/);
$res = $ua->get("http://037777777777/");
ok(! $res->is_success && $res->status_line =~ /blocked/);
$res = $ua->get("http://192.052000001/");
ok(! $res->is_success && $res->status_line =~ /blocked/);
$res = $ua->get("http://0x00.00/");
ok(! $res->is_success && $res->status_line =~ /blocked/);

# test the the blocked host above in decimal form is blocked by this non-decimal form:
$res = $ua->get("http://0x01.02.0x306/");
ok(! $res->is_success && $res->status_line =~ /blocked/);

# more blocked spaces
$res = $ua->get("http://192.0.2.13/");
ok(! $res->is_success && $res->status_line =~ /blocked/);
$res = $ua->get("http://192.88.99.77/");
ok(! $res->is_success && $res->status_line =~ /blocked/);

if($ENV{ONLINE_TESTS}){
    # hostnames doing CNAMEs (this one resolves to "brad.lj", which is verboten)
    my $old_resolver = $ua->resolver;
    $ua->resolver($mock_resolver);
    $res = $ua->get("http://bradlj-fortest.danga.com/");
    ok(! $res->is_success);
    like($res->status_line, qr/DNS lookup resulted in bad host/);
    $ua->resolver($old_resolver);
    
    # black-listed via blocked_hosts
    $res = $ua->get("http://brad.lj/");
    print $res->status_line, "\n";
    ok(! $res->is_success);
    
    # can't do octal in IPs
    $res = $ua->get("http://012.1.2.1/");
    print $res->status_line, "\n";
    ok(! $res->is_success);
    
    # can't do decimal/octal IPs
    $res = $ua->get("http://167838209/");
    print $res->status_line, "\n";
    ok(! $res->is_success);
    
    # checking that port isn't affected
    $res = $ua->get("http://brad.lj:80/");
    print $res->status_line, "\n";
    ok(! $res->is_success);
    
    # this domain is okay. 
    $res = $ua->get("http://google.com");
    print $res->status_line, "\n";
    ok($res->is_success);
    
    # internal. bad.  blocked by default by module.
    $res = $ua->get("http://10.2.3.4/");
    print $res->status_line, "\n";
    ok(! $res->is_success);
    
    # okay
    $res = $ua->get("http://danga.com/temp/");
    print $res->status_line, "\n";
    ok(  $res->is_success);
    
    # localhost is blocked, case insensitive
    $res = $ua->get("http://LOCALhost/temp/");
    print $res->status_line, "\n";
    ok(! $res->is_success);
    
    # redirecting to invalid host
    $res = $ua->get("$HELPER_SERVER/redir/http://10.2.3.4/");
    print $res->status_line, "\n";
    ok(! $res->is_success);
    
    # redirecting a bunch and getting the final good host
    $res = $ua->get("$HELPER_SERVER/redir/$HELPER_SERVER/redir/$HELPER_SERVER/redir/http://www.danga.com/");
    ok( $res->is_success && $res->request->uri->host eq "www.danga.com");
}

kill 9, $child_pid;

sub bind_local {
    IO::Socket::INET->new(Listen    => 5,
                          LocalAddr => $HELPER_IP,
                          LocalPort => $HELPER_PORT,
                          ReuseAddr => 1,
                          Proto     => 'tcp')
}

sub web_server_mode {
    my $ssock = bind_local
        or die "Couldn't start webserver: $!\n";

    while (my $csock = $ssock->accept) {
        exit 0 unless $csock;
        fork and next;

        my $eat = sub {
            while (<$csock>) {
                last if ! $_ || /^\r?\n/;
            }
        };

        my $req = <$csock>;
        print STDERR "    ####### GOT REQ:  $req" if $ENV{VERBOSE};

        if ($req =~ m!^GET /(\d+)\.(\d+) HTTP/1\.\d+\r?\n?$!) {
            my ($delay, $count) = ($1, $2);
            $eat->();
            print $csock
                "HTTP/1.0 200 OK\r\nContent-Type: text/plain\r\n\r\n";
            for (1..$count) {
                print $csock "[$_/$count]\n";
                sleep $delay;
            }
            exit 0;
        }

        if ($req =~ m!^GET /redir/(\S+) HTTP/1\.\d+\r?\n?$!) {
            my $dest = $1;
            $eat->();
            print $csock
                "HTTP/1.0 302 Found\r\nLocation: $dest\r\nContent-Length: 0\r\n\r\n";
            exit 0;
        }

        if ($req =~ m!^GET /redir-(\d+)/(\S+) HTTP/1\.\d+\r?\n?$!) {
            my $sleep = $1;
            sleep $sleep;
            my $dest = $2;
            $eat->();
            print $csock
                "HTTP/1.0 302 Found\r\nLocation: $dest\r\nContent-Length: 0\r\n\r\n";
            exit 0;
        }

        print $csock
            "HTTP/1.0 500 Server Error\r\n" .
            "Content-Length: 10\r\n\r\n" .
            "bogus_req\n";
        exit 0;
    }
    exit 0;
}

package MockResolver;
use strict;
use base 'Net::DNS::Resolver';

sub new {
    my $class = shift;
    return bless {
        proxy => Net::DNS::Resolver->new,
        fake_record => {},
    }, $class;
}

sub set_fake_record {
    my ($self, $host, $packet) = @_;
    $self->{fake_record}{$host} = $packet;
}

sub _make_proxy {
    my $method = shift;
    return sub {
        my $self = shift;
        my $fr = $self->{fake_record};
        if ($method eq "bgsend" && $fr->{$_[0]}) {
            $self->{next_fake_packet} = $fr->{$_[0]};
            Test::More::diag("mock DNS resolver doing fake bgsend() of $_[0]\n")
                if $ENV{VERBOSE};
            return "MOCK";  # magic value that'll not be treated as a socket
        }
        if ($method eq "bgread" && $_[0] eq "MOCK") {
            Test::More::diag("mock DNS resolver returning mock packet for bgread.")
                if $ENV{VERBOSE};
            return $self->{next_fake_packet};
        }
        # No verbose conditional on this one because it shouldn't happen:
        Test::More::diag("Calling through to Net::DNS::Resolver proxy method '$method'");
        return $self->{proxy}->$method(@_);
    };
}

BEGIN {
    *search = _make_proxy("search");
    *query = _make_proxy("query");
    *send = _make_proxy("send");
    *bgsend = _make_proxy("bgsend");
    *bgread = _make_proxy("bgread");
}

1;
