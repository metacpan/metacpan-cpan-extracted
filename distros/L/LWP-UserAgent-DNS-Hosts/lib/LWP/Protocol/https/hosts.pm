package LWP::Protocol::https::hosts;

use strict;
use warnings;
use parent 'LWP::Protocol::https';
use LWP::UserAgent::DNS::Hosts;

sub _extra_sock_opts {
    my ($self, $host, $port) = @_;

    my @opts = $self->SUPER::_extra_sock_opts($host, $port);
    if (my $peer_addr = LWP::UserAgent::DNS::Hosts->_registered_peer_addr($host)) {
        push @opts, (
            PeerAddr          => $peer_addr,
            Host              => $host,
            SSL_verifycn_name => $host,
            SSL_hostname      => $host, # for SNI
        );
    }

    return @opts;
}

sub socket_class { 'LWP::Protocol::https::Socket' }

1;

__END__
