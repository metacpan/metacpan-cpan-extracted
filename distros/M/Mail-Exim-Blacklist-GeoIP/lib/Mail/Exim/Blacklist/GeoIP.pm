package Mail::Exim::Blacklist::GeoIP;

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.016;
use warnings;
use utf8;

our $VERSION = 1.001;

use Exporter qw(import);
use MaxMind::DB::Reader;
use List::Util qw(first);

our @EXPORT_OK = qw(geoip_country_code);

our @DIRECTORIES = qw(
  /var/lib/GeoIP
  /usr/share/GeoIP
);

our @DATABASES = qw(
  dbip-country.mmdb
  GeoIP2-Country.mmdb
  dbip-country-lite.mmdb
  GeoLite2-Country.mmdb
);

our $DATABASE = $ENV{GEOIP_COUNTRY} || first {-r} map {
  my $dir = $_;
  map {"$dir/$_"} @DATABASES
} @DIRECTORIES;

our $GEOIP_READER = eval { MaxMind::DB::Reader->new(file => $DATABASE) };

sub geoip_country_code {
  my $ip_address = shift;

  my $code = eval {
    $GEOIP_READER->record_for_address($ip_address)->{country}->{iso_code};
  };

  return $code;
}

1;
__END__

=encoding UTF-8

=head1 NAME

Mail::Exim::Blacklist::GeoIP - Map IP addresses to country codes

=head1 VERSION

version 1.001

=head1 SYNOPSIS

  acl_check_rcpt:

    warn
      domains = +local_domains : +relay_to_domains
      set acl_m_country_code = ${perl{geoip_country_code}{$sender_host_address}}
      add_header = X-Sender-Host-Country: $acl_m_country_code

    accept

=head1 DESCRIPTION

A Perl module for the Exim mailer that maps IP addresses to two-letter country
codes such as "DE", "FR" and "US".  SpamAssassin can use these country codes
to filter junk e-mail.

=head1 SUBROUTINES/METHODS

=head2 geoip_country_code

  my $country_code = geoip_country_code($ip_address);

Maps an IP address to a country.  Returns the country code or the undefined
value.

=head1 DIAGNOSTICS

None.

=head1 CONFIGURATION AND ENVIRONMENT

Create a file such as F</etc/exim/exim.pl>.  Add the following Perl code.

  use Mail::Exim::Blacklist::GeoIP qw(geoip_country_code);

Edit Exim's configuration file.  Enable Perl in the main section.

  perl_startup = do '/etc/exim/exim.pl'
  perl_taintmode = yes

Get the sending host's country code in the RCPT ACL.  Add the country code to
the message header.

  acl_check_rcpt:

    warn
      domains = +local_domains : +relay_to_domains
      set acl_m_country_code = ${perl{geoip_country_code}{$sender_host_address}}
      add_header = X-Sender-Host-Country: $acl_m_country_code

    accept

Add a rule to your SpamAssassin configuration that increases the spam score if
the message is sent from a country that is not whitelisted.

  bayes_ignore_header X-Sender-Host-Country

  header UNCOMMON_COUNTRY X-Sender-Host-Country !~ /^(?:DE|FR|US)/ [if-unset: US]
  describe UNCOMMON_COUNTRY Message is sent from non-whitelisted country
  tflags UNCOMMON_COUNTRY noautolearn
  score UNCOMMON_COUNTRY 0.1

See L<https://en.wikipedia.org/wiki/ISO_3166-2> for a list of two-letter
country codes.  A useful list for businesses with contacts in Western Europe
and North America is:

  (?:AT|BE|CA|CH|DE|DK|ES|EU|FI|FR|GB|IE|IS|IT|LU|NL|NO|PT|SE|US)

Combine your new rule with other rules.

  meta SUSPICIOUS_BULKMAIL UNCOMMON_COUNTRY && (DCC_CHECK || RAZOR2_CHECK)
  describe SUSPICIOUS_BULKMAIL Fuzzy checksum and from non-whitelisted country
  tflags SUSPICIOUS_BULKMAIL net
  score SUSPICIOUS_BULKMAIL 1.5

=head1 DEPENDENCIES

Requires the Perl module MaxMind::DB::Reader from CPAN and the modules
Exporter and List::Util, which are distributed with Perl.

Requires an IP to country database in the MMDB format from
L<https://db-ip.com/> or L<https://www.maxmind.com/>.  The module searches the
directories F</var/lib/GeoIP> and F</usr/share/GeoIP> for one of the following
database files:

  dbip-country.mmdb
  GeoIP2-Country.mmdb
  dbip-country-lite.mmdb
  GeoLite2-Country.mmdb

=head1 INCOMPATIBILITIES

None.

=head1 SEE ALSO

L<Mail::SpamAssassin::Conf>

=head1 AUTHOR

Andreas Vögele E<lt>voegelas@cpan.orgE<gt>

=head1 BUGS AND LIMITATIONS

None known.

=head1 LICENSE AND COPYRIGHT

Copyright 2021 Andreas Vögele

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
