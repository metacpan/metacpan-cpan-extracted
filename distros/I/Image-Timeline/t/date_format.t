
######################### We start with some black magic to print on failure.

$| = 1;
use strict;
use Image::Timeline;
use Test;
require "t/common.pl";

eval "use Date::Format";
if ($@) {
  print "1..0 # Skipped: Date::Format is not installed\n";
  exit;
}

plan tests => 5;

ok 1;

######################### End of black magic.

my $t = new Image::Timeline(width => 600,
			    date_format => '%Y-%m-%d',
			    bar_stepsize => '40%',
			   );
ok $t;

while (<DATA>) {
  my @data = /(.*) \((\d+)-(\d+)\)/ or next;
  $t->add(@data);
}
ok 1;  # Just say we got this far.

ok $t->draw;

my $format = has_gif() ? 'gif' : 'png';
ok &write_and_compare($t, 't/testimage_format', 't/truth_format', $format);

__DATA__
PersonA (306764700-946684800)
PersonB (300000000-876954321)
PersonC (946684800-1262304000)
