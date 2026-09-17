package InternetDataTest::Origin;

use strict;
use warnings;

use Mojo::IOLoop;
use Mojo::Server::Daemon;
use Mojolicious;

# A real HTTP origin on an ephemeral port, sharing the singleton event loop with
# the client under test.
#
# A stub user agent would be cheaper and would prove less: it cannot show that a
# redirect was NOT followed, that a refusal was asked for exactly once, or that
# the request reaching object storage carried no credential.
sub new {
    my ($class, $handler) = @_;

    my $self = bless { handler => $handler, requests => [] }, $class;

    my $app = Mojolicious->new;
    $app->log->level('fatal');
    # NOT `/*path`: a route placeholder named `path` collides with a reserved
    # stash value and the application dies at startup.
    $app->routes->any('/*rest' => sub {
        my $c = shift;
        push @{ $self->{requests} }, {
            path => $c->req->url->path->to_string,
            query => $c->req->url->query->to_hash,
            headers => $c->req->headers->to_hash,
        };
        $self->{handler}->($c, $self);
    });

    $self->{daemon} = Mojo::Server::Daemon->new(
        app => $app, listen => ['http://127.0.0.1'], silent => 1,
    )->start;
    $self->{port} = $self->{daemon}->ports->[0];
    return $self;
}

sub url {
    return "http://127.0.0.1:$_[0]{port}";
}

sub requests {
    return @{ $_[0]{requests} };
}

sub count {
    return scalar @{ $_[0]{requests} };
}

sub paths {
    return map { $_->{path} } @{ $_[0]{requests} };
}

sub reset {
    my ($self) = @_;
    @{ $self->{requests} } = ();
    return $self;
}

# Sends the headers and the start of a body, then nothing, for longer than any
# bound in the suite: a deadline that stopped the clock at the headers would
# never fire here.
sub stall_body {
    my ($c) = @_;
    $c->res->headers->content_type('application/json');
    $c->res->headers->content_length(1024);
    $c->write('{"ip":');
}

# The same, except a byte keeps arriving every 20 ms, for 4 s in all, so no
# single read ever waits long: only a bound on the whole response ends the call.
sub trickle_body {
    my ($c) = @_;
    $c->res->headers->content_type('application/json');
    $c->res->headers->content_length(200);
    my $sent = 0;
    my $timer = Mojo::IOLoop->recurring(0.02 => sub {
        return if ++$sent > 199;
        $c->write(' ') if $c->tx;
    });
    $c->on(finish => sub { Mojo::IOLoop->remove($timer) });
    $c->write('{');
}

1;
