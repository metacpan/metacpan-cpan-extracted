use strict;
use warnings FATAL => 'all';
use Test::More;

use Config;
use FindBin;
use lib "$FindBin::Bin/lib";

use HTTP::Daemon ();
use LWP::Protocol::GHTTP;
use LWP::UserAgent;

delete $ENV{PERL_LWP_ENV_PROXY};
$| = 1; # autoflush

my $DAEMON;
my $base;

my $D = shift(@ARGV) || '';
if ($D eq 'daemon') {
    daemonize();
}
else {
    # start the daemon and the testing
    if ( $^O ne 'MacOS' ) {
        my $perl = $Config{'perlpath'};
        $perl = $^X if $^O eq 'VMS' or -x $^X and $^X =~ m,^([a-z]:)?/,i;
        open($DAEMON, "$perl $0 daemon |") or die "Can't exec daemon: $!";
        my $greeting = <$DAEMON> || '';
        if ( $greeting =~ /(<[^>]+>)/ ) {
            $base = URI->new($1);
        }
    }
    _test();
}
exit(0);

sub _test {
    # First we make ourself a daemon in another process
    # listen to our daemon
    return plan skip_all => "Can't test on this platform" if $^O eq 'MacOS';
    return plan skip_all => 'We could not talk to our daemon' unless $DAEMON;
    return plan skip_all => 'No base URI' unless $base;

    plan tests => 26;
    isa_ok($base, 'URI', "Base URL is good.");
    can_ok('LWP::Protocol::GHTTP', qw(request));
    LWP::Protocol::implementor('http', 'LWP::Protocol::GHTTP');
    is(LWP::Protocol::implementor('http'), 'LWP::Protocol::GHTTP', 'use of GHTTP verified');

    my $ua = LWP::UserAgent->new();
    isa_ok($ua, 'LWP::UserAgent', 'New UserAgent instance');
    $ua->agent("Mozilla/0.01 " . $ua->agent);
    $ua->from('gisle@aas.no');

    { # head
        my $req = HTTP::Request->new(HEAD => url("/test", $base));
        isa_ok($req, 'HTTP::Request', 'head: new HTTP::Request instance');
        my $res = $ua->request($req);
        isa_ok($res, 'HTTP::Response', 'head: good response object');
        is($res->code, 200, 'head: code is 200');
    }
    { # get
        my $req = HTTP::Request->new(GET => url("/test", $base));
        isa_ok($req, 'HTTP::Request', 'get: new HTTP::Request instance');
        my $res = $ua->request($req);
        isa_ok($res, 'HTTP::Response', 'get: good response object');
        is($res->code, 200, 'get: code is 200');
    }
    { # post
        my $req = HTTP::Request->new(POST => url("/test", $base));
        isa_ok($req, 'HTTP::Request', 'post: new HTTP::Request instance');
        $req->content_type("application/x-www-form-urlencoded");
        $req->content("foo=bar&bar=test");
        my $res = $ua->request($req);
        isa_ok($res, 'HTTP::Response', 'post: good response object');

        my $content = $res->content;
        ok($res->is_success, 'post: is_success');
        like($content, qr/^Content-Length:\s*16$/mi, 'post: content length good');
        like($content, qr/^Content-Type:\s*application\/x-www-form-urlencoded$/mi, 'post: application/x-www-form-urlencoded');
        like($content, qr/^foo=bar&bar=test$/m, 'post: foo=bar&bar=test');
    }
    { # 404
        my $req = HTTP::Request->new(HEAD => url("/testing", $base));
        isa_ok($req, 'HTTP::Request', 'head 404: new HTTP::Request instance');
        my $res = $ua->request($req);
        isa_ok($res, 'HTTP::Response', 'head 404: good response object');
        is($res->code, 404, 'head 404: code is 404');
    }
    { # bad verb
        my $req = HTTP::Request->new(PUT => url("/testing", $base));
        isa_ok($req, 'HTTP::Request', 'put: new HTTP::Request instance');
        my $res = $ua->request($req);
        isa_ok($res, 'HTTP::Response', 'put: good response object');
        is($res->code, 400, 'put: code is 400');
    }
    { # terminate server
        my $req = HTTP::Request->new(GET => url("/quit", $base));
        isa_ok($req, 'HTTP::Request', 'terminate: new HTTP::Request instance');
        my $res = $ua->request($req);
        isa_ok($res, 'HTTP::Response', 'terminate: good response object');

        is($res->code, 503, 'terminate: code is 503');
        like($res->content, qr/Bye, bye/, 'terminate: bye bye');
    }
}
sub daemonize {
    my %router = (
        head_test => sub {
            my ($c) = @_;
            $c->send_response(HTTP::Response->new(200));
        },
        get_test => sub {
            my ($c) = @_;
            $c->send_response(HTTP::Response->new(200));
        },
        post_test => sub {
            my($c,$r) = @_;
            my $res = HTTP::Response->new(200);
            $res->header('Content-Type'=>'text/plain');
            $res->content($r->as_string);
            $c->send_response($res);
        },
        get_quit => sub {
            my ($c) = @_;
            $c->send_error(503, "Bye, bye");
            exit;  # terminate HTTP server
        },
    );
    my $d = HTTP::Daemon->new(Timeout => 10, LocalAddr => '127.0.0.1') || die $!;
    print "Pleased to meet you at: <URL:", $d->url, ">\n";
    open(STDOUT, $^O eq 'VMS'? ">nl: " : ">/dev/null");

    while (my $c = $d->accept) {
        while (my $r = $c->get_request) {
            my $p = ($r->uri->path_segments)[1];
            my $func = lc($r->method . "_$p");
            if ( $router{$func} ) {
                $router{$func}->($c, $r);
            }
            else {
                $c->send_error(404);
            }
        }
        $c->close;
        undef($c);
    }
    print STDERR "HTTP Server terminated\n";
    exit;
}
sub url {
    my $u = URI->new(@_);
    $u = $u->abs($_[1]) if @_ > 1;
    $u->as_string;
}
