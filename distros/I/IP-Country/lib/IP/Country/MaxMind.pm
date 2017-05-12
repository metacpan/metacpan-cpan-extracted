package IP::Country::MaxMind;
use strict;
use warnings;
use Socket qw ( inet_ntoa );

use vars qw ( @ISA $VERSION @EXPORT );
require Exporter;

$VERSION = 1.0;

@ISA = qw( Exporter );
@EXPORT = qw( GEOIP_STANDARD GEOIP_MEMORY_CACHE GEOIP_CHECK_CACHE );

my $MM;
BEGIN
{
    eval 'use Geo::IP';
    if($@){
	eval 'use Geo::IP::PurePerl';
	if($@){
	    die($@);
	} else {
	    $MM = 'Geo::IP::PurePerl';
	}
    } else {
	$MM = 'Geo::IP';
    }
}

my $ip_match = qr/^(\d|[01]?\d\d|2[0-4]\d|25[0-5])\.(\d|[01]?\d\d|2[0-4]\d|25[0-5])\.(\d|[01]?\d\d|2[0-4]\d|25[0-5])\.(\d|[01]?\d\d|2[0-4]\d|25[0-5])$/o;

sub new
{
    my($caller,$flags) = @_;
    my $class = ref($caller) || $caller;
    $flags = GEOIP_STANDARD unless (defined $flags);
    my $gi;
    eval "\$gi = $MM->new(\$flags)";
    die($@) if $@;
    bless \$gi,$class;
}

sub open
{
    my($caller,$database_filename,$flags) = @_;
    my $class = ref($caller) || $caller;
    $flags = GEOIP_STANDARD unless (defined $flags);
    my $gi;
    eval "\$gi = $MM->open(\$database_filename,\$flags)";
    die($@) if $@;
    bless \$gi,$class;
}

sub inet_atocc
{
    my ($gi,$host) = (${$_[0]},$_[1]);
    if($host=~$ip_match){
	return $gi->country_code_by_addr($host);
    } else {
	return $gi->country_code_by_name($host);
    }
}

sub inet_ntocc
{
    return ${$_[0]}->country_code_by_addr(inet_ntoa($_[1]));
}

sub db_time
{
    return 0;
}

1;
__END__

=head1 NAME

IP::Country::MaxMind - Look up country by IP Address

=head1 SYNOPSIS

  use IP::Country::MaxMind;

  my $gi = IP::Country::MaxMind->new(GEOIP_STANDARD);

  # look up IP address '65.15.30.247'
  # returns undef if country is unallocated, or not defined in our database
  my $cc1 = $gi->inet_atocc('65.15.30.247');
  my $cc2 = $gi->inet_atocc('yahoo.com');

=head1 DESCRIPTION

This module adapts the Geo::IP module to use the same interface as the IP::Country
modules; thus allowing users to easily switch between using the two underlying
databases.

=head1 DATABASE UPDATES

Free monthly updates to the database are available from 

  http://www.maxmind.com/download/geoip/database/

If you require greater accuracy, MaxMind offers a Premium database on a paid 
subscription basis.

The author of this module is in no way associated with MaxMind.

=head1 CLASS METHODS

=over 4

=item $gi = IP::Country::MaxMind-E<gt>new( $flags );

Constructs a new IP::Country::MaxMind object with the default database located 
inside your system's I<datadir>, typically I</usr/local/share/GeoIP/GeoIP.dat>.

Flags can be set to either GEOIP_STANDARD, or for faster performance
(at a cost of using more memory), GEOIP_MEMORY_CACHE.  When using memory
cache you can force a reload if the file is updated by setting GEOIP_CHECK_CACHE.

=item $gi = IP::Country::MaxMind-E<gt>open( $database_filename, $flags );

Constructs a new Geo::IP object with the database located at C<$database_filename>.

=back

=head1 OBJECT METHODS

All object methods are designed to be used in an object-oriented fashion.

  $result = $object->foo_method($bar,$baz);

Using the module in a procedural fashion (without the arrow syntax) won't work.

=over 4

=item $cc = $gi-E<gt>inet_atocc(HOSTNAME)

Takes a string giving the name of a host, and translates that to an
two-letter country code. Takes arguments of both the 'rtfm.mit.edu' 
type and '18.181.0.24'. If the host name cannot be resolved, returns undef. 
If the resolved IP address is not contained within the database, returns undef.

=item $cc = $gi-E<gt>inet_ntocc(IP_ADDRESS)

Takes a string (an opaque string as returned by Socket::inet_aton()) 
and translates it into a two-letter country code. If the IP address is 
not contained within the database, returns undef.

=item $cc = $gi-E<gt>db_time()

Returns zero. For compatibility only.

=back


=head1 COPYRIGHT

Copyright (C) 2002,2003 Nigel Wetters Gourlay. All Rights Reserved.

NO WARRANTY. This module is free software; you can redistribute 
it and/or modify it under the same terms as Perl itself.

=cut
