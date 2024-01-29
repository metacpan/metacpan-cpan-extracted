package Lemonldap::NG::Common::UserAgent;

use strict;
use LWP::UserAgent;
use Lemonldap::NG::Common;

our $VERSION = '2.18.0';

sub new {
    my ( $class, $conf ) = @_;
    my $opts  = $conf->{lwpOpts} || {};
    my $agent = "LemonLDAP-NG/" . $Lemonldap::NG::Common::VERSION . " ";
    $opts->{agent} ||= $agent;
    $opts->{ssl_opts} = $conf->{lwpSslOpts} if ( $conf->{lwpSslOpts} );
    my $ua = LWP::UserAgent->new(%$opts);
    push @{ $ua->requests_redirectable }, 'POST';
    return $ua;
}

1;
