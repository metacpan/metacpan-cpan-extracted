package Lemonldap::NG::Portal::Plugins::SingleSession;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(PE_OK);

our $VERSION = '2.0.0';

extends 'Lemonldap::NG::Portal::Main::Plugin',
  'Lemonldap::NG::Portal::Lib::OtherSessions';

use constant endAuth => 'run';

sub init { 1 }

sub run {
    my ( $self, $req ) = @_;
    my $deleted       = [];
    my $otherSessions = [];

    my $moduleOptions = $self->conf->{globalStorageOptions} || {};
    $moduleOptions->{backend} = $self->conf->{globalStorage};

    my $sessions = $self->module->searchOn(
        $moduleOptions,
        $self->conf->{whatToTrace},
        $req->{sessionInfo}->{ $self->conf->{whatToTrace} }
    );
    foreach my $id ( keys %$sessions ) {
        next if ( $req->id eq $id );
        my $session = $self->p->getApacheSession($id) or next;
        if (
            $self->conf->{singleSession}
            or (    $self->conf->{singleIP}
                and $req->{sessionInfo}->{ipAddr} ne $session->data->{ipAddr} )
          )
        {
            push @$deleted, $self->p->_sumUpSession( $session->data );
            $self->p->_deleteSession( $req, $session, 1 );
        }
        else {
            push @$otherSessions, $self->p->_sumUpSession( $session->data );
        }
    }
    if ( $self->conf->{singleUserByIP} ) {
        my $sessions =
          $self->module->searchOn( $moduleOptions, 'ipAddr',
            $req->sessionInfo->ipAddr );
        foreach my $id ( keys %$sessions ) {
            next if ( $req->id eq $id );
            my $session = $self->p->getApacheSession($id) or next;
            unless ( $req->{sessionInfo}->{ $self->conf->{whatToTrace} } eq
                $session->data->{ $self->conf->{whatToTrace} } )
            {
                push @$deleted, $self->p->_sumUpSession( $session->data );
                $self->p->_deleteSession( $req, $session, 1 );
            }
        }
    }
    $req->info( $self->p->mkSessionArray( $deleted, 'sessionsDeleted', 1 ) )
      if ( $self->conf->{notifyDeleted} and @$deleted );
    $req->info( $self->p->mkSessionArray( $otherSessions, 'otherSessions', 1 )
          . $self->_mkRemoveOtherLink() )
      if ( $self->conf->{notifyOther} and @$otherSessions );

    PE_OK;
}

# Build the removeOther link
# Last part of URL is built trough javascript
# @return removeOther link in HTML code
sub _mkRemoveOtherLink {
    my $self = shift;

    # TODO: remove this
    return $self->loadTemplate(
        'removeOther',
        params => {
            link => $self->conf->{portal} . "?removeOther=1"
        }
    );
}

1;
