package Lemonldap::NG::Portal::Captcha::SecurityImage;

use strict;
use Mouse;
use MIME::Base64;
use GD::SecurityImage use_magick => 1;

our $VERSION = '2.0.15';

extends 'Lemonldap::NG::Portal::Main::Plugin';

has width => (
    is      => 'rw',
    lazy    => 1,
    default => sub { $_[0]->{conf}->{captchaWidth} || 220 }
);
has height => (
    is      => 'rw',
    lazy    => 1,
    default => sub { $_[0]->{conf}->{captchaHeight} || 40 }
);
has lines => (
    is      => 'rw',
    lazy    => 1,
    default => sub { $_[0]->{conf}->{captchaLines} || 5 }
);
has scramble => (
    is      => 'rw',
    lazy    => 1,
    default => sub { $_[0]->{conf}->{captchaScramble} || 1 }
);
has fgColor => (
    is      => 'rw',
    lazy    => 1,
    default => sub { $_[0]->{conf}->{captchaFg} || '#403030' }
);
has bgColor => (
    is      => 'rw',
    lazy    => 1,
    default => sub { $_[0]->{conf}->{captchaBg} || '#FF644B' }
);
has rndmax => (
    is      => 'rw',
    lazy    => 1,
    default => sub { $_[0]->{conf}->{captcha_size} || 6 }
);
has timeout => (
    is      => 'rw',
    lazy    => 1,
    default => sub { $_[0]->{conf}->{formTimeout} }
);

has ott => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $ott = $_[0]->{p}->loadModule('::Lib::OneTimeToken');
        $ott->timeout( $_[0]->timeout );
        return $ott;
    }
);

sub init {
    my ($self) = @_;
    if (   $self->conf->{captcha_mail_enabled}
        || $self->conf->{captcha_login_enabled}
        || $self->conf->{captcha_register_enabled} )
    {
        $self->addUnauthRoute( renewcaptcha => '_sendCaptcha', ['GET'] );
    }
    return 1;
}

# Internal methods
sub _getCaptcha {
    my ($self) = @_;
    my $image = GD::SecurityImage->new(
        width    => $self->width,
        height   => $self->height,
        lines    => $self->lines,
        gd_font  => 'Giant',
        scramble => $self->scramble,
        rndmax   => $self->rndmax,
    );
    $image->random;
    $image->create( 'normal', 'default', $self->fgColor, $self->bgColor );
    my ( $imageData, $mimeType, $rdm ) = $image->out( force => 'png' );
    my $img   = 'data:image/png;base64,' . encode_base64( $imageData, '' );
    my $token = $self->ott->createToken( { captcha => $rdm } );
    return ( $token, $img );
}

sub _sendCaptcha {
    my ( $self, $req ) = @_;
    $self->logger->info("User request for captcha renew");
    my ( $token, $image ) = $self->_getCaptcha($req);

    return $self->p->sendJSONresponse( $req,
        { newtoken => $token, newimage => $image } );
}

sub _validate_captcha_token {
    my ( $self, $token, $value ) = @_;
    my $s = $self->ott->getToken($token);
    unless ($s) {
        $self->logger->warn("Captcha token $token isn't valid");
        return 0;
    }
    unless ( $s->{captcha} eq $value ) {
        $self->logger->notice('Bad captcha response');
        return 0;
    }
    $self->logger->debug('Good captcha response');
    return 1;
}

sub _get_captcha_html {
    my ( $self, $req, $src ) = @_;

    my $sp = $self->p->staticPrefix;
    $sp =~ s/\/*$/\//;

    return $self->loadTemplate(
        $req,
        'captcha',
        params => {
            STATIC_PREFIX => $sp,
            CAPTCHA_SRC   => $src,
            CAPTCHA_SIZE  => $self->rndmax,
        }
    );
}

# New API
sub check_captcha {
    my ( $self, $req ) = @_;
    my $token = $req->param('token');
    unless ($token) {
        $self->logger->warn("No token provided for Captcha::SecurityImage");
        return 0;
    }

    my $value = $req->param('captcha');
    unless ($value) {
        $self->logger->warn("No response provided for Captcha::SecurityImage");
        return 0;
    }

    return $self->_validate_captcha_token( $token, $value );
}

sub init_captcha {
    my ( $self, $req ) = @_;

    my ( $token, $image ) = $self->_getCaptcha;
    $self->logger->debug('Prepare captcha');
    $req->token($token);
    $req->captchaHtml( $self->_get_captcha_html( $req, $image ) );

    # DEPRECATED: Compatibility with old templates
    $req->captcha($image);
}

# #######
# Old API
# TODO: Remove this in 3.0
# #######

sub validateCaptcha {
    my ( $self, $token, $value ) = @_;
    return $self->_validate_captcha_token( $token, $value );
}

sub setCaptcha {
    my ( $self, $req ) = @_;
    $self->init_captcha($req);
}

sub sendCaptcha {
    my ( $self, $req ) = @_;
    return $self->_sendCaptcha($req);
}

sub getCaptcha {
    my ( $self, $req ) = @_;
    return $self->_getCaptcha($req);
}

1;
