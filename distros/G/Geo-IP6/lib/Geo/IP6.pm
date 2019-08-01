package Geo::IP6;

use 5.006;
use strict;
use warnings;

=head1 NAME

Geo::IP6 - get country code for an ipv6 or ipv4 address 

=head1 VERSION

Version 1.0 

=head1 SYNOPSIS

	use Geo::IP6;

	my $geo = Geo::IP6->new();                      # default currently uses maxmind GeoLite2
	my $geo = Geo::IP->new(db => 'software77');	# use software77 db 

	say $geo->cc("217.31.205.50");                  # returns country code CZ 
	say $geo->cc("2001:1488:0:3::2");               # returns country code CZ 

Hint: ipv6 network prefixes are sorted by network count internally for performance reasons, which may result in incorrect lookups.
Currently (2019-07-01) there is only one minor overlap (2001:1c00::/22,ZZ vs 2001:1c00::/23,NL) in software77 and none in GeoLite2
ipv6db. If you want to avoid this condition use C<< $geo->cc_exact() >> for ipv6 addresses. There is no cc_exact for ipv4 which is
not affected. 

	say $geo->cc("2001:1c00::1");                   # returns country code ZZ
	say $geo->cc_exact("2001:1c00::1");             # returns country code NL 

=head1 DESCRIPTION 

This module provides functions to get the country code for ipv6 and ipv4 addresses
using IPV6 CIDR and IPV4 RANGE files in csv format provided by http://software77.net/faq.html#automated
and https://dev.maxmind.com/geoip/geoip2/geolite2/

It depends on LMDB_FILE for internal storage and should run on 32bit and 64bit sytems as the databases
are quite small (around 6MB each). LMDB is not platform independent and may not be portable. You can
use the geoip6 cmdline tool to recreate all databases.

Initial setup:
If there are no geoip4-maxmind.lmdb/geoip4-software77.lmdb and geoip6-*.lmdb files in /usr/share/geoip6/ 
create them with the geoip6 cmdline tool:

	geoip6 update_maxmind

	geoip6 update_db4_software77
	geoip6 update_db6_software77

=head1 EXPORT

This module does not export any functions

=cut

our $VERSION = '1.0';

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw();
# our @EXPORT_OK = qw();

use Socket qw(inet_pton inet_ntop AF_INET6 AF_INET);
use LMDB_File qw(:flags :cursor_op);

our @cidr6;
our @cidr6_exact;
our $ip4db_file_software77 = '/usr/share/geoip6/geoip4-software77.lmdb';
our $ip4db_file_maxmind = '/usr/share/geoip6/geoip4-maxmind.lmdb';
our $ip4db_url_software77 = 'http://software77.net/geo-ip/?DL=1';
our $ip4db_url_maxmind = 'https://geolite.maxmind.com/download/geoip/database/GeoLite2-Country-CSV.zip';
our $ip4db_size = 32 * 1024 * 1024;
our $ip6db_file_software77 = '/usr/share/geoip6/geoip6-software77.lmdb';
our $ip6db_file_maxmind = '/usr/share/geoip6/geoip6-maxmind.lmdb';
our $ip6db_url_software77 = 'http://software77.net/geo-ip/?DL=9';
our $ip6db_url_maxmind = 'https://geolite.maxmind.com/download/geoip/database/GeoLite2-Country-CSV.zip';
our $ip6db_size = 32 * 1024 * 1024;
our $ip4db_file;
our $ip6db_file;
our %opt; 

our %ip6db;
our $ip4env;


=head1 SUBROUTINES/METHODS

=cut


sub int_ip4 ($) {
	return join '.', unpack 'C4', pack 'N', $_[0];
}

sub ip4_int ($) {
	return unpack('N', inet_pton(AF_INET, $_[0]));
}

sub v4country_init {

	$ip4env = LMDB::Env->new($ip4db_file, { mapsize => 32 * 1024 * 1024, maxdbs => 1, maxreaders => 128, mode => 0644, flags => MDB_NOSUBDIR|MDB_RDONLY });
	if($opt{'debug'}){
		if($ip4env){ print "Loaded database $ip4db_file\n"; }
		else { print "Failed to load database $ip4db_file\n"; }
	}
	return undef if !$ip4env;
	return 1;
}

sub v4country ($) {

	my $ip4 = shift || return undef;
	my $ipnum = ip4_int($ip4);

        my $txn = $ip4env->BeginTxn();
        my $db = $txn->OpenDB({ dbname => undef, flags => MDB_INTEGERKEY});
	my $cursor = $db->Cursor;
	my ($dbkey, $dbkey_ip4, $dbdata, $dbkey_last, $dbkey_last_ip4, $cc);

	$dbkey = $ipnum;
	$cursor->get($dbkey, $dbdata, MDB_SET_RANGE);
	return undef if !$dbkey;

	($dbkey_last, $cc) = split(/;/, $dbdata);
	$dbkey_ip4 = int_ip4($dbkey);
	$dbkey_last_ip4 = int_ip4($dbkey_last);

	print "ip4:$ip4 = $ipnum,  dbkey:$dbkey = $dbkey_ip4, dbkey_last:$dbkey_last = $dbkey_last_ip4, cc:$cc\n" if $opt{'debug'}; 
	
	if($ipnum eq $dbkey){
		my($net_last,$cc) = split(/;/, $dbdata);
		return $cc;
	}

	($dbkey, $dbkey_ip4, $dbdata, $dbkey_last, $dbkey_last_ip4, $cc) = undef;
	$cursor->get($dbkey, $dbdata, MDB_PREV);
	return undef if !$dbkey;

	($dbkey_last, $cc) = split(/;/, $dbdata);
	$dbkey_ip4 = int_ip4($dbkey);
	$dbkey_last_ip4 = int_ip4($dbkey_last);

	print "ip4:$ip4 = $ipnum,  dbkey:$dbkey = $dbkey_ip4, dbkey_last:$dbkey_last = $dbkey_last_ip4, cc:$cc\n" if $opt{'debug'}; 

	if($dbkey <= $ipnum && $dbkey_last >= $ipnum){ return $cc; }

	return undef;
}


sub v6country_init {

	# load cidr order optimized by network count
	foreach (split(/,/, $ip6db{'CIDRS'})){
                push(@cidr6, [$_, 1 x $_ . 0 x (128 - $_)]);
	}

	# load exact cidr order (small net to big net)
        foreach ( sort { $b <=> $a } split(/,/, $ip6db{'CIDRS'})){
                push(@cidr6_exact, [$_, 1 x $_ . 0 x (128 - $_)]);
        }

}


sub v6country ($;$) {

        my $ip6 = shift || return undef;
	my $exact = shift;

	if(!$exact){
		foreach(@cidr6){
			my $net = $_->[0] . '/' . inet_ntop(AF_INET6, pack('B128', (unpack('B128', inet_pton(AF_INET6, $ip6)) & $_->[1])));
			print "search $net\n" if $opt{'debug'};
			my $p = $ip6db{ $net }; 
			return $p if $p;
		}
	} else {

		foreach(@cidr6_exact){
			my $net = $_->[0] . '/' . inet_ntop(AF_INET6, pack('B128', (unpack('B128', inet_pton(AF_INET6, $ip6)) & $_->[1])));
			print "search $net\n" if $opt{'debug'};
			my $p = $ip6db{ $net };
			return $p if $p;
		}
	}
}

sub net2cidr ($$) {

	my $self = shift;
	my $net = shift;
	my $res = [];

	foreach(@cidr6_exact){
		my $cc = $ip6db{ $_->[0] . '/' . $net};
		push(@$res, "$net/$_->[0]=$cc") if $cc;
	}

	return $res;
}



=head2 cc 

Lookup country code for ipv6 or ipv4 address

	my $cc =  $geo->cc("2001:1488:0:3::2");   # result: CZ
	my $cc =  $geo->cc("217.31.205.50");      # result: CZ

=cut	

sub cc ($$) {
	my ($self, $ip) = @_;
	if($ip =~ /^[a-f0-9:]{3,39}$/){ return v6country($ip) || 'ZZ' }
	elsif($ip =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/o){ return v4country($ip) || 'ZZ' }
	else { Carp::carp "invalid ip: <$ip>\n" }
}

=head2 cc_exact 

Lookup exact country code for ipv6. See SYNOPSIS for overlap information. 

	my $cc =  $geo->cc_exact("2001:1c00::1"); 	# result: NL 

=cut	

sub cc_exact ($$) {
	my ($self, $ip) = @_;
	if($ip =~ /^[a-f0-9:]{3,39}$/){ return v6country($ip, 1) || 'ZZ' }
	elsif($ip =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/o){ return v4country($ip) || 'ZZ' }
	else { Carp::carp "invalid ip: <$ip>\n" }
}

=head2 new

	my $geo = Geo::IP6->new();
 
	my $geo = Geo::IP6->new(db => 'maxmind', memcache => 0, debug => 0, ip4db_file => undef, ip6db_file => undef);


=over 4

=item db

If not set, C<< maxmind >> is currently used. You can choose C<< maxmind >> (GeoIP2Lite) or C<< software77 >> ipv4/6 databases.

=item memcache

It is possible to load the ipv6 data into memory (probably not needed as LMDB is very fast).
Ipv4 dataset is using ip-ranges (integers) instead of netmasks (CIDR). There is no memcache option.

=item debug

Print debug output for ipv4 addresses (mainly convert ipv4 to integers back and forth to show network ranges)

	[user@host ~]$ geoip6 217.31.205.50
	ip4:217.31.205.50 = 3642740018,  dbkey:3642740736 = 217.31.208.0, dbkey_last:3642744831 = 217.31.223.255, cc:DE
	ip4:217.31.205.50 = 3642740018,  dbkey:3642736640 = 217.31.192.0, dbkey_last:3642740735 = 217.31.207.255, cc:CZ
	CZ

	[user@host ~]# geoip6 -debug 2001:1488:0:3::2
	Loaded database /usr/share/geoip6/geoip4-maxmind.lmdb
	Loaded database /usr/share/geoip6/geoip6-maxmind.lmdb
	search 32/2001:1488::
	search 48/2001:1488::
	search 29/2001:1488::
	CZ

=item ip4db_file

Manually set path to ip4 database file, e.g. /usr/share/geoip6/geoip4-maxmind.lmdb 

=item ip6db_file

Manually set path to ip6 database file, e.g. /usr/share/geoip6/geoip6-software77.lmdb

=back

=cut

sub new {
	my ($class, %copt) = @_;
	%opt = %copt;
	my $self = {};
	bless $self, $class;

	$opt{'db'} = 'maxmind' if !$opt{'db'};
	$opt{'debug'} = 0 if !$opt{'db'};
	$opt{'memcache'} = 0 if !$opt{'memcache'};

	# ipv4
	if($opt{'db'} eq 'software77'){ $ip4db_file = $ip4db_file_software77 } else { $ip4db_file = $ip4db_file_maxmind }
	$ip4db_file = $opt{'ip4db_file'} if $opt{'ipdb4_file'};
	Carp::croak "ip4db_file $ip4db_file not found\n" if !-e $ip4db_file;

	my $v4status = v4country_init();
	return undef if !$v4status;

	# ipv6
	if($opt{'db'} eq 'software77'){ $ip6db_file = $ip6db_file_software77 } else { $ip6db_file = $ip6db_file_maxmind }
	$ip6db_file = $opt{'ip6db_file'} if $opt{'ip6db_file'}; 

	Carp::croak "ip6db_file $ip6db_file not found\n" if !-e $ip6db_file;

	if($opt{'memcache'}){
		my $start = time;
		my %db;
		tie %db, 'LMDB_File', $ip6db_file, { mapsize => $ip6db_size, flags => MDB_NOSUBDIR|MDB_RDONLY };
		return undef if !%db;
		while( my($key, $val) = each(%db) ){
			$ip6db{$key} = $val;
		}
		untie %db;
		my $dur = time - $start;
		if($opt{'debug'}){ print "memcache is read, duration $dur secs\n"; }
	} else {
		tie %ip6db, 'LMDB_File', $ip6db_file, { mapsize => $ip6db_size, flags => MDB_NOSUBDIR|MDB_RDONLY };
		return undef if !%ip6db;
	}

	if($opt{'debug'}){
		if(%ip6db){ print "Loaded database $ip6db_file\n"; }
		else { print "Failed to load database $ip6db_file\n"; }
	}

	v6country_init();

	return $self;
}

sub DESTROY {
	untie %ip6db if !$opt{'memcache'};
}



=head1 geoip6 cmdline tool

This module includes the geoip6 program that can be used to get the country code of ipv6 and ipv4 addresses on the command line.

	[user@host ~] geoip6

	geoip6 [options] 2001:1488:0:3::2         	# returns country code CZ (2001:1488:0:3::2 = nic.cz ipv6) 
	geoip6 217.31.205.50				# returns country code CZ (217.31.205.50 = nic.cz ipv4)
							# options: -exact (slow but exact lookup for ipv4)
							# options: -debug (enable debug)
							# options: -memcache (load ipv6 data into ram)
							# options: -software77 (use software77 ip database)
							# options: -maxmind (use maxmind ip database; default) 

	* Hint: ipv6 network prefixes are sorted by network count for performance reasons, which may result in incorrect lookups.
	* Currently (2019-07-01) there is only one minor overlap (2001:1c00::/22,ZZ vs 2001:1c00::/23,NL)
	* If you want to avoid this condition use "-exact" for ipv6 addresses. There is no "-exact" for ipv4 which is not affected.

	geoip6 update_maxmind				# update using maxmind GeoLite2 Country (ipv4 and ipv6 databases)

	geoip6 update_db6_software77 			# update ipv6 networks from http://software77.net/faq.html#automated	 
							# needs /usr/bin/curl | /usr/bin/wget, /usr/bin/gunzip, /usr/bin/unzip

	geoip6 update_db4_software77			# update ipv4 networks (same as above)

	geoip6 verify_db6				# show software77 ipv6 overlaps (ipv4 is not affected); see "geoip6 [-exact]"

	geoip6 version					# show version number

	* geoip6 uses the IpToCountry database from http://software77.net/geo-ip/ which is donationware
	* See license http://software77.net/geo-ip/?license and FAQ http://software77.net/faq.html

	* geoip6 uses GeoLite2 Country data created by MaxMind, available from https://www.maxmind.com/
	* See https://dev.maxmind.com/geoip/geoip2/geolite2/ and https://creativecommons.org/licenses/by-sa/4.0/



=head1 AUTHOR

GCORE, C<< <cpan at gcore.de> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-geo-ip6 at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Geo-IP6>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Geo::IP6


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Geo-IP6>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Geo-IP6>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Geo-IP6>

=item * Search CPAN

L<https://metacpan.org/release/Geo-IP6>

=back


=head1 ACKNOWLEDGEMENTS

The IpToCountry databases are provided by http://software77.net/geo-ip/ and are donationware.
Software77.net is asking for donations to cope with hosting costs, see

L<< http://software77.net/geo-ip/?license >>  and  L<< http://software77.net/faq.html >>

GeoLite2 data is created by MaxMind, see  L<< https://www.maxmind.com >> and L<< https://dev.maxmind.com/geoip/geoip2/geolite2/ >>



=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2019 by GCore GmbH.
L<https://gcore.de/>

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of Geo::IP6
