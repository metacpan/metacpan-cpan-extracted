
# test timestamp option decoding

use Test;

BEGIN { plan tests => 2 + 2 + 2 + 2 + 2 + 2 };
use Ham::APRS::FAP qw(parseaprs);

my($aprspacket, $tlm);
my %h;
my $retval;

my $now = time();
my @gm = gmtime($now);
my $mday = $gm[3];
my $tstamp = sprintf('%02d%02d%02d', $gm[3], $gm[2], $gm[1]);
my $outcome = $now - ($now % 60); # will round down to the minute

# First, try to get the raw timestam through
$aprspacket = 'KB3HVP-14>APU25N,N8TJG-10*,WIDE2-1,qAR,LANSNG:@' . $tstamp . 'z4231.16N/08449.88Wu227/052/A=000941 {UIV32N}';
$retval = parseaprs($aprspacket, \%h, 'raw_timestamp' => 1);
ok($retval, 1, "failed to parse a position packet with @..z timestamp");
ok($h{'timestamp'}, $tstamp, "wrong @..z raw timestamp parsed from position packet");

# Then, try the one decoded to an UNIX timestamp
$aprspacket = 'KB3HVP-14>APU25N,N8TJG-10*,WIDE2-1,qAR,LANSNG:@' . $tstamp . 'z4231.16N/08449.88Wu227/052/A=000941 {UIV32N}';
$retval = parseaprs($aprspacket, \%h);
ok($retval, 1, "failed to parse a position packet with @..z timestamp");
ok($h{'timestamp'}, $outcome, "wrong @..z UNIX timestamp parsed from position packet");

# raw again, from a HMS version
$aprspacket = 'G4EUM-9>APOTC1,G4EUM*,WIDE2-2,qAS,M3SXA-10:/055816h5134.38N/00019.47W>155/023!W26!/A=000188 14.3V 27C HDOP01.0 SATS09';
$retval = parseaprs($aprspacket, \%h, 'raw_timestamp' => 1);
ok($retval, 1, "failed to parse a position packet with /..h timestamp");
ok($h{'timestamp'}, '055816', "wrong /..h raw timestamp parsed from position packet");

# decoded UNIX timestamp from HMS
$now = time();
@gm = gmtime($now);
$mday = $gm[3];
$tstamp = sprintf('%02d%02d%02d', $gm[2], $gm[1], $gm[0]);
$aprspacket = 'G4EUM-9>APOTC1,G4EUM*,WIDE2-2,qAS,M3SXA-10:/' . $tstamp . 'h5134.38N/00019.47W>155/023!W26!/A=000188 14.3V 27C HDOP01.0 SATS09';
$retval = parseaprs($aprspacket, \%h);
ok($retval, 1, "failed to parse a position packet with /..h timestamp");
ok($h{'timestamp'}, $now, "wrong /..h UNIX timestamp parsed from position packet");

# raw again, from a local-time DMH
$aprspacket = 'G4EUM-9>APOTC1,G4EUM*,WIDE2-2,qAS,M3SXA-10:/060642/5134.38N/00019.47W>155/023!W26!/A=000188 14.3V 27C HDOP01.0 SATS09';
$retval = parseaprs($aprspacket, \%h, 'raw_timestamp' => 1);
ok($retval, 1, "failed to parse a position packet with /../ local timestamp");
ok($h{'timestamp'}, '060642', "wrong /..h raw local timestamp parsed from position packet");

# decoded UNIX timestamp from local-time DMH
$now = time();
@gm = localtime($now);
$mday = $gm[3];
$tstamp = sprintf('%02d%02d%02d', $gm[3], $gm[2], $gm[1]);
$outcome = $now - ($now % 60); # will round down to the minute
$aprspacket = 'G4EUM-9>APOTC1,G4EUM*,WIDE2-2,qAS,M3SXA-10:/' . $tstamp . '/5134.38N/00019.47W>155/023!W26!/A=000188 14.3V 27C HDOP01.0 SATS09';
$retval = parseaprs($aprspacket, \%h);
ok($retval, 1, "failed to parse a position packet with /../ local timestamp");
ok($h{'timestamp'}, $outcome, "wrong /../ UNIX timestamp parsed from position packet");

