package Lemonldap::NG::Portal::CertificateResetByMail::LDAP;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_LDAPCONNECTFAILED
  PE_LDAPERROR
  PE_OK
  PE_ERROR
);

extends 'Lemonldap::NG::Portal::Lib::LDAP';

our $VERSION = '2.0.14';

# PRIVATE METHOD
sub modifCertificate {
    my ( $self, $req, $newCertif, $userCertif ) = @_;
    my $ceaAttribute = $self->conf->{certificateResetByMailCeaAttribute}
      || "description";
    my $certificateAttribute =
      $self->conf->{certificateResetByMailCertificateAttribute}
      || "userCertificate;binary";

    # Set the dn unless done before
    my $dn;
    if ( $req->userData->{_dn} ) {
        $dn = $req->userData->{_dn};
        $self->logger->debug("Get DN from request data: $dn");
    }
    else {
        $dn = $req->sessionInfo->{_dn};
        $self->logger->debug("Get DN from session data: $dn");
    }
    unless ($dn) {
        $self->logger->error('"dn" is not set, aborting certificate reset');
        return PE_ERROR;
    }

    #my $dn = "uid=" . $req->{user}. "," . $self->conf->{ldapBase};

    my $result = $self->ldap->modify(
        $dn,
        replace => [
            $ceaAttribute           => $newCertif,
            "$certificateAttribute" => [$userCertif]
        ]
    );

    unless ( $result->code == 0 ) {
        $self->logger->debug( "LDAP modify Error: " . $result->code );
        $self->ldap->unbind;
        return PE_LDAPERROR;
    }

    $self->logger->debug("$ceaAttribute set to $newCertif");

    return PE_OK;
}

1;
