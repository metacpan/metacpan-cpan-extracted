package Finance::Bank::Postbank_de::APIv1;
use Moo;
use JSON 'decode_json';
use Filter::signatures;
no warnings 'experimental::signatures';
use feature 'signatures';
use Carp 'croak';
use WWW::Mechanize;
use Mozilla::CA;
use HTTP::CookieJar::LWP;
use IO::Socket::SSL qw(SSL_VERIFY_PEER SSL_VERIFY_NONE);

use HAL::Resource;
use Finance::Bank::Postbank_de::APIv1::Finanzstatus;
use Finance::Bank::Postbank_de::APIv1::Message;
use Finance::Bank::Postbank_de::APIv1::Transaction;
use Finance::Bank::Postbank_de::APIv1::Account;
use Finance::Bank::Postbank_de::APIv1::Depot;
use Finance::Bank::Postbank_de::APIv1::Position;

our $VERSION = '0.55';

=head1 NAME

Finance::Bank::Postbank_de::APIv1 - Postbank connection

=head1 SYNOPSIS

    my $api = Finance::Bank::Postbank_de::APIv1->new();
    $api->configure_ua();
    my $postbank = $api->login( 'Petra.Pfiffig', '11111' );

=cut

#my $logger;
has ua => (
    is => 'ro',
    default => sub( $class ) {
        my $ua = WWW::Mechanize->new(
            autocheck  => 1,
            keep_alive => 1,
            cookie_jar => HTTP::CookieJar::LWP->new(),
        );
#use LWP::ConsoleLogger::Easy qw( debug_ua );
#$logger = debug_ua($ua);
#$logger->dump_content(0);
#$logger->dump_text(0);
        $ua
    }
);

has config => (
    is => 'rw',
);

has certificate_subject => (
    is => 'ro',
    default => sub {
        +{
                                    #/jurisdictionC=DE/jurisdictionST=Nordrhein-Westfalen/jurisdictionL=Bonn/businessCategory=Private Organization/serialNumber=HRB6793/C=DE/postalCode=53113/ST=Nordrhein-Westfalen/L=Bonn/street=Friedrich Ebert Allee 114 126/O=Deutsche Postbank AG/OU=PB Systems AG/CN=meine.postbank.de
            #meine_postbank_de => qr{^/(?:\Q1.3.6.1.4.1.311.60.2.1.3\E|jurisdictionC|jurisdictionCountryName)=DE/(?:\Q1.3.6.1.4.1.311.60.2.1.2\E|jurisdictionST|jurisdictionStateOrProvinceName)=Nordrhein-Westfalen/(?:\Q1.3.6.1.4.1.311.60.2.1.1\E|jurisdictionL|jurisdictionLocalityName)=Bonn/businessCategory=Private Organization/serialNumber=HRB6793/C=DE/postalCode=53113/ST=Nordrhein-Westfalen/L=Bonn/street=Friedrich Ebert Allee 114 126/O=Deutsche Postbank AG/OU=PB Systems AG/CN=meine.postbank.de$},
            api_public_postbank_de => qr{^/(?:\Q2.5.4.15\E|businessCategory)=Private Organization/(?:\Q1.3.6.1.4.1.311.60.2.1.3\E|jurisdictionC|jurisdictionCountryName)=DE/(?:\Q1.3.6.1.4.1.311.60.2.1.2\E|jurisdictionST|jurisdictionStateOrProvinceName)=Hessen/(?:\Q1.3.6.1.4.1.311.60.2.1.1\E|jurisdictionL|jurisdictionLocalityName)=Frankfurt am Main/serialNumber=HRB 47141/C=DE/ST=Nordrhein-Westfalen/L=Bonn/O=DB Privat- und Firmenkundenbank AG/OU=Postbank Systems AG/CN=bankapi-public.postbank.de$}
        },
    },
);

sub diagnoseCertificateError( $self, $error=$@ ) {
    my( $found, $re ) = ($error =~ m#'(.+?)' !~ /\Q(?^:\E(.+?)/ at #)
        or die "$error"; # reraise
    warn $found;
    warn $re;
    my @found_parts = split m!/!, $found;
    my @re_parts = split m!/!, $re;

    for my $i (0..$#re_parts ) {
        if( $found_parts[ $i ] =~ $re_parts[ $i ]) {
            warn "'$found_parts[ $i ]' =~ /$re_parts[ $i ]/, OK\n";
        } else {
            warn "'$found_parts[ $i ]' !~ /$re_parts[ $i ]/, not OK\n";
        };
    };
    die "Certificate mismatch";
}

sub fetch_config( $self ) {
    # Do an initial fetch to set up cookies
    my $ua = $self->ua;
    $self->configure_ua_ssl;
    #my $re = join "|", values %{ $self->certificate_subject };
    #$ua->add_header(
    #    "If-SSL-Cert-Subject" => qr/$re/,
    #);
    eval {
        $ua->get('https://meine.postbank.de');
        $ua->get('https://meine.postbank.de/configuration.json');
    };
    if( my $err = $@ ) {
        $self->diagnoseCertificateError( "$@ ");
    };
    my $config = decode_json( $ua->content );
    if( ! exists $config->{ 'iob5-base' }) {
        require Data::Dumper;
        croak "Invalid config retrieved: " . Data::Dumper::Dumper($config);
    };
    $self->config( $config );
    $config
}

sub configure_ua_ssl( $self, $ua=$self->ua ) {
    # OpenSSL 1.0.1 doesn't properly scan the certificate chain as supplied
    # by Mozilla::CA, so we only verify the certificate directly there:
    my @verify;

    if( IO::Socket::SSL->VERSION <= 1.990 ) {
        # No OCSP support
        @verify = ();
    } elsif( Net::SSLeay::SSLeay() <= 0x100010bf ) { # 1.0.1k
        @verify = (
            SSL_fingerprint => 'sha256$C0F407E7D1562B52D8896B4A00DFF538CBC84407E95D8E0A7E5BFC6647B98967',
            SSL_ocsp_mode => IO::Socket::SSL::SSL_OCSP_NO_STAPLE(),
        );
    } else {
        # We need no special additional options to verify the certificate chain
        @verify = (
            SSL_ocsp_mode => IO::Socket::SSL::SSL_OCSP_FULL_CHAIN(),
        );
    };
    $ua->ssl_opts(
        SSL_ca_file => Mozilla::CA::SSL_ca_file(),
        SSL_verify_mode => SSL_VERIFY_PEER(),
        @verify,
        #SSL_verify_callback => sub {
            #use Data::Dumper;
            #warn Dumper \@_;
            #return 1;
        #},
    );
};

sub configure_ua( $self, $config = $self->fetch_config ) {
    my $ua = $self->ua;

    $ua->add_header(
        'api-key' => $config->{'iob5-base'}->{apiKey},
        #'device-signature' => '494f423500225fd9',
        accept => ['application/hal+json', '*/*'],
        keep_alive => 1,
        #                            /                businessCategory =Private Organization/                                jurisdictionC                         =DE/                                jurisdictionST                                 =Hessen/                                jurisdictionL                          =Frankfurt am Main/serialNumber=HRB 47141/C=DE/ST=Nordrhein-Westfalen/L=Bonn/O=DB Privat- und Firmenkundenbank AG/OU=Postbank Systems AG/CN=(?:banking|bankapi-public).postbank.de
        "If-SSL-Cert-Subject" => $self->certificate_subject->{ api_public_postbank_de },
    );
};

sub login_url( $self ) {
    my $config = $self->config;
    my $loginUrl = $config->{'iob5-base'}->{loginUrl};
    $loginUrl =~ s!%(\w+)%!$config->{'iob5-base'}->{$1}!ge;
    $loginUrl
}

sub login( $self, $username, $password ) {
    my $ua = $self->ua;
    my $loginUrl = $self->login_url();

    my $r =
    $ua->post(
        $loginUrl,
        #content => sprintf 'dummy=value&password=%s&username=%s', $password, $username
        #content => sprintf 'password=%s&username=%s', $password, $username
        content => sprintf 'username=%s&password=%s', $username, $password
    );

    my $postbank = HAL::Resource->new(
        ua => $ua,
        %{ decode_json($ua->content)}
    );

};

1;

=head1 RESOURCE HIERARCHY

This is the hierarchy of the resources in the API:

    APIv1
        Finanzstatus
            BusinessPartner
                Account
                    Transaction
                    Message
                        Attachment
                    Depot

=head1 AUTHOR

Max Maischein, E<lt>corion@cpan.orgE<gt>

=head1 SEE ALSO

L<perl>, L<WWW::Mechanize>.

=head1 REPOSITORY

The public repository of this module is
L<https://github.com/Corion/Finance-Bank-Postbank_de>.

=head1 SUPPORT

The public support forum of this module is
L<https://perlmonks.org/>.

=head1 BUG TRACKER

Please report bugs in this module via the RT CPAN bug queue at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Finance-Bank-Postbank_de>
or via mail to L<finance-bank-postbank_de-Bugs@rt.cpan.org>.

=head1 COPYRIGHT (c)

Copyright 2003-2018 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut

