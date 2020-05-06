package Lemonldap::NG::Portal::Lib::Captcha;

use strict;
use GD::SecurityImage use_magick => 1;
use Mouse;
use MIME::Base64;

our $VERSION = '2.0.1';

extends 'Lemonldap::NG::Common::Module';

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

sub init { 1 }

# Returns secret + a HTML image src content
sub getCaptcha {
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

sub validateCaptcha {
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

sub setCaptcha {
    my ( $self,  $req )   = @_;
    my ( $token, $image ) = $self->getCaptcha;
    $self->logger->debug('Prepare captcha');
    $req->token($token);
    $req->captcha($image);
}

1;
