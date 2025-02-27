package Mail::Exim::ACL::Geolocation;

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.016;
use warnings;
use utf8;

our $VERSION = 1.005;

use Exporter qw(import);
use IP::Geolocation::MMDB;

our @EXPORT_OK = qw(country_code asn_lookup);

my @directories = qw(
    /var/lib/GeoIP
    /usr/local/share/GeoIP
    /usr/share/GeoIP
    /opt/share/GeoIP
    /var/db/GeoIP
);

my @country_databases = qw(
    GeoIP2-Country.mmdb
    GeoIP2-City.mmdb
    dbip-country.mmdb
    dbip-city.mmdb
    GeoLite2-Country.mmdb
    GeoLite2-City.mmdb
    dbip-country-lite.mmdb
    dbip-city-lite.mmdb
);

my @asn_databases = qw(
    GeoIP2-ASN.mmdb
    dbip-asn.mmdb
    GeoLite2-ASN.mmdb
    dbip-asn-lite.mmdb
);

my $country_reader = eval {
    my $filename = $ENV{COUNTRY_DB}
        || _first_database(\@directories, \@country_databases);
    IP::Geolocation::MMDB->new(file => $filename);
};

my $asn_reader = eval {
    my $filename = $ENV{ASN_DB}
        || _first_database(\@directories, \@asn_databases);
    IP::Geolocation::MMDB->new(file => $filename);
};

sub country_code {
    my $ip_address = shift;

    return eval { $country_reader->getcc($ip_address) };
}

sub asn_lookup {
    my $ip_address = shift;

    my $asn_tag;
    my $asn = eval { $asn_reader->record_for_address($ip_address) };
    if (defined $asn) {
        my $number = $asn->{autonomous_system_number};
        if (defined $number) {
            $asn_tag = $number;
            my $organization = $asn->{autonomous_system_organization};
            if (defined $organization) {
                $asn_tag .= q{ } . $organization;
            }
        }
    }
    return $asn_tag;
}

sub _first_database {
    my ($directories, $databases) = @_;

    for my $dir (@{$directories}) {
        for my $db (@{$databases}) {
            my $filename = $dir . q{/} . $db;
            if (-r $filename) {
                return $filename;
            }
        }
    }
    return;
}

1;
__END__

=encoding UTF-8

=head1 NAME

Mail::Exim::ACL::Geolocation - Map IP addresses to location information

=head1 VERSION

version 1.005

=head1 SYNOPSIS

  acl_check_rcpt:

    warn
      domains = +local_domains : +relay_to_domains

      set acl_m_country_code = ${perl{country_code}{$sender_host_address}}
      add_header = X-Sender-Host-Country: $acl_m_country_code

      set acl_m_asn = ${perl{asn_lookup}{$sender_host_address}}
      add_header = X-Sender-Host-ASN: $acl_m_asn

=head1 DESCRIPTION

A Perl module for the Exim mailer that maps IP addresses to country codes and
Autonomous Systems.  Spam filters can use this information to filter junk
email.

=head1 SUBROUTINES/METHODS

=head2 country_code

  my $country_code = country_code($ip_address);

Maps an IP address to a country.  Returns a two-letter country code or the
undefined value.

=head2 asn_lookup

  my $asn = asn_lookup($ip_address);

Maps an IP address to an Autonomous System.  Returns the Autonomous System
number and organization or the undefined value.

=head1 DIAGNOSTICS

None.

=head1 CONFIGURATION AND ENVIRONMENT

=head2 Exim

Create a file such as F</etc/exim/exim.pl>.  Add the following Perl code.

  use Mail::Exim::ACL::Geolocation qw(country_code asn_lookup);

Edit Exim's configuration file.  Enable Perl in the main section.

  perl_startup = do '/etc/exim/exim.pl'
  perl_taintmode = yes

Get the sending host's country code in the RCPT ACL.  Add the country code to
the message header.

  acl_check_rcpt:

    warn
      domains = +local_domains : +relay_to_domains

      set acl_m_country_code = ${perl{country_code}{$sender_host_address}}
      add_header = X-Sender-Host-Country: $acl_m_country_code

      set acl_m_asn = ${perl{asn_lookup}{$sender_host_address}}
      add_header = X-Sender-Host-ASN: $acl_m_asn

=head2 SpamAssassin

Add a rule to your SpamAssassin configuration that increases the spam score if
the message is sent from a country that you usually don't get email from.

  bayes_ignore_header X-Sender-Host-Country

  header UNCOMMON_COUNTRY X-Sender-Host-Country !~ /^(?:DE|FR|US)/ [if-unset: US]
  describe UNCOMMON_COUNTRY Message is sent from uncommon country
  tflags UNCOMMON_COUNTRY noautolearn
  score UNCOMMON_COUNTRY 0.1

See L<https://en.wikipedia.org/wiki/ISO_3166-2> for a list of country codes.
A useful list for businesses with contacts in Western Europe and North America
is:

  (?:AT|BE|CA|CH|DE|DK|ES|EU|FI|FR|GB|IE|IS|IT|LU|NL|NO|PT|SE|US)

Combine your new rule with other rules.

  meta SUSPICIOUS_BULKMAIL UNCOMMON_COUNTRY && (DCC_CHECK || RAZOR2_CHECK)
  describe SUSPICIOUS_BULKMAIL Bulk email from uncommon country
  tflags SUSPICIOUS_BULKMAIL net
  score SUSPICIOUS_BULKMAIL 1.5

=head1 DEPENDENCIES

Requires the Perl module L<IP::Geolocation::MMDB> from CPAN.

Requires geolocation databases in the MaxMind DB file format from
L<MaxMind|https://www.maxmind.com/> or L<DP-IP.com|https://db-ip.com/>.  The
module searches the directories F</var/lib/GeoIP>, F</usr/local/share/GeoIP>,
F</usr/share/GeoIP>, F</opt/share/GeoIP> and F</var/db/GeoIP> for the
following database files:

  GeoIP2-Country.mmdb
  GeoIP2-City.mmdb
  dbip-country.mmdb
  dbip-city.mmdb
  GeoLite2-Country.mmdb
  GeoLite2-City.mmdb
  dbip-country-lite.mmdb
  dbip-city-lite.mmdb

  GeoIP2-ASN.mmdb
  dbip-asn.mmdb
  GeoLite2-ASN.mmdb
  dbip-asn-lite.mmdb

=head1 INCOMPATIBILITIES

None.

=head1 BUGS AND LIMITATIONS

None known.

=head1 SEE ALSO

L<Mail::SpamAssassin::Conf>

=head1 AUTHOR

Andreas Vögele E<lt>voegelas@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2025 Andreas Vögele

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
