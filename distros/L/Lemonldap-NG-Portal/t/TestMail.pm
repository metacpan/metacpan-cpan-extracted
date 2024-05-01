package t::TestMail;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
  PE_ERROR
);

extends qw(
  Lemonldap::NG::Portal::Main::Plugin
  Lemonldap::NG::Portal::Lib::SMTP
);

# INITIALIZATION

sub init {
    my ($self) = @_;

    $self->addUnauthRoute( 'testmail' => 'testmail', ['GET'] );
    return 1;
}

sub testmail {
    my ( $self, $req ) = @_;
    $self->logger->debug("coucou");

    # Build mail content
    my $subject        = $req->param('subject');
    my $dest           = $req->param('dest') || 'user@example.com';
    my $param_body     = $req->param('body');
    my $param_template = $req->param('template');

    my $tr = $self->translate($req);

    unless ($subject) {
        $subject = 'mail2fSubject';
        $tr->( \$subject );
    }

    # Use HTML template
    my $body = $self->loadMailTemplate( $req, 'mail_2fcode', filter => $tr, );

    # Send mail
    unless ( $self->send_mail( $dest, $subject, $body, 1 ) ) {
        return $self->p->sendError( $req, "Error sending mail" );
    }
    return $self->p->sendJSONresponse( $req, [] );
}

1;
