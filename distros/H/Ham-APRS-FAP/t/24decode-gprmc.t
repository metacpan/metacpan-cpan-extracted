
# a $GPRMC NMEA decoding test
# Wed Dec 12 2007, Hessu, OH7LZB

use Test;

BEGIN { plan tests => 15 };
use Ham::APRS::FAP qw(parseaprs);

my $srccall = "OH7LZB-11";
my $dstcall = "APRS";
my $header = "$srccall>$dstcall,W4GR*,WIDE2-1,qAR,WA4DSY";
my $body = '$GPRMC,145526,A,3349.0378,N,08406.2617,W,23.726,27.9,121207,4.9,W*7A';
my $aprspacket = "$header:$body";
my %h;
my $retval = parseaprs($aprspacket, \%h);

# the parser always appends an SSID - make sure the behaviour doesn't change
$dstcall .= '-0';

ok($retval, 1, "failed to parse a GPRMC NMEA packet");

ok($h{'header'}, $header, "incorrect header parsing");
ok($h{'body'}, $body, "incorrect body parsing");
ok($h{'type'}, 'location', "incorrect packet type parsing");
ok($h{'format'}, 'nmea', "incorrect packet format parsing");

# check for undefined value, when there is no such data in the packet
ok($h{'posambiguity'}, undef, "incorrect posambiguity parsing");
ok($h{'messaging'}, undef, "incorrect messaging bit parsing");

ok($h{'checksumok'}, "1", "incorrect GPRMC checksumok bit parsing");
ok($h{'timestamp'}, "1197471326", "incorrect GPRMC timestamp parsing");

ok(sprintf('%.4f', $h{'latitude'}), "33.8173", "incorrect latitude parsing");
ok(sprintf('%.4f', $h{'longitude'}), "-84.1044", "incorrect longitude parsing");
ok(sprintf('%.4f', $h{'posresolution'}), "0.1852", "incorrect position resolution");

# check for undefined value, when there is no such data in the packet
ok(sprintf('%.2f', $h{'speed'}), "43.94", "incorrect speed");
ok($h{'course'}, "28", "incorrect course");
ok($h{'altitude'}, undef, "incorrect altitude");

