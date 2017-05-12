
# a basic uncompressed packet decoding test for a moving target
# Tue Dec 11 2007, Hessu, OH7LZB

use Test;

BEGIN { plan tests => 25 };
use Ham::APRS::FAP qw(parseaprs);

my $srccall = "OH7FDN";
my $dstcall = "APZMDR";
my $header = "$srccall>$dstcall,OH7AA-1*,WIDE2-1,qAR,OH7AA";
# The comment field contains telemetry just to see that it doesn't break
# the actual position parsing.
my $body = "!6253.52N/02739.47E>036/010/A=000465 |!!!!!!!!!!!!!!|";
my $aprspacket = "$header:$body";
my %h;
my $retval = parseaprs($aprspacket, \%h);

ok($retval, 1, "failed to parse a moving target's uncompressed packet");
ok($h{'srccallsign'}, $srccall, "incorrect source callsign parsing");
ok($h{'dstcallsign'}, $dstcall, "incorrect destination callsign parsing");

ok($h{'header'}, $header, "incorrect header parsing");
ok($h{'body'}, $body, "incorrect body parsing");
ok($h{'type'}, 'location', "incorrect packet type parsing");

my @digis = @{ $h{'digipeaters'} };
ok(${ $digis[0] }{'call'}, 'OH7AA-1', "Incorrect first digi parsing");
ok(${ $digis[0] }{'wasdigied'}, '1', "Incorrect first digipeated bit parsing");
ok(${ $digis[1] }{'call'}, 'WIDE2-1', "Incorrect second digi parsing");
ok(${ $digis[1] }{'wasdigied'}, '0', "Incorrect second digipeated bit parsing");
ok(${ $digis[2] }{'call'}, 'qAR', "Incorrect third digi parsing");
ok(${ $digis[2] }{'wasdigied'}, '0', "Incorrect third digipeated bit parsing");
ok(${ $digis[3] }{'call'}, 'OH7AA', "Incorrect igate call parsing");
ok(${ $digis[3] }{'wasdigied'}, '0', "Incorrect igate digipeated bit parsing");
ok($#digis, 3, "Incorrect amount of digipeaters parsed");

ok($h{'symboltable'}, '/', "incorrect symboltable parsing");
ok($h{'symbolcode'}, '>', "incorrect symbolcode parsing");

ok($h{'posambiguity'}, '0', "incorrect posambiguity parsing");
ok($h{'messaging'}, '0', "incorrect messaging bit parsing");

ok(sprintf('%.4f', $h{'latitude'}), "62.8920", "incorrect latitude parsing");
ok(sprintf('%.4f', $h{'longitude'}), "27.6578", "incorrect longitude parsing");
ok(sprintf('%.2f', $h{'posresolution'}), "18.52", "incorrect position resolution");

ok(sprintf('%.2f', $h{'speed'}), "18.52", "incorrect speed");
ok(sprintf('%.0f', $h{'course'}), "36", "incorrect course");
ok(sprintf('%.3f', $h{'altitude'}), "141.732", "incorrect altitude");

