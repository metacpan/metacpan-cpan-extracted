# Fake gpsbabel for testing

use strict;
use warnings;
use Data::Dumper;

$| = 1;

my %response = ();
my $name     = undef;
while ( <DATA> ) {
  chomp;
  next if /^\s*$/;
  if ( /^!(\S+)/ ) {
    $name = $1;
  }
  elsif ( defined $name ) {
    s/\\t/\t/g;
    $response{$name} .= "$_\n";
  }
}

#warn join( ' ', @ARGV ), "\n";
my $dump = shift;
my $verb = shift;
defined( my $exit = shift )
 or die "fake-babel <dump file> <verb> <exit_code> <babel args>\n";

# Dump our args where the test can find them
open my $dh, '>', $dump or die "Can't write $dump\n";
print $dh Data::Dumper->Dump( [ \@ARGV ], ['$args'] );
close $dh;

my %personality = (
  'bork' => sub {
  },
  '1.2.5' => sub {
    if ( $ARGV[0] eq '-V' ) {
      print "\nGPSBabel Version 1.2.5\n\n";
    }
  },
  '1.3.0' => sub {
    if ( $ARGV[0] eq '-V' ) {
      print "\nGPSBabel Version 1.3.0\n\n";
    }
    elsif ( $ARGV[0] eq '-%1' ) {
      print $response{filters};
    }
    elsif ( $ARGV[0] eq '-^3' ) {
      print $response{formats};
    }
  },
  '1.3.3' => sub {
    if ( $ARGV[0] eq '-V' ) {
      print "\nGPSBabel Version 1.3.3 -beta20061125\n\n";
    }
    elsif ( $ARGV[0] eq '-%1' ) {
      print $response{filters};
    }
    elsif ( $ARGV[0] eq '-^3' ) {
      print $response{formats};
    }
  },
  '1.3.5' => sub {
    if ( $ARGV[0] eq '-V' ) {
      print "\nGPSBabel Version 1.3.5-beta20070807\n\n";
    }
    elsif ( $ARGV[0] eq '-%1' ) {
      print $response{filters135};
    }
    elsif ( $ARGV[0] eq '-^3' ) {
      print $response{formats135};
    }
  },
);

my $action = $personality{$verb} or die "Verb $verb not known\n";
$action->();
exit $exit;

__DATA__

!formats

internal\trw----\txcsv\t\t? Character Separated Values\txcsv
option\txcsv\tstyle\tFull path to XCSV style file\tfile\t\t\t
option\txcsv\tsnlen\tMax synthesized shortname length\tinteger\t\t1\t
option\txcsv\tsnwhite\tAllow whitespace synth. shortnames\tboolean\t\t\t
option\txcsv\tsnupper\tUPPERCASE synth. shortnames\tboolean\t\t\t
option\txcsv\tsnunique\tMake synth. shortnames unique\tboolean\t\t\t
option\txcsv\turlbase\tBasename prepended to URL on output\tstring\t\t\t
option\txcsv\tprefer_shortnames\tUse shortname instead of description\tboolean\t\t\t
option\txcsv\tdatum\tGPS datum (def. WGS 84)\tstring\t\t\t
file\t--rw--\talantrl\ttrl\tAlan Map500 tracklogs (.trl)\talantrl
file\trw--rw\talanwpr\twpr\tAlan Map500 waypoints and routes (.wpr)\talanwpr
internal\trw----\ttabsep\t\tAll database fields on one tab-separated line\txcsv
option\ttabsep\tsnlen\tMax synthesized shortname length\tinteger\t\t1\t
option\ttabsep\tsnwhite\tAllow whitespace synth. shortnames\tboolean\t\t\t
option\ttabsep\tsnupper\tUPPERCASE synth. shortnames\tboolean\t\t\t
option\ttabsep\tsnunique\tMake synth. shortnames unique\tboolean\t\t\t
option\ttabsep\turlbase\tBasename prepended to URL on output\tstring\t\t\t
option\ttabsep\tprefer_shortnames\tUse shortname instead of description\tboolean\t\t\t
option\ttabsep\tdatum\tGPS datum (def. WGS 84)\tstring\t\t\t
serial\trwrwrw\tbaroiq\t\tBrauniger IQ Series Barograph Download\tbaroiq
file\trw----\tcambridge\tdat\tCambridge/Winpilot glider software\txcsv
option\tcambridge\tsnlen\tMax synthesized shortname length\tinteger\t\t1\t
option\tcambridge\tsnwhite\tAllow whitespace synth. shortnames\tboolean\t\t\t
option\tcambridge\tsnupper\tUPPERCASE synth. shortnames\tboolean\t\t\t
option\tcambridge\tsnunique\tMake synth. shortnames unique\tboolean\t\t\t
option\tcambridge\turlbase\tBasename prepended to URL on output\tstring\t\t\t
option\tcambridge\tprefer_shortnames\tUse shortname instead of description\tboolean\t\t\t
option\tcambridge\tdatum\tGPS datum (def. WGS 84)\tstring\t\t\t
file\tr-r-r-\tcst\tcst\tCarteSurTable data file\tcst
file\trwr---\tcetus\tpdb\tCetus for Palm/OS\tcetus
option\tcetus\tdbname\tDatabase name\tstring\t\t\t
option\tcetus\tappendicon\tAppend icon_descr to description\tboolean\t\t\t
file\trw--rw\tcoastexp\t\tCoastalExplorer XML\tcoastexp
file\trw----\tcsv\t\tComma separated values\txcsv
option\tcsv\tsnlen\tMax synthesized shortname length\tinteger\t\t1\t
option\tcsv\tsnwhite\tAllow whitespace synth. shortnames\tboolean\t\t\t
option\tcsv\tsnupper\tUPPERCASE synth. shortnames\tboolean\t\t\t
option\tcsv\tsnunique\tMake synth. shortnames unique\tboolean\t\t\t
option\tcsv\turlbase\tBasename prepended to URL on output\tstring\t\t\t
option\tcsv\tprefer_shortnames\tUse shortname instead of description\tboolean\t\t\t
option\tcsv\tdatum\tGPS datum (def. WGS 84)\tstring\t\t\t
file\trwrwrw\tcompegps\t\tCompeGPS data files (.wpt/.trk/.rte)\tcompegps
option\tcompegps\tdeficon\tDefault icon name\tstring\t\t\t
option\tcompegps\tindex\tIndex of route/track to write (if more the one in source)\tinteger\t\t1\t
option\tcompegps\tradius\tGive points (waypoints/route points) a default radius (proximity)\tfloat\t\t0\t
option\tcompegps\tsnlen\tLength of generated shortnames (default 16)\tinteger\t16\t1\t
file\trw----\tcopilot\tpdb\tCoPilot Flight Planner for Palm/OS\tcopilot
file\trwr---\tcoto\tpdb\tcotoGPS for Palm/OS\tcoto
option\tcoto\tzerocat\tName of the 'unassigned' category\tstring\t\t\t
internal\trw----\tcustom\t\tCustom "Everything" Style\txcsv
option\tcustom\tsnlen\tMax synthesized shortname length\tinteger\t\t1\t
option\tcustom\tsnwhite\tAllow whitespace synth. shortnames\tboolean\t\t\t
option\tcustom\tsnupper\tUPPERCASE synth. shortnames\tboolean\t\t\t
option\tcustom\tsnunique\tMake synth. shortnames unique\tboolean\t\t\t
option\tcustom\turlbase\tBasename prepended to URL on output\tstring\t\t\t
option\tcustom\tprefer_shortnames\tUse shortname instead of description\tboolean\t\t\t
option\tcustom\tdatum\tGPS datum (def. WGS 84)\tstring\t\t\t
file\t--r---\taxim_gpb\tgpb\tDell Axim Navigation System (.gpb) file format\taxim_gpb
file\trw-wrw\tan1\tan1\tDeLorme .an1 (drawing) file\tan1
option\tan1\ttype\tType of .an1 file\tstring\t\t\t
option\tan1\troad\tRoad type changes\tstring\t\t\t
option\tan1\tnogc\tDo not add geocache data to description\tboolean\t\t\t
option\tan1\tdeficon\tSymbol to use for point data\tstring\tRed Flag\t\t
option\tan1\tcolor\tColor for lines or mapnotes\tstring\tred\t\t
option\tan1\tzoom\tZoom level to reduce points\tinteger\t\t\t
option\tan1\twpt_type\tWaypoint type\tstring\t\t\t
option\tan1\tradius\tRadius for circles\tstring\t\t\t
file\t--rw--\tgpl\tgpl\tDeLorme GPL\tgpl
file\trw----\tsaplus\t\tDeLorme Street Atlas Plus\txcsv
option\tsaplus\tsnlen\tMax synthesized shortname length\tinteger\t\t1\t
option\tsaplus\tsnwhite\tAllow whitespace synth. shortnames\tboolean\t\t\t
option\tsaplus\tsnupper\tUPPERCASE synth. shortnames\tboolean\t\t\t
option\tsaplus\tsnunique\tMake synth. shortnames unique\tboolean\t\t\t
option\tsaplus\turlbase\tBasename prepended to URL on output\tstring\t\t\t
option\tsaplus\tprefer_shortnames\tUse shortname instead of description\tboolean\t\t\t
option\tsaplus\tdatum\tGPS datum (def. WGS 84)\tstring\t\t\t
file\t--r---\tsaroute\tanr\tDeLorme Street Atlas Route\tsaroute
option\tsaroute\tturns_important\tKeep turns if simplify filter is used\tboolean\t\t\t
option\tsaroute\tturns_only\tOnly read turns; skip all other points\tboolean\t\t\t
option\tsaroute\tsplit\tSplit into multiple routes at turns\tboolean\t\t\t
option\tsaroute\tcontrols\tRead control points as waypoint/route/none\tstring\tnone\t\t
option\tsaroute\ttimes\tSynthesize track times\tboolean\t\t\t
file\trw----\txmap\twpt\tDeLorme XMap HH Native .WPT\txcsv
option\txmap\tsnlen\tMax synthesized shortname length\tinteger\t\t1\t
option\txmap\tsnwhite\tAllow whitespace synth. shortnames\tboolean\t\t\t
option\txmap\tsnupper\tUPPERCASE synth. shortnames\tboolean\t\t\t
option\txmap\tsnunique\tMake synth. shortnames unique\tboolean\t\t\t
option\txmap\turlbase\tBasename prepended to URL on output\tstring\t\t\t
option\txmap\tprefer_shortnames\tUse shortname instead of description\tboolean\t\t\t
option\txmap\tdatum\tGPS datum (def. WGS 84)\tstring\t\t\t
file\trw----\txmap2006\ttxt\tDeLorme XMap/SAHH 2006 Native .TXT\txcsv
option\txmap2006\tsnlen\tMax synthesized shortname length\tinteger\t\t1\t
option\txmap2006\tsnwhite\tAllow whitespace synth. shortnames\tboolean\t\t\t
option\txmap2006\tsnupper\tUPPERCASE synth. shortnames\tboolean\t\t\t
option\txmap2006\tsnunique\tMake synth. shortnames unique\tboolean\t\t\t
option\txmap2006\turlbase\tBasename prepended to URL on output\tstring\t\t\t
option\txmap2006\tprefer_shortnames\tUse shortname instead of description\tboolean\t\t\t
option\txmap2006\tdatum\tGPS datum (def. WGS 84)\tstring\t\t\t
file\trw----\txmapwpt\t\tDeLorme XMat HH Street Atlas USA .WPT (PPC)\txcsv
option\txmapwpt\tsnlen\tMax synthesized shortname length\tinteger\t\t1\t
option\txmapwpt\tsnwhite\tAllow whitespace synth. shortnames\tboolean\t\t\t
option\txmapwpt\tsnupper\tUPPERCASE synth. shortnames\tboolean\t\t\t
option\txmapwpt\tsnunique\tMake synth. shortnames unique\tboolean\t\t\t
option\txmapwpt\turlbase\tBasename prepended to URL on output\tstring\t\t\t
option\txmapwpt\tprefer_shortnames\tUse shortname instead of description\tboolean\t\t\t
option\txmapwpt\tdatum\tGPS datum (def. WGS 84)\tstring\t\t\t
file\trw----\teasygps\t.loc\tEasyGPS binary format\teasygps
internal\trwrwrw\tshape\tshp\tESRI shapefile\tshape
option\tshape\tname\tIndex of name field in .dbf\tstring\t\t0\t
option\tshape\turl\tIndex of URL field in .dbf\tinteger\t\t0\t
file\t--rwrw\tigc\t\tFAI/IGC Flight Recorder Data Format\tigc
option\tigc\ttimeadj\t(integer sec or 'auto') Barograph to GPS time diff\tstring\t\t\t
file\t-w-w-w\tgpssim\tgpssim\tFranson GPSGate Simulation\tgpssim
option\tgpssim\twayptspd\tDefault speed for waypoints (knots/hr)\tfloat\t\t\t
option\tgpssim\tsplit\tSplit input into separate files\tboolean\t0\t\t
file\trw----\tfugawi\ttxt\tFugawi\txcsv
option\tfugawi\tsnlen\tMax synthesized shortname length\tinteger\t\t1\t
option\tfugawi\tsnwhite\tAllow whitespace synth. shortnames\tboolean\t\t\t
option\tfugawi\tsnupper\tUPPERCASE synth. shortnames\tboolean\t\t\t
option\tfugawi\tsnunique\tMake synth. shortnames unique\tboolean\t\t\t
option\tfugawi\turlbase\tBasename prepended to URL on output\tstring\t\t\t
option\tfugawi\tprefer_shortnames\tUse shortname instead of description\tboolean\t\t\t
option\tfugawi\tdatum\tGPS datum (def. WGS 84)\tstring\t\t\t
file\trw----\tgarmin301\t\tGarmin 301 Custom position and heartrate\txcsv
option\tgarmin301\tsnlen\tMax synthesized shortname length\tinteger\t\t1\t
option\tgarmin301\tsnwhite\tAllow whitespace synth. shortnames\tboolean\t\t\t
option\tgarmin301\tsnupper\tUPPERCASE synth. shortnames\tboolean\t\t\t
option\tgarmin301\tsnunique\tMake synth. shortnames unique\tboolean\t\t\t
option\tgarmin301\turlbase\tBasename prepended to URL on output\tstring\t\t\t
option\tgarmin301\tprefer_shortnames\tUse shortname instead of description\tboolean\t\t\t
option\tgarmin301\tdatum\tGPS datum (def. WGS 84)\tstring\t\t\t
file\t--rw--\tglogbook\txml\tGarmin Logbook XML\tglogbook
file\trwrwrw\tgdb\tgdb\tGarmin MapSource - gdb\tgdb
option\tgdb\tcat\tDefault category on output (1..16)\tinteger\t\t1\t16
option\tgdb\tver\tVersion of gdb file to generate (1,2)\tinteger\t2\t1\t2
option\tgdb\tvia\tDrop route points that do not have an equivalent waypoint (hidden points)\tboolean\t\t\t
file\trwrwrw\tmapsource\tmps\tGarmin MapSource - mps\tmapsource
option\tmapsource\tsnlen\tLength of generated shortnames\tinteger\t10\t1\t
option\tmapsource\tsnwhite\tAllow whitespace synth. shortnames\tboolean\t\t\t
option\tmapsource\tmpsverout\tVersion of mapsource file to generate (3,4,5)\tinteger\t\t\t
option\tmapsource\tmpsmergeout\tMerge output with existing file\tboolean\t\t\t
option\tmapsource\tmpsusedepth\tUse depth values on output (default is ignore)\tboolean\t\t\t
option\tmapsource\tmpsuseprox\tUse proximity values on output (default is ignore)\tboolean\t\t\t
file\trwrwrw\tgarmin_txt\ttxt\tGarmin MapSource - txt (tab delimited)\tgarmin_txt
option\tgarmin_txt\tdate\tRead/Write date format (i.e. yyyy/mm/dd)\tstring\t\t\t
option\tgarmin_txt\tdatum\tGPS datum (def. WGS 84)\tstring\tWGS 84\t\t
option\tgarmin_txt\tdist\tDistance unit [m=metric, s=statute]\tstring\tm\t\t
option\tgarmin_txt\tgrid\tWrite position using this grid.\tstring\t\t\t
option\tgarmin_txt\tprec\tPrecision of coordinates\tinteger\t3\t\t
option\tgarmin_txt\ttemp\tTemperature unit [c=Celsius, f=Fahrenheit]\tstring\tc\t\t
option\tgarmin_txt\ttime\tRead/Write time format (i.e. HH:mm:ss xx)\tstring\t\t\t
option\tgarmin_txt\tutc\tWrite timestamps with offset x to UTC time\tinteger\t\t-23\t+23
file\trwrwrw\tpcx\tpcx\tGarmin PCX5\tpcx
option\tpcx\tdeficon\tDefault icon name\tstring\tWaypoint\t\t
option\tpcx\tcartoexploreur\tWrite tracks compatible with Carto Exploreur\tboolean\t\t\t
file\trw----\tgarmin_poi\t\tGarmin POI database\txcsv
option\tgarmin_poi\tsnlen\tMax synthesized shortname length\tinteger\t\t1\t
option\tgarmin_poi\tsnwhite\tAllow whitespace synth. shortnames\tboolean\t\t\t
option\tgarmin_poi\tsnupper\tUPPERCASE synth. shortnames\tboolean\t\t\t
option\tgarmin_poi\tsnunique\tMake synth. shortnames unique\tboolean\t\t\t
option\tgarmin_poi\turlbase\tBasename prepended to URL on output\tstring\t\t\t
option\tgarmin_poi\tprefer_shortnames\tUse shortname instead of description\tboolean\t\t\t
option\tgarmin_poi\tdatum\tGPS datum (def. WGS 84)\tstring\t\t\t
serial\trwrwrw\tgarmin\t\tGarmin serial/USB protocol\tgarmin
option\tgarmin\tsnlen\tLength of generated shortnames\tinteger\t\t1\t
option\tgarmin\tsnwhite\tAllow whitespace synth. shortnames\tboolean\t\t\t
option\tgarmin\tdeficon\tDefault icon name\tstring\t\t\t
option\tgarmin\tget_posn\tReturn current position as a waypoint\tboolean\t\t\t
option\tgarmin\tpower_off\tCommand unit to power itself down\tboolean\t\t\t
option\tgarmin\tcategory\tCategory number to use for written waypoints\tinteger\t\t1\t16
file\t---w--\tgtrnctr\t\tGarmin Training Centerxml\tgtrnctr
file\trw----\tgeo\tloc\tGeocaching.com .loc\tgeo
option\tgeo\tdeficon\tDefault icon name\tstring\t\t\t
option\tgeo\tnuke_placer\tOmit Placer name\tboolean\t\t\t
file\trw----\tgcdb\tpdb\tGeocachingDB for Palm/OS\tgcdb
file\trw----\tgeonet\ttxt\tGEOnet Names Server (GNS)\txcsv
option\tgeonet\tsnlen\tMax synthesized shortname length\tinteger\t\t1\t
option\tgeonet\tsnwhite\tAllow whitespace synth. shortnames\tboolean\t\t\t
option\tgeonet\tsnupper\tUPPERCASE synth. shortnames\tboolean\t\t\t
option\tgeonet\tsnunique\tMake synth. shortnames unique\tboolean\t\t\t
option\tgeonet\turlbase\tBasename prepended to URL on output\tstring\t\t\t
option\tgeonet\tprefer_shortnames\tUse shortname instead of description\tboolean\t\t\t
option\tgeonet\tdatum\tGPS datum (def. WGS 84)\tstring\t\t\t
file\trw----\tgeoniche\tpdb\tGeoNiche .pdb\tgeoniche
option\tgeoniche\tdbname\tDatabase name (filename)\tstring\t\t\t
option\tgeoniche\tcategory\tCategory name (Cache)\tstring\t\t\t
file\trwrwrw\tkml\tkml\tGoogle Earth (Keyhole) Markup Language\tkml
option\tkml\tdeficon\tDefault icon name\tstring\t\t\t
option\tkml\tlines\tExport linestrings for tracks and routes\tboolean\t1\t\t
option\tkml\tpoints\tExport placemarks for tracks and routes\tboolean\t1\t\t
option\tkml\tline_width\tWidth of lines, in pixels\tinteger\t6\t\t
option\tkml\tline_color\tLine color, specified in hex AABBGGRR\tstring\t64eeee17\t\t
option\tkml\tfloating\tAltitudes are absolute and not clamped to ground\tboolean\t0\t\t
option\tkml\textrude\tDraw extrusion line from trackpoint to ground\tboolean\t0\t\t
option\tkml\ttrackdata\tInclude extended data for trackpoints (default = 1)\tboolean\t1\t\t
option\tkml\tunits\tUnits used when writing comments ('s'tatute or 'm'etric)\tstring\ts\t\t
option\tkml\tlabels\tDisplay labels on track and routepoints  (default = 1)\tboolean\t1\t\t
option\tkml\tmax_position_points\tRetain at most this number of position points  (0 = unlimited)\tinteger\t0\t\t
file\t--r---\tgoogle\txml\tGoogle Maps XML\tgoogle
file\trw----\tgpilots\tpdb\tGpilotS\tgpilots
option\tgpilots\tdbname\tDatabase name\tstring\t\t\t
file\trwrwrw\tgtm\tgtm\tGPS TrackMaker\tgtm
file\trw----\tarc\ttxt\tGPSBabel arc filter file\txcsv
option\tarc\tsnlen\tMax synthesized shortname length\tinteger\t\t1\t
option\tarc\tsnwhite\tAllow whitespace synth. shortnames\tboolean\t\t\t
option\tarc\tsnupper\tUPPERCASE synth. shortnames\tboolean\t\t\t
option\tarc\tsnunique\tMake synth. shortnames unique\tboolean\t\t\t
option\tarc\turlbase\tBasename prepended to URL on output\tstring\t\t\t
option\tarc\tprefer_shortnames\tUse shortname instead of description\tboolean\t\t\t
option\tarc\tdatum\tGPS datum (def. WGS 84)\tstring\t\t\t
file\trw----\tgpsdrive\t\tGpsDrive Format\txcsv
option\tgpsdrive\tsnlen\tMax synthesized shortname length\tinteger\t\t1\t
option\tgpsdrive\tsnwhite\tAllow whitespace synth. shortnames\tboolean\t\t\t
option\tgpsdrive\tsnupper\tUPPERCASE synth. shortnames\tboolean\t\t\t
option\tgpsdrive\tsnunique\tMake synth. shortnames unique\tboolean\t\t\t
option\tgpsdrive\turlbase\tBasename prepended to URL on output\tstring\t\t\t
option\tgpsdrive\tprefer_shortnames\tUse shortname instead of description\tboolean\t\t\t
option\tgpsdrive\tdatum\tGPS datum (def. WGS 84)\tstring\t\t\t
file\trw----\tgpsdrivetrack\t\tGpsDrive Format for Tracks\txcsv
option\tgpsdrivetrack\tsnlen\tMax synthesized shortname length\tinteger\t\t1\t
option\tgpsdrivetrack\tsnwhite\tAllow whitespace synth. shortnames\tboolean\t\t\t
option\tgpsdrivetrack\tsnupper\tUPPERCASE synth. shortnames\tboolean\t\t\t
option\tgpsdrivetrack\tsnunique\tMake synth. shortnames unique\tboolean\t\t\t
option\tgpsdrivetrack\turlbase\tBasename prepended to URL on output\tstring\t\t\t
option\tgpsdrivetrack\tprefer_shortnames\tUse shortname instead of description\tboolean\t\t\t
option\tgpsdrivetrack\tdatum\tGPS datum (def. WGS 84)\tstring\t\t\t
file\trw----\tgpsman\t\tGPSman\txcsv
option\tgpsman\tsnlen\tMax synthesized shortname length\tinteger\t\t1\t
option\tgpsman\tsnwhite\tAllow whitespace synth. shortnames\tboolean\t\t\t
option\tgpsman\tsnupper\tUPPERCASE synth. shortnames\tboolean\t\t\t
option\tgpsman\tsnunique\tMake synth. shortnames unique\tboolean\t\t\t
option\tgpsman\turlbase\tBasename prepended to URL on output\tstring\t\t\t
option\tgpsman\tprefer_shortnames\tUse shortname instead of description\tboolean\t\t\t
option\tgpsman\tdatum\tGPS datum (def. WGS 84)\tstring\t\t\t
file\trw----\tgpspilot\tpdb\tGPSPilot Tracker for Palm/OS\tgpspilot
option\tgpspilot\tdbname\tDatabase name\tstring\t\t\t
file\trw----\tgpsutil\t\tgpsutil\tgpsutil
file\trwrwrw\tgpx\tgpx\tGPX XML\tgpx
option\tgpx\tsnlen\tLength of generated shortnames\tinteger\t32\t1\t
option\tgpx\tsuppresswhite\tNo whitespace in generated shortnames\tboolean\t\t\t
option\tgpx\tlogpoint\tCreate waypoints from geocache log entries\tboolean\t\t\t
option\tgpx\turlbase\tBase URL for link tag in output\tstring\t\t\t
option\tgpx\tgpxver\tTarget GPX version for output\tstring\t1.0\t\t
file\trwrw--\thiketech\tgps\tHikeTech\thiketech
file\trw----\tholux\twpo\tHolux (gm-100) .wpo Format\tholux
file\trw----\thsandv\t\tHSA Endeavour Navigator export File\thsandv
file\t-w----\thtml\thtml\tHTML Output\thtml
option\thtml\tstylesheet\tPath to HTML style sheet\tstring\t\t\t
option\thtml\tencrypt\tEncrypt hints using ROT13\tboolean\t\t\t
option\thtml\tlogs\tInclude groundspeak logs if present\tboolean\t\t\t
option\thtml\tdegformat\tDegrees output as 'ddd', 'dmm'(default) or 'dms'\tstring\tdmm\t\t
option\thtml\taltunits\tUnits for altitude (f)eet or (m)etres\tstring\tm\t\t
file\t--rw--\tignrando\trdn\tIGN Rando track files\tignrando
option\tignrando\tindex\tIndex of track to write (if more the one in source)\tinteger\t\t1\t
file\trw----\tktf2\tktf\tKartex 5 Track File\txcsv
option\tktf2\tsnlen\tMax synthesized shortname length\tinteger\t\t1\t
option\tktf2\tsnwhite\tAllow whitespace synth. shortnames\tboolean\t\t\t
option\tktf2\tsnupper\tUPPERCASE synth. shortnames\tboolean\t\t\t
option\tktf2\tsnunique\tMake synth. shortnames unique\tboolean\t\t\t
option\tktf2\turlbase\tBasename prepended to URL on output\tstring\t\t\t
option\tktf2\tprefer_shortnames\tUse shortname instead of description\tboolean\t\t\t
option\tktf2\tdatum\tGPS datum (def. WGS 84)\tstring\t\t\t
file\trw----\tkwf2\tkwf\tKartex 5 Waypoint File\txcsv
option\tkwf2\tsnlen\tMax synthesized shortname length\tinteger\t\t1\t
option\tkwf2\tsnwhite\tAllow whitespace synth. shortnames\tboolean\t\t\t
option\tkwf2\tsnupper\tUPPERCASE synth. shortnames\tboolean\t\t\t
option\tkwf2\tsnunique\tMake synth. shortnames unique\tboolean\t\t\t
option\tkwf2\turlbase\tBasename prepended to URL on output\tstring\t\t\t
option\tkwf2\tprefer_shortnames\tUse shortname instead of description\tboolean\t\t\t
option\tkwf2\tdatum\tGPS datum (def. WGS 84)\tstring\t\t\t
file\trwrwrw\tpsitrex\t\tKuDaTa PsiTrex text\tpsitrex
file\trwrwrw\tlowranceusr\tusr\tLowrance USR\tlowranceusr
option\tlowranceusr\tignoreicons\tIgnore event marker icons\tboolean\t\t\t
option\tlowranceusr\tmerge\t(USR output) Merge into one segmented track\tboolean\t\t\t
option\tlowranceusr\tbreak\t(USR input) Break segments into separate tracks\tboolean\t\t\t
file\t-w----\tmaggeo\tgs\tMagellan Explorist Geocaching\tmaggeo
file\trwrwrw\tmapsend\t\tMagellan Mapsend\tmapsend
option\tmapsend\ttrkver\tMapSend version TRK file to generate (3,4)\tinteger\t4\t3\t4
file\trw----\tmagnav\tpdb\tMagellan NAV Companion for Palm/OS\tmagnav
file\trwrwrw\tmagellanx\tupt\tMagellan SD files (as for eXplorist)\tmagellanx
option\tmagellanx\tdeficon\tDefault icon name\tstring\t\t\t
option\tmagellanx\tmaxcmts\tMax number of comments to write (maxcmts=200)\tinteger\t\t\t
file\trwrwrw\tmagellan\t\tMagellan SD files (as for Meridian)\tmagellan
option\tmagellan\tdeficon\tDefault icon name\tstring\t\t\t
option\tmagellan\tmaxcmts\tMax number of comments to write (maxcmts=200)\tinteger\t\t\t
serial\trwrwrw\tmagellan\t\tMagellan serial protocol\tmagellan
option\tmagellan\tdeficon\tDefault icon name\tstring\t\t\t
option\tmagellan\tmaxcmts\tMax number of comments to write (maxcmts=200)\tinteger\t\t\t
option\tmagellan\tbaud\tNumeric value of bitrate (baud=4800)\tinteger\t\t\t
option\tmagellan\tnoack\tSuppress use of handshaking in name of speed\tboolean\t\t\t
option\tmagellan\tnukewpt\tDelete all waypoints\tboolean\t\t\t
file\t----r-\ttef\txml\tMap&Guide 'TourExchangeFormat' XML\ttef
option\ttef\troutevia\tInclude only via stations in route\tboolean\t\t\t
file\tr---r-\tmag_pdb\tpdb\tMap&Guide to Palm/OS exported files (.pdb)\tmag_pdb
file\trw----\tmapconverter\ttxt\tMapopolis.com Mapconverter CSV\txcsv
option\tmapconverter\tsnlen\tMax synthesized shortname length\tinteger\t\t1\t
option\tmapconverter\tsnwhite\tAllow whitespace synth. shortnames\tboolean\t\t\t
option\tmapconverter\tsnupper\tUPPERCASE synth. shortnames\tboolean\t\t\t
option\tmapconverter\tsnunique\tMake synth. shortnames unique\tboolean\t\t\t
option\tmapconverter\turlbase\tBasename prepended to URL on output\tstring\t\t\t
option\tmapconverter\tprefer_shortnames\tUse shortname instead of description\tboolean\t\t\t
option\tmapconverter\tdatum\tGPS datum (def. WGS 84)\tstring\t\t\t
file\trw----\tmxf\tmxf\tMapTech Exchange Format\txcsv
option\tmxf\tsnlen\tMax synthesized shortname length\tinteger\t\t1\t
option\tmxf\tsnwhite\tAllow whitespace synth. shortnames\tboolean\t\t\t
option\tmxf\tsnupper\tUPPERCASE synth. shortnames\tboolean\t\t\t
option\tmxf\tsnunique\tMake synth. shortnames unique\tboolean\t\t\t
option\tmxf\turlbase\tBasename prepended to URL on output\tstring\t\t\t
option\tmxf\tprefer_shortnames\tUse shortname instead of description\tboolean\t\t\t
option\tmxf\tdatum\tGPS datum (def. WGS 84)\tstring\t\t\t
file\t----r-\tmsroute\taxe\tMicrosoft AutoRoute 2002 (pin/route reader)\tmsroute
file\t----r-\tmsroute\test\tMicrosoft Streets and Trips (pin/route reader)\tmsroute
file\trw----\ts_and_t\ttxt\tMicrosoft Streets and Trips 2002-2006\txcsv
option\ts_and_t\tsnlen\tMax synthesized shortname length\tinteger\t\t1\t
option\ts_and_t\tsnwhite\tAllow whitespace synth. shortnames\tboolean\t\t\t
option\ts_and_t\tsnupper\tUPPERCASE synth. shortnames\tboolean\t\t\t
option\ts_and_t\tsnunique\tMake synth. shortnames unique\tboolean\t\t\t
option\ts_and_t\turlbase\tBasename prepended to URL on output\tstring\t\t\t
option\ts_and_t\tprefer_shortnames\tUse shortname instead of description\tboolean\t\t\t
option\ts_and_t\tdatum\tGPS datum (def. WGS 84)\tstring\t\t\t
file\t----rw\tbcr\tbcr\tMotorrad Routenplaner (Map&Guide) .bcr files\tbcr
option\tbcr\tindex\tIndex of route to write (if more the one in source)\tinteger\t\t1\t
option\tbcr\tname\tNew name for the route\tstring\t\t\t
option\tbcr\tradius\tRadius of our big earth (default 6371000 meters)\tfloat\t6371000\t\t
file\trw----\tpsp\tpsp\tMS PocketStreets 2002 Pushpin\tpsp
file\trw----\ttpg\ttpg\tNational Geographic Topo .tpg (waypoints)\ttpg
option\ttpg\tdatum\tDatum (default=NAD27)\tstring\tN. America 1927 mean\t\t
file\t--r---\ttpo2\ttpo\tNational Geographic Topo 2.x .tpo\ttpo2
file\tr-r-r-\ttpo3\ttpo\tNational Geographic Topo 3.x/4.x .tpo\ttpo3
file\tr-----\tnavicache\t\tNavicache.com XML\tnavicache
option\tnavicache\tnoretired\tSuppress retired geocaches\tboolean\t\t\t
file\t----rw\tnmn4\trte\tNavigon Mobile Navigator .rte files\tnmn4
option\tnmn4\tindex\tIndex of route to write (if more the one in source)\tinteger\t\t1\t
file\trw----\tdna\tdna\tNavitrak DNA marker format\txcsv
option\tdna\tsnlen\tMax synthesized shortname length\tinteger\t\t1\t
option\tdna\tsnwhite\tAllow whitespace synth. shortnames\tboolean\t\t\t
option\tdna\tsnupper\tUPPERCASE synth. shortnames\tboolean\t\t\t
option\tdna\tsnunique\tMake synth. shortnames unique\tboolean\t\t\t
option\tdna\turlbase\tBasename prepended to URL on output\tstring\t\t\t
option\tdna\tprefer_shortnames\tUse shortname instead of description\tboolean\t\t\t
option\tdna\tdatum\tGPS datum (def. WGS 84)\tstring\t\t\t
file\tr-----\tnetstumbler\t\tNetStumbler Summary File (text)\tnetstumbler
option\tnetstumbler\tnseicon\tNon-stealth encrypted icon name\tstring\tRed Square\t\t
option\tnetstumbler\tnsneicon\tNon-stealth non-encrypted icon name\tstring\tGreen Square\t\t
option\tnetstumbler\tseicon\tStealth encrypted icon name\tstring\tRed Diamond\t\t
option\tnetstumbler\tsneicon\tStealth non-encrypted icon name\tstring\tGreen Diamond\t\t
option\tnetstumbler\tsnmac\tShortname is MAC address\tboolean\t\t\t
file\trw----\tnima\t\tNIMA/GNIS Geographic Names File\txcsv
option\tnima\tsnlen\tMax synthesized shortname length\tinteger\t\t1\t
option\tnima\tsnwhite\tAllow whitespace synth. shortnames\tboolean\t\t\t
option\tnima\tsnupper\tUPPERCASE synth. shortnames\tboolean\t\t\t
option\tnima\tsnunique\tMake synth. shortnames unique\tboolean\t\t\t
option\tnima\turlbase\tBasename prepended to URL on output\tstring\t\t\t
option\tnima\tprefer_shortnames\tUse shortname instead of description\tboolean\t\t\t
option\tnima\tdatum\tGPS datum (def. WGS 84)\tstring\t\t\t
file\trwrw--\tnmea\t\tNMEA 0183 sentences\tnmea
option\tnmea\tsnlen\tMax length of waypoint name to write\tinteger\t6\t1\t64
option\tnmea\tgprmc\tRead/write GPRMC sentences\tboolean\t1\t\t
option\tnmea\tgpgga\tRead/write GPGGA sentences\tboolean\t1\t\t
option\tnmea\tgpvtg\tRead/write GPVTG sentences\tboolean\t1\t\t
option\tnmea\tgpgsa\tRead/write GPGSA sentences\tboolean\t1\t\t
option\tnmea\tdate\tComplete date-free tracks with given date (YYYYMMDD).\tinteger\t\t\t
option\tnmea\tget_posn\tReturn current position as a waypoint\tboolean\t\t\t
option\tnmea\tpause\tDecimal seconds to pause between groups of strings\tinteger\t\t\t
option\tnmea\tbaud\tSpeed in bits per second of serial port (baud=4800)\tinteger\t\t\t
file\trwrwrw\tozi\t\tOziExplorer\tozi
option\tozi\tsnlen\tMax synthesized shortname length\tinteger\t32\t1\t
option\tozi\tsnwhite\tAllow whitespace synth. shortnames\tboolean\t\t\t
option\tozi\tsnupper\tUPPERCASE synth. shortnames\tboolean\t\t\t
option\tozi\tsnunique\tMake synth. shortnames unique\tboolean\t\t\t
option\tozi\twptfgcolor\tWaypoint foreground color\tstring\tblack\t\t
option\tozi\twptbgcolor\tWaypoint background color\tstring\tyellow\t\t
file\t-w----\tpalmdoc\tpdb\tPalmDoc Output\tpalmdoc
option\tpalmdoc\tnosep\tNo separator lines between waypoints\tboolean\t\t\t
option\tpalmdoc\tdbname\tDatabase name\tstring\t\t\t
option\tpalmdoc\tencrypt\tEncrypt hints with ROT13\tboolean\t\t\t
option\tpalmdoc\tlogs\tInclude groundspeak logs if present\tboolean\t\t\t
option\tpalmdoc\tbookmarks_short\tInclude short name in bookmarks\tboolean\t\t\t
file\trwrwrw\tpathaway\tpdb\tPathAway Database for Palm/OS\tpathaway
option\tpathaway\tdate\tRead/Write date format (i.e. DDMMYYYY)\tstring\t\t\t
option\tpathaway\tdbname\tDatabase name\tstring\t\t\t
option\tpathaway\tdeficon\tDefault icon name\tstring\t\t\t
option\tpathaway\tsnlen\tLength of generated shortnames\tinteger\t10\t1\t
file\trw----\tquovadis\tpdb\tQuovadis\tquovadis
option\tquovadis\tdbname\tDatabase name\tstring\t\t\t
file\trw--rw\traymarine\trwf\tRaymarine Waypoint File (.rwf)\traymarine
option\traymarine\tlocation\tDefault location\tstring\tNew location\t\t
file\trw----\tcup\tcup\tSee You flight analysis data\txcsv
option\tcup\tsnlen\tMax synthesized shortname length\tinteger\t\t1\t
option\tcup\tsnwhite\tAllow whitespace synth. shortnames\tboolean\t\t\t
option\tcup\tsnupper\tUPPERCASE synth. shortnames\tboolean\t\t\t
option\tcup\tsnunique\tMake synth. shortnames unique\tboolean\t\t\t
option\tcup\turlbase\tBasename prepended to URL on output\tstring\t\t\t
option\tcup\tprefer_shortnames\tUse shortname instead of description\tboolean\t\t\t
option\tcup\tdatum\tGPS datum (def. WGS 84)\tstring\t\t\t
file\trw----\tsportsim\ttxt\tSportsim track files (part of zipped .ssz files)\txcsv
option\tsportsim\tsnlen\tMax synthesized shortname length\tinteger\t\t1\t
option\tsportsim\tsnwhite\tAllow whitespace synth. shortnames\tboolean\t\t\t
option\tsportsim\tsnupper\tUPPERCASE synth. shortnames\tboolean\t\t\t
option\tsportsim\tsnunique\tMake synth. shortnames unique\tboolean\t\t\t
option\tsportsim\turlbase\tBasename prepended to URL on output\tstring\t\t\t
option\tsportsim\tprefer_shortnames\tUse shortname instead of description\tboolean\t\t\t
option\tsportsim\tdatum\tGPS datum (def. WGS 84)\tstring\t\t\t
file\t--rwrw\tstmsdf\tsdf\tSuunto Trek Manager (STM) .sdf files\tstmsdf
option\tstmsdf\tindex\tIndex of route (if more the one in source)\tinteger\t1\t1\t
file\trwrwrw\tstmwpp\ttxt\tSuunto Trek Manager (STM) WaypointPlus files\tstmwpp
option\tstmwpp\tindex\tIndex of route/track to write (if more the one in source)\tinteger\t\t1\t
file\trw----\topenoffice\t\tTab delimited fields useful for OpenOffice, Ploticus etc.\txcsv
option\topenoffice\tsnlen\tMax synthesized shortname length\tinteger\t\t1\t
option\topenoffice\tsnwhite\tAllow whitespace synth. shortnames\tboolean\t\t\t
option\topenoffice\tsnupper\tUPPERCASE synth. shortnames\tboolean\t\t\t
option\topenoffice\tsnunique\tMake synth. shortnames unique\tboolean\t\t\t
option\topenoffice\turlbase\tBasename prepended to URL on output\tstring\t\t\t
option\topenoffice\tprefer_shortnames\tUse shortname instead of description\tboolean\t\t\t
option\topenoffice\tdatum\tGPS datum (def. WGS 84)\tstring\t\t\t
file\t-w----\ttext\ttxt\tTextual Output\ttext
option\ttext\tnosep\tSuppress separator lines between waypoints\tboolean\t\t\t
option\ttext\tencrypt\tEncrypt hints using ROT13\tboolean\t\t\t
option\ttext\tlogs\tInclude groundspeak logs if present\tboolean\t\t\t
option\ttext\tdegformat\tDegrees output as 'ddd', 'dmm'(default) or 'dms'\tstring\tdmm\t\t
option\ttext\taltunits\tUnits for altitude (f)eet or (m)etres\tstring\tm\t\t
file\trw----\ttomtom\tov2\tTomTom POI file\ttomtom
file\trw----\ttmpro\ttmpro\tTopoMapPro Places File\ttmpro
file\trwrw--\tdmtlog\ttrl\tTrackLogs digital mapping (.trl)\tdmtlog
option\tdmtlog\tindex\tIndex of track (if more the one in source)\tinteger\t1\t1\t
file\trw----\ttiger\t\tU.S. Census Bureau Tiger Mapping Service\ttiger
option\ttiger\tnolabels\tSuppress labels on generated pins\tboolean\t\t\t
option\ttiger\tgenurl\tGenerate file with lat/lon for centering map\toutfile\t\t\t
option\ttiger\tmargin\tMargin for map.  Degrees or percentage\tfloat\t15%\t\t
option\ttiger\tsnlen\tMax shortname length when used with -s\tinteger\t10\t1\t
option\ttiger\toldthresh\tDays after which points are considered old\tinteger\t14\t\t
option\ttiger\toldmarker\tMarker type for old points\tstring\tredpin\t\t
option\ttiger\tnewmarker\tMarker type for new points\tstring\tgreenpin\t\t
option\ttiger\tsuppresswhite\tSuppress whitespace in generated shortnames\tboolean\t\t\t
option\ttiger\tunfoundmarker\tMarker type for unfound points\tstring\tbluepin\t\t
option\ttiger\txpixels\tWidth in pixels of map\tinteger\t768\t\t
option\ttiger\typixels\tHeight in pixels of map\tinteger\t768\t\t
option\ttiger\ticonismarker\tThe icon description is already the marker\tboolean\t\t\t
file\tr-----\tunicsv\t\tUniversal csv with field structure in first line\tunicsv
file\t-w----\tvcard\tvcf\tVcard Output (for iPod)\tvcard
option\tvcard\tencrypt\tEncrypt hints using ROT13\tboolean\t\t\t
file\trwrwrw\tvitosmt\tsmt\tVito Navigator II tracks\tvitosmt
file\tr-----\twfff\txml\tWiFiFoFum 2.0 for PocketPC XML\twfff
option\twfff\taicicon\tInfrastructure closed icon name\tstring\tRed Square\t\t
option\twfff\taioicon\tInfrastructure open icon name\tstring\tGreen Square\t\t
option\twfff\tahcicon\tAd-hoc closed icon name\tstring\tRed Diamond\t\t
option\twfff\tahoicon\tAd-hoc open icon name\tstring\tGreen Diamond\t\t
option\twfff\tsnmac\tShortname is MAC address\tboolean\t\t\t
file\t--r---\twbt-bin\t\tWintec WBT-100/200 Binary file format\twbt-bin
serial\t--r---\twbt\tbin\tWintec WBT-100/200 GPS Download\twbt
option\twbt\terase\tErase device data after download\tboolean\t0\t\t
file\tr-----\tyahoo\t\tYahoo Geocode API data\tyahoo
option\tyahoo\taddrsep\tString to separate concatenated address fields (default=", ")\tstring\t, \t\t

!filters

polygon\tInclude Only Points Inside Polygon
option\tpolygon\tfile\tFile containing vertices of polygon\tfile\t\t\t
option\tpolygon\texclude\tExclude points inside the polygon\tboolean\t\t\t
arc\tInclude Only Points Within Distance of Arc
option\tarc\tfile\tFile containing vertices of arc\tfile\t\t\t
option\tarc\tdistance\tMaximum distance from arc\tfloat\t\t\t
option\tarc\texclude\tExclude points close to the arc\tboolean\t\t\t
option\tarc\tpoints\tUse distance from vertices not lines\tboolean\t\t\t
radius\tInclude Only Points Within Radius
option\tradius\tlat\tLatitude for center point (D.DDDDD)\tfloat\t\t\t
option\tradius\tlon\tLongitude for center point (D.DDDDD)\tfloat\t\t\t
option\tradius\tdistance\tMaximum distance from center\tfloat\t\t\t
option\tradius\texclude\tExclude points close to center\tboolean\t\t\t
option\tradius\tnosort\tInhibit sort by distance to center\tboolean\t\t\t
option\tradius\tmaxcount\tOutput no more than this number of points\tinteger\t\t1\t
option\tradius\tasroute\tPut resulting waypoints in route of this name\tstring\t\t\t
interpolate\tInterpolate between trackpoints
option\tinterpolate\ttime\tTime interval in seconds\tinteger\t\t0\t
option\tinterpolate\tdistance\tDistance interval in miles or kilometers\tstring\t\t\t
option\tinterpolate\troute\tInterpolate routes instead\tboolean\t\t\t
track\tManipulate track lists
option\ttrack\tmove\tCorrect trackpoint timestamps by a delta\tstring\t\t\t
option\ttrack\tpack\tPack all tracks into one\tboolean\t\t\t
option\ttrack\tsplit\tSplit by date or time interval (see README)\tstring\t\t\t
option\ttrack\tsdistance\tSplit by distance\tstring\t\t\t
option\ttrack\tmerge\tMerge multiple tracks for the same way\tstring\t\t\t
option\ttrack\tname\tUse only track(s) where title matches given name\tstring\t\t\t
option\ttrack\tstart\tUse only track points after this timestamp\tinteger\t\t\t
option\ttrack\tstop\tUse only track points before this timestamp\tinteger\t\t\t
option\ttrack\ttitle\tBasic title for new track(s)\tstring\t\t\t
option\ttrack\tfix\tSynthesize GPS fixes (PPS, DGPS, 3D, 2D, NONE)\tstring\t\t\t
option\ttrack\tcourse\tSynthesize course\tboolean\t\t\t
option\ttrack\tspeed\tSynthesize speed\tboolean\t\t\t
sort\tRearrange waypoints by resorting
option\tsort\tgcid\tSort by numeric geocache ID\tboolean\t\t\t
option\tsort\tshortname\tSort by waypoint short name\tboolean\t\t\t
option\tsort\tdescription\tSort by waypoint description\tboolean\t\t\t
option\tsort\ttime\tSort by time\tboolean\t\t\t
nuketypes\tRemove all waypoints, tracks, or routes
option\tnuketypes\twaypoints\tRemove all waypoints from data stream\tboolean\t0\t\t
option\tnuketypes\ttracks\tRemove all tracks from data stream\tboolean\t0\t\t
option\tnuketypes\troutes\tRemove all routes from data stream\tboolean\t0\t\t
duplicate\tRemove Duplicates
option\tduplicate\tshortname\tSuppress duplicate waypoints based on name\tboolean\t\t\t
option\tduplicate\tlocation\tSuppress duplicate waypoint based on coords\tboolean\t\t\t
option\tduplicate\tall\tSuppress all instances of duplicates\tboolean\t\t\t
option\tduplicate\tcorrect\tUse coords from duplicate points\tboolean\t\t\t
position\tRemove Points Within Distance
option\tposition\tdistance\tMaximum positional distance\tfloat\t\t\t
option\tposition\tall\tSuppress all points close to other points\tboolean\t\t\t
discard\tRemove unreliable points with high hdop or vdop
option\tdiscard\thdop\tSuppress waypoints with higher hdop\tfloat\t-1.0\t\t
option\tdiscard\tvdop\tSuppress waypoints with higher vdop\tfloat\t-1.0\t\t
option\tdiscard\thdopandvdop\tLink hdop and vdop supression with AND\tboolean\t\t\t
reverse\tReverse stops within routes
stack\tSave and restore waypoint lists
option\tstack\tpush\tPush waypoint list onto stack\tboolean\t\t\t
option\tstack\tpop\tPop waypoint list from stack\tboolean\t\t\t
option\tstack\tswap\tSwap waypoint list with <depth> item on stack\tboolean\t\t\t
option\tstack\tcopy\t(push) Copy waypoint list\tboolean\t\t\t
option\tstack\tappend\t(pop) Append list\tboolean\t\t\t
option\tstack\tdiscard\t(pop) Discard top of stack\tboolean\t\t\t
option\tstack\treplace\t(pop) Replace list (default)\tboolean\t\t\t
option\tstack\tdepth\t(swap) Item to use (default=1)\tinteger\t\t0\t
simplify\tSimplify routes
option\tsimplify\tcount\tMaximum number of points in route\tinteger\t\t1\t
option\tsimplify\terror\tMaximum error\tstring\t\t0\t
option\tsimplify\tcrosstrack\tUse cross-track error (default)\tboolean\t\t\t
option\tsimplify\tlength\tUse arclength error\tboolean\t\t\t
transform\tTransform waypoints into a route, tracks into routes, ...
option\ttransform\twpt\tTransform track(s) or route(s) into waypoint(s) [R/T]\tstring\t\t\t
option\ttransform\trte\tTransform waypoint(s) or track(s) into route(s) [W/T]\tstring\t\t\t
option\ttransform\ttrk\tTransform waypoint(s) or route(s) into tracks(s) [W/R]\tstring\t\t\t
option\ttransform\tdel\tDelete source data after transformation\tboolean\tN\t\t

!filters135

polygon	Include Only Points Inside Polygon	http://www.gpsbabel.org/htmldoc-development/fmt_polygon.html
option	polygon	file	File containing vertices of polygon	file				http://www.gpsbabel.org/htmldoc-development/fmt_polygon.html#fmt_polygon_o_file
option	polygon	exclude	Exclude points inside the polygon	boolean				http://www.gpsbabel.org/htmldoc-development/fmt_polygon.html#fmt_polygon_o_exclude
arc	Include Only Points Within Distance of Arc	http://www.gpsbabel.org/htmldoc-development/fmt_arc.html
option	arc	file	File containing vertices of arc	file				http://www.gpsbabel.org/htmldoc-development/fmt_arc.html#fmt_arc_o_file
option	arc	distance	Maximum distance from arc	float				http://www.gpsbabel.org/htmldoc-development/fmt_arc.html#fmt_arc_o_distance
option	arc	exclude	Exclude points close to the arc	boolean				http://www.gpsbabel.org/htmldoc-development/fmt_arc.html#fmt_arc_o_exclude
option	arc	points	Use distance from vertices not lines	boolean				http://www.gpsbabel.org/htmldoc-development/fmt_arc.html#fmt_arc_o_points
radius	Include Only Points Within Radius	http://www.gpsbabel.org/htmldoc-development/fmt_radius.html
option	radius	lat	Latitude for center point (D.DDDDD)	float				http://www.gpsbabel.org/htmldoc-development/fmt_radius.html#fmt_radius_o_lat
option	radius	lon	Longitude for center point (D.DDDDD)	float				http://www.gpsbabel.org/htmldoc-development/fmt_radius.html#fmt_radius_o_lon
option	radius	distance	Maximum distance from center	float				http://www.gpsbabel.org/htmldoc-development/fmt_radius.html#fmt_radius_o_distance
option	radius	exclude	Exclude points close to center	boolean				http://www.gpsbabel.org/htmldoc-development/fmt_radius.html#fmt_radius_o_exclude
option	radius	nosort	Inhibit sort by distance to center	boolean				http://www.gpsbabel.org/htmldoc-development/fmt_radius.html#fmt_radius_o_nosort
option	radius	maxcount	Output no more than this number of points	integer		1		http://www.gpsbabel.org/htmldoc-development/fmt_radius.html#fmt_radius_o_maxcount
option	radius	asroute	Put resulting waypoints in route of this name	string				http://www.gpsbabel.org/htmldoc-development/fmt_radius.html#fmt_radius_o_asroute
interpolate	Interpolate between trackpoints	http://www.gpsbabel.org/htmldoc-development/fmt_interpolate.html
option	interpolate	time	Time interval in seconds	integer		0		http://www.gpsbabel.org/htmldoc-development/fmt_interpolate.html#fmt_interpolate_o_time
option	interpolate	distance	Distance interval in miles or kilometers	string				http://www.gpsbabel.org/htmldoc-development/fmt_interpolate.html#fmt_interpolate_o_distance
option	interpolate	route	Interpolate routes instead	boolean				http://www.gpsbabel.org/htmldoc-development/fmt_interpolate.html#fmt_interpolate_o_route
track	Manipulate track lists	http://www.gpsbabel.org/htmldoc-development/fmt_track.html
option	track	move	Correct trackpoint timestamps by a delta	string				http://www.gpsbabel.org/htmldoc-development/fmt_track.html#fmt_track_o_move
option	track	pack	Pack all tracks into one	boolean				http://www.gpsbabel.org/htmldoc-development/fmt_track.html#fmt_track_o_pack
option	track	split	Split by date or time interval (see README)	string				http://www.gpsbabel.org/htmldoc-development/fmt_track.html#fmt_track_o_split
option	track	sdistance	Split by distance	string				http://www.gpsbabel.org/htmldoc-development/fmt_track.html#fmt_track_o_sdistance
option	track	merge	Merge multiple tracks for the same way	string				http://www.gpsbabel.org/htmldoc-development/fmt_track.html#fmt_track_o_merge
option	track	name	Use only track(s) where title matches given name	string				http://www.gpsbabel.org/htmldoc-development/fmt_track.html#fmt_track_o_name
option	track	start	Use only track points after this timestamp	integer				http://www.gpsbabel.org/htmldoc-development/fmt_track.html#fmt_track_o_start
option	track	stop	Use only track points before this timestamp	integer				http://www.gpsbabel.org/htmldoc-development/fmt_track.html#fmt_track_o_stop
option	track	title	Basic title for new track(s)	string				http://www.gpsbabel.org/htmldoc-development/fmt_track.html#fmt_track_o_title
option	track	fix	Synthesize GPS fixes (PPS, DGPS, 3D, 2D, NONE)	string				http://www.gpsbabel.org/htmldoc-development/fmt_track.html#fmt_track_o_fix
option	track	course	Synthesize course	boolean				http://www.gpsbabel.org/htmldoc-development/fmt_track.html#fmt_track_o_course
option	track	speed	Synthesize speed	boolean				http://www.gpsbabel.org/htmldoc-development/fmt_track.html#fmt_track_o_speed
sort	Rearrange waypoints by resorting	http://www.gpsbabel.org/htmldoc-development/fmt_sort.html
option	sort	gcid	Sort by numeric geocache ID	boolean				http://www.gpsbabel.org/htmldoc-development/fmt_sort.html#fmt_sort_o_gcid
option	sort	shortname	Sort by waypoint short name	boolean				http://www.gpsbabel.org/htmldoc-development/fmt_sort.html#fmt_sort_o_shortname
option	sort	description	Sort by waypoint description	boolean				http://www.gpsbabel.org/htmldoc-development/fmt_sort.html#fmt_sort_o_description
option	sort	time	Sort by time	boolean				http://www.gpsbabel.org/htmldoc-development/fmt_sort.html#fmt_sort_o_time
nuketypes	Remove all waypoints, tracks, or routes	http://www.gpsbabel.org/htmldoc-development/fmt_nuketypes.html
option	nuketypes	waypoints	Remove all waypoints from data stream	boolean	0			http://www.gpsbabel.org/htmldoc-development/fmt_nuketypes.html#fmt_nuketypes_o_waypoints
option	nuketypes	tracks	Remove all tracks from data stream	boolean	0			http://www.gpsbabel.org/htmldoc-development/fmt_nuketypes.html#fmt_nuketypes_o_tracks
option	nuketypes	routes	Remove all routes from data stream	boolean	0			http://www.gpsbabel.org/htmldoc-development/fmt_nuketypes.html#fmt_nuketypes_o_routes
duplicate	Remove Duplicates	http://www.gpsbabel.org/htmldoc-development/fmt_duplicate.html
option	duplicate	shortname	Suppress duplicate waypoints based on name	boolean				http://www.gpsbabel.org/htmldoc-development/fmt_duplicate.html#fmt_duplicate_o_shortname
option	duplicate	location	Suppress duplicate waypoint based on coords	boolean				http://www.gpsbabel.org/htmldoc-development/fmt_duplicate.html#fmt_duplicate_o_location
option	duplicate	all	Suppress all instances of duplicates	boolean				http://www.gpsbabel.org/htmldoc-development/fmt_duplicate.html#fmt_duplicate_o_all
option	duplicate	correct	Use coords from duplicate points	boolean				http://www.gpsbabel.org/htmldoc-development/fmt_duplicate.html#fmt_duplicate_o_correct
position	Remove Points Within Distance	http://www.gpsbabel.org/htmldoc-development/fmt_position.html
option	position	distance	Maximum positional distance	float				http://www.gpsbabel.org/htmldoc-development/fmt_position.html#fmt_position_o_distance
option	position	all	Suppress all points close to other points	boolean				http://www.gpsbabel.org/htmldoc-development/fmt_position.html#fmt_position_o_all
discard	Remove unreliable points with high hdop or vdop	http://www.gpsbabel.org/htmldoc-development/fmt_discard.html
option	discard	hdop	Suppress waypoints with higher hdop	float	-1.0			http://www.gpsbabel.org/htmldoc-development/fmt_discard.html#fmt_discard_o_hdop
option	discard	vdop	Suppress waypoints with higher vdop	float	-1.0			http://www.gpsbabel.org/htmldoc-development/fmt_discard.html#fmt_discard_o_vdop
option	discard	hdopandvdop	Link hdop and vdop supression with AND	boolean				http://www.gpsbabel.org/htmldoc-development/fmt_discard.html#fmt_discard_o_hdopandvdop
reverse	Reverse stops within routes	http://www.gpsbabel.org/htmldoc-development/fmt_reverse.html
stack	Save and restore waypoint lists	http://www.gpsbabel.org/htmldoc-development/fmt_stack.html
option	stack	push	Push waypoint list onto stack	boolean				http://www.gpsbabel.org/htmldoc-development/fmt_stack.html#fmt_stack_o_push
option	stack	pop	Pop waypoint list from stack	boolean				http://www.gpsbabel.org/htmldoc-development/fmt_stack.html#fmt_stack_o_pop
option	stack	swap	Swap waypoint list with <depth> item on stack	boolean				http://www.gpsbabel.org/htmldoc-development/fmt_stack.html#fmt_stack_o_swap
option	stack	copy	(push) Copy waypoint list	boolean				http://www.gpsbabel.org/htmldoc-development/fmt_stack.html#fmt_stack_o_copy
option	stack	append	(pop) Append list	boolean				http://www.gpsbabel.org/htmldoc-development/fmt_stack.html#fmt_stack_o_append
option	stack	discard	(pop) Discard top of stack	boolean				http://www.gpsbabel.org/htmldoc-development/fmt_stack.html#fmt_stack_o_discard
option	stack	replace	(pop) Replace list (default)	boolean				http://www.gpsbabel.org/htmldoc-development/fmt_stack.html#fmt_stack_o_replace
option	stack	depth	(swap) Item to use (default=1)	integer		0		http://www.gpsbabel.org/htmldoc-development/fmt_stack.html#fmt_stack_o_depth
simplify	Simplify routes	http://www.gpsbabel.org/htmldoc-development/fmt_simplify.html
option	simplify	count	Maximum number of points in route	integer		1		http://www.gpsbabel.org/htmldoc-development/fmt_simplify.html#fmt_simplify_o_count
option	simplify	error	Maximum error	string		0		http://www.gpsbabel.org/htmldoc-development/fmt_simplify.html#fmt_simplify_o_error
option	simplify	crosstrack	Use cross-track error (default)	boolean				http://www.gpsbabel.org/htmldoc-development/fmt_simplify.html#fmt_simplify_o_crosstrack
option	simplify	length	Use arclength error	boolean				http://www.gpsbabel.org/htmldoc-development/fmt_simplify.html#fmt_simplify_o_length
transform	Transform waypoints into a route, tracks into routes, ...	http://www.gpsbabel.org/htmldoc-development/fmt_transform.html
option	transform	wpt	Transform track(s) or route(s) into waypoint(s) [R/T]	string				http://www.gpsbabel.org/htmldoc-development/fmt_transform.html#fmt_transform_o_wpt
option	transform	rte	Transform waypoint(s) or track(s) into route(s) [W/T]	string				http://www.gpsbabel.org/htmldoc-development/fmt_transform.html#fmt_transform_o_rte
option	transform	trk	Transform waypoint(s) or route(s) into tracks(s) [W/R]	string				http://www.gpsbabel.org/htmldoc-development/fmt_transform.html#fmt_transform_o_trk
option	transform	del	Delete source data after transformation	boolean	N			http://www.gpsbabel.org/htmldoc-development/fmt_transform.html#fmt_transform_o_del

!formats135

internal\trw----\txcsv\t\t? Character Separated Values\txcsv
\thttp://www.gpsbabel.org/htmldoc-development/fmt_xcsv.html
option\txcsv\tstyle\tFull path to XCSV style file\tfile\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_xcsv.html#fmt_xcsv_o_style

option\txcsv\tsnlen\tMax synthesized shortname length\tinteger\t\t1\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_xcsv.html#fmt_xcsv_o_snlen

option\txcsv\tsnwhite\tAllow whitespace synth. shortnames\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_xcsv.html#fmt_xcsv_o_snwhite

option\txcsv\tsnupper\tUPPERCASE synth. shortnames\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_xcsv.html#fmt_xcsv_o_snupper

option\txcsv\tsnunique\tMake synth. shortnames unique\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_xcsv.html#fmt_xcsv_o_snunique

option\txcsv\turlbase\tBasename prepended to URL on output\tstring\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_xcsv.html#fmt_xcsv_o_urlbase

option\txcsv\tprefer_shortnames\tUse shortname instead of description\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_xcsv.html#fmt_xcsv_o_prefer_shortnames

option\txcsv\tdatum\tGPS datum (def. WGS 84)\tstring\tWGS 84\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_xcsv.html#fmt_xcsv_o_datum

file\t--rw--\talantrl\ttrl\tAlan Map500 tracklogs (.trl)\talantrl
\thttp://www.gpsbabel.org/htmldoc-development/fmt_alantrl.html
file\trw--rw\talanwpr\twpr\tAlan Map500 waypoints and routes (.wpr)\talanwpr
\thttp://www.gpsbabel.org/htmldoc-development/fmt_alanwpr.html
internal\trw----\ttabsep\t\tAll database fields on one tab-separated line\txcsv
\thttp://www.gpsbabel.org/htmldoc-development/fmt_tabsep.html
option\ttabsep\tsnlen\tMax synthesized shortname length\tinteger\t\t1\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_tabsep.html#fmt_tabsep_o_snlen

option\ttabsep\tsnwhite\tAllow whitespace synth. shortnames\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_tabsep.html#fmt_tabsep_o_snwhite

option\ttabsep\tsnupper\tUPPERCASE synth. shortnames\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_tabsep.html#fmt_tabsep_o_snupper

option\ttabsep\tsnunique\tMake synth. shortnames unique\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_tabsep.html#fmt_tabsep_o_snunique

option\ttabsep\turlbase\tBasename prepended to URL on output\tstring\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_tabsep.html#fmt_tabsep_o_urlbase

option\ttabsep\tprefer_shortnames\tUse shortname instead of description\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_tabsep.html#fmt_tabsep_o_prefer_shortnames

option\ttabsep\tdatum\tGPS datum (def. WGS 84)\tstring\tWGS 84\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_tabsep.html#fmt_tabsep_o_datum

serial\t--r---\tbaroiq\t\tBrauniger IQ Series Barograph Download\tbaroiq
\thttp://www.gpsbabel.org/htmldoc-development/fmt_baroiq.html
file\trw----\tcambridge\tdat\tCambridge/Winpilot glider software\txcsv
\thttp://www.gpsbabel.org/htmldoc-development/fmt_cambridge.html
option\tcambridge\tsnlen\tMax synthesized shortname length\tinteger\t\t1\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_cambridge.html#fmt_cambridge_o_snlen

option\tcambridge\tsnwhite\tAllow whitespace synth. shortnames\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_cambridge.html#fmt_cambridge_o_snwhite

option\tcambridge\tsnupper\tUPPERCASE synth. shortnames\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_cambridge.html#fmt_cambridge_o_snupper

option\tcambridge\tsnunique\tMake synth. shortnames unique\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_cambridge.html#fmt_cambridge_o_snunique

option\tcambridge\turlbase\tBasename prepended to URL on output\tstring\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_cambridge.html#fmt_cambridge_o_urlbase

option\tcambridge\tprefer_shortnames\tUse shortname instead of description\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_cambridge.html#fmt_cambridge_o_prefer_shortnames

option\tcambridge\tdatum\tGPS datum (def. WGS 84)\tstring\tWGS 84\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_cambridge.html#fmt_cambridge_o_datum

file\tr-r-r-\tcst\tcst\tCarteSurTable data file\tcst
\thttp://www.gpsbabel.org/htmldoc-development/fmt_cst.html
file\trwr---\tcetus\tpdb\tCetus for Palm/OS\tcetus
\thttp://www.gpsbabel.org/htmldoc-development/fmt_cetus.html
option\tcetus\tdbname\tDatabase name\tstring\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_cetus.html#fmt_cetus_o_dbname

option\tcetus\tappendicon\tAppend icon_descr to description\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_cetus.html#fmt_cetus_o_appendicon

file\trw--rw\tcoastexp\t\tCoastalExplorer XML\tcoastexp
\thttp://www.gpsbabel.org/htmldoc-development/fmt_coastexp.html
file\trw----\tcsv\t\tComma separated values\txcsv
\thttp://www.gpsbabel.org/htmldoc-development/fmt_csv.html
option\tcsv\tsnlen\tMax synthesized shortname length\tinteger\t\t1\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_csv.html#fmt_csv_o_snlen

option\tcsv\tsnwhite\tAllow whitespace synth. shortnames\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_csv.html#fmt_csv_o_snwhite

option\tcsv\tsnupper\tUPPERCASE synth. shortnames\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_csv.html#fmt_csv_o_snupper

option\tcsv\tsnunique\tMake synth. shortnames unique\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_csv.html#fmt_csv_o_snunique

option\tcsv\turlbase\tBasename prepended to URL on output\tstring\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_csv.html#fmt_csv_o_urlbase

option\tcsv\tprefer_shortnames\tUse shortname instead of description\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_csv.html#fmt_csv_o_prefer_shortnames

option\tcsv\tdatum\tGPS datum (def. WGS 84)\tstring\tWGS 84\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_csv.html#fmt_csv_o_datum

file\trwrwrw\tcompegps\t\tCompeGPS data files (.wpt/.trk/.rte)\tcompegps
\thttp://www.gpsbabel.org/htmldoc-development/fmt_compegps.html
option\tcompegps\tdeficon\tDefault icon name\tstring\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_compegps.html#fmt_compegps_o_deficon

option\tcompegps\tindex\tIndex of route/track to write (if more the one in source)\tinteger\t\t1\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_compegps.html#fmt_compegps_o_index

option\tcompegps\tradius\tGive points (waypoints/route points) a default radius (proximity)\tfloat\t\t0\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_compegps.html#fmt_compegps_o_radius

option\tcompegps\tsnlen\tLength of generated shortnames (default 16)\tinteger\t16\t1\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_compegps.html#fmt_compegps_o_snlen

file\trw----\tcopilot\tpdb\tCoPilot Flight Planner for Palm/OS\tcopilot
\thttp://www.gpsbabel.org/htmldoc-development/fmt_copilot.html
file\trwr---\tcoto\tpdb\tcotoGPS for Palm/OS\tcoto
\thttp://www.gpsbabel.org/htmldoc-development/fmt_coto.html
option\tcoto\tzerocat\tName of the 'unassigned' category\tstring\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_coto.html#fmt_coto_o_zerocat

\thttp://www.gpsbabel.org/htmldoc-development/fmt_coto.html#fmt_coto_o_internals

internal\trw----\tcustom\t\tCustom "Everything" Style\txcsv
\thttp://www.gpsbabel.org/htmldoc-development/fmt_custom.html
option\tcustom\tsnlen\tMax synthesized shortname length\tinteger\t\t1\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_custom.html#fmt_custom_o_snlen

option\tcustom\tsnwhite\tAllow whitespace synth. shortnames\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_custom.html#fmt_custom_o_snwhite

option\tcustom\tsnupper\tUPPERCASE synth. shortnames\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_custom.html#fmt_custom_o_snupper

option\tcustom\tsnunique\tMake synth. shortnames unique\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_custom.html#fmt_custom_o_snunique

option\tcustom\turlbase\tBasename prepended to URL on output\tstring\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_custom.html#fmt_custom_o_urlbase

option\tcustom\tprefer_shortnames\tUse shortname instead of description\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_custom.html#fmt_custom_o_prefer_shortnames

option\tcustom\tdatum\tGPS datum (def. WGS 84)\tstring\tWGS 84\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_custom.html#fmt_custom_o_datum

file\t--r---\taxim_gpb\tgpb\tDell Axim Navigation System (.gpb) file format\taxim_gpb
\thttp://www.gpsbabel.org/htmldoc-development/fmt_axim_gpb.html
file\trw-wrw\tan1\tan1\tDeLorme .an1 (drawing) file\tan1
\thttp://www.gpsbabel.org/htmldoc-development/fmt_an1.html
option\tan1\ttype\tType of .an1 file\tstring\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_an1.html#fmt_an1_o_type

option\tan1\troad\tRoad type changes\tstring\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_an1.html#fmt_an1_o_road

option\tan1\tnogc\tDo not add geocache data to description\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_an1.html#fmt_an1_o_nogc

option\tan1\tnourl\tDo not add URLs to description\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_an1.html#fmt_an1_o_nourl

option\tan1\tdeficon\tSymbol to use for point data\tstring\tRed Flag\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_an1.html#fmt_an1_o_deficon

option\tan1\tcolor\tColor for lines or mapnotes\tstring\tred\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_an1.html#fmt_an1_o_color

option\tan1\tzoom\tZoom level to reduce points\tinteger\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_an1.html#fmt_an1_o_zoom

option\tan1\twpt_type\tWaypoint type\tstring\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_an1.html#fmt_an1_o_wpt_type

option\tan1\tradius\tRadius for circles\tstring\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_an1.html#fmt_an1_o_radius

file\t--rw--\tgpl\tgpl\tDeLorme GPL\tgpl
\thttp://www.gpsbabel.org/htmldoc-development/fmt_gpl.html
file\trw----\tsaplus\t\tDeLorme Street Atlas Plus\txcsv
\thttp://www.gpsbabel.org/htmldoc-development/fmt_saplus.html
option\tsaplus\tsnlen\tMax synthesized shortname length\tinteger\t\t1\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_saplus.html#fmt_saplus_o_snlen

option\tsaplus\tsnwhite\tAllow whitespace synth. shortnames\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_saplus.html#fmt_saplus_o_snwhite

option\tsaplus\tsnupper\tUPPERCASE synth. shortnames\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_saplus.html#fmt_saplus_o_snupper

option\tsaplus\tsnunique\tMake synth. shortnames unique\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_saplus.html#fmt_saplus_o_snunique

option\tsaplus\turlbase\tBasename prepended to URL on output\tstring\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_saplus.html#fmt_saplus_o_urlbase

option\tsaplus\tprefer_shortnames\tUse shortname instead of description\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_saplus.html#fmt_saplus_o_prefer_shortnames

option\tsaplus\tdatum\tGPS datum (def. WGS 84)\tstring\tWGS 84\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_saplus.html#fmt_saplus_o_datum

file\t--r---\tsaroute\tanr\tDeLorme Street Atlas Route\tsaroute
\thttp://www.gpsbabel.org/htmldoc-development/fmt_saroute.html
option\tsaroute\tturns_important\tKeep turns if simplify filter is used\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_saroute.html#fmt_saroute_o_turns_important

option\tsaroute\tturns_only\tOnly read turns; skip all other points\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_saroute.html#fmt_saroute_o_turns_only

option\tsaroute\tsplit\tSplit into multiple routes at turns\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_saroute.html#fmt_saroute_o_split

option\tsaroute\tcontrols\tRead control points as waypoint/route/none\tstring\tnone\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_saroute.html#fmt_saroute_o_controls

option\tsaroute\ttimes\tSynthesize track times\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_saroute.html#fmt_saroute_o_times

file\trw----\txmap\twpt\tDeLorme XMap HH Native .WPT\txcsv
\thttp://www.gpsbabel.org/htmldoc-development/fmt_xmap.html
option\txmap\tsnlen\tMax synthesized shortname length\tinteger\t\t1\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_xmap.html#fmt_xmap_o_snlen

option\txmap\tsnwhite\tAllow whitespace synth. shortnames\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_xmap.html#fmt_xmap_o_snwhite

option\txmap\tsnupper\tUPPERCASE synth. shortnames\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_xmap.html#fmt_xmap_o_snupper

option\txmap\tsnunique\tMake synth. shortnames unique\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_xmap.html#fmt_xmap_o_snunique

option\txmap\turlbase\tBasename prepended to URL on output\tstring\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_xmap.html#fmt_xmap_o_urlbase

option\txmap\tprefer_shortnames\tUse shortname instead of description\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_xmap.html#fmt_xmap_o_prefer_shortnames

option\txmap\tdatum\tGPS datum (def. WGS 84)\tstring\tWGS 84\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_xmap.html#fmt_xmap_o_datum

file\trw----\txmap2006\ttxt\tDeLorme XMap/SAHH 2006 Native .TXT\txcsv
\thttp://www.gpsbabel.org/htmldoc-development/fmt_xmap2006.html
option\txmap2006\tsnlen\tMax synthesized shortname length\tinteger\t\t1\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_xmap2006.html#fmt_xmap2006_o_snlen

option\txmap2006\tsnwhite\tAllow whitespace synth. shortnames\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_xmap2006.html#fmt_xmap2006_o_snwhite

option\txmap2006\tsnupper\tUPPERCASE synth. shortnames\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_xmap2006.html#fmt_xmap2006_o_snupper

option\txmap2006\tsnunique\tMake synth. shortnames unique\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_xmap2006.html#fmt_xmap2006_o_snunique

option\txmap2006\turlbase\tBasename prepended to URL on output\tstring\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_xmap2006.html#fmt_xmap2006_o_urlbase

option\txmap2006\tprefer_shortnames\tUse shortname instead of description\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_xmap2006.html#fmt_xmap2006_o_prefer_shortnames

option\txmap2006\tdatum\tGPS datum (def. WGS 84)\tstring\tWGS 84\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_xmap2006.html#fmt_xmap2006_o_datum

file\trw----\txmapwpt\t\tDeLorme XMat HH Street Atlas USA .WPT (PPC)\txcsv
\thttp://www.gpsbabel.org/htmldoc-development/fmt_xmapwpt.html
option\txmapwpt\tsnlen\tMax synthesized shortname length\tinteger\t\t1\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_xmapwpt.html#fmt_xmapwpt_o_snlen

option\txmapwpt\tsnwhite\tAllow whitespace synth. shortnames\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_xmapwpt.html#fmt_xmapwpt_o_snwhite

option\txmapwpt\tsnupper\tUPPERCASE synth. shortnames\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_xmapwpt.html#fmt_xmapwpt_o_snupper

option\txmapwpt\tsnunique\tMake synth. shortnames unique\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_xmapwpt.html#fmt_xmapwpt_o_snunique

option\txmapwpt\turlbase\tBasename prepended to URL on output\tstring\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_xmapwpt.html#fmt_xmapwpt_o_urlbase

option\txmapwpt\tprefer_shortnames\tUse shortname instead of description\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_xmapwpt.html#fmt_xmapwpt_o_prefer_shortnames

option\txmapwpt\tdatum\tGPS datum (def. WGS 84)\tstring\tWGS 84\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_xmapwpt.html#fmt_xmapwpt_o_datum

file\trw----\teasygps\t.loc\tEasyGPS binary format\teasygps
\thttp://www.gpsbabel.org/htmldoc-development/fmt_easygps.html
internal\trwrwrw\tshape\tshp\tESRI shapefile\tshape
\thttp://www.gpsbabel.org/htmldoc-development/fmt_shape.html
option\tshape\tname\tIndex of name field in .dbf\tstring\t\t0\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_shape.html#fmt_shape_o_name

option\tshape\turl\tIndex of URL field in .dbf\tinteger\t\t0\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_shape.html#fmt_shape_o_url

file\t--rwrw\tigc\t\tFAI/IGC Flight Recorder Data Format\tigc
\thttp://www.gpsbabel.org/htmldoc-development/fmt_igc.html
option\tigc\ttimeadj\t(integer sec or 'auto') Barograph to GPS time diff\tstring\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_igc.html#fmt_igc_o_timeadj

file\t-w-w-w\tgpssim\tgpssim\tFranson GPSGate Simulation\tgpssim
\thttp://www.gpsbabel.org/htmldoc-development/fmt_gpssim.html
option\tgpssim\twayptspd\tDefault speed for waypoints (knots/hr)\tfloat\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_gpssim.html#fmt_gpssim_o_wayptspd

option\tgpssim\tsplit\tSplit input into separate files\tboolean\t0\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_gpssim.html#fmt_gpssim_o_split

file\trw----\tfugawi\ttxt\tFugawi\txcsv
\thttp://www.gpsbabel.org/htmldoc-development/fmt_fugawi.html
option\tfugawi\tsnlen\tMax synthesized shortname length\tinteger\t\t1\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_fugawi.html#fmt_fugawi_o_snlen

option\tfugawi\tsnwhite\tAllow whitespace synth. shortnames\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_fugawi.html#fmt_fugawi_o_snwhite

option\tfugawi\tsnupper\tUPPERCASE synth. shortnames\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_fugawi.html#fmt_fugawi_o_snupper

option\tfugawi\tsnunique\tMake synth. shortnames unique\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_fugawi.html#fmt_fugawi_o_snunique

option\tfugawi\turlbase\tBasename prepended to URL on output\tstring\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_fugawi.html#fmt_fugawi_o_urlbase

option\tfugawi\tprefer_shortnames\tUse shortname instead of description\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_fugawi.html#fmt_fugawi_o_prefer_shortnames

option\tfugawi\tdatum\tGPS datum (def. WGS 84)\tstring\tWGS 84\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_fugawi.html#fmt_fugawi_o_datum

file\tr-r-r-\tg7towin\tg7t\tG7ToWin data files (.g7t)\tg7towin
\thttp://www.gpsbabel.org/htmldoc-development/fmt_g7towin.html
file\trw----\tgarmin301\t\tGarmin 301 Custom position and heartrate\txcsv
\thttp://www.gpsbabel.org/htmldoc-development/fmt_garmin301.html
option\tgarmin301\tsnlen\tMax synthesized shortname length\tinteger\t\t1\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_garmin301.html#fmt_garmin301_o_snlen

option\tgarmin301\tsnwhite\tAllow whitespace synth. shortnames\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_garmin301.html#fmt_garmin301_o_snwhite

option\tgarmin301\tsnupper\tUPPERCASE synth. shortnames\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_garmin301.html#fmt_garmin301_o_snupper

option\tgarmin301\tsnunique\tMake synth. shortnames unique\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_garmin301.html#fmt_garmin301_o_snunique

option\tgarmin301\turlbase\tBasename prepended to URL on output\tstring\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_garmin301.html#fmt_garmin301_o_urlbase

option\tgarmin301\tprefer_shortnames\tUse shortname instead of description\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_garmin301.html#fmt_garmin301_o_prefer_shortnames

option\tgarmin301\tdatum\tGPS datum (def. WGS 84)\tstring\tWGS 84\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_garmin301.html#fmt_garmin301_o_datum

file\t--rw--\tglogbook\txml\tGarmin Logbook XML\tglogbook
\thttp://www.gpsbabel.org/htmldoc-development/fmt_glogbook.html
file\trwrwrw\tgdb\tgdb\tGarmin MapSource - gdb\tgdb
\thttp://www.gpsbabel.org/htmldoc-development/fmt_gdb.html
option\tgdb\tcat\tDefault category on output (1..16)\tinteger\t\t1\t16\thttp://www.gpsbabel.org/htmldoc-development/fmt_gdb.html#fmt_gdb_o_cat

option\tgdb\tver\tVersion of gdb file to generate (1..3)\tinteger\t2\t1\t3\thttp://www.gpsbabel.org/htmldoc-development/fmt_gdb.html#fmt_gdb_o_ver

option\tgdb\tvia\tDrop route points that do not have an equivalent waypoint (hidden points)\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_gdb.html#fmt_gdb_o_via

option\tgdb\troadbook\tInclude major turn points (with description) from calculated route\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_gdb.html#fmt_gdb_o_roadbook

file\trwrwrw\tmapsource\tmps\tGarmin MapSource - mps\tmapsource
\thttp://www.gpsbabel.org/htmldoc-development/fmt_mapsource.html
option\tmapsource\tsnlen\tLength of generated shortnames\tinteger\t10\t1\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_mapsource.html#fmt_mapsource_o_snlen

option\tmapsource\tsnwhite\tAllow whitespace synth. shortnames\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_mapsource.html#fmt_mapsource_o_snwhite

option\tmapsource\tmpsverout\tVersion of mapsource file to generate (3,4,5)\tinteger\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_mapsource.html#fmt_mapsource_o_mpsverout

option\tmapsource\tmpsmergeout\tMerge output with existing file\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_mapsource.html#fmt_mapsource_o_mpsmergeout

option\tmapsource\tmpsusedepth\tUse depth values on output (default is ignore)\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_mapsource.html#fmt_mapsource_o_mpsusedepth

option\tmapsource\tmpsuseprox\tUse proximity values on output (default is ignore)\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_mapsource.html#fmt_mapsource_o_mpsuseprox

file\trwrwrw\tgarmin_txt\ttxt\tGarmin MapSource - txt (tab delimited)\tgarmin_txt
\thttp://www.gpsbabel.org/htmldoc-development/fmt_garmin_txt.html
option\tgarmin_txt\tdate\tRead/Write date format (i.e. yyyy/mm/dd)\tstring\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_garmin_txt.html#fmt_garmin_txt_o_date

option\tgarmin_txt\tdatum\tGPS datum (def. WGS 84)\tstring\tWGS 84\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_garmin_txt.html#fmt_garmin_txt_o_datum

option\tgarmin_txt\tdist\tDistance unit [m=metric, s=statute]\tstring\tm\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_garmin_txt.html#fmt_garmin_txt_o_dist

option\tgarmin_txt\tgrid\tWrite position using this grid.\tstring\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_garmin_txt.html#fmt_garmin_txt_o_grid

option\tgarmin_txt\tprec\tPrecision of coordinates\tinteger\t3\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_garmin_txt.html#fmt_garmin_txt_o_prec

option\tgarmin_txt\ttemp\tTemperature unit [c=Celsius, f=Fahrenheit]\tstring\tc\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_garmin_txt.html#fmt_garmin_txt_o_temp

option\tgarmin_txt\ttime\tRead/Write time format (i.e. HH:mm:ss xx)\tstring\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_garmin_txt.html#fmt_garmin_txt_o_time

option\tgarmin_txt\tutc\tWrite timestamps with offset x to UTC time\tinteger\t\t-23\t+23\thttp://www.gpsbabel.org/htmldoc-development/fmt_garmin_txt.html#fmt_garmin_txt_o_utc

file\trwrwrw\tpcx\tpcx\tGarmin PCX5\tpcx
\thttp://www.gpsbabel.org/htmldoc-development/fmt_pcx.html
option\tpcx\tdeficon\tDefault icon name\tstring\tWaypoint\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_pcx.html#fmt_pcx_o_deficon

option\tpcx\tcartoexploreur\tWrite tracks compatible with Carto Exploreur\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_pcx.html#fmt_pcx_o_cartoexploreur

file\trw----\tgarmin_poi\t\tGarmin POI database\txcsv
\thttp://www.gpsbabel.org/htmldoc-development/fmt_garmin_poi.html
option\tgarmin_poi\tsnlen\tMax synthesized shortname length\tinteger\t\t1\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_garmin_poi.html#fmt_garmin_poi_o_snlen

option\tgarmin_poi\tsnwhite\tAllow whitespace synth. shortnames\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_garmin_poi.html#fmt_garmin_poi_o_snwhite

option\tgarmin_poi\tsnupper\tUPPERCASE synth. shortnames\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_garmin_poi.html#fmt_garmin_poi_o_snupper

option\tgarmin_poi\tsnunique\tMake synth. shortnames unique\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_garmin_poi.html#fmt_garmin_poi_o_snunique

option\tgarmin_poi\turlbase\tBasename prepended to URL on output\tstring\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_garmin_poi.html#fmt_garmin_poi_o_urlbase

option\tgarmin_poi\tprefer_shortnames\tUse shortname instead of description\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_garmin_poi.html#fmt_garmin_poi_o_prefer_shortnames

option\tgarmin_poi\tdatum\tGPS datum (def. WGS 84)\tstring\tWGS 84\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_garmin_poi.html#fmt_garmin_poi_o_datum

file\trw----\tgarmin_gpi\tgpi\tGarmin Points of Interest (.gpi)\tgarmin_gpi
\thttp://www.gpsbabel.org/htmldoc-development/fmt_garmin_gpi.html
option\tgarmin_gpi\tbitmap\tUse specified bitmap on output\tfile\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_garmin_gpi.html#fmt_garmin_gpi_o_bitmap

option\tgarmin_gpi\tcategory\tDefault category on output\tstring\tMy points\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_garmin_gpi.html#fmt_garmin_gpi_o_category

option\tgarmin_gpi\thide\tDon't show gpi bitmap on device\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_garmin_gpi.html#fmt_garmin_gpi_o_hide

option\tgarmin_gpi\tdescr\tWrite description to address field\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_garmin_gpi.html#fmt_garmin_gpi_o_descr

option\tgarmin_gpi\tnotes\tWrite notes to address field\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_garmin_gpi.html#fmt_garmin_gpi_o_notes

option\tgarmin_gpi\tposition\tWrite position to address field\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_garmin_gpi.html#fmt_garmin_gpi_o_position

serial\trwrwrw\tgarmin\t\tGarmin serial/USB protocol\tgarmin
\thttp://www.gpsbabel.org/htmldoc-development/fmt_garmin.html
option\tgarmin\tsnlen\tLength of generated shortnames\tinteger\t\t1\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_garmin.html#fmt_garmin_o_snlen

option\tgarmin\tsnwhite\tAllow whitespace synth. shortnames\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_garmin.html#fmt_garmin_o_snwhite

option\tgarmin\tdeficon\tDefault icon name\tstring\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_garmin.html#fmt_garmin_o_deficon

option\tgarmin\tget_posn\tReturn current position as a waypoint\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_garmin.html#fmt_garmin_o_get_posn

option\tgarmin\tpower_off\tCommand unit to power itself down\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_garmin.html#fmt_garmin_o_power_off

option\tgarmin\tcategory\tCategory number to use for written waypoints\tinteger\t\t1\t16\thttp://www.gpsbabel.org/htmldoc-development/fmt_garmin.html#fmt_garmin_o_category

file\t---w--\tgtrnctr\t\tGarmin Training Centerxml\tgtrnctr
\thttp://www.gpsbabel.org/htmldoc-development/fmt_gtrnctr.html
file\trw----\tgeo\tloc\tGeocaching.com .loc\tgeo
\thttp://www.gpsbabel.org/htmldoc-development/fmt_geo.html
option\tgeo\tdeficon\tDefault icon name\tstring\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_geo.html#fmt_geo_o_deficon

option\tgeo\tnuke_placer\tOmit Placer name\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_geo.html#fmt_geo_o_nuke_placer

file\trw----\tgcdb\tpdb\tGeocachingDB for Palm/OS\tgcdb
\thttp://www.gpsbabel.org/htmldoc-development/fmt_gcdb.html
file\t--rw--\tggv_log\tlog\tGeogrid Viewer tracklogs (.log)\tggv_log
\thttp://www.gpsbabel.org/htmldoc-development/fmt_ggv_log.html
file\trw----\tgeonet\ttxt\tGEOnet Names Server (GNS)\txcsv
\thttp://www.gpsbabel.org/htmldoc-development/fmt_geonet.html
option\tgeonet\tsnlen\tMax synthesized shortname length\tinteger\t\t1\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_geonet.html#fmt_geonet_o_snlen

option\tgeonet\tsnwhite\tAllow whitespace synth. shortnames\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_geonet.html#fmt_geonet_o_snwhite

option\tgeonet\tsnupper\tUPPERCASE synth. shortnames\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_geonet.html#fmt_geonet_o_snupper

option\tgeonet\tsnunique\tMake synth. shortnames unique\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_geonet.html#fmt_geonet_o_snunique

option\tgeonet\turlbase\tBasename prepended to URL on output\tstring\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_geonet.html#fmt_geonet_o_urlbase

option\tgeonet\tprefer_shortnames\tUse shortname instead of description\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_geonet.html#fmt_geonet_o_prefer_shortnames

option\tgeonet\tdatum\tGPS datum (def. WGS 84)\tstring\tWGS 84\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_geonet.html#fmt_geonet_o_datum

file\trw----\tgeoniche\tpdb\tGeoNiche .pdb\tgeoniche
\thttp://www.gpsbabel.org/htmldoc-development/fmt_geoniche.html
option\tgeoniche\tdbname\tDatabase name (filename)\tstring\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_geoniche.html#fmt_geoniche_o_dbname

option\tgeoniche\tcategory\tCategory name (Cache)\tstring\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_geoniche.html#fmt_geoniche_o_category

serial\t--r---\tdg-100\t\tGlobalSat DG-100/BT-335 Download\tdg-100
\thttp://www.gpsbabel.org/htmldoc-development/fmt_dg-100.html
option\tdg-100\terase\tErase device data after download\tboolean\t0\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_dg-100.html#fmt_dg-100_o_erase

file\trwrwrw\tkml\tkml\tGoogle Earth (Keyhole) Markup Language\tkml
\thttp://www.gpsbabel.org/htmldoc-development/fmt_kml.html
option\tkml\tdeficon\tDefault icon name\tstring\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_kml.html#fmt_kml_o_deficon

option\tkml\tlines\tExport linestrings for tracks and routes\tboolean\t1\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_kml.html#fmt_kml_o_lines

option\tkml\tpoints\tExport placemarks for tracks and routes\tboolean\t1\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_kml.html#fmt_kml_o_points

option\tkml\tline_width\tWidth of lines, in pixels\tinteger\t6\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_kml.html#fmt_kml_o_line_width

option\tkml\tline_color\tLine color, specified in hex AABBGGRR\tstring\t64eeee17\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_kml.html#fmt_kml_o_line_color

option\tkml\tfloating\tAltitudes are absolute and not clamped to ground\tboolean\t0\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_kml.html#fmt_kml_o_floating

option\tkml\textrude\tDraw extrusion line from trackpoint to ground\tboolean\t0\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_kml.html#fmt_kml_o_extrude

option\tkml\ttrackdata\tInclude extended data for trackpoints (default = 1)\tboolean\t1\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_kml.html#fmt_kml_o_trackdata

option\tkml\tunits\tUnits used when writing comments ('s'tatute or 'm'etric)\tstring\ts\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_kml.html#fmt_kml_o_units

option\tkml\tlabels\tDisplay labels on track and routepoints  (default = 1)\tboolean\t1\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_kml.html#fmt_kml_o_labels

option\tkml\tmax_position_points\tRetain at most this number of position points  (0 = unlimited)\tinteger\t0\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_kml.html#fmt_kml_o_max_position_points

file\t--r---\tgoogle\txml\tGoogle Maps XML\tgoogle
\thttp://www.gpsbabel.org/htmldoc-development/fmt_google.html
file\trw----\tgpilots\tpdb\tGpilotS\tgpilots
\thttp://www.gpsbabel.org/htmldoc-development/fmt_gpilots.html
option\tgpilots\tdbname\tDatabase name\tstring\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_gpilots.html#fmt_gpilots_o_dbname

file\trwrwrw\tgtm\tgtm\tGPS TrackMaker\tgtm
\thttp://www.gpsbabel.org/htmldoc-development/fmt_gtm.html
file\trw----\tarc\ttxt\tGPSBabel arc filter file\txcsv
\thttp://www.gpsbabel.org/htmldoc-development/fmt_arc.html
option\tarc\tsnlen\tMax synthesized shortname length\tinteger\t\t1\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_arc.html#fmt_arc_o_snlen

option\tarc\tsnwhite\tAllow whitespace synth. shortnames\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_arc.html#fmt_arc_o_snwhite

option\tarc\tsnupper\tUPPERCASE synth. shortnames\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_arc.html#fmt_arc_o_snupper

option\tarc\tsnunique\tMake synth. shortnames unique\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_arc.html#fmt_arc_o_snunique

option\tarc\turlbase\tBasename prepended to URL on output\tstring\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_arc.html#fmt_arc_o_urlbase

option\tarc\tprefer_shortnames\tUse shortname instead of description\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_arc.html#fmt_arc_o_prefer_shortnames

option\tarc\tdatum\tGPS datum (def. WGS 84)\tstring\tWGS 84\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_arc.html#fmt_arc_o_datum

file\trw----\tgpsdrive\t\tGpsDrive Format\txcsv
\thttp://www.gpsbabel.org/htmldoc-development/fmt_gpsdrive.html
option\tgpsdrive\tsnlen\tMax synthesized shortname length\tinteger\t\t1\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_gpsdrive.html#fmt_gpsdrive_o_snlen

option\tgpsdrive\tsnwhite\tAllow whitespace synth. shortnames\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_gpsdrive.html#fmt_gpsdrive_o_snwhite

option\tgpsdrive\tsnupper\tUPPERCASE synth. shortnames\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_gpsdrive.html#fmt_gpsdrive_o_snupper

option\tgpsdrive\tsnunique\tMake synth. shortnames unique\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_gpsdrive.html#fmt_gpsdrive_o_snunique

option\tgpsdrive\turlbase\tBasename prepended to URL on output\tstring\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_gpsdrive.html#fmt_gpsdrive_o_urlbase

option\tgpsdrive\tprefer_shortnames\tUse shortname instead of description\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_gpsdrive.html#fmt_gpsdrive_o_prefer_shortnames

option\tgpsdrive\tdatum\tGPS datum (def. WGS 84)\tstring\tWGS 84\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_gpsdrive.html#fmt_gpsdrive_o_datum

file\trw----\tgpsdrivetrack\t\tGpsDrive Format for Tracks\txcsv
\thttp://www.gpsbabel.org/htmldoc-development/fmt_gpsdrivetrack.html
option\tgpsdrivetrack\tsnlen\tMax synthesized shortname length\tinteger\t\t1\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_gpsdrivetrack.html#fmt_gpsdrivetrack_o_snlen

option\tgpsdrivetrack\tsnwhite\tAllow whitespace synth. shortnames\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_gpsdrivetrack.html#fmt_gpsdrivetrack_o_snwhite

option\tgpsdrivetrack\tsnupper\tUPPERCASE synth. shortnames\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_gpsdrivetrack.html#fmt_gpsdrivetrack_o_snupper

option\tgpsdrivetrack\tsnunique\tMake synth. shortnames unique\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_gpsdrivetrack.html#fmt_gpsdrivetrack_o_snunique

option\tgpsdrivetrack\turlbase\tBasename prepended to URL on output\tstring\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_gpsdrivetrack.html#fmt_gpsdrivetrack_o_urlbase

option\tgpsdrivetrack\tprefer_shortnames\tUse shortname instead of description\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_gpsdrivetrack.html#fmt_gpsdrivetrack_o_prefer_shortnames

option\tgpsdrivetrack\tdatum\tGPS datum (def. WGS 84)\tstring\tWGS 84\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_gpsdrivetrack.html#fmt_gpsdrivetrack_o_datum

file\trw----\tgpsman\t\tGPSman\txcsv
\thttp://www.gpsbabel.org/htmldoc-development/fmt_gpsman.html
option\tgpsman\tsnlen\tMax synthesized shortname length\tinteger\t\t1\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_gpsman.html#fmt_gpsman_o_snlen

option\tgpsman\tsnwhite\tAllow whitespace synth. shortnames\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_gpsman.html#fmt_gpsman_o_snwhite

option\tgpsman\tsnupper\tUPPERCASE synth. shortnames\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_gpsman.html#fmt_gpsman_o_snupper

option\tgpsman\tsnunique\tMake synth. shortnames unique\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_gpsman.html#fmt_gpsman_o_snunique

option\tgpsman\turlbase\tBasename prepended to URL on output\tstring\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_gpsman.html#fmt_gpsman_o_urlbase

option\tgpsman\tprefer_shortnames\tUse shortname instead of description\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_gpsman.html#fmt_gpsman_o_prefer_shortnames

option\tgpsman\tdatum\tGPS datum (def. WGS 84)\tstring\tWGS 84\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_gpsman.html#fmt_gpsman_o_datum

file\trw----\tgpspilot\tpdb\tGPSPilot Tracker for Palm/OS\tgpspilot
\thttp://www.gpsbabel.org/htmldoc-development/fmt_gpspilot.html
option\tgpspilot\tdbname\tDatabase name\tstring\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_gpspilot.html#fmt_gpspilot_o_dbname

file\trw----\tgpsutil\t\tgpsutil\tgpsutil
\thttp://www.gpsbabel.org/htmldoc-development/fmt_gpsutil.html
file\trwrwrw\tgpx\tgpx\tGPX XML\tgpx
\thttp://www.gpsbabel.org/htmldoc-development/fmt_gpx.html
option\tgpx\tsnlen\tLength of generated shortnames\tinteger\t32\t1\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_gpx.html#fmt_gpx_o_snlen

option\tgpx\tsuppresswhite\tNo whitespace in generated shortnames\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_gpx.html#fmt_gpx_o_suppresswhite

option\tgpx\tlogpoint\tCreate waypoints from geocache log entries\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_gpx.html#fmt_gpx_o_logpoint

option\tgpx\turlbase\tBase URL for link tag in output\tstring\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_gpx.html#fmt_gpx_o_urlbase

option\tgpx\tgpxver\tTarget GPX version for output\tstring\t1.0\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_gpx.html#fmt_gpx_o_gpxver

file\trwrw--\thiketech\tgps\tHikeTech\thiketech
\thttp://www.gpsbabel.org/htmldoc-development/fmt_hiketech.html
file\trw----\tholux\twpo\tHolux (gm-100) .wpo Format\tholux
\thttp://www.gpsbabel.org/htmldoc-development/fmt_holux.html
file\trw----\thsandv\t\tHSA Endeavour Navigator export File\thsandv
\thttp://www.gpsbabel.org/htmldoc-development/fmt_hsandv.html
file\t-w----\thtml\thtml\tHTML Output\thtml
\thttp://www.gpsbabel.org/htmldoc-development/fmt_html.html
option\thtml\tstylesheet\tPath to HTML style sheet\tstring\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_html.html#fmt_html_o_stylesheet

option\thtml\tencrypt\tEncrypt hints using ROT13\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_html.html#fmt_html_o_encrypt

option\thtml\tlogs\tInclude groundspeak logs if present\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_html.html#fmt_html_o_logs

option\thtml\tdegformat\tDegrees output as 'ddd', 'dmm'(default) or 'dms'\tstring\tdmm\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_html.html#fmt_html_o_degformat

option\thtml\taltunits\tUnits for altitude (f)eet or (m)etres\tstring\tm\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_html.html#fmt_html_o_altunits

file\t--rw--\tignrando\trdn\tIGN Rando track files\tignrando
\thttp://www.gpsbabel.org/htmldoc-development/fmt_ignrando.html
option\tignrando\tindex\tIndex of track to write (if more the one in source)\tinteger\t\t1\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_ignrando.html#fmt_ignrando_o_index

internal\tr-r-r-\trandom\t\tInternal GPS data generator\trandom
\thttp://www.gpsbabel.org/htmldoc-development/fmt_random.html
option\trandom\tpoints\tGenerate # points\tinteger\t\t1\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_random.html#fmt_random_o_points

option\trandom\tseed\tStarting seed of the internal number generator\tinteger\t\t1\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_random.html#fmt_random_o_seed

file\trw----\tktf2\tktf\tKartex 5 Track File\txcsv
\thttp://www.gpsbabel.org/htmldoc-development/fmt_ktf2.html
option\tktf2\tsnlen\tMax synthesized shortname length\tinteger\t\t1\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_ktf2.html#fmt_ktf2_o_snlen

option\tktf2\tsnwhite\tAllow whitespace synth. shortnames\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_ktf2.html#fmt_ktf2_o_snwhite

option\tktf2\tsnupper\tUPPERCASE synth. shortnames\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_ktf2.html#fmt_ktf2_o_snupper

option\tktf2\tsnunique\tMake synth. shortnames unique\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_ktf2.html#fmt_ktf2_o_snunique

option\tktf2\turlbase\tBasename prepended to URL on output\tstring\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_ktf2.html#fmt_ktf2_o_urlbase

option\tktf2\tprefer_shortnames\tUse shortname instead of description\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_ktf2.html#fmt_ktf2_o_prefer_shortnames

option\tktf2\tdatum\tGPS datum (def. WGS 84)\tstring\tWGS 84\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_ktf2.html#fmt_ktf2_o_datum

file\trw----\tkwf2\tkwf\tKartex 5 Waypoint File\txcsv
\thttp://www.gpsbabel.org/htmldoc-development/fmt_kwf2.html
option\tkwf2\tsnlen\tMax synthesized shortname length\tinteger\t\t1\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_kwf2.html#fmt_kwf2_o_snlen

option\tkwf2\tsnwhite\tAllow whitespace synth. shortnames\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_kwf2.html#fmt_kwf2_o_snwhite

option\tkwf2\tsnupper\tUPPERCASE synth. shortnames\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_kwf2.html#fmt_kwf2_o_snupper

option\tkwf2\tsnunique\tMake synth. shortnames unique\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_kwf2.html#fmt_kwf2_o_snunique

option\tkwf2\turlbase\tBasename prepended to URL on output\tstring\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_kwf2.html#fmt_kwf2_o_urlbase

option\tkwf2\tprefer_shortnames\tUse shortname instead of description\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_kwf2.html#fmt_kwf2_o_prefer_shortnames

option\tkwf2\tdatum\tGPS datum (def. WGS 84)\tstring\tWGS 84\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_kwf2.html#fmt_kwf2_o_datum

file\t--rw--\tkompass_tk\twp\tKompass (DAV) Track (.tk)\txcsv
\thttp://www.gpsbabel.org/htmldoc-development/fmt_kompass_tk.html
option\tkompass_tk\tsnlen\tMax synthesized shortname length\tinteger\t\t1\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_kompass_tk.html#fmt_kompass_tk_o_snlen

option\tkompass_tk\tsnwhite\tAllow whitespace synth. shortnames\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_kompass_tk.html#fmt_kompass_tk_o_snwhite

option\tkompass_tk\tsnupper\tUPPERCASE synth. shortnames\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_kompass_tk.html#fmt_kompass_tk_o_snupper

option\tkompass_tk\tsnunique\tMake synth. shortnames unique\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_kompass_tk.html#fmt_kompass_tk_o_snunique

option\tkompass_tk\turlbase\tBasename prepended to URL on output\tstring\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_kompass_tk.html#fmt_kompass_tk_o_urlbase

option\tkompass_tk\tprefer_shortnames\tUse shortname instead of description\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_kompass_tk.html#fmt_kompass_tk_o_prefer_shortnames

option\tkompass_tk\tdatum\tGPS datum (def. WGS 84)\tstring\tWGS 84\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_kompass_tk.html#fmt_kompass_tk_o_datum

file\trw----\tkompass_wp\twp\tKompass (DAV) Waypoints (.wp)\txcsv
\thttp://www.gpsbabel.org/htmldoc-development/fmt_kompass_wp.html
option\tkompass_wp\tsnlen\tMax synthesized shortname length\tinteger\t\t1\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_kompass_wp.html#fmt_kompass_wp_o_snlen

option\tkompass_wp\tsnwhite\tAllow whitespace synth. shortnames\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_kompass_wp.html#fmt_kompass_wp_o_snwhite

option\tkompass_wp\tsnupper\tUPPERCASE synth. shortnames\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_kompass_wp.html#fmt_kompass_wp_o_snupper

option\tkompass_wp\tsnunique\tMake synth. shortnames unique\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_kompass_wp.html#fmt_kompass_wp_o_snunique

option\tkompass_wp\turlbase\tBasename prepended to URL on output\tstring\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_kompass_wp.html#fmt_kompass_wp_o_urlbase

option\tkompass_wp\tprefer_shortnames\tUse shortname instead of description\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_kompass_wp.html#fmt_kompass_wp_o_prefer_shortnames

option\tkompass_wp\tdatum\tGPS datum (def. WGS 84)\tstring\tWGS 84\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_kompass_wp.html#fmt_kompass_wp_o_datum

file\trwrwrw\tpsitrex\t\tKuDaTa PsiTrex text\tpsitrex
\thttp://www.gpsbabel.org/htmldoc-development/fmt_psitrex.html
file\trwrwrw\tlowranceusr\tusr\tLowrance USR\tlowranceusr
\thttp://www.gpsbabel.org/htmldoc-development/fmt_lowranceusr.html
option\tlowranceusr\tignoreicons\tIgnore event marker icons on read\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_lowranceusr.html#fmt_lowranceusr_o_ignoreicons

option\tlowranceusr\twriteasicons\tTreat waypoints as icons on write\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_lowranceusr.html#fmt_lowranceusr_o_writeasicons

option\tlowranceusr\tmerge\t(USR output) Merge into one segmented track\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_lowranceusr.html#fmt_lowranceusr_o_merge

option\tlowranceusr\tbreak\t(USR input) Break segments into separate tracks\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_lowranceusr.html#fmt_lowranceusr_o_break

file\t-w----\tmaggeo\tgs\tMagellan Explorist Geocaching\tmaggeo
\thttp://www.gpsbabel.org/htmldoc-development/fmt_maggeo.html
file\trwrwrw\tmapsend\t\tMagellan Mapsend\tmapsend
\thttp://www.gpsbabel.org/htmldoc-development/fmt_mapsend.html
option\tmapsend\ttrkver\tMapSend version TRK file to generate (3,4)\tinteger\t4\t3\t4\thttp://www.gpsbabel.org/htmldoc-development/fmt_mapsend.html#fmt_mapsend_o_trkver

file\trw----\tmagnav\tpdb\tMagellan NAV Companion for Palm/OS\tmagnav
\thttp://www.gpsbabel.org/htmldoc-development/fmt_magnav.html
file\trwrwrw\tmagellanx\tupt\tMagellan SD files (as for eXplorist)\tmagellanx
\thttp://www.gpsbabel.org/htmldoc-development/fmt_magellanx.html
option\tmagellanx\tdeficon\tDefault icon name\tstring\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_magellanx.html#fmt_magellanx_o_deficon

option\tmagellanx\tmaxcmts\tMax number of comments to write (maxcmts=200)\tinteger\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_magellanx.html#fmt_magellanx_o_maxcmts

file\trwrwrw\tmagellan\t\tMagellan SD files (as for Meridian)\tmagellan
\thttp://www.gpsbabel.org/htmldoc-development/fmt_magellan.html
option\tmagellan\tdeficon\tDefault icon name\tstring\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_magellan.html#fmt_magellan_o_deficon

option\tmagellan\tmaxcmts\tMax number of comments to write (maxcmts=200)\tinteger\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_magellan.html#fmt_magellan_o_maxcmts

serial\trwrwrw\tmagellan\t\tMagellan serial protocol\tmagellan
\thttp://www.gpsbabel.org/htmldoc-development/fmt_magellan.html
option\tmagellan\tdeficon\tDefault icon name\tstring\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_magellan.html#fmt_magellan_o_deficon

option\tmagellan\tmaxcmts\tMax number of comments to write (maxcmts=200)\tinteger\t200\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_magellan.html#fmt_magellan_o_maxcmts

option\tmagellan\tbaud\tNumeric value of bitrate (baud=4800)\tinteger\t4800\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_magellan.html#fmt_magellan_o_baud

option\tmagellan\tnoack\tSuppress use of handshaking in name of speed\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_magellan.html#fmt_magellan_o_noack

option\tmagellan\tnukewpt\tDelete all waypoints\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_magellan.html#fmt_magellan_o_nukewpt

file\t----r-\ttef\txml\tMap&Guide 'TourExchangeFormat' XML\ttef
\thttp://www.gpsbabel.org/htmldoc-development/fmt_tef.html
option\ttef\troutevia\tInclude only via stations in route\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_tef.html#fmt_tef_o_routevia

file\tr---r-\tmag_pdb\tpdb\tMap&Guide to Palm/OS exported files (.pdb)\tmag_pdb
\thttp://www.gpsbabel.org/htmldoc-development/fmt_mag_pdb.html
file\trw----\tmapconverter\ttxt\tMapopolis.com Mapconverter CSV\txcsv
\thttp://www.gpsbabel.org/htmldoc-development/fmt_mapconverter.html
option\tmapconverter\tsnlen\tMax synthesized shortname length\tinteger\t\t1\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_mapconverter.html#fmt_mapconverter_o_snlen

option\tmapconverter\tsnwhite\tAllow whitespace synth. shortnames\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_mapconverter.html#fmt_mapconverter_o_snwhite

option\tmapconverter\tsnupper\tUPPERCASE synth. shortnames\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_mapconverter.html#fmt_mapconverter_o_snupper

option\tmapconverter\tsnunique\tMake synth. shortnames unique\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_mapconverter.html#fmt_mapconverter_o_snunique

option\tmapconverter\turlbase\tBasename prepended to URL on output\tstring\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_mapconverter.html#fmt_mapconverter_o_urlbase

option\tmapconverter\tprefer_shortnames\tUse shortname instead of description\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_mapconverter.html#fmt_mapconverter_o_prefer_shortnames

option\tmapconverter\tdatum\tGPS datum (def. WGS 84)\tstring\tWGS 84\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_mapconverter.html#fmt_mapconverter_o_datum

file\trw----\tmxf\tmxf\tMapTech Exchange Format\txcsv
\thttp://www.gpsbabel.org/htmldoc-development/fmt_mxf.html
option\tmxf\tsnlen\tMax synthesized shortname length\tinteger\t\t1\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_mxf.html#fmt_mxf_o_snlen

option\tmxf\tsnwhite\tAllow whitespace synth. shortnames\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_mxf.html#fmt_mxf_o_snwhite

option\tmxf\tsnupper\tUPPERCASE synth. shortnames\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_mxf.html#fmt_mxf_o_snupper

option\tmxf\tsnunique\tMake synth. shortnames unique\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_mxf.html#fmt_mxf_o_snunique

option\tmxf\turlbase\tBasename prepended to URL on output\tstring\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_mxf.html#fmt_mxf_o_urlbase

option\tmxf\tprefer_shortnames\tUse shortname instead of description\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_mxf.html#fmt_mxf_o_prefer_shortnames

option\tmxf\tdatum\tGPS datum (def. WGS 84)\tstring\tWGS 84\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_mxf.html#fmt_mxf_o_datum

file\t----r-\tmsroute\taxe\tMicrosoft AutoRoute 2002 (pin/route reader)\tmsroute
\thttp://www.gpsbabel.org/htmldoc-development/fmt_msroute.html
file\t----r-\tmsroute\test\tMicrosoft Streets and Trips (pin/route reader)\tmsroute
\thttp://www.gpsbabel.org/htmldoc-development/fmt_msroute.html
file\trw----\ts_and_t\ttxt\tMicrosoft Streets and Trips 2002-2006\txcsv
\thttp://www.gpsbabel.org/htmldoc-development/fmt_s_and_t.html
option\ts_and_t\tsnlen\tMax synthesized shortname length\tinteger\t\t1\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_s_and_t.html#fmt_s_and_t_o_snlen

option\ts_and_t\tsnwhite\tAllow whitespace synth. shortnames\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_s_and_t.html#fmt_s_and_t_o_snwhite

option\ts_and_t\tsnupper\tUPPERCASE synth. shortnames\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_s_and_t.html#fmt_s_and_t_o_snupper

option\ts_and_t\tsnunique\tMake synth. shortnames unique\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_s_and_t.html#fmt_s_and_t_o_snunique

option\ts_and_t\turlbase\tBasename prepended to URL on output\tstring\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_s_and_t.html#fmt_s_and_t_o_urlbase

option\ts_and_t\tprefer_shortnames\tUse shortname instead of description\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_s_and_t.html#fmt_s_and_t_o_prefer_shortnames

option\ts_and_t\tdatum\tGPS datum (def. WGS 84)\tstring\tWGS 84\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_s_and_t.html#fmt_s_and_t_o_datum

file\t----rw\tbcr\tbcr\tMotorrad Routenplaner (Map&Guide) .bcr files\tbcr
\thttp://www.gpsbabel.org/htmldoc-development/fmt_bcr.html
option\tbcr\tindex\tIndex of route to write (if more the one in source)\tinteger\t\t1\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_bcr.html#fmt_bcr_o_index

option\tbcr\tname\tNew name for the route\tstring\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_bcr.html#fmt_bcr_o_name

option\tbcr\tradius\tRadius of our big earth (default 6371000 meters)\tfloat\t6371000\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_bcr.html#fmt_bcr_o_radius

option\tbcr\tprefer_shortnames\tUse shortname instead of description\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_bcr.html#fmt_bcr_o_prefer_shortnames

file\trw----\tpsp\tpsp\tMS PocketStreets 2002 Pushpin\tpsp
\thttp://www.gpsbabel.org/htmldoc-development/fmt_psp.html
file\trw----\ttpg\ttpg\tNational Geographic Topo .tpg (waypoints)\ttpg
\thttp://www.gpsbabel.org/htmldoc-development/fmt_tpg.html
option\ttpg\tdatum\tDatum (default=NAD27)\tstring\tN. America 1927 mean\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_tpg.html#fmt_tpg_o_datum

file\t--r---\ttpo2\ttpo\tNational Geographic Topo 2.x .tpo\ttpo2
\thttp://www.gpsbabel.org/htmldoc-development/fmt_tpo2.html
file\tr-r-r-\ttpo3\ttpo\tNational Geographic Topo 3.x/4.x .tpo\ttpo3
\thttp://www.gpsbabel.org/htmldoc-development/fmt_tpo3.html
file\tr-----\tnavicache\t\tNavicache.com XML\tnavicache
\thttp://www.gpsbabel.org/htmldoc-development/fmt_navicache.html
option\tnavicache\tnoretired\tSuppress retired geocaches\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_navicache.html#fmt_navicache_o_noretired

file\t----rw\tnmn4\trte\tNavigon Mobile Navigator .rte files\tnmn4
\thttp://www.gpsbabel.org/htmldoc-development/fmt_nmn4.html
option\tnmn4\tindex\tIndex of route to write (if more the one in source)\tinteger\t\t1\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_nmn4.html#fmt_nmn4_o_index

file\trw----\tdna\tdna\tNavitrak DNA marker format\txcsv
\thttp://www.gpsbabel.org/htmldoc-development/fmt_dna.html
option\tdna\tsnlen\tMax synthesized shortname length\tinteger\t\t1\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_dna.html#fmt_dna_o_snlen

option\tdna\tsnwhite\tAllow whitespace synth. shortnames\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_dna.html#fmt_dna_o_snwhite

option\tdna\tsnupper\tUPPERCASE synth. shortnames\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_dna.html#fmt_dna_o_snupper

option\tdna\tsnunique\tMake synth. shortnames unique\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_dna.html#fmt_dna_o_snunique

option\tdna\turlbase\tBasename prepended to URL on output\tstring\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_dna.html#fmt_dna_o_urlbase

option\tdna\tprefer_shortnames\tUse shortname instead of description\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_dna.html#fmt_dna_o_prefer_shortnames

option\tdna\tdatum\tGPS datum (def. WGS 84)\tstring\tWGS 84\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_dna.html#fmt_dna_o_datum

file\tr-----\tnetstumbler\t\tNetStumbler Summary File (text)\tnetstumbler
\thttp://www.gpsbabel.org/htmldoc-development/fmt_netstumbler.html
option\tnetstumbler\tnseicon\tNon-stealth encrypted icon name\tstring\tRed Square\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_netstumbler.html#fmt_netstumbler_o_nseicon

option\tnetstumbler\tnsneicon\tNon-stealth non-encrypted icon name\tstring\tGreen Square\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_netstumbler.html#fmt_netstumbler_o_nsneicon

option\tnetstumbler\tseicon\tStealth encrypted icon name\tstring\tRed Diamond\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_netstumbler.html#fmt_netstumbler_o_seicon

option\tnetstumbler\tsneicon\tStealth non-encrypted icon name\tstring\tGreen Diamond\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_netstumbler.html#fmt_netstumbler_o_sneicon

option\tnetstumbler\tsnmac\tShortname is MAC address\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_netstumbler.html#fmt_netstumbler_o_snmac

file\trw----\tnima\t\tNIMA/GNIS Geographic Names File\txcsv
\thttp://www.gpsbabel.org/htmldoc-development/fmt_nima.html
option\tnima\tsnlen\tMax synthesized shortname length\tinteger\t\t1\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_nima.html#fmt_nima_o_snlen

option\tnima\tsnwhite\tAllow whitespace synth. shortnames\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_nima.html#fmt_nima_o_snwhite

option\tnima\tsnupper\tUPPERCASE synth. shortnames\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_nima.html#fmt_nima_o_snupper

option\tnima\tsnunique\tMake synth. shortnames unique\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_nima.html#fmt_nima_o_snunique

option\tnima\turlbase\tBasename prepended to URL on output\tstring\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_nima.html#fmt_nima_o_urlbase

option\tnima\tprefer_shortnames\tUse shortname instead of description\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_nima.html#fmt_nima_o_prefer_shortnames

option\tnima\tdatum\tGPS datum (def. WGS 84)\tstring\tWGS 84\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_nima.html#fmt_nima_o_datum

file\trwrw--\tnmea\t\tNMEA 0183 sentences\tnmea
\thttp://www.gpsbabel.org/htmldoc-development/fmt_nmea.html
option\tnmea\tsnlen\tMax length of waypoint name to write\tinteger\t6\t1\t64\thttp://www.gpsbabel.org/htmldoc-development/fmt_nmea.html#fmt_nmea_o_snlen

option\tnmea\tgprmc\tRead/write GPRMC sentences\tboolean\t1\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_nmea.html#fmt_nmea_o_gprmc

option\tnmea\tgpgga\tRead/write GPGGA sentences\tboolean\t1\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_nmea.html#fmt_nmea_o_gpgga

option\tnmea\tgpvtg\tRead/write GPVTG sentences\tboolean\t1\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_nmea.html#fmt_nmea_o_gpvtg

option\tnmea\tgpgsa\tRead/write GPGSA sentences\tboolean\t1\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_nmea.html#fmt_nmea_o_gpgsa

option\tnmea\tdate\tComplete date-free tracks with given date (YYYYMMDD).\tinteger\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_nmea.html#fmt_nmea_o_date

option\tnmea\tget_posn\tReturn current position as a waypoint\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_nmea.html#fmt_nmea_o_get_posn

option\tnmea\tpause\tDecimal seconds to pause between groups of strings\tinteger\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_nmea.html#fmt_nmea_o_pause

option\tnmea\tappend_positioning\tAppend realtime positioning data to the output file instead of truncating\tboolean\t0\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_nmea.html#fmt_nmea_o_append_positioning

option\tnmea\tbaud\tSpeed in bits per second of serial port (baud=4800)\tinteger\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_nmea.html#fmt_nmea_o_baud

file\trw----\tlmx\t\tNokia Landmark Exchange\tlmx
\thttp://www.gpsbabel.org/htmldoc-development/fmt_lmx.html
file\trwrwrw\tozi\t\tOziExplorer\tozi
\thttp://www.gpsbabel.org/htmldoc-development/fmt_ozi.html
option\tozi\tpack\tWrite all tracks into one file\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_ozi.html#fmt_ozi_o_pack

option\tozi\tsnlen\tMax synthesized shortname length\tinteger\t32\t1\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_ozi.html#fmt_ozi_o_snlen

option\tozi\tsnwhite\tAllow whitespace synth. shortnames\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_ozi.html#fmt_ozi_o_snwhite

option\tozi\tsnupper\tUPPERCASE synth. shortnames\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_ozi.html#fmt_ozi_o_snupper

option\tozi\tsnunique\tMake synth. shortnames unique\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_ozi.html#fmt_ozi_o_snunique

option\tozi\twptfgcolor\tWaypoint foreground color\tstring\tblack\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_ozi.html#fmt_ozi_o_wptfgcolor

option\tozi\twptbgcolor\tWaypoint background color\tstring\tyellow\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_ozi.html#fmt_ozi_o_wptbgcolor

file\t-w----\tpalmdoc\tpdb\tPalmDoc Output\tpalmdoc
\thttp://www.gpsbabel.org/htmldoc-development/fmt_palmdoc.html
option\tpalmdoc\tnosep\tNo separator lines between waypoints\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_palmdoc.html#fmt_palmdoc_o_nosep

option\tpalmdoc\tdbname\tDatabase name\tstring\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_palmdoc.html#fmt_palmdoc_o_dbname

option\tpalmdoc\tencrypt\tEncrypt hints with ROT13\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_palmdoc.html#fmt_palmdoc_o_encrypt

option\tpalmdoc\tlogs\tInclude groundspeak logs if present\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_palmdoc.html#fmt_palmdoc_o_logs

option\tpalmdoc\tbookmarks_short\tInclude short name in bookmarks\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_palmdoc.html#fmt_palmdoc_o_bookmarks_short

file\trwrwrw\tpathaway\tpdb\tPathAway Database for Palm/OS\tpathaway
\thttp://www.gpsbabel.org/htmldoc-development/fmt_pathaway.html
option\tpathaway\tdate\tRead/Write date format (i.e. DDMMYYYY)\tstring\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_pathaway.html#fmt_pathaway_o_date

option\tpathaway\tdbname\tDatabase name\tstring\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_pathaway.html#fmt_pathaway_o_dbname

option\tpathaway\tdeficon\tDefault icon name\tstring\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_pathaway.html#fmt_pathaway_o_deficon

option\tpathaway\tsnlen\tLength of generated shortnames\tinteger\t10\t1\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_pathaway.html#fmt_pathaway_o_snlen

file\trw----\tquovadis\tpdb\tQuovadis\tquovadis
\thttp://www.gpsbabel.org/htmldoc-development/fmt_quovadis.html
option\tquovadis\tdbname\tDatabase name\tstring\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_quovadis.html#fmt_quovadis_o_dbname

file\trw--rw\traymarine\trwf\tRaymarine Waypoint File (.rwf)\traymarine
\thttp://www.gpsbabel.org/htmldoc-development/fmt_raymarine.html
option\traymarine\tlocation\tDefault location\tstring\tMy Waypoints\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_raymarine.html#fmt_raymarine_o_location

file\trw----\tcup\tcup\tSee You flight analysis data\txcsv
\thttp://www.gpsbabel.org/htmldoc-development/fmt_cup.html
option\tcup\tsnlen\tMax synthesized shortname length\tinteger\t\t1\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_cup.html#fmt_cup_o_snlen

option\tcup\tsnwhite\tAllow whitespace synth. shortnames\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_cup.html#fmt_cup_o_snwhite

option\tcup\tsnupper\tUPPERCASE synth. shortnames\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_cup.html#fmt_cup_o_snupper

option\tcup\tsnunique\tMake synth. shortnames unique\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_cup.html#fmt_cup_o_snunique

option\tcup\turlbase\tBasename prepended to URL on output\tstring\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_cup.html#fmt_cup_o_urlbase

option\tcup\tprefer_shortnames\tUse shortname instead of description\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_cup.html#fmt_cup_o_prefer_shortnames

option\tcup\tdatum\tGPS datum (def. WGS 84)\tstring\tWGS 84\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_cup.html#fmt_cup_o_datum

file\trw----\tsportsim\ttxt\tSportsim track files (part of zipped .ssz files)\txcsv
\thttp://www.gpsbabel.org/htmldoc-development/fmt_sportsim.html
option\tsportsim\tsnlen\tMax synthesized shortname length\tinteger\t\t1\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_sportsim.html#fmt_sportsim_o_snlen

option\tsportsim\tsnwhite\tAllow whitespace synth. shortnames\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_sportsim.html#fmt_sportsim_o_snwhite

option\tsportsim\tsnupper\tUPPERCASE synth. shortnames\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_sportsim.html#fmt_sportsim_o_snupper

option\tsportsim\tsnunique\tMake synth. shortnames unique\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_sportsim.html#fmt_sportsim_o_snunique

option\tsportsim\turlbase\tBasename prepended to URL on output\tstring\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_sportsim.html#fmt_sportsim_o_urlbase

option\tsportsim\tprefer_shortnames\tUse shortname instead of description\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_sportsim.html#fmt_sportsim_o_prefer_shortnames

option\tsportsim\tdatum\tGPS datum (def. WGS 84)\tstring\tWGS 84\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_sportsim.html#fmt_sportsim_o_datum

file\t--rwrw\tstmsdf\tsdf\tSuunto Trek Manager (STM) .sdf files\tstmsdf
\thttp://www.gpsbabel.org/htmldoc-development/fmt_stmsdf.html
option\tstmsdf\tindex\tIndex of route (if more the one in source)\tinteger\t1\t1\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_stmsdf.html#fmt_stmsdf_o_index

file\trwrwrw\tstmwpp\ttxt\tSuunto Trek Manager (STM) WaypointPlus files\tstmwpp
\thttp://www.gpsbabel.org/htmldoc-development/fmt_stmwpp.html
option\tstmwpp\tindex\tIndex of route/track to write (if more the one in source)\tinteger\t\t1\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_stmwpp.html#fmt_stmwpp_o_index

file\trwrw--\txol\txol\tSwiss Map # (.xol) format\txol
\thttp://www.gpsbabel.org/htmldoc-development/fmt_xol.html
file\trw----\topenoffice\t\tTab delimited fields useful for OpenOffice, Ploticus etc.\txcsv
\thttp://www.gpsbabel.org/htmldoc-development/fmt_openoffice.html
option\topenoffice\tsnlen\tMax synthesized shortname length\tinteger\t\t1\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_openoffice.html#fmt_openoffice_o_snlen

option\topenoffice\tsnwhite\tAllow whitespace synth. shortnames\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_openoffice.html#fmt_openoffice_o_snwhite

option\topenoffice\tsnupper\tUPPERCASE synth. shortnames\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_openoffice.html#fmt_openoffice_o_snupper

option\topenoffice\tsnunique\tMake synth. shortnames unique\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_openoffice.html#fmt_openoffice_o_snunique

option\topenoffice\turlbase\tBasename prepended to URL on output\tstring\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_openoffice.html#fmt_openoffice_o_urlbase

option\topenoffice\tprefer_shortnames\tUse shortname instead of description\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_openoffice.html#fmt_openoffice_o_prefer_shortnames

option\topenoffice\tdatum\tGPS datum (def. WGS 84)\tstring\tWGS 84\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_openoffice.html#fmt_openoffice_o_datum

file\t-w----\ttext\ttxt\tTextual Output\ttext
\thttp://www.gpsbabel.org/htmldoc-development/fmt_text.html
option\ttext\tnosep\tSuppress separator lines between waypoints\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_text.html#fmt_text_o_nosep

option\ttext\tencrypt\tEncrypt hints using ROT13\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_text.html#fmt_text_o_encrypt

option\ttext\tlogs\tInclude groundspeak logs if present\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_text.html#fmt_text_o_logs

option\ttext\tdegformat\tDegrees output as 'ddd', 'dmm'(default) or 'dms'\tstring\tdmm\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_text.html#fmt_text_o_degformat

option\ttext\taltunits\tUnits for altitude (f)eet or (m)etres\tstring\tm\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_text.html#fmt_text_o_altunits

option\ttext\tsplitoutput\tWrite each waypoint in a separate file\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_text.html#fmt_text_o_splitoutput

file\t----rw\ttomtom_itn\titn\tTomTom Itineraries (.itn)\txcsv
\thttp://www.gpsbabel.org/htmldoc-development/fmt_tomtom_itn.html
option\ttomtom_itn\tsnlen\tMax synthesized shortname length\tinteger\t\t1\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_tomtom_itn.html#fmt_tomtom_itn_o_snlen

option\ttomtom_itn\tsnwhite\tAllow whitespace synth. shortnames\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_tomtom_itn.html#fmt_tomtom_itn_o_snwhite

option\ttomtom_itn\tsnupper\tUPPERCASE synth. shortnames\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_tomtom_itn.html#fmt_tomtom_itn_o_snupper

option\ttomtom_itn\tsnunique\tMake synth. shortnames unique\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_tomtom_itn.html#fmt_tomtom_itn_o_snunique

option\ttomtom_itn\turlbase\tBasename prepended to URL on output\tstring\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_tomtom_itn.html#fmt_tomtom_itn_o_urlbase

option\ttomtom_itn\tprefer_shortnames\tUse shortname instead of description\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_tomtom_itn.html#fmt_tomtom_itn_o_prefer_shortnames

option\ttomtom_itn\tdatum\tGPS datum (def. WGS 84)\tstring\tWGS 84\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_tomtom_itn.html#fmt_tomtom_itn_o_datum

file\trw----\ttomtom_asc\tasc\tTomTom POI file (.asc)\txcsv
\thttp://www.gpsbabel.org/htmldoc-development/fmt_tomtom_asc.html
option\ttomtom_asc\tsnlen\tMax synthesized shortname length\tinteger\t\t1\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_tomtom_asc.html#fmt_tomtom_asc_o_snlen

option\ttomtom_asc\tsnwhite\tAllow whitespace synth. shortnames\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_tomtom_asc.html#fmt_tomtom_asc_o_snwhite

option\ttomtom_asc\tsnupper\tUPPERCASE synth. shortnames\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_tomtom_asc.html#fmt_tomtom_asc_o_snupper

option\ttomtom_asc\tsnunique\tMake synth. shortnames unique\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_tomtom_asc.html#fmt_tomtom_asc_o_snunique

option\ttomtom_asc\turlbase\tBasename prepended to URL on output\tstring\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_tomtom_asc.html#fmt_tomtom_asc_o_urlbase

option\ttomtom_asc\tprefer_shortnames\tUse shortname instead of description\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_tomtom_asc.html#fmt_tomtom_asc_o_prefer_shortnames

option\ttomtom_asc\tdatum\tGPS datum (def. WGS 84)\tstring\tWGS 84\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_tomtom_asc.html#fmt_tomtom_asc_o_datum

file\trw----\ttomtom\tov2\tTomTom POI file (.ov2)\ttomtom
\thttp://www.gpsbabel.org/htmldoc-development/fmt_tomtom.html
file\trw----\ttmpro\ttmpro\tTopoMapPro Places File\ttmpro
\thttp://www.gpsbabel.org/htmldoc-development/fmt_tmpro.html
file\trwrw--\tdmtlog\ttrl\tTrackLogs digital mapping (.trl)\tdmtlog
\thttp://www.gpsbabel.org/htmldoc-development/fmt_dmtlog.html
option\tdmtlog\tindex\tIndex of track (if more the one in source)\tinteger\t1\t1\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_dmtlog.html#fmt_dmtlog_o_index

file\trw----\ttiger\t\tU.S. Census Bureau Tiger Mapping Service\ttiger
\thttp://www.gpsbabel.org/htmldoc-development/fmt_tiger.html
option\ttiger\tnolabels\tSuppress labels on generated pins\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_tiger.html#fmt_tiger_o_nolabels

option\ttiger\tgenurl\tGenerate file with lat/lon for centering map\toutfile\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_tiger.html#fmt_tiger_o_genurl

option\ttiger\tmargin\tMargin for map.  Degrees or percentage\tfloat\t15%\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_tiger.html#fmt_tiger_o_margin

option\ttiger\tsnlen\tMax shortname length when used with -s\tinteger\t10\t1\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_tiger.html#fmt_tiger_o_snlen

option\ttiger\toldthresh\tDays after which points are considered old\tinteger\t14\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_tiger.html#fmt_tiger_o_oldthresh

option\ttiger\toldmarker\tMarker type for old points\tstring\tredpin\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_tiger.html#fmt_tiger_o_oldmarker

option\ttiger\tnewmarker\tMarker type for new points\tstring\tgreenpin\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_tiger.html#fmt_tiger_o_newmarker

option\ttiger\tsuppresswhite\tSuppress whitespace in generated shortnames\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_tiger.html#fmt_tiger_o_suppresswhite

option\ttiger\tunfoundmarker\tMarker type for unfound points\tstring\tbluepin\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_tiger.html#fmt_tiger_o_unfoundmarker

option\ttiger\txpixels\tWidth in pixels of map\tinteger\t768\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_tiger.html#fmt_tiger_o_xpixels

option\ttiger\typixels\tHeight in pixels of map\tinteger\t768\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_tiger.html#fmt_tiger_o_ypixels

option\ttiger\ticonismarker\tThe icon description is already the marker\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_tiger.html#fmt_tiger_o_iconismarker

file\trwrwrw\tunicsv\t\tUniversal csv with field structure in first line\tunicsv
\thttp://www.gpsbabel.org/htmldoc-development/fmt_unicsv.html
option\tunicsv\tdatum\tGPS datum (def. WGS 84)\tstring\tWGS 84\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_unicsv.html#fmt_unicsv_o_datum

option\tunicsv\tgrid\tWrite position using this grid.\tstring\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_unicsv.html#fmt_unicsv_o_grid

option\tunicsv\tutc\tWrite timestamps with offset x to UTC time\tinteger\t\t-23\t+23\thttp://www.gpsbabel.org/htmldoc-development/fmt_unicsv.html#fmt_unicsv_o_utc

file\t-w----\tvcard\tvcf\tVcard Output (for iPod)\tvcard
\thttp://www.gpsbabel.org/htmldoc-development/fmt_vcard.html
option\tvcard\tencrypt\tEncrypt hints using ROT13\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_vcard.html#fmt_vcard_o_encrypt

file\trwrwrw\tvitosmt\tsmt\tVito Navigator II tracks\tvitosmt
\thttp://www.gpsbabel.org/htmldoc-development/fmt_vitosmt.html
file\t--r---\tvitovtt\tvtt\tVito SmartMap tracks (.vtt)\tvitovtt
\thttp://www.gpsbabel.org/htmldoc-development/fmt_vitovtt.html
file\tr-----\twfff\txml\tWiFiFoFum 2.0 for PocketPC XML\twfff
\thttp://www.gpsbabel.org/htmldoc-development/fmt_wfff.html
option\twfff\taicicon\tInfrastructure closed icon name\tstring\tRed Square\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_wfff.html#fmt_wfff_o_aicicon

option\twfff\taioicon\tInfrastructure open icon name\tstring\tGreen Square\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_wfff.html#fmt_wfff_o_aioicon

option\twfff\tahcicon\tAd-hoc closed icon name\tstring\tRed Diamond\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_wfff.html#fmt_wfff_o_ahcicon

option\twfff\tahoicon\tAd-hoc open icon name\tstring\tGreen Diamond\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_wfff.html#fmt_wfff_o_ahoicon

option\twfff\tsnmac\tShortname is MAC address\tboolean\t\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_wfff.html#fmt_wfff_o_snmac

file\t--r---\twbt-bin\tbin\tWintec WBT-100/200 Binary File Format\twbt-bin
\thttp://www.gpsbabel.org/htmldoc-development/fmt_wbt-bin.html
serial\tr-r---\twbt\t\tWintec WBT-100/200 GPS Download\twbt
\thttp://www.gpsbabel.org/htmldoc-development/fmt_wbt.html
option\twbt\terase\tErase device data after download\tboolean\t0\t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_wbt.html#fmt_wbt_o_erase

file\t--r---\twbt-tk1\ttk1\tWintec WBT-201/G-Rays 2 Binary File Format\twbt-tk1
\thttp://www.gpsbabel.org/htmldoc-development/fmt_wbt-tk1.html
file\tr-----\tyahoo\t\tYahoo Geocode API data\tyahoo
\thttp://www.gpsbabel.org/htmldoc-development/fmt_yahoo.html
option\tyahoo\taddrsep\tString to separate concatenated address fields (default=", ")\tstring\t, \t\t\thttp://www.gpsbabel.org/htmldoc-development/fmt_yahoo.html#fmt_yahoo_o_addrsep

