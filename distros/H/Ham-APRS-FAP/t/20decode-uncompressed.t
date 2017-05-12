
# a basic uncompressed packet decoding test
# Mon Dec 10 2007, Hessu, OH7LZB

use Test;

BEGIN { plan tests => 28 + 5 + 5 + 3 + 4 + 2 + 3 };
use Ham::APRS::FAP qw(parseaprs);

my $comment = "RELAY,WIDE, OH2AP Jarvenpaa";
my $phg = "7220";
my $srccall = "OH2RDP-1";
my $dstcall = "BEACON-15";
my $aprspacket = "$srccall>$dstcall,OH2RDG*,WIDE:!6028.51N/02505.68E#PHG$phg/$comment";
my %h;
my $retval = parseaprs($aprspacket, \%h);

ok($retval, 1, "failed to parse a basic uncompressed packet (northeast)");
ok($h{'format'}, 'uncompressed', "incorrect packet format parsing");
ok($h{'srccallsign'}, $srccall, "incorrect source callsign parsing");
ok($h{'dstcallsign'}, $dstcall, "incorrect destination callsign parsing");
ok(sprintf('%.4f', $h{'latitude'}), "60.4752", "incorrect latitude parsing (northern)");
ok(sprintf('%.4f', $h{'longitude'}), "25.0947", "incorrect longitude parsing (eastern)");
ok(sprintf('%.2f', $h{'posresolution'}), "18.52", "incorrect position resolution");
ok($h{'phg'}, $phg, "incorrect PHG parsing");
ok($h{'comment'}, $comment, "incorrect comment parsing");

my @digis = @{ $h{'digipeaters'} };
ok(${ $digis[0] }{'call'}, 'OH2RDG', "Incorrect first digi parsing");
ok(${ $digis[0] }{'wasdigied'}, '1', "Incorrect first digipeated bit parsing");
ok(${ $digis[1] }{'call'}, 'WIDE', "Incorrect second digi parsing");
ok(${ $digis[1] }{'wasdigied'}, '0', "Incorrect second digipeated bit parsing");
ok($#digis, 1, "Incorrect amount of digipeaters parsed");

# and the same, southwestern...
%h = (); # clean up
$aprspacket = "$srccall>$dstcall,OH2RDG*,WIDE:!6028.51S/02505.68W#PHG$phg$comment";
$retval = parseaprs($aprspacket, \%h);

ok($retval, 1, "failed to parse a basic uncompressed packet (southwest)");
ok(sprintf('%.4f', $h{'latitude'}), "-60.4752", "incorrect latitude parsing (southern)");
ok(sprintf('%.4f', $h{'longitude'}), "-25.0947", "incorrect longitude parsing (western)");
ok(sprintf('%.2f', $h{'posresolution'}), "18.52", "incorrect position resolution");

# and the same, with ambiguity
%h = (); # clean up
$aprspacket = "$srccall>$dstcall,OH2RDG*,WIDE:!602 .  S/0250 .  W#PHG$phg$comment";
$retval = parseaprs($aprspacket, \%h);

ok($retval, 1, "failed to parse a basic ambiguity packet (southwest)");
ok(sprintf('%.4f', $h{'latitude'}), "-60.4167", "incorrect latitude parsing (southern)");
ok(sprintf('%.4f', $h{'longitude'}), "-25.0833", "incorrect longitude parsing (western)");
ok(sprintf('%.0f', $h{'posambiguity'}), "3", "incorrect position ambiguity");
ok(sprintf('%.0f', $h{'posresolution'}), "18520", "incorrect position resolution");

# and the same, with even more ambiguity
%h = (); # clean up
$aprspacket = "$srccall>$dstcall,OH2RDG*,WIDE:!60  .  S/025  .  W#PHG$phg$comment";
$retval = parseaprs($aprspacket, \%h);

ok($retval, 1, "failed to parse a very ambiguous packet (southwest)");
ok(sprintf('%.4f', $h{'latitude'}), "-60.5000", "incorrect latitude parsing (southern)");
ok(sprintf('%.4f', $h{'longitude'}), "-25.5000", "incorrect longitude parsing (western)");
ok(sprintf('%.0f', $h{'posambiguity'}), "4", "incorrect position ambiguity");
ok(sprintf('%.0f', $h{'posresolution'}), "111120", "incorrect position resolution");

# and the same with "last resort" !-location parsing
%h = (); # clean up
$aprspacket = "$srccall>$dstcall,OH2RDG*,WIDE:hoponassualku!6028.51S/02505.68W#PHG$phg$comment";
$retval = parseaprs($aprspacket, \%h);

ok($retval, 1, "failed to parse an uncompressed packet (last resort)");
ok(sprintf('%.4f', $h{'latitude'}), "-60.4752", "incorrect latitude parsing (last resort)");
ok(sprintf('%.4f', $h{'longitude'}), "-25.0947", "incorrect longitude parsing (last resort)");
ok(sprintf('%.2f', $h{'posresolution'}), "18.52", "incorrect position resolution (last resort)");
ok($h{'comment'}, $comment, "incorrect comment parsing (last resort)");

# Here is a comment on a station with a WX symbol. The comment is ignored,
# because it easily gets confused with weather data.
%h = ();
$aprspacket = "A0RID-1>KC0PID-7,WIDE1,qAR,NX0R-6:=3851.38N/09908.75W_Home of KA0RID";
$retval = parseaprs($aprspacket, \%h);

ok($retval, 1, "failed to parse an uncompressed packet (comment instead of wx)");
ok(sprintf('%.4f', $h{'latitude'}), "38.8563", "incorrect latitude parsing (comment instead of wx)");
ok(sprintf('%.4f', $h{'longitude'}), "-99.1458", "incorrect longitude parsing (comment instead of wx)");
ok(sprintf('%.2f', $h{'posresolution'}), "18.52", "incorrect position resolution (comment instead of wx)");
ok($h{'comment'}, undef, "incorrect comment parsing (comment instead of wx)");

# validate that whitespace is trimmed from comment
$aprspacket = "$srccall>$dstcall,OH2RDG*,WIDE:!6028.51N/02505.68E#PHG$phg   $comment  \t ";
$retval = parseaprs($aprspacket, \%h);
ok($retval, 1, "failed to parse a basic uncompressed packet with extra whitespace");
ok($h{'phg'}, $phg, "incorrect PHG parsing");
ok($h{'comment'}, $comment, "incomment comment whitespace trimming");

# position with timestamp and altitude
%h = (); # clean up
$aprspacket = "YB1RUS-9>APOTC1,WIDE2-2,qAS,YC0GIN-1:/180000z0609.31S/10642.85E>058/010/A=000079 13.8V 15CYB1RUS-9 Mobile Tracker";
$retval = parseaprs($aprspacket, \%h);

ok($retval, 1, "failed to parse an uncompressed packet (with timestamp, position, alt)");
ok(sprintf('%.5f', $h{'latitude'}), "-6.15517", "incorrect latitude parsing (uncompressed packet with timestamp, position, alt)");
ok(sprintf('%.5f', $h{'longitude'}), "106.71417", "incorrect longitude parsing (uncompressed packet with timestamp, position, alt)");
ok(sprintf('%.5f', $h{'altitude'}), "24.07920", "incorrect altitude parsing (uncompressed packet with timestamp, position, alt)");

# position with timestamp and altitude
%h = (); # clean up
$aprspacket = "YB1RUS-9>APOTC1,WIDE2-2,qAS,YC0GIN-1:/180000z0609.31S/10642.85E>058/010/A=-00079 13.8V 15CYB1RUS-9 Mobile Tracker";
$retval = parseaprs($aprspacket, \%h);

ok($retval, 1, "failed to parse an uncompressed packet with negative altitude");
ok(sprintf('%.5f', $h{'altitude'}), "-24.07920", "incorrect negative altitude (uncompressed packet)");

# rather basic position packet
%h = (); # clean up
$aprspacket = "YC0SHR>APU25N,TCPIP*,qAC,ALDIMORI:=0606.23S/10644.61E-GW SAHARA PENJARINGAN JAKARTA 147.880 MHz";
$retval = parseaprs($aprspacket, \%h);

ok($retval, 1, "failed to parse an uncompressed packet (YC0SHR)");
ok(sprintf('%.5f', $h{'latitude'}), "-6.10383", "incorrect latitude parsing (YC0SHR)");
ok(sprintf('%.5f', $h{'longitude'}), "106.74350", "incorrect longitude parsing (YC0SHR)");

