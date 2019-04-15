package HTTP::PublicKeyPins;

use 5.006;
use strict;
use warnings;
use Crypt::OpenSSL::X509();
use Crypt::OpenSSL::RSA();
use Crypt::PKCS10();
use Convert::ASN1();
use Digest();
use MIME::Base64();
use English qw( -no_match_vars );
use FileHandle();
use Exporter();
use Carp();
*import = \&Exporter::import;
our @EXPORT_OK = qw(
  pin_sha256
);
our %EXPORT_TAGS = ( 'all' => \@EXPORT_OK, );

sub _CERTIFICATE_HEADER_SIZE { return 40; }
sub _MAX_PUBLIC_KEY_SIZE     { return 65_536; }

our $VERSION = '0.15';

sub pin_sha256 {
    my ($path) = @_;
    my $handle = FileHandle->new($path)
      or Carp::croak("Failed to open $path for reading:$EXTENDED_OS_ERROR");
    binmode $handle;
    read $handle, my $file_header, _CERTIFICATE_HEADER_SIZE()
      or Carp::croak("Failed to read from $path:$EXTENDED_OS_ERROR");
    my $pem_encoded_public_key_string;
    if ( $file_header =~
        /^[-]{5}BEGIN[ ](?:X[.]?509[ ]|TRUSTED[ ])?CERTIFICATE[-]{5}/smx )
    {
        $pem_encoded_public_key_string =
          _process_pem_x509_certificate( $handle, $file_header, $path );
    }
    elsif ( $file_header =~
        /^[-]{5}BEGIN[ ](?:RSA[ ])?(PUBLIC|PRIVATE)[ ]KEY[-]{5}/smx )
    {
        my ($type) = ($1);
        if ( $type eq 'PRIVATE' ) {
            $pem_encoded_public_key_string =
              _process_pem_private_key( $handle, $file_header, $path );
        }
        else {
            $pem_encoded_public_key_string =
              _process_pem_public_key( $handle, $file_header, $path );
        }
    }
    elsif ( $file_header =~
        /^[-]{5}BEGIN[ ](?:NEW[ ])?CERTIFICATE[ ]REQUEST[-]{5}/smx )
    {
        $pem_encoded_public_key_string =
          _process_pem_pkcs10_certificate_request( $handle, $file_header,
            $path );
    }
    else {
        $pem_encoded_public_key_string =
          _check_for_der_encoded_x509_certificate( $handle, $file_header,
            $path )
          || _check_for_der_encoded_private_key( $handle, $file_header, $path )
          || _check_for_der_pkcs10_certificate_request( $handle, $file_header,
            $path )
          || _check_for_der_encoded_public_key( $handle, $file_header, $path );
        if ( !defined $pem_encoded_public_key_string ) {
            Carp::croak("$path is not an X.509 Certificate");
        }
    }

    $pem_encoded_public_key_string =~
      s/^[-]{5}BEGIN[ ]PUBLIC[ ]KEY[-]{5}\r?\n//smx;
    $pem_encoded_public_key_string =~
      s/^[-]{5}END[ ]PUBLIC[ ]KEY[-]{5}\r?\n//smx;
    my $der_encoded_public_key_string =
      MIME::Base64::decode($pem_encoded_public_key_string);
    my $digest = Digest->new('SHA-256');
    $digest->add($der_encoded_public_key_string);
    my $base64 = MIME::Base64::encode_base64( $digest->digest() );
    chomp $base64;
    return $base64;
}

sub _process_pem_x509_certificate {
    my ( $handle, $file_header, $path ) = @_;
    my $pem_encoded_public_key_string;
    if ( $file_header =~ /^[-]{5}BEGIN[ ]CERTIFICATE[-]{5}/smx ) {
        my $x509 = Crypt::OpenSSL::X509->new_from_file($path);
        $pem_encoded_public_key_string =
          _get_pem_encoded_public_key_string($x509);
    }
    else {
        seek $handle, 0, Fcntl::SEEK_SET()
          or Carp::croak("Failed to seek to start of $path:$EXTENDED_OS_ERROR");
        defined read $handle, my $pem_encoded_certificate_string,
          _MAX_PUBLIC_KEY_SIZE()
          or Carp::croak("Failed to read from $path:$EXTENDED_OS_ERROR");
        $pem_encoded_certificate_string =~
s/^([-]{5}BEGIN[ ])(?:X[.]?509|TRUSTED)[ ](CERTIFICATE[-]{5})/$1$2/smx;
        $pem_encoded_certificate_string =~
          s/^([-]{5}END[ ])(?:X[.]?509|TRUSTED)[ ](CERTIFICATE[-]{5})/$1$2/smx;
        my $x509 = Crypt::OpenSSL::X509->new_from_string(
            $pem_encoded_certificate_string);
        $pem_encoded_public_key_string =
          _get_pem_encoded_public_key_string($x509);
    }
    return $pem_encoded_public_key_string;
}

sub _process_pem_pkcs10_certificate_request {
    my ( $handle, $file_header, $path ) = @_;
    seek $handle, 0, Fcntl::SEEK_SET()
      or Carp::croak("Failed to seek to start of $path:$EXTENDED_OS_ERROR");
    defined read $handle, my $pkcs10_certificate_string, _MAX_PUBLIC_KEY_SIZE()
      or Carp::croak("Failed to read from $path:$EXTENDED_OS_ERROR");
    Crypt::PKCS10->setAPIversion(1);
    my $req = Crypt::PKCS10->new($pkcs10_certificate_string)
      or Carp::croak( 'Failed to initialise Crypt::PKCS10 library:'
          . Crypt::PKCS10->error() );
    my $pem_encoded_public_key_string = $req->subjectPublicKey(1);
    return $pem_encoded_public_key_string;
}

sub _check_for_der_pkcs10_certificate_request {
    my ( $handle, $file_header, $path ) = @_;
    my $pem_encoded_public_key_string;
    eval {
        seek $handle, 0, Fcntl::SEEK_SET()
          or Carp::croak("Failed to seek to start of $path:$EXTENDED_OS_ERROR");
        defined read $handle, my $pkcs10_certificate_string,
          _MAX_PUBLIC_KEY_SIZE()
          or Carp::croak("Failed to read from $path:$EXTENDED_OS_ERROR");
        Crypt::PKCS10->setAPIversion(1);
        my $req = Crypt::PKCS10->new($pkcs10_certificate_string);
        $pem_encoded_public_key_string = $req->subjectPublicKey(1);
    } or do {
        return;
    };
    return $pem_encoded_public_key_string;
}

sub _check_for_der_encoded_x509_certificate {
    my ( $handle, $file_header, $path ) = @_;
    my $pem_encoded_public_key_string;
    eval {
        my $x509 = Crypt::OpenSSL::X509->new_from_file( $path,
            Crypt::OpenSSL::X509::FORMAT_ASN1() );
        $pem_encoded_public_key_string =
          _get_pem_encoded_public_key_string($x509);
    } or do {
        return;
    };
    return $pem_encoded_public_key_string;
}

sub _check_for_der_encoded_public_key {
    my ( $handle, $file_header, $path ) = @_;
    my $pem_encoded_public_key_string;
    seek $handle, 0, Fcntl::SEEK_SET()
      or Carp::croak("Failed to seek to start of $path:$EXTENDED_OS_ERROR");
    defined read $handle, my $der_encoded_public_key_string,
      _MAX_PUBLIC_KEY_SIZE()
      or Carp::croak("Failed to read from $path:$EXTENDED_OS_ERROR");
    my $asn = Convert::ASN1->new( encoding => 'DER' );
    $asn->prepare(
        <<"__SUBJECT_PUBLIC_KEY_INFO__") or Carp::croak( 'Failed to prepare SubjectPublicKeyInfo in ASN1:' . $asn->error() );
SEQUENCE {
  algorithm SEQUENCE { algorithm OBJECT IDENTIFIER, parameters ANY OPTIONAL },
  subjectPublicKey BIT STRING
}
__SUBJECT_PUBLIC_KEY_INFO__
    eval {
        my $pub_key = $asn->decode($der_encoded_public_key_string)
          or Carp::croak(
            'Failed to decode SubjectPublicKeyInfo in ASN1:' . $asn->error() );
        $pem_encoded_public_key_string =
            "-----BEGIN PUBLIC KEY-----\n"
          . MIME::Base64::encode_base64($der_encoded_public_key_string)
          . "-----END PUBLIC KEY-----\n";
    } or do {
        return;
    };
    return $pem_encoded_public_key_string;
}

sub _check_for_der_encoded_private_key {
    my ( $handle, $file_header, $path ) = @_;
    my $pem_encoded_public_key_string;
    seek $handle, 0, Fcntl::SEEK_SET()
      or Carp::croak("Failed to seek to start of $path:$EXTENDED_OS_ERROR");
    defined read $handle, my $der_encoded_private_key_string,
      _MAX_PUBLIC_KEY_SIZE()
      or Carp::croak("Failed to read from $path:$EXTENDED_OS_ERROR");
    my $pem_encoded_private_key_string =
        "-----BEGIN RSA PRIVATE KEY-----\n"
      . MIME::Base64::encode_base64($der_encoded_private_key_string)
      . "-----END RSA PRIVATE KEY-----\n";
    eval {
        my $privkey =
          Crypt::OpenSSL::RSA->new_private_key($pem_encoded_private_key_string);
        $pem_encoded_public_key_string = $privkey->get_public_key_x509_string();
    } or do {
        return;
    };
    return $pem_encoded_public_key_string;
}

sub _process_pem_private_key {
    my ( $handle, $file_header, $path ) = @_;
    my $pem_encoded_public_key_string;
    seek $handle, 0, Fcntl::SEEK_SET()
      or Carp::croak("Failed to seek to start of $path:$EXTENDED_OS_ERROR");
    defined read $handle, my $rsa_private_key_string, _MAX_PUBLIC_KEY_SIZE()
      or Carp::croak("Failed to read from $path:$EXTENDED_OS_ERROR");
    my $privkey = Crypt::OpenSSL::RSA->new_private_key($rsa_private_key_string);
    $pem_encoded_public_key_string = $privkey->get_public_key_x509_string();
    return $pem_encoded_public_key_string;
}

sub _process_pem_public_key {
    my ( $handle, $file_header, $path ) = @_;
    my $pem_encoded_public_key_string;
    if ( $file_header =~ /^[-]{5}BEGIN[ ]RSA[ ]PUBLIC[ ]KEY[-]{5}/smx ) {
        seek $handle, 0, Fcntl::SEEK_SET()
          or Carp::croak("Failed to seek to start of $path:$EXTENDED_OS_ERROR");
        defined read $handle, my $pem_encoded_rsa_public_key_string,
          _MAX_PUBLIC_KEY_SIZE()
          or Carp::croak("Failed to read from $path:$EXTENDED_OS_ERROR");
        my $pubkey = Crypt::OpenSSL::RSA->new_public_key(
            $pem_encoded_rsa_public_key_string);
        $pem_encoded_public_key_string = $pubkey->get_public_key_x509_string();
    }
    else {
        seek $handle, 0, Fcntl::SEEK_SET()
          or Carp::croak("Failed to seek to start of $path:$EXTENDED_OS_ERROR");
        defined read $handle, $pem_encoded_public_key_string,
          _MAX_PUBLIC_KEY_SIZE()
          or Carp::croak("Failed to read from $path:$EXTENDED_OS_ERROR");
    }
    return $pem_encoded_public_key_string;
}

sub _get_pem_encoded_public_key_string {
    my ($x509) = @_;
    my $pem_encoded_public_key_string;
    if ( $x509->key_alg_name() eq 'rsaEncryption' ) {
        my $pubkey = Crypt::OpenSSL::RSA->new_public_key( $x509->pubkey() );
        $pem_encoded_public_key_string = $pubkey->get_public_key_x509_string();
    }
    else {
        $pem_encoded_public_key_string = $x509->pubkey();
    }
    return $pem_encoded_public_key_string;
}

1;    # End of HTTP::PublicKeyPins
__END__

=head1 NAME

HTTP::PublicKeyPins - Generate RFC 7469 HTTP Public Key Pin (HPKP) header values

=head1 VERSION

Version 0.15

=head1 SYNOPSIS

Make it more difficult for the bad guys to Man-In-The-Middle your users TLS sessions

    use HTTP::Headers();
    use HTTP::PublicKeyPins qw( pin_sha256 );

    ...
    my $h = HTTP::Headers->new();
    $h->header( 'Public-Key-Pins-Report-Only',
            'pin-sha256="'
          . pin_sha256('/etc/pki/tls/certs/example.pem')
          . '"; pin-sha256="'
          . pin_sha256('/etc/pki/tls/certs/backup.req')
          . '"; report-uri="https://example.com/pkp-report.pl' );


=head1 DESCRIPTION

This module allows the calculation of RFC 7469 HTTP Public Key Pin header values. This can be used to verify your TLS session to a remote server has not been hit by a Man-In-The-Middle attack OR to instruct your users to ignore any TLS sessions to your web service that does not use your Public Key

=head1 EXPORT

=head2 pin_sha256

This function accepts the path to a L<X.509 Certificate|http://tools.ietf.org/html/rfc5280>.  It will load the public key from the certificate and prepare the appropriate value for the pin_sha256 parameter of the Public-Key-Pins value. This function will also make an attempt to read public keys (in PEM (L<SubjectPublicKeyInfo|http://tools.ietf.org/html/rfc5280#section-4.1.2.7> or L<PKCS#1|https://tools.ietf.org/html/rfc2437>) or DER format), private keys (in PEM L<PKCS#1|https://tools.ietf.org/html/rfc2437> or DER format) and L<PKCS#10 Certificate Requests|https://tools.ietf.org/html/rfc2986> in PEM or DER format.

=head1 SUBROUTINES/METHODS

None.  This module only has the one exported function.

=head1 DIAGNOSTICS
 
=over
 
=item C<< Failed to open %s for reading >>
 
Failed to open the supplied X.509 Certificate, PKCS10 Certificate Request, Private or Public Key file
 
=item C<< Failed to read from %s >>
 
Failed to read from the X.509 Certificate, PKCS10 Certificate Request, Private or Public Key file

=item C<< %s is not an X.509 Certificate, PKCS10 Certificate Request, Private or Public Key >>
 
The supplied input file does not look like X.509 Certificate File, PKCS10 Certificate Request, Private or Public Key. These files may be encoded in PEM or DER format. A PEM encoded X.509 Certificate file has the following header

  -----BEGIN CERTIFICATE-----

A PEM encoded PKCS#10 Certificate Request has the following header

  -----BEGIN CERTIFICATE REQUEST-----

A PEM encoded PKCS#1 Public Key has the following header

  -----BEGIN RSA PUBLIC KEY-----

A PEM encoded PKCS#1 Private Key has the following header

  -----BEGIN RSA PRIVATE KEY-----

A PEM encoded SubjectPublicKeyInfo Public Key has the following header

  -----BEGIN PUBLIC KEY-----

=back
 
=head1 CONFIGURATION AND ENVIRONMENT
 
HTTP::PublicKeyPins requires no configuration files or environment variables.
 
=head1 DEPENDENCIES
 
HTTP::PublicKeyPins requires the following non-core modules
 
  Convert::ASN1
  Crypt::PKCS10
  Crypt::OpenSSL::RSA
  Crypt::OpenSSL::X509
  Digest
 
=head1 INCOMPATIBILITIES
 
None known.

=head1 SEE ALSO

=over

=item L<RFC 7469 - Public Key Pinning Extension for HTTP|http://tools.ietf.org/html/rfc7469>

=item L<X.509 Certificate|http://tools.ietf.org/html/rfc5280>

=item L<PKCS#1|https://tools.ietf.org/html/rfc2437>

=item L<PKCS#10|https://tools.ietf.org/html/rfc2986>

=back

=head1 AUTHOR

David Dick, C<< <ddick at cpan.org> >>

=head1 BUGS AND LIMITATIONS
 
Please report any bugs or feature requests to C<bug-http-publickeypins at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTTP-PublicKeyPins>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HTTP::PublicKeyPins

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTTP-PublicKeyPins>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HTTP-PublicKeyPins>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/HTTP-PublicKeyPins>

=item * Search CPAN

L<http://search.cpan.org/dist/HTTP-PublicKeyPins/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2015 David Dick.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. This program is distributed in the hope that 
it will be useful, but WITHOUT ANY WARRANTY; without even the implied 
warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
