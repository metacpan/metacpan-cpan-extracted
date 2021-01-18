package Lemonldap::NG::Portal::Plugins::Refresh;

use strict;
use Mouse;
use JSON;

our $VERSION = '2.0.10';

extends qw(
  Lemonldap::NG::Portal::Main::Plugin
  Lemonldap::NG::Portal::Lib::OtherSessions
);

sub init {
    my ($self) = @_;
    $self->addUnauthRoute( refreshsessions => 'run', ['POST'] );

    return 1;
}

sub run {
    my ( $self, $req ) = @_;
    return $self->p->sendError( $req, 'Not a JSON request', 400 )
      unless $req->wantJSON;
    my $info = $req->jsonBodyToObj;
    return $self->p->sendError( $req, 'Bad content', 400 ) unless $info->{uid};
    my $sessions =
      $self->module->searchOn( $self->moduleOpts, $self->conf->{whatToTrace},
        $info->{uid} );
    my $c  = 0;
    my $nb = scalar( keys %$sessions );

    foreach my $id ( keys %$sessions ) {
        $req->userData(
            { _session_id => $id, $self->conf->{whatToTrace} => $info->{uid} }
        );
        $req->id($id);
        $req->user( $info->{uid} );
        my $res;
        eval { $res = $self->p->refresh($req); };
        if ($@) {
            $self->logger->error("Refresh: $@");
            next;
        }
        if ( ref($res) ne "ARRAY" ) {
            $self->logger->error("Refresh failed for session $id");
            next;
        }
        my $refreshJSON = $res->[2]->[0];
        $self->logger->debug("Refresh result: $refreshJSON");
        my $refreshHASH = from_json($refreshJSON);
        if ( $refreshHASH->{error} == 0 ) {
            $self->logger->notice("Refresh succeed for session $id");
            $c++;
        }
        else {
            $self->logger->error("Refresh failed for session $id");
        }
    }
    $req->userData( {} );
    $req->$_(undef) foreach (qw(user id));
    return $self->sendJSONresponse( $req,
        { updated => $c, errors => ( $nb - $c ) } );
}

1;
