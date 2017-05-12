#!/usr/bin/perl
package Mail::SpamCannibal::WhoisIP;

# fix up the whois routine to get the stuff we want
BEGIN {
  use vars qw($old_d_q $lastresp);
  use Net::Whois::IP;
  $old_d_q = \&Net::Whois::IP::_do_query;
}

{ no warnings;
  eval {
    sub Net::Whois::IP::_do_query {
      my @rv = &$old_d_q(@_);
      $lastresp = $rv[0];
      return @rv;
    }
  }
}

use strict;
#use diagnostics;
use vars qw($VERSION @ISA @EXPORT_OK);
require Exporter;
@ISA = qw(Exporter);

$VERSION = do { my @r = (q$Revision: 0.02 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

@EXPORT_OK = qw(
	whoisip_query
	whoisIP
);

=head1 NAME

Mail::SpamCannibal::WhoisIP - IP address whois service

=head1 SYNOPSIS

  use Mail::SpamCannibal::WhoisIP qw(
	whoisip_query
	whoisIP
  );

  $response = whoisip_query($ip);
  $response = whoisip_query( $ip,"true");
  $response = whoisIP($ip);
  @response = whoisIP($ip);
  
=head1 DESCRIPTION

B<Mail::SpamCannibal::WhoisIP> provides utilities to look up an IP address
and return the ownership information as a text string. In addition it
provides form and script generation service for web pages.

=over 4

=item * $response = whoisip_query($ip,$flag);

This function is exported directly from Net::Whois::IP. This description is
from version 0.35 of that module.

if $optional_flag is not null, all possible responses for a given record will be returned
for example, normally only the last instance of Tech phone will be give if record
contains more than one, however, setting this flag to a not null
will return both is an array.
The other consequence, is that all records returned become references to an array and must be
dereferenced to utilize. 

Normal unwrap of $response ($optional_flag not set)

  my $response = whoisip_query($ip);
  foreach (sort keys(%{$response}) ) {
    print "$_ $response->{$_} \n";
  }
       
$optional_flag set to a value 

  my $response = whoisip_query( $ip,"true");
  foreach ( sort keys %$response ){
    print "$_ is\n";
    foreach ( @{$response->{$_}}) {
      print "  $_\n";
    }
  }

=cut

*whoisip_query = \&Net::Whois::IP::whoisip_query;

=item * $response=whiosIP($ip); or @response=whoisIP($ip);

This function returns a text string or array of text lines which is the
response (or last response if there were multiple records) from the 
authoratitive server for the IP address of interest.

Returns an array containing a null or a null text string on error 
or if called with no $IP or an invalid $IP.

  input:	dotquad IP address
  returns:	text string or
		text array dependent
		on calling context

=back

=cut

sub whoisIP {
  my $ip = shift;
  $lastresp = [''];
  if ($ip && $ip =~ /^\d+\.\d+\.\d+\.\d+$/) {
    eval { whoisip_query($ip)};
  }
  if ($@) {
    @$lastresp = ('could not connect to whois server, try again later');
  }
  if (wantarray) {
    return @$lastresp;
  } else {
    return join('',@$lastresp);
  }
}

=head1 DEPENDENCIES

	Net::Whois::IP 0.35
  
=head1 EXPORT_OK

	whoisip_query
	whoisIP

=head1 COPYRIGHT

Copyright 2003, Michael Robinton <michael@bizsystems.com>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or 
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of 
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the  
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

=head1 AUTHOR

Michael Robinton <michael@bizsystems.com>

=cut

1;
