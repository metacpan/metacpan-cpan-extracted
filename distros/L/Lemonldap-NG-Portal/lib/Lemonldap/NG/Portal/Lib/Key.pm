package Lemonldap::NG::Portal::Lib::Key;

=pod

=head1 NAME

Lemonldap::NG::Portal::Lib::Key - A role for private key management in Portal
plugins

=head1 SYNOPSIS

use Mouse;

with 'Lemonldap::NG::Portal::Lib::Key';

=head1 DESCRIPTION

This role is meant to be composed into portal modules to give them the ability
to lookup private/public keys from the General parameters > Keys interface

All asymetric key retrieval should be performed through the functions provided
here

=head1 METHODS
=cut

use strict;
use Mouse::Role;

our $VERSION = '2.22.0';

requires qw(conf);

=pod

=head2 get_private_key

This method returns a private key structure containing the following fields

=over

=item private: PEM private key

=item password: optional password for key decryption

=item public: PEM public key or certificate

=item external_id: optional external key identified (kid)

=back

=cut

sub get_private_key {
    my ( $self, $key_id ) = @_;
    my $key_id_log = $key_id // '[undef]' || "[empty]";

    $self->logger->debug("Looking up private key $key_id_log");

    my $key_config = $self->_get_key_config($key_id);

    if ($key_config) {
        $self->logger->debug("Found private key $key_id_log");
        return {
            private     => $key_config->{keyPrivate},
            public      => $key_config->{keyPublic},
            external_id => $key_config->{keyId},
            password    => $key_config->{keyPrivatePwd},
        };
    }

    $self->logger->debug("Private key $key_id_log not found");
    return;
}

sub get_public_key {
    my ( $self, $key_id ) = @_;
    my $key_id_log = $key_id // '[undef]' || "[empty]";
    $self->logger->debug("Looking up public key $key_id_log");

    my $key_config = $self->_get_key_config($key_id);

    if ($key_config) {
        $self->logger->debug("Found public key $key_id_log");
        return {
            public      => $key_config->{keyPublic},
            external_id => $key_config->{keyId},
        };
    }

    $self->logger->debug("Public key $key_id_log not found");
    return;
}

sub _get_key_config {
    my ( $self, $key_id ) = @_;

    return unless $key_id;
    if ( my $key = $self->conf->{'keys'}->{$key_id} ) {
        return {
            keyPrivate    => $key->{keyPrivate},
            keyPrivatePwd => ( $key->{keyPrivatePwd} // "" ),
            keyPublic     => $key->{keyPublic},
            keyId         => ( $key->{keyId} || $key_id ),
        };
    }

    if ( $key_id eq "default-saml-sig" ) {
        if ( $self->conf->{samlServicePrivateKeySig} ) {
            return {
                keyPrivate    => $self->conf->{samlServicePrivateKeySig},
                keyPrivatePwd =>
                  ( $self->conf->{samlServicePrivateKeySigPwd} // '' ),
                keyPublic => $self->conf->{samlServicePublicKeySig},
                keyId     => "default-saml-sig",
            };
        }
    }

    if ( $key_id eq "default-saml-enc" ) {
        if ( $self->conf->{samlServicePrivateKeyEnc} ) {
            return {
                keyPrivate    => $self->conf->{samlServicePrivateKeyEnc},
                keyPrivatePwd =>
                  ( $self->conf->{samlServicePrivateKeyEncPwd} // '' ),
                keyPublic => $self->conf->{samlServicePublicKeyEnc},
                keyId     => "default-saml-enc",
            };
        }
    }

    if ( $key_id eq "default-oidc-sig" ) {
        if ( $self->conf->{oidcServicePrivateKeySig} ) {
            return {
                keyPrivate    => $self->conf->{oidcServicePrivateKeySig},
                keyPrivatePwd => '',
                keyPublic     => $self->conf->{oidcServicePublicKeySig},
                keyId         => $self->conf->{oidcServiceKeyIdSig},
            };
        }
    }

    if ( $key_id eq "old-oidc-sig" ) {
        if ( $self->conf->{oidcServiceOldPrivateKeySig} ) {
            return {
                keyPrivate    => $self->conf->{oidcServiceOldPrivateKeySig},
                keyPrivatePwd => '',
                keyPublic     => $self->conf->{oidcServiceOldPublicKeySig},
                keyId         => $self->conf->{oidcServiceOldKeyIdSig},
            };
        }
    }

    if ( $key_id eq "new-oidc-sig" ) {
        if ( $self->conf->{oidcServiceNewPrivateKeySig} ) {
            return {
                keyPrivate    => $self->conf->{oidcServiceNewPrivateKeySig},
                keyPrivatePwd => '',
                keyPublic     => $self->conf->{oidcServiceNewPublicKeySig},
                keyId         => $self->conf->{oidcServiceNewKeyIdSig},
            };
        }
    }

    if ( $key_id eq "default-oidc-enc" ) {
        if ( $self->conf->{oidcServicePrivateKeyEnc} ) {
            return {
                keyPrivate    => $self->conf->{oidcServicePrivateKeyEnc},
                keyPrivatePwd => '',
                keyPublic     => $self->conf->{oidcServicePublicKeyEnc},
                keyId         => $self->conf->{oidcServiceKeyIdEnc},
            };
        }
    }

    return;
}

1;

__END__

=head1 AUTHORS

=over

=item LemonLDAP::NG team L<http://lemonldap-ng.org/team>

=back

=head1 BUG REPORT

Use OW2 system to report bug or ask for features:
L<https://gitlab.ow2.org/lemonldap-ng/lemonldap-ng/issues>

=head1 DOWNLOAD

Lemonldap::NG is available at
L<https://lemonldap-ng.org/download>

=head1 COPYRIGHT AND LICENSE

See COPYING file for details.

This library is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2, or (at your option)
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see L<http://www.gnu.org/licenses/>.
