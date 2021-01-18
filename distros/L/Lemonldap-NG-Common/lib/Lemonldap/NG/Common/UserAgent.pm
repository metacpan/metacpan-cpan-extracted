package Lemonldap::NG::Common::UserAgent;

use strict;
use LWP::UserAgent;

our $VERSION = '2.0.10';

sub new {
    my ( $class, $conf ) = @_;
    my $opts = $conf->{lwpOpts} || {};
    $opts->{ssl_opts} = $conf->{lwpSslOpts} if ( $conf->{lwpSslOpts} );
    my $ua = LWP::UserAgent->new(%$opts);
    push @{ $ua->requests_redirectable }, 'POST';
    return $ua;
}

1;
