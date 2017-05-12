#!/usr/bin/perl

use warnings;
use strict;

use Ekahau::Events;
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

my $ek = Ekahau::Events->new(%ekopts)
    or die "Couldn't create Ekahau object: $!\n";

our %lastloc;
our %floor;
our %macaddr;
our $last_devlist_scan = 0;

$SIG{ALRM} = sub { warn "ALRM at ",time,"!\n"; };

$| = 1;

$ek->register_handler('','DEVICE_LIST',\&update_devices);
$ek->register_handler('','DEVICE_PROPERTIES',\&update_device_properties);
$ek->register_handler('','AREA_ESTIMATE',\&update_areas);
$ek->register_handler('','LOCATION_ESTIMATE',\&update_locations);
$ek->register_handler('','CONTEXT',\&update_contexts);
$ek->register_handler('','',\&other_events);

while(1)
{
  if ((time - $last_devlist_scan) >= $device_check_timeout)
  {
    print "DEBUG Getting device list\n";
    printf "IMOK %s AT %ld TIMEOUT %ld\n",
      'ekahau', time, $device_check_timeout*3;
    #	$need_devlist = 0;
    my $dl = $ek->request_device_list()
      or die "Couldn't get device list: $ek->{err}\n";
    $last_devlist_scan = time;
  }
  if ($ek->can_read($device_check_timeout))
  {
      $ek->dispatch;
  }
}

sub update_devices
{
  my($resp)=@_;

  foreach my $dev (grep { !$macaddr{$_} } keys %{$resp->{params}})
  {
    my $prop = $ek->request_device_properties($dev)
      or die "Couldn't get properties for '$dev'\n";
  }
}

sub update_device_properties
{
  my($prop)=@_;

  my $dev = $prop->{args}[0];
  $macaddr{$dev}=$prop->{params}{'NETWORK.MAC'};
  $ek->start_location_track($dev);
  $ek->start_area_track({ 'EPE.NUMBER_OF_AREAS' => $num_guesses }, $dev);
}

sub update_areas
{
    my($loc)=@_;
    my $dev = $loc->{args}[0];
    my $floor = $floor{$loc->{params}{contextId}};

    if (!$macaddr{$dev})
    {
	# Skip unknown devices
	return;
    }
    if (!$floor)
    {
	# Request the context, and we'll display the location after we get it.
	$ek->request_location_context($loc->{params}{contextId});
	return;
    }
    
    my $where = $loc->{params}{name};
    if ($where eq 'null') { $where = 'Unknown' }
    my($coord,$relcoord)=("","");
    

    $where = $floor.".".$where;
    
    if (defined($lastloc{$dev}{x}) and defined($lastloc{$dev}{y}))
    {
	$coord = " COORDINATES $lastloc{$dev}{x},$lastloc{$dev}{y}";
	if ($loc->{params}{polygon} and $loc->{params}{polygon} ne 'null')
	{
 	    my($all_x,$all_y) = split(/\&/,$loc->{params}{polygon});
	    my $upper_y = min(split(/;/,$all_y));
	    my $leftmost_x = min(split(/;/,$all_y));
	    $relcoord = sprintf(" RELCOORD %.2f,%.2f",
				($lastloc{$dev}{x}-$leftmost_x),
				($lastloc{$dev}{y}-$upper_y));
	}
    }
    my $ormaybe = "";
    foreach my $i (1..$#{$loc->{params}{AREA}})
    {
        if (my $room = $loc->{params}{AREA}[$i])
	{
	    if ($room->{probability} >= $guess_threshold)
	    {
		my $or_floor = $floor{$room->{contextId}};
		if (!$or_floor)
		{
		    # Request the context, and we'll display the location after we get it.
		    $ek->request_location_context($loc->{params}{contextId});
		    next;
		}

	        $ormaybe .= " ORMAYBE_FROM " . $or_floor.".".$room->{name} .
		            " ORMAYBE_CONFIDENCE ".$room->{probability};
	    }
	}
    }
    print "ISEE Ekahau.$macaddr{$dev} FROM $where$coord$relcoord AT ",time," CONFIDENCE ",$loc->{params}{probability},"$ormaybe\n";
}

sub update_locations
{
    my($loc)=@_;
    my $dev = $loc->{args}[0];

    $lastloc{$dev}{x} = $loc->{params}{latestX};
    $lastloc{$dev}{y} = $loc->{params}{latestY};
}

sub update_contexts
{
    my($ctx)=@_;
    my $ctx_id = $ctx->{args}[0];

    $floor{$ctx_id}=$ctx->{params}{address};
    $floor{$ctx_id} =~ s|/|.|g;
}

sub other_events
{
    my($loc) = @_;
    my $dev = $loc->{args}[0];

    if ($loc->{cmd} =~ /_(?:PROBLEM|FAILED)$/)
    {
        warn "Handling error: error='$loc->{cmd}', errorCode='$loc->{params}{errorCode}', errorLevel='$loc->{params}{errorLevel}'\n"
	    if ($ENV{VERBOSE});
	if (!defined($loc->{params}{errorLevel}) or $loc->{params}{errorLevel} >= 3)
	{
	  print "DEBUG Ekahau client encountered a fatal error, and is restarting.  See you in a jiffy!  errorCode=$loc->{params}{errorCode}, errorLevel=$loc->{params}{errorLevel}\n";
	  die "Fatal error encountered: $loc->{params}{errorCode}, errorLevel=$loc->{params}{errorLevel}.\n";
	}
	
	if ($macaddr{$dev})
	{
	    print "DEBUG Device $macaddr{$dev} ($dev) is gone ($loc->{cmd}).\n";
	    delete $macaddr{$dev};
	  }
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
