package Lemonldap::NG::Portal::Plugins::Refresh;

use strict;
use Mouse;

our $VERSION = '2.0.7';

extends 'Lemonldap::NG::Portal::Main::Plugin',
  'Lemonldap::NG::Portal::Lib::OtherSessions';

sub init {
    my ($self) = @_;
    $self->addUnauthRoute( refreshsessions => 'run', ['POST'] );
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
        eval { $self->p->refresh($req); };
        $self->logger->debug("Refresh: $@") if $@;
        $c++;
    }
    $req->userData( {} );
    $req->$_(undef) foreach (qw(user id));
    return $self->sendJSONresponse( $req,
        { updated => $c, errors => ( $nb - $c ) } );
}

1;
