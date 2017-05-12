use strict;
use warnings;
no warnings "void";

package LWP::UserAgent::Paranoid::Test;

use Test::More;
use Test::Requires qw(
    Test::TCP
    HTTP::Server::PSGI
);
use LWP::UserAgent::Paranoid;

use base 'Exporter';
our @EXPORT = qw/ server create_ua_ok get_status_is /;

sub server {
    my $app  = shift;
    my $host = "127.0.0.1";
    my $tcp  = Test::TCP->new(
        code => sub {
            my $port = shift;
            my $server = HTTP::Server::PSGI->new(
                host    => $host,
                port    => $port,
                timeout => 20,
            );
            $server->run($app);
        }
    );
    return ("http://$host:" . $tcp->port, $tcp);
}

sub create_ua_ok {
    my $ua = LWP::UserAgent::Paranoid->new;
    ok      $ua, "Created agent object";
    isa_ok  $ua, "LWP::UserAgent::Paranoid";
    return $ua;
}

sub get_status_is {
    my ($ua, $url, $status, $desc) = @_;
    $desc ||= "GET $url";

    subtest $desc => sub {
        my $r = $ua->get($url);
        ok      $r, "Received a response";
        isa_ok  $r, "HTTP::Response";
        is      $r->code, $status, "Status is $status"
            or diag $r->status_line;
    };
}

"I want to believe.";
