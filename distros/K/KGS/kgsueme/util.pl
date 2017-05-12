package util;

use Storable ();
use Scalar::Util ();

my $staterc = "$ENV{HOME}/.kgsueme";

$stateversion = 1;

our $state = -r $staterc ? Storable::retrieve($staterc) : {};

if ($state->{version} != $stateversion) {
   warn "$staterc has wrong version - ignoring it.\n";
   $state = {};
}

$state->{version} = $stateversion;

$::config = $state->{config} ||= {};

$::config->{speed}            = 0; #d# optimize for speed or memory? (0,1)
$::config->{conserve_memory}  = 0; # try to conserve memory at the expense of speed (0,1,2)
$::config->{randomize}        = 0; # randomize placement of stones (BROKEN)
$::config->{suppress_userpic} = 0; # for omitting the userpic in the game window

sub save_config {
   &gtk::save_state;
   Storable::nstore ($state, $staterc);
   app::status ("save_state", "layout saved");
}

sub format_time($) {
   my ($time) = @_;

   $time > 60*60
      ? sprintf "%d:%02d:%02d", $time / (60 * 60), $time / 60 % 60, $time % 60
      : sprintf      "%d:%02d", $time / 60 % 60, $time % 60;
}

sub date_string($) {
  my ($timestamp) = @_;
  use POSIX ();
  return (POSIX::strftime "%Y-%m-%d %H:%M", localtime $timestamp);
}

sub parse_time($) {

   my $time;
   $time = $time * 60 + $_ for split /:/, $_[0];

   $time;
}

# text to xml
sub toxml($) {
   local $_ = shift;
   s/&/&amp;/g;
   s/</&lt;/g;
   s/]]>/]]&gt;/g;
   $_;
}

# pseudo-"xml" to text
sub xmlto($) {
   local $_ = shift;
   s/&lt;/</g;
   s/&amp;/&/g;
   $_;
}

1;

