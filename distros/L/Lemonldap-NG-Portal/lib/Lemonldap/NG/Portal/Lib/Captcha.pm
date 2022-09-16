package Lemonldap::NG::Portal::Lib::Captcha;

# Old Captcha API, this is only a wrapper around Captcha::SecurityImage

use strict;
use Mouse;
use MIME::Base64;

our $VERSION = '2.0.15';

extends 'Lemonldap::NG::Common::Module';

has module => (
    is      => 'rw',
    handles => [
        qw(setCaptcha validateCaptcha getCaptcha ott width height lines scramble fgColor bgColor rndmax timeout )
    ]
);

sub init {
    my ($self) = @_;

    if ( $self->conf->{captcha} ) {
        $self->logger->error( "The Lib::Captcha API is not compatible"
              . " with custom Captcha module" );
        return 0;
    }
    else {
        my $module = $self->p->loadModule("::Captcha::SecurityImage");
        if ($module) {
            $self->module($module);
            return 1;
        }
        else {
            return 0;
        }
    }
}

1;
