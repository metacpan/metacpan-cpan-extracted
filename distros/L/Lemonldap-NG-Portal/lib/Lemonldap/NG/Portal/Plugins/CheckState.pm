# Check state plugin
#
# test if portal is well loaded. If user/pasword parameters are set, it tests
# also login process

package Lemonldap::NG::Portal::Plugins::CheckState;

use strict;
use Mouse;

our $VERSION = '2.0.0';

extends 'Lemonldap::NG::Portal::Main::Plugin';

# INITIALIZATION

sub init {
    my ($self) = @_;
    unless ( $self->conf->{checkStateSecret} ) {
        $self->logger->error(
            'checkStateSecret is required for "check state" plugin');
        return 0;
    }
    $self->addUnauthRoute( checkstate => 'check', ['GET'] );
    $self->addAuthRoute( checkstate => 'check', ['GET'] );
    return 1;
}

sub check {
    my ( $self, $req ) = @_;
    my @rep;
    unless ($req->param('secret')
        and $req->param('secret') eq $self->conf->{checkStateSecret} )
    {
        return $self->p->sendError( $req, 'Bad secret' );
    }
    $req->steps( [ 'controlUrl', @{ $self->p->beforeAuth } ] );
    my $res = $self->p->process($req);
    if ( $res > 0 ) {
        push @rep, "Bad result before auth: $res";
    }
    if ( my $user = $req->param('user') and my $pwd = $req->param('password') )
    {
        $req->user($user);
        $req->data->{password} = $pwd;

        # Not launched methods:
        #  - "extractFormInfo" due to "token"
        #  - "buildCookie" useless here
        $req->steps(
            [
                'getUser',
                'authenticate',
                @{ $self->p->betweenAuthAndData },
                qw( setAuthSessionInfo setSessionInfo setMacros setGroups
                  setPersistentSessionInfo setLocalGroups store secondFactor),
                @{ $self->p->afterData }, 'storeHistory',
                @{ $self->p->endAuth }
            ]
        );
        if ( $res = $self->p->process( $req, ) ) {
            push @rep, "Bad result during auth: $res";
        }
        $self->p->deleteSession($req);
    }
    if (@rep) {
        return $self->p->sendError( $req, join( ",\n", @rep ), 500 );
    }
    else {
        return $self->p->sendJSONresponse( $req, { result => 1 } );
    }
}

1;
