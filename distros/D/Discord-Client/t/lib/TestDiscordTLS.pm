package TestDiscordTLS;

use v5.26;
use warnings;
use Exporter 'import';
use File::Temp qw(tempdir);
use IO::Socket::SSL::Utils qw(CERT_create PEM_cert2file PEM_key2file CERT_free KEY_free);

our @EXPORT_OK = qw(certificate_directory);

sub certificate_directory {
    my ($certificate_ip) = @_;

    # Use a private CA so the client can test trust and hostname checks separately.
    my $directory = tempdir( CLEANUP => 1 );
    my ( $ca_certificate, $ca_key ) = CERT_create(
        subject => { commonName => 'Discord client test CA' },
        purpose => 'sslCA',
    );
    my ( $certificate, $key ) = CERT_create(
        issuer => [ $ca_certificate, $ca_key ],
        purpose => 'server',
        subject => { commonName => $certificate_ip },
        subjectAltNames => [ [ 'IP', $certificate_ip ] ],
        not_before => time() - 60,
        not_after => time() + 3600,
    );

    # Persist only the files consumed by the local client and server, then release OpenSSL objects.
    PEM_cert2file( $ca_certificate, "$directory/ca.pem" );
    PEM_cert2file( $certificate, "$directory/cert.pem" );
    PEM_key2file( $key, "$directory/key.pem" );
    CERT_free($_) for $certificate, $ca_certificate;
    KEY_free($_) for $key, $ca_key;
    return $directory;
}

1;
