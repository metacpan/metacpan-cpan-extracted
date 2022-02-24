package Lemonldap::NG::Portal::CertificateResetByMail::Custom;
use Lemonldap::NG::Portal::Lib::CustomModule;

use strict;

our @ISA = qw(Lemonldap::NG::Portal::Lib::CustomModule);
use constant {
    custom_name       => "CertificateResetByMail",
    custom_config_key => "customResetCertByMail",
};

sub new {
    my ( $class, $self ) = @_;
    unless ( $self->{conf}->{customRegister} ) {
        die 'Custom register module not defined';
    }
    return $class->Lemonldap::NG::Portal::Lib::CustomModule::new($self);
}

1;
