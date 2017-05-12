#!perl
use v5.12;
use warnings;
use GStreamer1;

# This is based on the GStreamer Hello, World! tutorial at:
#
# http://docs.gstreamer.com/pages/viewpage.action?pageId=327735
# 
# You can download 'sintel_trailer-480p.webm' from there
#

my $URI = shift || die "Need URI to play\n";

GStreamer1::init([ $0, @ARGV ]);
my $pipeline = GStreamer1::parse_launch( "playbin uri=$URI" );

$pipeline->set_state( "playing" );

my $bus = $pipeline->get_bus;
my $msg = $bus->timed_pop_filtered( GStreamer1::CLOCK_TIME_NONE,
    [ 'error', 'eos' ]);

$pipeline->set_state( "null" );
