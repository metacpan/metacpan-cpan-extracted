package Mail::Exim::ACL::Geolocation;

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.016;
use warnings;
use utf8;

our $VERSION = 1.001;

use Exporter qw(import);
use IP::Geolocation::MMDB;
use List::Util qw(first);

our @EXPORT_OK = qw(country_code);

our @DIRECTORIES = qw(
  /var/lib/GeoIP
  /usr/share/GeoIP
);

our @DATABASES = qw(
  GeoIP2-Country.mmdb
  GeoIP2-City.mmdb
  dbip-country.mmdb
  dbip-location.mmdb
  GeoLite2-Country.mmdb
  GeoLite2-City.mmdb
  dbip-country-lite.mmdb
  dbip-city-lite.mmdb
);

our $DATABASE = $ENV{IP_GEOLOCATION_MMDB} || first {-r} map {
  my $dir = $_;
  map {"$dir/$_"} @DATABASES
} @DIRECTORIES;

our $MMDB = eval { IP::Geolocation::MMDB->new(file => $DATABASE) };

sub country_code {
  my $ip_address = shift;

  return eval { $MMDB->getcc($ip_address) };
}

1;
__END__

=encoding UTF-8

=head1 NAME

Mail::Exim::ACL::Geolocation - Map IP addresses to country codes

=head1 VERSION

version 1.001

=head1 SYNOPSIS

  acl_check_rcpt:

    warn
      domains = +local_domains : +relay_to_domains
      set acl_m_country_code = ${perl{country_code}{$sender_host_address}}
      add_header = X-Sender-Host-Country: $acl_m_country_code

=head1 DESCRIPTION

A Perl module for the L<Exim|https://www.exim.org/> mailer that maps IP
addresses to two-letter country codes such as "DE", "FR" and "US".
SpamAssassin can use these country codes to filter junk email.

=head1 SUBROUTINES/METHODS

=head2 country_code

  my $country_code = country_code($ip_address);

Maps an IP address to a country.  Returns the country code or the undefined
value.

=head1 DIAGNOSTICS

None.

=head1 CONFIGURATION AND ENVIRONMENT

=head2 Exim

Create a file such as F</etc/exim/exim.pl>.  Add the following Perl code.

  use Mail::Exim::ACL::Geolocation qw(country_code);

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

=head2 SpamAssassin

Add a rule to your SpamAssassin configuration that increases the spam score if
the message is sent from a country that you usually don't get email from.

  bayes_ignore_header X-Sender-Host-Country

  header UNCOMMON_COUNTRY X-Sender-Host-Country !~ /^(?:DE|FR|US)/ [if-unset: US]
  describe UNCOMMON_COUNTRY Message is sent from uncommon country
  tflags UNCOMMON_COUNTRY noautolearn
  score UNCOMMON_COUNTRY 0.1

See L<https://en.wikipedia.org/wiki/ISO_3166-2> for a list of two-letter
country codes.  A useful list for businesses with contacts in Western Europe
and North America is:

  (?:AT|BE|CA|CH|DE|DK|ES|EU|FI|FR|GB|IE|IS|IT|LU|NL|NO|PT|SE|US)

Combine your new rule with other rules.

  meta SUSPICIOUS_BULKMAIL UNCOMMON_COUNTRY && (DCC_CHECK || RAZOR2_CHECK)
  describe SUSPICIOUS_BULKMAIL Bulk email from uncommon country
  tflags SUSPICIOUS_BULKMAIL net
  score SUSPICIOUS_BULKMAIL 1.5

=head1 DEPENDENCIES

Requires the Perl module L<IP::Geolocation::MMDB> from CPAN and the modules
L<Exporter> and L<List::Util>, which are distributed with Perl.

Requires an IP to country database in the MaxMind DB file format from
L<MaxMind|https://www.maxmind.com/> or L<DP-IP.com|https://db-ip.com/>.  The
module searches the directories F</var/lib/GeoIP> and F</usr/share/GeoIP> for
one of the following database files:

  GeoIP2-Country.mmdb
  GeoIP2-City.mmdb
  dbip-country.mmdb
  dbip-location.mmdb
  GeoLite2-Country.mmdb
  GeoLite2-City.mmdb
  dbip-country-lite.mmdb
  dbip-city-lite.mmdb

=head1 INCOMPATIBILITIES

None.

=head1 SEE ALSO

L<Mail::SpamAssassin::Conf>

=head1 AUTHOR

Andreas Vögele E<lt>voegelas@cpan.orgE<gt>

=head1 BUGS AND LIMITATIONS

None known.

=head1 LICENSE AND COPYRIGHT

Copyright 2022 Andreas Vögele

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
