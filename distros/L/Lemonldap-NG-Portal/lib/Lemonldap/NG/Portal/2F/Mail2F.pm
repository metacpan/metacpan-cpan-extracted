package Lemonldap::NG::Portal::2F::Mail2F;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_BADCREDENTIALS
  PE_ERROR
  PE_FORMEMPTY
  PE_OK
  PE_SENDRESPONSE
  PE_MUSTHAVEMAIL
);

our $VERSION = '2.0.3';

extends 'Lemonldap::NG::Portal::Main::SecondFactor',
  'Lemonldap::NG::Portal::Lib::SMTP';

# INITIALIZATION

has prefix => ( is => 'ro', default => 'mail' );
has random => (
    is      => 'rw',
    default => sub {
        return Lemonldap::NG::Common::Crypto::srandom();
    }
);

has ott => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $ott =
          $_[0]->{p}->loadModule('Lemonldap::NG::Portal::Lib::OneTimeToken');
        $ott->timeout( $_[0]->{conf}->{mail2fTimeout}
              || $_[0]->{conf}->{formTimeout} );
        return $ott;
    }
);

sub init {
    my ($self) = @_;
    $self->{conf}->{mail2fCodeRegex} ||= '\d{6}';
    unless ( $self->conf->{mailSessionKey} ) {
        $self->error("Missing 'mailSessionKey' parameter, aborting");
        return 0;
    }
    $self->logo( $self->conf->{mail2fLogo} )
      if ( $self->conf->{mail2fLogo} );
    return $self->SUPER::init();
}

sub run {
    my ( $self, $req, $token ) = @_;

    my $checkLogins = $req->param('checkLogins');

    my $code = $self->random->randregex( $self->conf->{mail2fCodeRegex} );
    $self->logger->debug("Generated two-factor code: $code");
    $self->ott->updateToken( $token, __mail2fcode => $code );

    my $dest = $req->{sessionInfo}->{ $self->conf->{mailSessionKey} };
    unless ($dest) {
        $self->logger->error( "Could not find mail attribute for login "
              . $req->{sessionInfo}->{_user} );
        return PE_MUSTHAVEMAIL;
    }

    # Build mail content
    my %tplPrms;
    $tplPrms{MAIN_LOGO} = $self->conf->{portalMainLogo};
    my $tr      = $self->translate($req);
    my $subject = $self->conf->{mail2fSubject};

    unless ($subject) {
        $subject = 'mail2fSubject';
        $tr->( \$subject );
    }
    my ( $body, $html );
    if ( $self->conf->{mail2fBody} ) {

        # We use a specific text message, no html
        $body = $self->conf->{mail2fBody};
    }
    else {

        # Use HTML template
        $body = $self->loadTemplate(
            $req,
            'mail_2fcode',
            filter => $tr,
            params => \%tplPrms
        );
        $html = 1;
    }

    # Replace variables in body
    $body =~ s/\$code/$code/g;
    $body =~ s/\$(\w+)/$req->{sessionInfo}->{$1} || ''/ge;

    # Send mail
    unless ( $self->send_mail( $dest, $subject, $body, $html ) ) {
        $self->logger->error( 'Unable to send 2F code mail to ' . $dest );
        return PE_ERROR;
    }

    # Prepare form
    my $tmp = $self->p->sendHtml(
        $req,
        'ext2fcheck',
        params => {
            MAIN_LOGO   => $self->conf->{portalMainLogo},
            SKIN        => $self->p->getSkin($req),
            TOKEN       => $token,
            TARGET      => '/' . $self->prefix . '2fcheck',
            CHECKLOGINS => $checkLogins
        }
    );
    $req->response($tmp);
    return PE_SENDRESPONSE;
}

sub verify {
    my ( $self, $req, $session ) = @_;
    my $usercode;
    unless ( $usercode = $req->param('code') ) {
        $self->logger->error('Mail2F: no code');
        return PE_FORMEMPTY;
    }
    my $savedcode = $session->{__mail2fcode};

    unless ($savedcode) {
        $self->logger->error(
            'Unable to find generated 2F code in token session');
        return PE_ERROR;
    }

    $self->logger->debug(
        "Verifying Mail 2F code: $usercode against $savedcode");

    return PE_OK if ( $usercode eq $savedcode );

    $self->userLogger->warn( 'Second factor failed for '
          . $session->{ $self->conf->{whatToTrace} } );
    return PE_BADCREDENTIALS;
}

1;
