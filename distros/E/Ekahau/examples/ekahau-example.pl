#!/usr/bin/perl

# Test line.

use warnings;
use strict;

use Ekahau;
use Getopt::Std;

use constant DEFAULT_DEVICE_CHECK => 10;
use constant DEFAULT_NUM_GUESSES => 5;
use constant DEFAULT_GUESS_THRESHOLD => .10;

our %opt;
our %ekopts;
getopts("h:p:L:g:G:c:",\%opt)
    or die "Usage: $0 [-h hostname] [-p port] [-L licensefile]\n";
if ($opt{h}) { $ekopts{PeerAddr} = $opt{h} };
if ($opt{p}) { $ekopts{PeerPort} = $opt{p} };
if ($opt{L} || $ENV{EKAHAU_SDK_LICENSE}) { $ekopts{LicenseFile} = $opt{L} || $ENV{EKAHAU_SDK_LICENSE} };

our $num_guesses = $opt{g} || DEFAULT_NUM_GUESSES;
our $guess_threshold = $opt{G} || DEFAULT_GUESS_THRESHOLD;
our $device_check_timeout = $opt{c} || DEFAULT_DEVICE_CHECK;
$ekopts{Timeout} = $device_check_timeout;

our $loc_params = {
  };

#    'EPE.WLAN_SCAN_INTERVAL' => 100,
#    'EPE.WLAN_SCAN_MODE'     => 2,
#    'EPE.SNAP_TO_RAIL'       => 'true',
#    'EPE.EXPECTED_ERROR'     => 'true',
#    'EPE.POSITIONING_MODE'   => '2',
#    'EPE.LOCATION_UPDATE_INTERVAL' => 10_000,
#    'EPE.NUMBER_OF_AREAS'     => 5 };
    

my $ek = Ekahau->new(%ekopts)
    or die "Couldn't create Ekahau object: $!\n";

our %lastloc;
our %floor;
our %macaddr;
our $last_devlist_scan = 0;

$SIG{ALRM} = sub { warn "ALRM at ",time,"!\n"; };
$SIG{TERM} = $SIG{QUIT} = $SIG{INT} = $SIG{PIPE} = sub { die "ektest.pl PID $$ killed by signal $_[0]\n"; };

$| = 1;

while (1)
{
    if ((time - $last_devlist_scan) >= $device_check_timeout)
    {
	print "DEBUG Getting device list\n";
	printf "IMOK %s AT %ld TIMEOUT %ld\n",
  	  'ekahau', time, $device_check_timeout*3;
	my $dl = $ek->get_device_list()
	    or die "Couldn't get device list: $ek->{err}\n";
	
	foreach my $dev (grep { !$macaddr{$_} } @$dl)
	{
	    my $prop = $ek->get_device_properties($dev)
		or die "Couldn't get properties for '$dev': $ek->{err}\n";
	    $macaddr{$dev}=$prop->get_prop('NETWORK.MAC');
	    $ek->start_location_track($loc_params, $dev);
	    $ek->start_area_track($loc_params, $dev);
	}
	$last_devlist_scan = time;
#	warn "DEBUG set alarm($device_check_timeout) at ",time,"\n";
#	alarm($device_check_timeout);
    }

    warn "DEBUG Waiting for next location update\n"
	if ($ENV{VERBOSE});

    my $loc = $ek->next_track(Timeout => $device_check_timeout);
    next unless $loc;
    my $dev = $loc->{args}[0];
    warn "DEBUG Got response $loc->{cmd}\n"
	if ($ENV{VERBOSE});

    if ($loc->type eq 'AreaEstimate')
    {
	next unless $macaddr{$dev};

	my $where = $loc->get_prop('name');
	if (!$where or $where eq 'null') { $where = 'Unknown' }
	my($coord,$relcoord)=("","");

	$where = join(".",get_floor($ek,$loc->get_prop('contextId')),
		          $where);

	if (defined($lastloc{$dev}{x}) and defined($lastloc{$dev}{y}))
	{
	    $coord = " COORDINATES $lastloc{$dev}{x},$lastloc{$dev}{y}";
	    my $poly = $loc->get_prop('polygon');
	    if ($poly and $poly ne 'null')
	    {
		my($all_x,$all_y) = split(/\&/,$poly);
		my $upper_y = min(split(/;/,$all_y));
		my $leftmost_x = min(split(/;/,$all_y));
		$relcoord = sprintf(" RELCOORD %.2f,%.2f",
				    ($lastloc{$dev}{x}-$leftmost_x),
				    ($lastloc{$dev}{y}-$upper_y));
	    }
	}
	my $ormaybe = "";
	my @alternate = $loc->get_all;
	shift @alternate;
	foreach my $room (@alternate)
	{
	    if ($room->get_prop('probability') >= $guess_threshold)
	    {
		$ormaybe .= " ORMAYBE_FROM " .
		    join(".",get_floor($ek,$room->get_prop('contextId')),
				       $room->get_prop('name'));
		$ormaybe .= " ORMAYBE_CONFIDENCE ".$room->get_prop('probability');
	    }
	}
	print "ISEE Ekahau.$macaddr{$dev} FROM $where$coord$relcoord AT ",time," CONFIDENCE ",$loc->{params}{probability},"$ormaybe\n";
    }
    elsif ($loc->type eq 'LocationEstimate')
    {
	$lastloc{$dev}{x} = $loc->get_prop('latestX');
	$lastloc{$dev}{y} = $loc->get_prop('latestY');
    }
    elsif ($loc->error)
    {
	my $errstr = "errorMessage=".$loc->error_msg.", errorCode=".$loc->error_code.", errorLevel=".$loc->error_level;
	warn "Handling error: $errstr\n"
	    if ($ENV{VERBOSE});
	if ($loc->error_fatal)
	{
	    print "DEBUG Ekahau client encountered a fatal error, and is restarting.  See you in a jiffy!  $errstr\n";
	    die "Fatal error encountered: $errstr\n";
	}

	if ($macaddr{$dev})
	{
	    print "DEBUG Device $macaddr{$dev} ($dev) is gone ($errstr).\n";
	    delete $macaddr{$dev};
	}
    }
    else
    {
	print "DEBUG Unrecognized response $loc->{cmd}\n";
    }
}

{
    my %floor;
    sub get_floor
    {
	my($ek,$ctx_id)=@_;
	die "Usage: get_floor(ekahau_obj, context_id)"
	    unless ($ek and $ctx_id);
	if (!$floor{$ctx_id})
	{
	    if (my $ctx = $ek->get_location_context($ctx_id))
	    {
		$floor{$ctx_id}=$ctx->get_prop('address');
		$floor{$ctx_id} =~ s|/|.|g;
	    }
	}
	$floor{$ctx_id};
    }
}

sub min
{
    my $min = shift;
    while(@_)
    {
	my $v = shift;
	if ($v < $min)
	{
	    $min = $v;
	}
    }
    $min;
}
