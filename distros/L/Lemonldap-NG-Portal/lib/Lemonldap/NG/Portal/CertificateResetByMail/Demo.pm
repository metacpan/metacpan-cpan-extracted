package Lemonldap::NG::Portal::CertificateResetByMail::Demo;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(PE_OK);

our $VERSION = '2.0.15';

sub init {
    return 1;
}

## @method int modifCertificate
# Do nothing
# @result Lemonldap::NG::Portal constant
sub modifCertificate {
    my ( $self, $req, $newCertif, $userCertif ) = @_;
    my $uid =
      $req->user || $req->userData->{_user} || $req->sessionInfo->{_user};

    $Lemonldap::NG::Portal::UserDB::Demo::demoAccounts{$uid} = {
        uid      => $uid,
        cn       => $uid . ' ' . uc $uid,
        mail     => $uid . '@badwolf.org',
        newCert  => $newCertif,
        userCert => $userCertif,
    };

    return PE_OK;
}

1;
