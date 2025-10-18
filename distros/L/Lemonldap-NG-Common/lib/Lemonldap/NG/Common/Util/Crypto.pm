package Lemonldap::NG::Common::Util::Crypto;
use strict;
use warnings;

require Exporter;

our $VERSION = '2.22.0';
our @ISA     = qw(Exporter);
our @EXPORT_OK = qw(genRsaKey);

use Crypt::OpenSSL::RSA;
use Digest::MD5 qw(md5_base64);
use Convert::PEM;
use Net::SSLeay;

sub genRsaKey {
    my ( $key_size, $password ) = @_;

    my $rsa = Crypt::OpenSSL::RSA->generate_key( $key_size );

    my $keys  = {
        'private' => $rsa->get_private_key_string(),
        'public'  => $rsa->get_public_key_x509_string(),
        'hash'    => md5_base64( $rsa->get_public_key_string() ),
    };
    if ( $password ) {
        my $pem = Convert::PEM->new(
            Name => 'RSA PRIVATE KEY',
            ASN  => q(
                RSAPrivateKey SEQUENCE {
                    version INTEGER,
                    n INTEGER,
                    e INTEGER,
                    d INTEGER,
                    p INTEGER,
                    q INTEGER,
                    dp INTEGER,
                    dq INTEGER,
                    iqmp INTEGER
    }
               )
        );
        $keys->{private} = $pem->encode(
            Content  => $pem->decode( Content => $keys->{private} ),
            Password => $password,
        );
    }

    return $keys;
}

sub _genSelfSignedCertificate {
    my ( $password, $cn, $assign_key_func ) = @_;

    Net::SSLeay::SSLeay_add_ssl_algorithms();
    $cn ||= "localhost";

    # Generate 2048 bits RSA key
    my $key = Net::SSLeay::EVP_PKEY_new();

    # Populate private key using supplied coderef
    $assign_key_func->($key);

    my $cert = Net::SSLeay::X509_new();

    # Serial
    Net::SSLeay::ASN1_INTEGER_set(
        Net::SSLeay::X509_get_serialNumber($cert),
        rand( 2**32 ),
    );

    # Version
    Net::SSLeay::X509_set_version( $cert, 2 );

    # Make it last 20 years
    Net::SSLeay::ASN1_TIME_set( Net::SSLeay::X509_get_notBefore($cert),
        time() );
    Net::SSLeay::ASN1_TIME_set( Net::SSLeay::X509_get_notAfter($cert),
        time() + 20 * 365 * 86400 );

    # set subject
    my $subj_e = Net::SSLeay::X509_get_subject_name($cert);
    my $subj   = { commonName => $cn, };

    while ( my ( $k, $v ) = each %$subj ) {

        # Not everything we get is nice - try with MBSTRING_UTF8 first and if it
        # fails try V_ASN1_T61STRING and finally V_ASN1_OCTET_STRING
        Net::SSLeay::X509_NAME_add_entry_by_txt( $subj_e, $k, 0x1000, $v, -1,
            0 )
          or
          Net::SSLeay::X509_NAME_add_entry_by_txt( $subj_e, $k, 20, $v, -1, 0 )
          or
          Net::SSLeay::X509_NAME_add_entry_by_txt( $subj_e, $k, 4, $v, -1, 0 )
          or croak( "failed to add entry for $k - "
              . Net::SSLeay::ERR_error_string( Net::SSLeay::ERR_get_error() ) );
    }

    # Set to self-sign
    Net::SSLeay::X509_set_pubkey( $cert, $key );
    Net::SSLeay::X509_set_issuer_name( $cert,
        Net::SSLeay::X509_get_subject_name($cert) );

    # Sign with default alg
    Net::SSLeay::X509_sign( $cert, $key, 0 );

    my $strCert = Net::SSLeay::PEM_get_string_X509($cert);
    my $strPrivate;
    if ($password) {
        my $alg = Net::SSLeay::EVP_get_cipherbyname("AES-256-CBC")
          || Net::SSLeay::EVP_get_cipherbyname("DES-EDE3-CBC");
        $strPrivate =
          Net::SSLeay::PEM_get_string_PrivateKey( $key, $password, $alg );
    }
    else {
        $strPrivate = Net::SSLeay::PEM_get_string_PrivateKey($key);
    }

    # Free OpenSSL objects
    Net::SSLeay::X509_free($cert);
    Net::SSLeay::EVP_PKEY_free($key);

    return {
        private => $strPrivate,
        public  => $strCert,
        hash    => md5_base64($strCert)
    };
}

sub genCertKey {
    my ( $key_size, $password, $cn ) = @_;
    return _genSelfSignedCertificate(
        $password,
        $cn,
        sub {
            my $key = shift;
            Net::SSLeay::EVP_PKEY_assign_RSA( $key,
                Net::SSLeay::RSA_generate_key( $key_size, 0x10001 ) );
        }
    );
}

sub genEcCertKey {
    my ( $curve, $password, $cn ) = @_;

    return _genSelfSignedCertificate(
        $password,
        $cn,
        sub {
            my $key = shift;
            Net::SSLeay::EVP_PKEY_assign_EC_KEY( $key,
                Net::SSLeay::EC_KEY_generate_key($curve) );
        }
    );
}

sub genEcKey {
    my ( $curve ) = @_;
    require Crypt::PK::ECC;
    my $ec_key = Crypt::PK::ECC->new();
    $ec_key->generate_key($curve);

    my $pubKey = $ec_key->export_key_pem('public');
    my $privKey = $ec_key->export_key_pem('private');
    return {
        private => $privKey,
        public => $pubKey,
        hash => md5_base64($pubKey),
    };
}

1;
__END__

=head1 NAME

=encoding utf8

Lemonldap::NG::Common::Util::Crypto - Crypto utilities for LemonLDAP::NG

=head1 DESCRIPTION

This package contains various cryptography-related functions

=head1 METHODS

=head3 genCertKey($key_len, $password, $cn)

This method generates a RSA private key and a self-signed certificate, and returns a hashref of

=over

=item public: certificate in PEM format, subject is built from given $cn

=item private: private key in PEM format, optionnaly encrypted with supplied password

=item hash: unique identifier for the key

=back

=head3 genEcKey($curve_name)

This method generates an ECDSA key pair and returns a hashref of

=over

=item public: public key in PEM format

=item private: private key in PEM format

=item hash: unique identifier for the key

=back

=head3 genRsaKey($key_len, $password)

This method generates a RSA key pair and returns a hashref of

=over

=item public: public key in PEM format

=item private: private key in PEM format, optionnaly encrypted with supplied password

=item hash: unique identifier for the key

=back

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

=cut
