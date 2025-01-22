package Lemonldap::NG::Portal::Captcha::ReCaptcha3;

use strict;
use Mouse;
use Lemonldap::NG::Common::UserAgent;

# Add constants used by this module

our $VERSION = '2.20.0';

extends 'Lemonldap::NG::Portal::Main::Plugin';

has ua => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        my $ua = Lemonldap::NG::Common::UserAgent->new( $_[0]->{conf} );
        $ua->env_proxy();
        return $ua;
    }
);

has score => (
    is      => 'ro',
    default => sub {
        return $_[0]->{conf}->{captchaOptions}->{score} || 0.5;
    }
);

sub init {
    my ($self) = @_;
    unless ($self->conf->{captchaOptions}->{dataSiteKey}
        and $self->conf->{captchaOptions}->{secretKey} )
    {
        $self->logger->error('Missing required options for reCaptcha');
        return 0;
    }
    return 1;
}

sub init_captcha {
    my ( $self, $req ) = @_;

    $req->data->{customScript} .=
        '<script src="https://www.google.com/recaptcha/api.js?render='
      . $self->conf->{captchaOptions}->{dataSiteKey}
      . '"></script>'
      . '<script type="application/init">
{
"datasitekey": "' . $self->conf->{captchaOptions}->{dataSiteKey} . '"
}
</script>'
      . '<script src="/static/common/js/recaptchav3.js"></script>';

    # Read option from the manager configuration
    my $dataSiteKey = $self->conf->{captchaOptions}->{dataSiteKey};
    my $html =
qq'<div class="g-recaptcha" data-sitekey="$dataSiteKey" data-action="LOGIN">
<input type="hidden" id="grr" name="g-recaptcha-response" />
</div>';
    $req->captchaHtml($html);
}

sub check_captcha {
    my ( $self, $req ) = @_;

    my $captcha_input = $req->param('g-recaptcha-response');
    unless ($captcha_input) {
        $self->logger->info('No captcha value submitted');
        return 0;
    }
    my $response = $self->ua->post(
        'https://www.google.com/recaptcha/api/siteverify',
        {
            secret   => $self->conf->{captchaOptions}->{secretKey},
            response => $captcha_input,
        }
    );
    if ( $response->is_success ) {
        my $res = eval { JSON::from_json( $response->decoded_content ) };
        if ($@) {
            $self->logger->error("reCaptcha: $@");
            return 0;
        }
        my $success =
              $res->{success}
          and $res->{score}
          and ( $res->{score} >= $self->score );
        unless ($success) {
            $self->logger->info(
                'reCaptcha errors:' . $response->decoded_content );
        }
        return $success;
    }
    $self->logger->error( 'reCaptcha error: ' . $response->status_line );
    return 0;
}

1;

