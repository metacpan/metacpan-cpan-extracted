package HTTP::Balancer::Actor::Nginx;
use Modern::Perl;
use Moose;
extends qw(HTTP::Balancer::Actor);

use Path::Tiny;

our $NAME = "nginx";

sub start {
    my ($self, %params) = @_;
    my $tempfile = Path::Tiny->tempfile(TEMPLATE => "http-balancer-XXXX");
    $tempfile->spew($self->render(%params));
    system $self->executable . " -c " . $tempfile->stringify;
}

sub stop {
    my ($self, %params) = @_;
    my $pidfile = path($params{pidfile});
    $pidfile->exists ? $self->kill($pidfile->slurp) : say "not running";
}

1;

=pod

=head1 NAME

HTTP::Balancer::Actor::Nginx - the Nginx actor

=head1 SYNOPSIS

    my $actor = HTTP::Balancer::Actor::Nginx->new;

    $actor->start(
        pidfile => "/tmp/http-balancer.pid",
        hosts   => [
            $host1->hash,
            $host2->hash,
        ],
    );

    $actor->stop(
        pidfile => "/tmp/http-balancer.pid",
    );

=cut

__DATA__
worker_processes  1;

pid <: $pidfile :>;

events {
    worker_connections  1024;
}

http {

    access_log off;
    error_log  off;

    sendfile        on;

    keepalive_timeout  65;
    tcp_nodelay        on;

    gzip  on;
    gzip_disable "MSIE [1-6]\.(?!.*SV1)";

    : for $hosts -> $host {

    upstream <: $host.name :> {
        : for $host.backends -> $backend {
        server <: $backend :>;
        : }
    }

    server {
        listen <: $host.address :>:<: $host.port :>;
        : if $host.fullname {
        server_name <: $host.fullname :>;
        : } else {
        server_name _;
        : }

        location / {
            try_files $uri @balancer;
            expires max;
        }

        location @balancer {
            proxy_pass http://<: $host.name :>;
        }
    }

    : }

}
