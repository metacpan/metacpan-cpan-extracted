package Lemonldap::NG::Portal::Plugins::Upgrade;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_CONFIRM
  PE_OK
  PE_TOKENEXPIRED
);

our $VERSION = '2.0.3';

extends 'Lemonldap::NG::Portal::Main::Plugin';

# INITIALIZATION

has ott => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $ott =
          $_[0]->{p}->loadModule('Lemonldap::NG::Portal::Lib::OneTimeToken');
        $ott->timeout( $_[0]->{conf}->{formTimeout} );
        return $ott;
    }
);

sub init {
    my ($self) = @_;
    $self->addAuthRoute( upgradesession => 'ask',     ['GET'] );
    $self->addAuthRoute( upgradesession => 'confirm', ['POST'] );
}

# RUNNING METHOD

sub ask {
    my ( $self, $req ) = @_;

    # Check if auth is already running
    if ( $req->param('upgrading') ) {

        # verify token
        return $self->confirm($req);
    }

    # Display form
    return $self->p->sendHtml(
        $req,
        'upgradesession',
        params => {
            MSG        => 'askToUpgrade',
            CONFIRMKEY => $self->p->stamp,
            PORTAL     => $self->conf->{portal},
            URL        => $req->param('url'),
        }
    );
}

sub confirm {
    my ( $self, $req ) = @_;

    # Disabled due to #1821
    #$req->pdata->{keepPdata} = 1;
    my $upg;
    if ( my $t = $req->param('upgrading') ) {
        if ( $self->ott->getToken($t) ) {
            $upg = 1;
        }
        else {
            return $self->p->do( $req, [ sub { PE_TOKENEXPIRED } ] );
        }
    }
    $req->steps( ['controlUrl'] );
    my $res = $self->p->process($req);
    return $self->p->do( $req, [ sub { $res } ] ) if ($res);
    if ( $upg or $req->param('confirm') == 1 ) {
        $req->data->{noerror} = 1;
        $self->p->setHiddenFormValue(
            $req,
            upgrading => $self->ott->createToken,
            '', 0
        );    # Insert token
        return $self->p->login($req);
    }
    else {
        # Go to portal
    }
}

1;
