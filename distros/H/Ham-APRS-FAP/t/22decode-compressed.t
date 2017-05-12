
# a basic compressed packet decoding test for a non-moving target
# Tue Dec 11 2007, Hessu, OH7LZB

use Test;

BEGIN { plan tests => 49 + 1 + 7 };
use Ham::APRS::FAP qw(parseaprs);

my $srccall = "OH2KKU-15";
my $dstcall = "APRS";
my $header = "$srccall>$dstcall,TCPIP*,qAC,FOURTH";
my $body = "!I0-X;T_Wv&{-Aigate testing";
my $aprspacket = "$header:$body";
my %h;
my $retval = parseaprs($aprspacket, \%h);

ok($retval, 1, "failed to parse a moving target's uncompressed packet");
ok($h{'srccallsign'}, $srccall, "incorrect source callsign parsing");
ok($h{'dstcallsign'}, $dstcall, "incorrect destination callsign parsing");

ok($h{'header'}, $header, "incorrect header parsing");
ok($h{'body'}, $body, "incorrect body parsing");
ok($h{'type'}, 'location', "incorrect packet type parsing");
ok($h{'format'}, 'compressed', "incorrect packet format parsing");

ok($h{'comment'}, 'igate testing', "incorrect comment parsing");

my @digis = @{ $h{'digipeaters'} };
ok(${ $digis[0] }{'call'}, 'TCPIP', "Incorrect first digi parsing");
ok(${ $digis[0] }{'wasdigied'}, '1', "Incorrect first digipeated bit parsing");
ok(${ $digis[1] }{'call'}, 'qAC', "Incorrect second digi parsing");
ok(${ $digis[1] }{'wasdigied'}, '0', "Incorrect second digipeated bit parsing");
ok(${ $digis[2] }{'call'}, 'FOURTH', "Incorrect igate call parsing");
ok(${ $digis[2] }{'wasdigied'}, '0', "Incorrect igate digipeated bit parsing");
ok($#digis, 2, "Incorrect amount of digipeaters parsed");

ok($h{'symboltable'}, 'I', "incorrect symboltable parsing");
ok($h{'symbolcode'}, '&', "incorrect symbolcode parsing");

# check for undefined value, when there is no such data in the packet
ok($h{'posambiguity'}, undef, "incorrect posambiguity parsing");
ok($h{'messaging'}, '0', "incorrect messaging bit parsing");

ok(sprintf('%.4f', $h{'latitude'}), "60.0520", "incorrect latitude parsing");
ok(sprintf('%.4f', $h{'longitude'}), "24.5045", "incorrect longitude parsing");
ok(sprintf('%.3f', $h{'posresolution'}), "0.291", "incorrect position resolution");

# check for undefined value, when there is no such data in the packet
ok($h{'speed'}, undef, "incorrect speed");
ok($h{'course'}, undef, "incorrect course");
ok($h{'altitude'}, undef, "incorrect altitude");

### another packet

$srccall = "OH2LCQ-10";
$dstcall = "APZMDR";
$header = "$srccall>$dstcall,WIDE3-2,qAo,OH2MQK-1";
# some telemetry in the comment
$comment = "Tero, Green Volvo 960, GGL-880";
$body = "!//zPHTfVv>!V_ $comment|!!!!!!!!!!!!!!|";
$aprspacket = "$header:$body";
%h = ();
$retval = parseaprs($aprspacket, \%h);

ok($retval, 1, "failed to parse a moving target's uncompressed packet");
ok($h{'srccallsign'}, $srccall, "incorrect source callsign parsing");
ok($h{'dstcallsign'}, $dstcall, "incorrect destination callsign parsing");

ok($h{'header'}, $header, "incorrect header parsing");
ok($h{'body'}, $body, "incorrect body parsing");
ok($h{'type'}, 'location', "incorrect packet type parsing");

ok($h{'comment'}, $comment, "incorrect comment parsing");

@digis = @{ $h{'digipeaters'} };
ok(${ $digis[0] }{'call'}, 'WIDE3-2', "Incorrect first digi parsing");
ok(${ $digis[0] }{'wasdigied'}, '0', "Incorrect first digipeated bit parsing");
ok(${ $digis[1] }{'call'}, 'qAo', "Incorrect second digi parsing");
ok(${ $digis[1] }{'wasdigied'}, '0', "Incorrect second digipeated bit parsing");
ok(${ $digis[2] }{'call'}, 'OH2MQK-1', "Incorrect igate call parsing");
ok(${ $digis[2] }{'wasdigied'}, '0', "Incorrect igate digipeated bit parsing");
ok($#digis, 2, "Incorrect amount of digipeaters parsed");

ok($h{'symboltable'}, '/', "incorrect symboltable parsing");
ok($h{'symbolcode'}, '>', "incorrect symbolcode parsing");

# check for undefined value, when there is no such data in the packet
ok($h{'posambiguity'}, undef, "incorrect posambiguity parsing");
ok($h{'messaging'}, 0, "incorrect messaging bit parsing");

ok(sprintf('%.4f', $h{'latitude'}), "60.3582", "incorrect latitude parsing");
ok(sprintf('%.4f', $h{'longitude'}), "24.8084", "incorrect longitude parsing");
ok(sprintf('%.3f', $h{'posresolution'}), "0.291", "incorrect position resolution");

# check for undefined value, when there is no such data in the packet
ok(sprintf("%.2f", $h{'speed'}), "107.57", "incorrect speed");
ok($h{'course'}, 360, "incorrect course");
ok($h{'altitude'}, undef, "incorrect altitude");

### short compressed packet without speed, altitude or course.
### The APRS 1.01 spec is clear on this - says that compressed packet
### is always 13 bytes long. Must not decode, even though this packet
### is otherwise valid. It's just missing 2 bytes of padding.

$aprspacket = 'KJ4ERJ-AL>APWW05,TCPIP*,qAC,FOURTH:@075111h/@@.Y:*lol ';
%h = ();
$retval = parseaprs($aprspacket, \%h);

ok($retval, 0, "erroneously decoded a too short compressed packet without speed/course/alt/range");

### compressed packet with weather

$aprspacket = 'SV4IKL-2>APU25N,WIDE2-2,qAR,SV6EXB-1:@011444z/:JF!T/W-_e!bg000t054r000p010P010h65b10073WS 2300 {UIV32N}';
%h = ();
$retval = parseaprs($aprspacket, \%h);

ok($retval, 1, "failed to parse a compressed packet with weather data");
ok($h{'symboltable'}, '/', "incorrect symboltable parsing (compressed+wx)");
ok($h{'symbolcode'}, '_', "incorrect symbolcode parsing (compressed+wx)");
ok($h{'comment'}, 'WS 2300 {UIV32N}', "incorrect comment parsing (compressed+wx)");

ok($h{'wx'}->{'temp'}, "12.2", "incorrect temperature parsing");
ok($h{'wx'}->{'humidity'}, 65, "incorrect humidity parsing");
ok($h{'wx'}->{'pressure'}, "1007.3", "incorrect pressure parsing");

