
# telemetry decoding
# Wed Mar 12 16:22:53 EET 2008

use Test;

BEGIN { plan tests => 11 };
use Ham::APRS::FAP qw(parseaprs);

my $srccall = "SRCCALL";
my $dstcall = "APRS";
my $aprspacket = "$srccall>$dstcall:T#324,000,038,257,255,50.12,01000001";

my %h;
my $retval = parseaprs($aprspacket, \%h);

ok($retval, 1, "failed to parse a telemetry packet");
ok($h{'resultcode'}, undef, "wrong result code");

ok(defined $h{'telemetry'}, 1, "no telemetry data in rethash");

my %t = %{ $h{'telemetry'} };

ok($t{'seq'}, 324, "wrong sequence number parsed from telemetry");
ok($t{'bits'}, '01000001', "wrong bits parsed from telemetry");
ok(defined $t{'vals'}, 1, "no value array parsed from telemetry");

my(@v) = @{ $t{'vals'} };
ok($v[0], "0.00", "wrong value 0 parsed from telemetry");
ok($v[1], "38.00", "wrong value 1 parsed from telemetry");
ok($v[2], "257.00", "wrong value 2 parsed from telemetry");
ok($v[3], "255.00", "wrong value 3 parsed from telemetry");
ok($v[4], "50.12", "wrong value 4 parsed from telemetry");

