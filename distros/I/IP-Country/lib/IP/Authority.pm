package IP::Authority;
use strict;
use warnings;
use Socket qw ( inet_aton );

use vars qw ( $VERSION );
$VERSION = '1305.001'; # MAY 2013, version 0.01

my $singleton = undef;
my $ip_db;
my $null = substr(pack('N',0),0,1);
my $nullnullnull = $null . $null . $null;
my %auth;
my $ip_match = qr/^(\d|[01]?\d\d|2[0-4]\d|25[0-5])\.(\d|[01]?\d\d|2[0-4]\d|25[0-5])\.(\d|[01]?\d\d|2[0-4]\d|25[0-5])\.(\d|[01]?\d\d|2[0-4]\d|25[0-5])$/o;

my $bit0;
my $bit1;
my @mask;
my @dtoc;
{
    $bit0 = substr(pack('N',2 ** 31),0,1);
    $bit1 = substr(pack('N',2 ** 30),0,1);

    for (my $i = 0; $i <= 31; $i++){
	$mask[$i] = pack('N',2 ** (31 - $i));
    }

    for (my $i = 0; $i <= 255; $i++){
	$dtoc[$i] = substr(pack('N',$i),3,1);
    }
    (my $module_dir = __FILE__) =~ s/\.pm$//;

    local $/;   # set it so <> reads all the file at once

    open (AUTH, "< $module_dir/auth.gif")
	or die ("couldn't read authority database: $!");
    binmode AUTH;
    my $auth_ultra = <AUTH>;  # read in the file
    close AUTH;
    my $auth_num = (length $auth_ultra) / 3;
    for (my $i = 0; $i < $auth_num; $i++){
	my $auth = substr($auth_ultra,3 * $i + 1,2);
	$auth = undef if ($auth eq '--');
	$auth{substr($auth_ultra,3 * $i,1)} = $auth;
    }

    open (IP, "< $module_dir/ipauth.gif")
	or die ("couldn't read IP database: $!");
    binmode IP;
    $ip_db = <IP>;
    close IP;
}

sub new ()
{
    my $caller = shift;
    unless (defined $singleton){
        my $class = ref($caller) || $caller;
	$singleton = bless {}, $class;
    }
    return $singleton;
}

sub inet_atoauth
{
    my $inet_a = $_[1];
    if ($inet_a =~ $ip_match){
	return inet_ntoauth($dtoc[$1].$dtoc[$2].$dtoc[$3].$dtoc[$4]);
    } else {
	if (defined (my $n = inet_aton($inet_a))){
	    return inet_ntoauth($n);
	} else {
	    return undef;
	}
    }
}

sub db_time
{
    return unpack("N",substr($ip_db,0,4));
}

sub inet_ntoauth
{
    my $inet_n = $_[1] || $_[0];

    my $pos = 4;
    my $byte_zero = substr($ip_db,$pos,1);
    # loop through bits of IP address
    for (my $i = 0; $i <= 31; $i++){

	if (($inet_n & $mask[$i]) eq $mask[$i]){
	    # bit[$i] is set [binary one]
	    # - jump to next node
	    # (start of child[1] node)
	    if (($byte_zero & $bit1) eq $bit1){
		$pos = $pos + 1 + unpack('N', $nullnullnull . ($byte_zero ^ $bit1));
	    } else {
		$pos = $pos + 3 + unpack('N', $null . substr($ip_db,$pos,3));
	    }
	} else {
	    # bit[$i] is unset [binary zero]
	    # jump to end of this node
	    # (start of child[0] node)
	    if (($byte_zero & $bit1) eq $bit1){
		$pos = $pos + 1;
	    } else {
		$pos = $pos + 3;
	    }
	}
	
	# all terminal nodes of the tree start with zeroth bit 
	# set to zero. the first bit can then be used to indicate
	# whether we're using the first or second byte to store the
	# country code
	$byte_zero = substr($ip_db,$pos,1);
	if (($byte_zero & $bit0) eq $bit0){ # country code
	    if (($byte_zero & $bit1) eq $bit1){
		# unpopular country code - stored in second byte
		return $auth{substr($ip_db,$pos+1,1)};
	    } else {
		# popular country code - stored in bits 2-7
		# (we already know that bit 1 is not set, so
		# just need to unset bit 1)
		return $auth{$byte_zero ^ $bit0};
	    }
	}
    }
}

1;
__END__

=head1 NAME

IP::Authority - fast lookup of authority by IP address

=head1 SYNOPSIS

  use IP::Authority;
  my $reg = IP::Authority->new();
  print $reg->inet_atoauth('212.67.197.128')   ."\n";
  print $reg->inet_atoauth('www.slashdot.org') ."\n";

=head1 DESCRIPTION

Historically, the former InterNIC  managed (under the auspices of IANA)
the allocation of IP numbers to ISPs and other organizations. This changed
somewhat when the Regional Internet Registry system was started, with the
creation of three (and later, four) Regional Internet Registries (RIRs)
around the world, each managing the allocation of IP addresses to 
organizations within differing physical areas (see also RFC2050).

This means that there is no central whois database for IP numbers.

This module allows the user to lookup the RIR who has authority for a 
particular IP address. After finding out the authority for an IP address,
it is possible to use the authority's whois server to lookup the netblock owner.

=head1 CONSTRUCTOR

The constructor takes no arguments.

  use IP::Authority;
  my $reg = IP::Authority->new();

=head1 OBJECT METHODS

All object methods are designed to be used in an object-oriented fashion.

  $result = $object->foo_method($bar,$baz);

Using the module in a procedural fashion (without the arrow syntax) won't work.

=over 4

=item $auth = $reg-E<gt>inet_atoauth(HOSTNAME)

Takes a string giving the name of a host, and translates that to an
two-letter string representing the regional Internet registry that has authority
of that IP address:

  AR = ARIN (North America)
  RI = RIPE (Europe)
  LA = LACNIC (Latin America)
  AP = APNIC (Asia-Pacific)
  AF = AFRINIC (Africa and Indian Ocean)
  IA = IANA (see RFC3330)
  
Takes arguments of both the 'rtfm.mit.edu' type and '18.181.0.24'. If the 
host name cannot be resolved, returns undef. If the resolved IP address is not 
contained within the database, returns undef. For multi-homed hosts (hosts 
with more than one address), the first address found is returned.

=item $auth = $reg-E<gt>inet_ntoauth(IP_ADDRESS)

Takes a string (an opaque string as returned by Socket::inet_aton()) 
and translates it into a two-letter string representing the regional Internet 
registry that has authority of that IP address:

  AR = ARIN (North America)
  RI = RIPE (Europe)
  LA = LACNIC (Latin America)
  AP = APNIC (Asia-Pacific)
  AF = AFRINIC (Africa and Indian Ocean)
  IA = IANA (see RFC3330)
  
If the IP address is not contained within the database, returns undef.

=item $t = $reg-E<gt>db_time()

Returns the creation date of the database, measured as number of seconds 
since the Unix epoch (00:00:00 GMT, January 1, 1970). Suitable for feeding 
to "gmtime" and "localtime".

=back

=head1 BUGS/LIMITATIONS

Only works with IPv4 addresses and ASCII hostnames.

=head1 SEE ALSO

L<IP::Country> - fast lookup of country codes from IP address.

L<http://www.apnic.net> - Asia-Pacific

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
