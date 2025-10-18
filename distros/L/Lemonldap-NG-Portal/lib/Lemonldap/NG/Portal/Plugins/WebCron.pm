package Lemonldap::NG::Portal::Plugins::WebCron;

use strict;
use Mouse;
use Lemonldap::NG::Common::Session::Purge;

our $VERSION = '2.22.0';

extends 'Lemonldap::NG::Portal::Main::Plugin';

sub init {
    my ($self) = @_;

    # Useless for now, webCronSecret is required by ::Portal::Main::Plugins
    # to enable this plugin

    #unless ( $self->conf->{webCronSecret} ) {
    #    $self->logger->warn(
    #        'No secret for webconf, be sure that API is protected by webserver'
    #    );
    #}
    $self->addUnauthRoute(
        webcron => {
            localpurge => 'localPurge',
            purge      => 'purge'
        },
        [ 'GET', 'POST' ]
    );
    return 1;
}

sub purge {
    my ( $self, $req ) = @_;
    return $self->_do( $req, 'purge' );
}

sub localPurge {
    my ( $self, $req ) = @_;
    return $self->_do( $req, 'localPurge' );
}

sub _do {
    my ( $self, $req, $sub ) = @_;
    return $self->p->sendError( $req, 'Bad secret' )
      if $self->conf->{webCronSecret}
      and $req->param('secret') ne $self->conf->{webCronSecret};
    my $r = eval {
        Lemonldap::NG::Common::Session::Purge->new( {
                conf   => $self->conf,
                logger => $self->logger,
            }
        );
    };
    if ($@) {
        $self->logger("Unable to clean session: $@");
        $r = 0;
    }
    else {
        $r = $r->$sub;
    }
    return $r
      ? $self->p->sendJSONresponse( $req, { result => 1, err => 0 } )
      : $self->p->sendError( $req, 'Error while purging sessions, check logs' );
}

1;
