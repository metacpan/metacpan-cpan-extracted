package IP::Country;
use IP::Country::Fast;
@IP::Country::ISA = qw ( IP::Country::Fast );
$IP::Country::VERSION = '2.28';
1;
__END__

=head1 NAME

IP::Country - fast lookup of country codes from IP addresses

=head1 SYNOPSIS

  use IP::Country::Fast;
  my $reg = IP::Country::Fast->new();
  print $reg->inet_atocc('212.67.197.128')   ."\n";
  print $reg->inet_atocc('www.slashdot.org') ."\n";
  print $reg->db_time() ."\n"; # revision date

=head1 DESCRIPTION

Finding the home country of a client using only the IP address can be difficult.
Looking up the domain name associated with that address can provide some help,
but many IP address are not reverse mapped to any useful domain, and the
most common domain (.com) offers no help when looking for country.

This module comes bundled with a database of countries where various IP addresses
have been assigned. Although the country of assignment will probably be the
country associated with a large ISP rather than the client herself, this is
probably good enough for most log analysis applications, and under test has proved
to be as accurate as reverse-DNS and WHOIS lookup.

=head1 CONSTRUCTOR

The constructor takes no arguments.

  use IP::Country::Fast;
  my $reg = IP::Country::Fast->new();

=head1 OBJECT METHODS

All object methods are designed to be used in an object-oriented fashion.

  $result = $object->foo_method($bar,$baz);

Using the module in a procedural fashion (without the arrow syntax) won't work.

=over 4

=item $cc = $reg-E<gt>inet_atocc(HOSTNAME)

Takes a string giving the name of a host, and translates that to an
two-letter country code. Takes arguments of both the 'rtfm.mit.edu' 
type and '18.181.0.24'. If the host name cannot be resolved, returns undef. 
If the resolved IP address is not contained within the database, returns undef.
For multi-homed hosts (hosts with more than one address), the first 
address found is returned. For private Internet addresses (see RFC1918), 
returns two asterisks '**'.

=item $cc = $reg-E<gt>inet_ntocc(IP_ADDRESS)

Takes a string (an opaque string as returned by Socket::inet_aton()) 
and translates it into a two-letter country code. If the IP address is 
not contained within the database, returns undef.

=item $cc = $reg-E<gt>db_time()

Returns the creation date of the database, measured as number of seconds 
since the Unix epoch (00:00:00 GMT, January 1, 1970). Suitable for feeding 
to "gmtime" and "localtime". When used with IP::Country::Medium or Slow objects,
returns zero.

=back

=head1 PERFORMANCE

With a random selection of 65,000 IP addresses, the module can look up
over 15,000 IP addresses per second on a 730MHz PIII (Coppermine) and
over 25,000 IP addresses per second on a 1.3GHz Athlon. Out of this random 
selection of IP addresses, 43% had an associated country code. Please let 
me know if you've run this against a set of 'real' IP addresses from your
log files, and have details of the proportion of IPs that had associated
country codes.

=head1 IP::Country::Slow warning

During tests of this module, it was found that there was no measurable advantage in using
this module in preference to IP::Country::Medium or IP::Country::Fast. You should
use IP::Country::Medium is the majority of your lookups are of the form 'rtfm.mit.edu'
(domain names), and IP::Country::Fast if the majority of your lookups are of the form
'18.181.0.24' (IP addresses).

IP::Country::Medium caches domain-name lookups, whereas IP::Country::Fast does not.

It is *very* rare for a domain-name lookup to differ from the database used by
IP::Country::Fast. Thus, there is no good reason to prefer a slow domain-name 
lookup to a fast database lookup. Nor is there any significant difference in
coverage between the domain-name system and database. If you can find a real reason
to use IP::Country::Slow, let me know.

=head1 COUNTRY CODES

You'll probably want some kind of country code -E<gt> country name conversion
utility: you should use L<Geography::Countries> from CPAN.

However, you should note the circumstances where the country code returned by
IP::Country will deviate from those used by L<Geography::Countries>:

  AP - non-specific Asia-Pacific location
  CS - Czechoslovakia (former)
  EU - non-specific European Union location
  FX - France, Metropolitan
  PS - Palestinian Territory, Occupied
  ** - intranet address
  undef - not in database

=head1 BUGS/LIMITATIONS

Only works with IPv4 addresses and ASCII hostnames.

=head1 SEE ALSO

L<IP::Country::Fast> - recommended for lookups of hostnames which are mostly
in the dotted-quad form ('213.45.67.89').

L<IP::Country::Medium> - recommended for lookups of hostnames which are mostly
in the domain-name form ('www.yahoo.com'). Caches domain-name lookups.

L<IP::Country::Slow> - NOT RECOMMENDED. Only included for completeness. Prefers
domain-name lookups to database lookups, which is an expensive strategy of
no benefit.

L<Geo::IP> - wrapper around the geoip C libraries. Less portable. Not measurably 
faster than these native Perl modules. Paid subscription required for database
updates.

L<http://www.apnic.net> - Asia pacific

L<http://www.ripe.net> - Europe

L<http://www.arin.net> - North America

L<http://www.lacnic.net> - Latin America

L<http://www.afrinic.net> - Africa and Indian Ocean

=head1 COPYRIGHT

Copyright (C) 2002-2005 Nigel Wetters Gourlay. All Rights Reserved.

NO WARRANTY. This module is free software; you can redistribute 
it and/or modify it under the same terms as Perl itself.

Some parts of this software distribution are derived from the APNIC,
LACNIC, ARIN, AFRINIC and RIPE databases (copyright details below).
I am not a lawyer, so please direct questions about the RIR's 
licenses to them, not me.

=head1 APNIC conditions of use

The files are freely available for download and use on the condition 
that APNIC will not be held responsible for any loss or damage 
arising from the application of the information contained in these 
reports.

APNIC endeavours to the best of its ability to ensure the accuracy 
of these reports; however, APNIC makes no guarantee in this regard.

In particular, it should be noted that these reports seek to 
indicate the country where resources were first allocated or 
assigned. It is not intended that these reports be considered 
as an authoritative statement of the location in which any specific 
resource may currently be in use.

=head1 ARIN database copyright

Copyright (c) American Registry for Internet Numbers. All rights reserved.

The ARIN WHOIS data is for Internet operational or technical research
purposes pertaining to Internet operations only.  It may not be used for
advertising, direct marketing, marketing research, or similar purposes.
Use of the ARIN WHOIS data for these activities is explicitly forbidden.
ARIN requests to be notified of any such activities or suspicions thereof.

=head1 RIPE database copyright

The information in the RIPE Database is available to the public 
for agreed Internet operation purposes, but is under copyright.
The copyright statement is:

"Except for agreed Internet operational purposes, no part of this 
publication may be reproduced, stored in a retrieval system, or transmitted, 
in any form or by any means, electronic, mechanical, recording, or 
otherwise, without prior permission of the RIPE NCC on behalf of the 
copyright holders. Any use of this material to target advertising 
or similar activities is explicitly forbidden and may be prosecuted. 
The RIPE NCC requests to be notified of any such activities or 
suspicions thereof."

=head1 LACNIC database copyright

Copyright (c) Latin American and Caribbean IP address Regional Registry. All rights reserved.

=head1 AFRINIC copyright

Seems to be the RIPE copyright. I'm sure they'll correct this in due course.

=cut
