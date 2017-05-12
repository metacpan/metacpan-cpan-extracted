#!/usr/bin/perl
#
# USAGE:
# to make an html page containing all flags from images in
# local directory ./flags
#	./make_htm.pl
#
# version 1.01, 9-15-06, michael@bizsystems.com
#

use Geo::CountryFlags;
use Geo::CountryFlags::ISO;
use Geo::CountryFlags::I2C;

my $i2c = hashptr Geo::CountryFlags::I2C;
my $iso = subref Geo::CountryFlags::ISO;

my $i = 0;
print <<EOF;
<html>
<body>
<center>
<table border=0>
<tr align=center>
EOF

foreach (sort keys %$i2c) {
  my $n = $iso->($_);
  if (-e "flags/${_}-flag.gif") {
    print qq|<td><img src=flags/${_}-flag.gif><br>$n</td>\n|;
  } else {
    print qq|<td>none<br>$n</td>\n|;
  }
  if ($i < 3) {
    ++$i;
  } else {
    print "</tr>\n<tr align=center>\n";
    $i = 0;
  }
}

print <<EOF;
</tr></table>
</body>
</html>
EOF
