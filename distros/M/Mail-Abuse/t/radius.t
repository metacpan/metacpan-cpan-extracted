#!/usr/bin/perl

# $Id: radius.t,v 1.6 2006/09/28 20:12:14 lem Exp $

# Check the basic parsing and recognition of events from different types
# of Radius detail / accounting files.

use IO::File;
use Test::More;
use File::Path;
use Date::Parse;
use NetAddr::IP;
use PerlIO::gzip;
use Mail::Abuse::Reader;
use Mail::Abuse::Report;
use Mail::Abuse::Incident;
use File::Spec::Functions;

use Data::Dumper;
				# Some funny helper classes
package myReader;
use base 'Mail::Abuse::Reader';
sub read { my $text = "All your base are belong to us!";
	   $_[1]->text(\$text); return 1 }

package myIncident;
use base 'Mail::Abuse::Incident';
sub new { bless {}, ref $_[0] || $_[0] };

package myParser;
use Date::Parse;
use base 'Mail::Abuse::Incident';
sub parse {
    my @incidents = ();
    push @incidents, new myIncident; # Match
    push @incidents, new myIncident; # Match
    push @incidents, new myIncident; # Miss

    $incidents[0]->ip		(new NetAddr::IP '172.16.64.25/32');
    $incidents[0]->time		(str2time('Tue Jul 30 14:48:42 1996'));
    $incidents[0]->type		('test/radius');

    $incidents[1]->ip		(new NetAddr::IP '192.168.32.35/32');
    $incidents[1]->time		(str2time('Tue Jul 8 08:45:24 1997'));
    $incidents[1]->type		('test/radius');

    $incidents[2]->ip		(new NetAddr::IP '172.16.64.25/32');
    $incidents[2]->time		(str2time('Tue Jul 30 14:48:32 1996'));
    $incidents[2]->type		('test/radius');

    return @incidents;
};
package main;
				# Which index corresponds to which parsing
				# mode
my %mode = (
	    livingston	=> 0,
	    );
				# Slurp the detail data
my @details = ();
{
    local $/ = "END_OF_DETAIL\n";
    @details = map { s!${/}!!; $_ } <DATA>;
};

my $config	= "config$$";	# Fake config
my $path	= "details$$";	# Where details are stashed

sub write_config ($)		# Produce a suitable config file for testing
{
    my $name = shift;
    my $fh = new IO::File;
    $fh->open($config, "w")
	or diag "Failed to create test config file: $!";
    print $fh "radius detail location: $name\n";
    print $fh "# debug radius: 1\n";
    $fh->close;
}
				# Create a hierarchy of files with our detail
				# files
mkdir $path;
my $fh;

for my $mode (keys %mode)
{
    my $name = $mode . $$;
    mkpath [ catdir($path, $mode) ];
    $fh = new IO::File;
    unless ($fh->open(catfile($path, $mode, $name), "w"))
    {
	die "Failed to create detail file: ", 
	catfile($path, $mode, $name), ": $!\n";
    }
    print $fh $details[$mode{$mode}];
    $fh->close;

    $name .= '.gz';

    $fh = new IO::File;
    unless ($fh->open(catfile($path, $mode, $name), ">:gzip"))
    {
	die "Failed to create gzipped detail file: ", 
	catfile($path, $mode, $name), ": $!\n";
    }
    print $fh $details[$mode{$mode}];
    $fh->close;
}
				# Get rid of our detail files after exiting
END { unlink $config; rmtree [ $path ]; };

plan tests => 1 + 6 * 3 * keys %mode;

use_ok('Mail::Abuse::Processor::Radius');

my $rep;

for my $mode (keys %mode)
{

    for my $location (catdir($path, $mode),
		      catfile($path, $mode, $mode . $$),
		      catfile($path, $mode, $mode . $$ . '.gz'))
    {

	write_config($location);
	$rep = new Mail::Abuse::Report
	{
	    config		=> $config,
	    reader		=> new myReader,
	    parsers		=> [ new myParser ],
	    processors	=> [ new Mail::Abuse::Processor::Radius ],
	};

	diag "mode     = $mode";
	diag "location = $location";
	isa_ok($rep, 'Mail::Abuse::Report');
	$rep->next;
	unless (is(ref($rep->incidents->[0]->radius), 'HASH',
		   "Incident zero matched"))
	{
	    use Data::Dumper;
	    diag '$rep is: ', Data::Dumper->Dump([$rep]), "\n";
	}
	unless (is(ref($rep->incidents->[1]->radius), 'HASH',
		   "Incident one matched"))
	{
	    use Data::Dumper;
	    diag '$rep is: ', Data::Dumper->Dump([$rep]), "\n";
	}
	ok(! defined $rep->incidents->[2]->radius,
	   "Incident two missed");
	is($rep->incidents->[0]->radius->{'Acct-Authentic'},
	   'RADIUS', "Dereference [0] of Radius data");
	is($rep->incidents->[1]->radius->{'Acct-Authentic'},
	   'RADIUS', "Dereference [1] of Radius data");
#	diag(Data::Dumper->Dump([$rep]));
#	diag(Data::Dumper->Dump($rep->incidents));
    }
}

# The __DATA__ below are example records from different detail file
# formats. When adding more test data, make sure to update %mode 
# accordingly.

# The Livingston RADIUS detail records were taken without permission from 
# http://portmasters.com/www.livingston.com/tech/docs/radius/accounting.html
# and some parameters were changed to adjust the log to the test harness

__DATA__
Tue Jul 30 14:48:39 1996
	Acct-Session-Id = "AC000004"
	User-Name = "jaime"
	NAS-IP-Address = 172.16.64.91
	NAS-Port = 1
	NAS-Port-Type = Async
	Acct-Status-Type = Stop
	Acct-Session-Time = 21
	Acct-Authentic = RADIUS
	Acct-Input-Octets = 22
	Acct-Output-Octets = 187
	Acct-Terminate-Cause = Host-Request
	Service-Type = Login-User
	Login-Service = Telnet
	Login-IP-Host = 172.16.64.25
	Acct-Delay-Time = 0
	Timestamp = 838763319

Tue Jul 8 08:45:24 1997
	Acct-Session-Id = "1A00014E"
	User-Name = "consolata"
	NAS-IP-Address = 192.168.32.7
	NAS-Port = 0
	NAS-Port-Type = Async
	Acct-Status-Type = Stop
	Acct-Session-Time = 67
	Acct-Authentic = RADIUS
	Connect-Info = "33600 LAPM/V42BIS"
	Acct-Input-Octets = 5877
	Acct-Output-Octets = 2418
	Called-Station-Id = "5557026"
	Calling-Station-Id = "5105550285"
	Acct-Terminate-Cause = User-Request
	Service-Type = Framed-User
	Framed-Protocol = PPP
	Framed-IP-Address = 192.168.32.35
	Acct-Delay-Time = 0
	Timestamp = 868376724

END_OF_DETAIL


