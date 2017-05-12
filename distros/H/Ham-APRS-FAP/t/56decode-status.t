
# test status message decoding

use Test;
use Data::Dumper;

BEGIN { plan tests => 4 };
use Ham::APRS::FAP qw(parseaprs);

my($aprspacket, $tlm);
my %h;
my $retval;

# the Status message's timestamp is not affected by the raw_timestamp flag.
my $now = time();
my @gm = gmtime($now);
my $mday = $gm[3];
my $tstamp = sprintf('%02d%02d%02dz', $gm[3], $gm[2], $gm[1]);
my $outcome = $now - ($now % 60); # will round down to the minute

my $msg = '>>Nashville,TN>>Toronto,ON';

$aprspacket = 'KB3HVP-14>APU25N,WIDE2-2,qAR,LANSNG:>' . $tstamp . $msg;
$retval = parseaprs($aprspacket, \%h, 'raw_timestamp' => 1);
ok($retval, 1, "failed to parse a status message packet");
ok($h{'type'}, 'status', "the type of a status message packet is wrong");
ok($h{'timestamp'}, $outcome, "the timestamp was miscalculated from the status message packet");
ok($h{'status'}, $msg, "the status message was not parsed correctly from a status packet");
