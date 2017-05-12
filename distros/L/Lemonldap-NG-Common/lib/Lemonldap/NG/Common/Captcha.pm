##@file
# Base package for LemonLDAP::NG Captcha

##@class
# Captcha module that uses session backend

package Lemonldap::NG::Common::Captcha;

our $VERSION = '1.9.1';

use strict;
use Lemonldap::NG::Common::Session;
use Mouse;
use Digest::MD5 qw(md5_hex);

has 'storageModule' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'storageModuleOptions' => (
    is  => 'ro',
    isa => 'HashRef|Undef',
);

has code => ( is => 'rw', isa => 'Str' );

has md5 => ( is => 'rw', isa => 'Str' );

has image => ( is => 'rw', isa => 'Str' );

has size => ( is => 'ro', isa => 'Int' );

sub BUILD {

    my $self = shift;

    unless ( $self->md5 ) {

        # Create captcha object
        require Authen::Captcha;
        my $captcha = Authen::Captcha->new();

        # Generate code and md5
        my $code = $captcha->generate_random_string( $self->size );
        my $md5  = md5_hex($code);
        $self->code($code);
        $self->md5($md5);

        # Generate image data
        my $data = $captcha->create_image_file( $code, $md5 );
        $self->image($$data);

        # Save captcha session
        $self->saveSession;
    }
    else {
        $self->getSession;
    }
}

sub saveSession {

    my $self = shift;

    # Create new session
    my $session = Lemonldap::NG::Common::Session->new(
        {
            storageModule        => $self->storageModule,
            storageModuleOptions => $self->storageModuleOptions,
            id                   => $self->md5,
            force                => 1,
            kind                 => "Captcha",
        }
    );

    $session->update(
        { _utime => time, code => $self->code, image => $self->image } );

}

sub getSession {
    my $self = shift;

    # Get session
    my $session = Lemonldap::NG::Common::Session->new(
        {
            storageModule        => $self->storageModule,
            storageModuleOptions => $self->storageModuleOptions,
            id                   => $self->md5,
        }
    );

    if ( $session && $session->data ) {
        $self->code( $session->data->{code} );
        $self->image( $session->data->{image} );
    }
}

sub removeSession {
    my $self = shift;

    # Get session
    my $session = Lemonldap::NG::Common::Session->new(
        {
            storageModule        => $self->storageModule,
            storageModuleOptions => $self->storageModuleOptions,
            id                   => $self->md5,
        }
    );

    if ($session) {
        return $session->remove;
    }

    return 0;
}

no Mouse;

1;
