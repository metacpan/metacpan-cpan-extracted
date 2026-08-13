#!perl
use 5.008003;
use strict;
use warnings;
use IO::Socket::INET;
use Test::More;
use File::Spec ();
use Fetch;

# JSON helpers: the `json =>` request option encodes the body and sets
# Content-Type, and $res->json decodes the response, both via File::Raw::JSON's
# C ABI. Booleans decode to File::Raw::JSON::Boolean, null to undef.

plan skip_all => 'no JSON module (Cpanel::JSON::XS or JSON::PP)'
    unless eval { require Cpanel::JSON::XS; 1 } or eval { require JSON::PP; 1 };

my $srv = IO::Socket::INET->new(
    LocalHost => '127.0.0.1', LocalPort => 0, Listen => 16, ReuseAddr => 1,
) or plan skip_all => "cannot listen: $!";
my $port = $srv->sockport;
my $base = "http://127.0.0.1:$port";

my $pid = fork;
plan skip_all => "cannot fork: $!" unless defined $pid;
if (!$pid) {
    # Never hold the harness TAP pipe open, and never outlive the run:
    # a leaked server child hangs the whole suite after this test is done.
    open STDOUT, ">", File::Spec->devnull();
    open STDERR, ">", File::Spec->devnull();
    alarm 120;
    $SIG{TERM} = sub { exit 0 };
    $SIG{CHLD} = 'IGNORE';
    while (my $c = $srv->accept) {
        my $kid = fork;
        if (defined $kid && $kid == 0) {
            $c->autoflush(1);
            while (my $line = <$c>) {
                my ($ct, $cl) = ('', 0);
                while (my $h = <$c>) {
                    $ct = $1 if $h =~ /^Content-Type:\s*(.*?)\r/i;
                    $cl = $1 if $h =~ /^Content-Length:\s*(\d+)/i;
                    last if $h eq "\r\n";
                }
                my $body = '';
                read($c, $body, $cl) if $cl;
                $body = 'null' unless length $body;
                # echo the received JSON back, plus a bool, false and null, and
                # the Content-Type we saw
                my $out = qq[{"echo":$body,"yes":true,"no":false,"nil":null,"ct":"$ct"}];
                print $c "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n"
                       . "Content-Length: " . length($out) . "\r\n"
                       . "Connection: close\r\n\r\n$out";
                close $c;
                last;
            }
            exit 0;
        }
        close $c;
    }
    exit 0;
}
select(undef, undef, undef, 0.3);

plan tests => 8;

my $ua = Fetch->new;

my $res = $ua->post("$base/x",
    json => { name => 'x', nums => [ 1, 2, 3 ], on => \1 })->get;

is($res->status, 200, 'request sent');
my $d = $res->json;
is(ref $d, 'HASH', '$res->json decodes to a structure');

# the server tells us what Content-Type it received
is($d->{ct}, 'application/json', 'json => set Content-Type: application/json');

# our payload round-tripped through the server's echo
is($d->{echo}{name}, 'x', 'nested string round-tripped');
is_deeply($d->{echo}{nums}, [ 1, 2, 3 ], 'nested array round-tripped');
ok($d->{echo}{on}, 'boolean true round-tripped as a true value');

# booleans/null decode via File::Raw::JSON
isa_ok($d->{yes}, 'File::Raw::JSON::Boolean', 'true decodes to a File::Raw::JSON::Boolean');
ok(!defined $d->{nil}, 'null decodes to undef');

END { local $?; if ($pid) { kill 'KILL', $pid; waitpid $pid, 0 } }
