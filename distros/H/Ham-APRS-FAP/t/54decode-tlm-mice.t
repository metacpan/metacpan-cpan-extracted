
# test mic-e telemetry decoding

use Test;
#use Data::Dumper;

BEGIN { plan tests => 9 + 8 + 2 + 2 };
use Ham::APRS::FAP qw(parseaprs);

my $srccall = "OH7LZB-13";
my $dstcall = "SX15S6";
my $header = "$srccall>$dstcall,TCPIP*,qAC,FOURTH";
my $body = "'I',l \x1C>/";
my $comment = "comment";

my($aprspacket, $tlm);
my %h;
my $retval;

# The new mic-e telemetry format:
# }ss112233445566}
#

# sequence 00, 5 channels of telemetry and one channel of binary bits
$tlm = '|!!!!!!!!!!!!!!|';

$aprspacket = "$header:$body $comment $tlm";
$retval = parseaprs($aprspacket, \%h);

ok($retval, 1, "failed to parse mic-e packet with 5-ch telemetry");
ok($h{'comment'}, $comment, "incorrect comment parsing");

ok($h{'telemetry'}{'seq'}, 0, "wrong sequence parsed from telemetry");

my(@v) = @{ $h{'telemetry'}{'vals'} };
ok($v[0], "0", "wrong value 0 parsed from telemetry");
ok($v[1], "0", "wrong value 1 parsed from telemetry");
ok($v[2], "0", "wrong value 2 parsed from telemetry");
ok($v[3], "0", "wrong value 3 parsed from telemetry");
ok($v[4], "0", "wrong value 4 parsed from telemetry");

ok($h{'telemetry'}{'bits'}, '00000000', "wrong bits parsed from telemetry");

# sequence 00, 1 channel of telemetry
$tlm = '|!!!!|';

$aprspacket = "$header:$body $comment $tlm";
$retval = parseaprs($aprspacket, \%h);

ok($retval, 1, "failed to parse mic-e packet with 5-ch telemetry");
ok($h{'comment'}, $comment, "incorrect comment parsing");

ok($h{'telemetry'}{'seq'}, 0, "wrong sequence parsed from telemetry");

@v = @{ $h{'telemetry'}{'vals'} };
ok($v[0], "0", "wrong value 0 parsed from telemetry");
ok($v[1], undef, "wrong value 1 parsed from telemetry");
ok($v[2], undef, "wrong value 2 parsed from telemetry");
ok($v[3], undef, "wrong value 3 parsed from telemetry");
ok($v[4], undef, "wrong value 4 parsed from telemetry");

## harder one:
$aprspacket = "N6BG-1>S6QTUX:`+,^l!cR/'\";z}||ss11223344bb!\"|!w>f!|3";
$retval = parseaprs($aprspacket, \%h);

#warn Dumper(\%h);

ok($retval, 1, "failed to parse mic-e packet with 5-ch telemetry");
ok($h{'telemetry'}{'bits'}, '10000000', "wrong bits parsed from telemetry");

## one to confuse with !DAO!
$tlm = '|!wEU!![S|';

$aprspacket = "$header:$body $comment $tlm";
$retval = parseaprs($aprspacket, \%h);

ok($retval, 1, "failed to parse mic-e packet with DAO-looking comment telemetry");
ok($h{'comment'}, $comment, "incorrect comment parsing");

