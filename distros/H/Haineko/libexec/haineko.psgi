#!/usr/bin/env perl
use strict;
use warnings;
use v5.10;

BEGIN { 
    use FindBin;
    unshift @INC, "$FindBin::Bin/../lib";
    my $v = qx(hostname); chomp $v;
    $ENV{'HOSTNAME'} //= $v;
}

use Haineko;
use Plack::Builder;

my $plackorder = [ 'Auth::Basic' ];
my $plackconds = {
    'Auth::Basic' => sub {
        return 0 unless $ENV{'HAINEKO_AUTH'};
        require Haineko::HTTPD::Auth;
        require Haineko::SMTPD::Response;
        require Haineko::JSON;
        $Haineko::HTTPD::Auth::PasswordDB = Haineko::JSON->loadfile( $ENV{'HAINEKO_AUTH'} );
    },
};

my $plackargvs = {
    'Auth::Basic' => {
        'authenticator' => sub {
            my $u = shift;
            my $p = shift;
            my $v = { 'username' => $u, 'password' => $p };
            return Haineko::HTTPD::Auth->basic( %$v );
        },
    },
};

my $hainekoapp = builder {
    while( my $e = shift @$plackorder ) {
        my $r = $plackconds->{ $e }->();
        next unless $r;
        if( exists $plackargvs->{ $e } ) {
            # Enable Plack-Middleware with arguments
            if( ref $plackargvs->{ $e } eq 'HASH' ) {
                enable $e, %{ $plackargvs->{ $e } };
            } else {
                enable $e, $plackargvs->{ $e };
            }
        } else {
            # Enable Plack-Middleware
            enable $e;
        }
    };
    Haineko->start;
};

{
    # Override unauthorized() method of Plack::Middleware::Auth::Basic
    # for responding error message as a JSON
    no warnings 'redefine';
    *Plack::Middleware::Auth::Basic::unauthorized = sub {
        my $self = shift;
        my $mesg = Haineko::SMTPD::Response->r( 'auth', 'auth-required' );
        my $json = Haineko::JSON->dumpjson( $mesg );
        my $head = [ 
            'Content-Type' => 'application/json',
            'Content-Length' => length $json,
            'WWW-Authenticate' => sprintf( "Basic realm='%s'", ( $self->realm || 'Restricted Area' ) ),
        ];
        return [ 401, $head, [ $json ] ];
    };
}

return $hainekoapp;
__END__
