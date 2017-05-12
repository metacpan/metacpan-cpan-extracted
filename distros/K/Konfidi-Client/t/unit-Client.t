#!perl -T

use strict;
use warnings;

use Test::More tests => 16;
use Test::Exception;

use Error qw(:try);
use HTTP::Daemon;
use HTTP::Status;

BEGIN {
    use_ok('Konfidi::Client');
    use_ok('Konfidi::Client::Error');
}

#=head1 Basic tests
#
#=cut

my $k = Konfidi::Client->new();
isa_ok($k, "Konfidi::Client", 'constructor from class');

my $kk = $k->new();
isa_ok($kk, "Konfidi::Client", 'constructor from instance');
isnt($k, $kk, 'different instances');

# see http://perldoc.perl.org/perltoot.html#Inheritance
dies_ok {
    Konfidi::Client::new();
} 'invoke new method as a function';

is($k->server, undef, 'server default');

$k->server("http://foo/bar");
is($k->server, "http://foo/bar", 'server get/set');

$k->server("http://foo/bar/");
is($k->server, "http://foo/bar", 'server get/set strip /');

$k->strategy("myStrategy");
is($k->strategy, "myStrategy", 'strategy get/set');

$k->server(undef);
throws_ok {
    $k->query(123,456,'http://www.konfidi.org/ns/topics/0.0#internet-communication');
} 'Konfidi::Client::Error', 'undef server string';


#=head1 Tests using a mock server
#
#=cut


#=head2
#From http://perldoc.perl.org/perlipc.html#Internet-TCP-Clients-and-Servers
#=cut
sub spawn {
    my $coderef = shift;

    unless (@_ == 0 && $coderef && ref($coderef) eq 'CODE') {
        die "usage: spawn CODEREF";
    }

    my $pid;
    if (!defined($pid = fork)) {
        die "cannot fork: $!";
    } elsif ($pid) {
        # I'm the parent
        return $pid;
    }
    # else I'm the child -- go spawn

    #open(STDIN,  "<&Client")   || die "can't dup client to stdin";
    #open(STDOUT, ">&Client")   || die "can't dup client to stdout";
    ## open(STDERR, ">&STDOUT") || die "can't dup stdout to stderr";
    exit &$coderef();
}

sub close_daemon {
    kill("TERM", shift);
}

sub setup_daemon {
    my $server_code = shift;
    my $d = HTTP::Daemon->new || die;
    diag $d->url;
    $k->server($d->url);
    my $d_pid = spawn sub {
        while (my $c = $d->accept) {
            while (my $r = $c->get_request) {
                &$server_code($c, $r);
            }
            $c->close;
            undef($c);
        }
    };
}

my $ref;


$ref = setup_daemon sub {
    my $c = shift;
    my $r = shift;
    diag $r->url;
    $c->send_error(RC_FORBIDDEN);
};
throws_ok {
    $k->query(123,456,'http://www.konfidi.org/ns/topics/0.0#internet-communication');
} 'Konfidi::Client::Error', 'invalid server';
close_daemon($ref);


$ref = setup_daemon sub {
    my $c = shift;
    my $r = shift;
    diag $r->url;
    $c->send_response(HTTP::Response->new(200, undef, HTTP::Headers->new('Content-Type' => 'text/html'), "<html>blarg</html>"));
};
throws_ok {
    $k->query(123,456,'http://www.konfidi.org/ns/topics/0.0#internet-communication');
} 'Konfidi::Client::Error', 'invalid response type';
close_daemon($ref);


$ref = setup_daemon sub {
    my $c = shift;
    my $r = shift;
    diag $r->url;
    $c->send_response(HTTP::Response->new(200, undef, HTTP::Headers->new('Content-Type' => 'text/plain'), "Error: oops"));
};
throws_ok {
    $k->query(123,456,'http://www.konfidi.org/ns/topics/0.0#internet-communication');
} 'Konfidi::Client::Error', 'trustserver error';
close_daemon($ref);

$ref = setup_daemon sub {
    my $c = shift;
    my $r = shift;
    diag $r->url;
    $c->send_response(HTTP::Response->new(200, undef, HTTP::Headers->new('Content-Type' => 'text/plain'), "Foo: 12\nRating: 0.23\nBar: baz"));
};
lives_and {
    ok($k->query(123,456,'http://www.konfidi.org/ns/topics/0.0#internet-communication') == 0.23);
    ok($k->query(123,456,'http://www.konfidi.org/ns/topics/0.0#internet-communication')->{'Rating'} == 0.23);
} 'successful query';
close_daemon($ref);

