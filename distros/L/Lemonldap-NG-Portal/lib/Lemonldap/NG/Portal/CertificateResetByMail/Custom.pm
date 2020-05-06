package Lemonldap::NG::Portal::CertificateResetByMail::Custom;

use strict;
use Mouse;

extends 'Lemonldap::NG::Portal::Main::Plugin';

sub new {
    my ( $class, $self ) = @_;
    unless ( $self->{conf}->{customRegister} ) {
        die 'Custom register module not defined';
    }

    my $res = $self->{p}->loadModule( $self->{conf}->{customResetCertByMail} );
    unless ($res) {
        die 'Unable to load register module '
          . $self->{conf}->{customResetCertByMail};
    }

    return $res;
}

1;
