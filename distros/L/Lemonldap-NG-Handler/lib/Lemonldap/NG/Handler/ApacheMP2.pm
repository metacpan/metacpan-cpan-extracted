# LLNG platform class for Apache-2/ModPerl-2
#
# See http://lemonldap-ng.org/documentation/latest/handlerarch
package Lemonldap::NG::Handler::ApacheMP2;

use strict;
use Lemonldap::NG::Handler::ApacheMP2::Request;

use Lemonldap::NG::Handler::ApacheMP2::Main;

our $VERSION = '2.0.0';

# PUBLIC METHODS

sub handler {
    shift if ($#_);
    return launch( 'run', @_ );
}

sub logout {
    shift if ($#_);
    return launch( 'unlog', @_ );
}

sub reload {
    shift if ($#_);
    return launch( 'reload', @_ );
}

sub status {
    shift if ($#_);
    return launch( 'getStatus', @_ );
}

# Internal method to get class to load
sub launch {
    my ( $sub, $r ) = @_;
    my $req  = Lemonldap::NG::Handler::ApacheMP2::Request->new($r);
    my $type = Lemonldap::NG::Handler::ApacheMP2::Main->checkType($req);
    if ( my $t = $r->dir_config('VHOSTTYPE') ) {
        $type = $t;
    }
    my $class = "Lemonldap::NG::Handler::ApacheMP2::$type";
    eval "require $class";
    die $@ if ($@);
    my ($res) = $class->$sub($req);
    return $res;
}

1;
