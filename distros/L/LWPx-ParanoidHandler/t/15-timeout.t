use strict;
use lib 'lib';
use LWPx::ParanoidHandler;
use LWP::UserAgent;
use Time::HiRes qw(time tv_interval gettimeofday);
use Test::More tests => 6;
use Test::Requires qw(LWP::Protocol::PSGI Plack::Request Test::TCP HTTP::Server::PSGI);

my $ua = LWP::UserAgent->new();
$ua->env_proxy;

my $paranoid = Net::DNS::Paranoid->new(
    whitelisted_hosts => [
        '127.0.0.1'
    ]
);
make_paranoid($ua, $paranoid);

my $psgi_app = sub {
    my $env = shift;
    my $path_info = $env->{PATH_INFO};
    note "[$path_info]";
    if ($env->{PATH_INFO} =~ m{^/(\d+)\.(\d+)$}) {
        my ($delay, $count) = ($1, $2);
        for my $i (1..$count) {
            note "[$i/$count]";
            sleep $delay;
        }
        return [200, [], []];
    } elsif ($env->{PATH_INFO} =~ m{^/redir/(\S+)$}) {
        my $dest = $1;
        return [302, [Location => $dest], []];
    } elsif ($env->{PATH_INFO} =~ m{^/redir-(\d+)/(\S+)$}) {
        my ($sleep, $dest) = ($1,$2);
        note "Sleeping $sleep seconds";
        sleep $sleep;
        return [302, [Location => $dest], []];
    } else {
        fail $env->{PATH_INFO};
        return [500, [], []];
    }
};
my $tcp = Test::TCP->new(
    code => sub {
        my $port = shift;
        my $server = HTTP::Server::PSGI->new(host => '127.0.0.1', port => $port, timeout => 20);
        $server->run($psgi_app);
    }
);

my $HELPER_SERVER = 'http://127.0.0.1:' . $tcp->port;

goto ONLY if $ENV{ONLY};

subtest "redirecting to invalid host" => sub {
    my $res = $ua->get("$HELPER_SERVER/redir/http://10.2.3.4/");
    print $res->status_line, "\n";
    ok(! $res->is_success);
};

subtest 'redirect with tarpitting' => sub {
    note "4 second redirect tarpit (tolerance 2)...";
    $ua->timeout(2);
    my $res = $ua->get("$HELPER_SERVER/redir-4/http://mixi.jp/");
    ok(! $res->is_success);
};

subtest "lots of slow redirects adding up to a lot of time" => sub {
    note "Three 1-second redirect tarpits (tolerance 2)...";
    $ua->timeout(2);
    my $t1 = [gettimeofday];
    my $res = $ua->get("$HELPER_SERVER/redir-1/$HELPER_SERVER/redir-1/$HELPER_SERVER/redir-1/http://mixi.jp/");
    cmp_ok(tv_interval($t1), '<', 2.5);
    ok(! $res->is_success);
};

subtest 'redirecting a bunch and getting the final good host' => sub {
    my $res = $ua->get("$HELPER_SERVER/redir/$HELPER_SERVER/redir/$HELPER_SERVER/redir/http://mixi.jp/");
    ok( $res->is_success );
    is( $res->code, 200);
    is( $res->request->uri->host, "mixi.jp");
};

subtest 'dying in a tarpit' => sub {
    note "5 second tarpit (tolerance 2)...";
    $ua->timeout(2);
    my $res = $ua->get("$HELPER_SERVER/1.5");
    ok(!  $res->is_success);
};

sleep 3;
ONLY:
subtest 'making it out of a tarpit.' => sub {
    note "3 second tarpit (tolerance 4)...";
    $ua->timeout(4);
    my $res = $ua->get("$HELPER_SERVER/1.3");
    ok( $res->is_success) or diag $res->as_string;
};
die if $ENV{ONLY};

