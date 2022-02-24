# Check state plugin
#
# test if portal is well loaded. If user/pasword parameters are set, it tests
# also login process

package Lemonldap::NG::Portal::Plugins::CheckState;

use strict;
use Mouse;
use Lemonldap::NG::Portal;

our $VERSION = '2.0.14';

extends 'Lemonldap::NG::Portal::Main::Plugin';

# INITIALIZATION

sub init {
    my ($self) = @_;
    unless ( $self->conf->{checkStateSecret} ) {
        $self->logger->error(
            'checkStateSecret is required for "check state" plugin');
        return 0;
    }
    $self->addUnauthRoute( checkstate => 'check', ['GET'] )
      ->addAuthRoute( checkstate => 'check', ['GET'] );

    return 1;
}

sub check {
    my ( $self, $req ) = @_;
    my @rep;
    return $self->p->sendError( $req, 'Bad secret' )
      unless ( $req->param('secret')
        and $req->param('secret') eq $self->conf->{checkStateSecret} );
    $req->steps( [ 'controlUrl', @{ $self->p->beforeAuth } ] );
    my $res = $self->p->process($req);
    if ( $res && $res > 0 ) {
        push @rep, "Bad result before auth: $res";
    }

    if ( my $user = $req->param('user') and my $pwd = $req->param('password') )
    {
        $req->parameters->{user}     = ($user);
        $req->parameters->{password} = $pwd;
        $req->data->{skipToken}      = 1;

        # This makes Auth::Choice use authChoiceAuthBasic if defined
        $req->data->{_pwdCheck} = 1;

        # Not launched methods:
        #  - "buildCookie" useless here
        $req->steps( [
                @{ $self->p->beforeAuth },
                $self->p->authProcess,
                @{ $self->p->betweenAuthAndData },
                $self->p->sessionData,
                @{ $self->p->afterData },
                'storeHistory',
                @{ $self->p->endAuth }
            ]
        );
        if ( $res = $self->p->process( $req, ) ) {
            push @rep, "Bad result during auth: $res";
        }
        $self->p->deleteSession($req);
    }

    return $self->p->sendError( $req, join( ",\n", @rep ), 500 ) if (@rep);
    return $self->p->sendJSONresponse( $req,
        { result => 1, version => $Lemonldap::NG::Portal::VERSION } );
}

1;
