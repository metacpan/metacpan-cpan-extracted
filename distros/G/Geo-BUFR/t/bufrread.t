use warnings;
use strict;

use Test::More tests => 36;
use Config;

my $perl = $Config{perlpath};

my $output = `$perl ./bufrread.pl --codetables t/tempLow_200707271955.bufr --tablepath t/bt`;
my $expected = read_file('t/tempLow_200707271955.txt');
is($output, $expected, 'testing bufrread.pl -c on temp edition 4 message');

$output = `$perl ./bufrread.pl --filter t/filter --param t/param t/3xBUFRSYNOP-com.bufr --tablepath t/bt`;
$expected = read_file('t/3xBUFRSYNOP-com_filtered.txt');
is($output, $expected, 'testing bufrread.pl -f -p on compressed synop message');

$output = `$perl ./bufrread.pl --bitmap t/substituted.bufr --tablepath t/bt`;
$expected = read_file('t/substituted.txt_bitmap');
is($output, $expected, 'testing bufrread.pl -b on temp message with qc and substituted values');

`$perl ./bufrread.pl --data_only --noqc --width 10 --outfile t/outrea1 t/substituted.bufr --tablepath t/bt`;
$output = read_file('t/outrea1');
unlink 't/outrea1';
$expected = read_file('t/substituted.txt_noqc');
is($output, $expected, 'testing bufrread.pl -d -n -w -o on temp message with qc');

$output = `$perl ./bufrread.pl --all_operators t/associated.bufr --tablepath t/bt`;
$expected = read_file('t/associated.txt');
is($output, $expected, 'testing bufrread.pl -all on message with associated values and 201-2 operators');

`$perl ./bufrread.pl --strict_checking 1 t/iozx.bufr --tablepath t/bt > t/outrea2 2> t/warnrea2`;

$output = read_file('t/outrea2');
unlink 't/outrea2';
$expected = read_file('t/iozx.txt_1');
is($output, $expected, 'testing bufrread.pl -s 1 on buoy message for output');

$output = read_file('t/warnrea2');
unlink 't/warnrea2';
$expected = read_file('t/iozx.warn');
# Newer versions of perl might add '.' to end of warning/error message.
# Remove that as well as actual line number (to ease future changes in bufrread.pl)
$output =~ s/line \d+[.]?/line/g;
$expected =~ s/line \d+[.]?/line/g;
is($output, $expected, 'testing bufrread.pl -s 1 on buoy message for warnings');

`$perl ./bufrread.pl --strict_checking 2 t/iozx.bufr --tablepath t/bt > t/outrea3 2> t/errrea3`;

$output = read_file('t/outrea3');
unlink 't/outrea3';
$expected = read_file('t/iozx.txt_2');
is($output, $expected, 'testing bufrread.pl -s 2 on buoy message for output');

$output = read_file('t/errrea3');
unlink 't/errrea3';
$expected = read_file('t/iozx.err');
# Newer versions of perl might add '.' to end of warning/error message.
# Remove that as well as actual line number (to ease future changes in bufrread.pl)
$output =~ s/line \d+[.]?/line/g;
$expected =~ s/line \d+[.]?/line/g;
is($output, $expected, 'testing bufrread.pl -s 2 on buoy message for error messages');

`$perl ./bufrread.pl --strict_checking 1 t/iupd_bad.bufr --tablepath t/bt > t/outrea4 2> t/warnrea4`;

$output = read_file('t/outrea4');
unlink 't/outrea4';
$expected = read_file('t/iupd_bad.txt');
is($output, $expected, 'testing bufrread.pl -s 1 on dubious left out descriptors for output');

$output = read_file('t/warnrea4');
unlink 't/warnrea4';
$expected = read_file('t/iupd_bad.warn');
# Newer versions of perl might add '.' to end of warning/error message.
# Remove that as well as actual line number (to ease future changes in bufrread.pl)
$output =~ s/line \d+[.]?/line/g;
$expected =~ s/line \d+[.]?/line/g;
is($output, $expected, 'testing bufrread.pl -s 1 on dubious left out descriptors for warnings');

$output = `$perl ./bufrread.pl t/change_refval.bufr --tablepath t/bt`;
$expected = read_file('t/change_refval.txt');
is($output, $expected, 'testing bufrread.pl on message containing 203Y');

$output = `$perl ./bufrread.pl t/change_refval_compressed.bufr --tablepath t/bt`;
$expected = read_file('t/change_refval_compressed.txt');
is($output, $expected, 'testing bufrread.pl on compressed message containing 203Y');

$output = `$perl ./bufrread.pl t/208035.bufr -w 35 --tablepath t/bt`;
$expected = read_file('t/208035.txt');
is($output, $expected, 'testing bufrread.pl on message containing 208Y');

$output = `$perl ./bufrread.pl t/multiple_qc.bufr --tablepath t/bt`;
$expected = read_file('t/multiple_qc.txt');
is($output, $expected, 'testing bufrread.pl on satellite data with triple 222000');

$output = `$perl ./bufrread.pl t/multiple_qc_compressed.bufr --tablepath t/bt`;
$expected = read_file('t/multiple_qc_compressed.txt');
is($output, $expected, 'testing bufrread.pl on compressed satellite data with triple 222000');

$output = `$perl ./bufrread.pl t/multiple_qc.bufr --tablepath t/bt --bitmap`;
$expected = read_file('t/multiple_qc.txt_bitmap');
is($output, $expected, 'testing bufrread.pl -b on satellite data with triple 222000');

$output = `$perl ./bufrread.pl t/multiple_qc_vary.bufr --tablepath t/bt --bitmap`;
$expected = read_file('t/multiple_qc_vary.txt_bitmap');
is($output, $expected, 'testing bufrread.pl -b on satellite data with triple 222000 and variable bitmaps');

$output = `$perl ./bufrread.pl t/firstorderstat.bufr --tablepath t/bt`;
$expected = read_file('t/firstorderstat.txt');
is($output, $expected, 'testing bufrread.pl on compressed satellite data with 224000 and 224255');

$output = `$perl ./bufrread.pl --bitmap t/firstorderstat.bufr --tablepath t/bt`;
$expected = read_file('t/firstorderstat.txt_bitmap');
is($output, $expected, 'testing bufrread.pl -b on satellite data with 224000 and large 224255 values');

$output = `$perl ./bufrread.pl --codetables --all_operators t/firstorderstat.bufr --tablepath t/bt`;
$expected = read_file('t/firstorderstat.txt_all');
is($output, $expected, 'testing bufrread.pl -c -all on data with operators mingled in bitmap and duplicated code table (001032)');

$output = `$perl ./bufrread.pl t/retained.bufr --tablepath t/bt`;
$expected = read_file('t/retained.txt');
is($output, $expected, 'testing bufrread.pl on message with 232000 and 204YYY operators');

$output = `$perl ./bufrread.pl t/signify_datawidth.bufr --tablepath t/bt`;
$expected = read_file('t/signify_datawidth.txt');
is($output, $expected, 'testing bufrread.pl on message with 206YYY signify data width operator with known local descriptor');

$output = `$perl ./bufrread.pl t/signify_datawidth.bufr2 --tablepath t/bt -all -v 1`;
$expected = read_file('t/signify_datawidth.txt2');
$output =~ s{Reading table (.*?)B0000000000000011000.TXT}{Reading table t/bt/B0000000000000011000.TXT};
$output =~ s{Reading table (.*?)D0000000000000011000.TXT}{Reading table t/bt/D0000000000000011000.TXT};
is($output, $expected, 'testing bufrread.pl on message with 206YYY signify data width operator with unknown local descriptor');


`$perl ./bufrread.pl t/BUFRBUFR.bufr --tablepath t/bt > t/outrea5 2> t/errrea5`;

$output = read_file('t/outrea5');
unlink 't/outrea5';
$expected = read_file('t/1xBUFRSYNOP-ed4.txt');
$expected =~ s/Message 1/Message 2/;
is($output, $expected, "testing bufrread.pl on a BUFR SYNOP preceded by 'BUFR'");

$output = read_file('t/errrea5');
unlink 't/errrea5';
$expected = read_file('t/BUFRBUFR.err');
# Newer versions of perl might add '.' to end of warning/error message.
# Remove that as well as actual line number (to ease future changes in bufrread.pl)
$output =~ s/line \d+[.]?/line/g;
$expected =~ s/line \d+[.]?/line/g;
is($output, $expected, "testing bufrread.pl on a BUFR SYNOP preceded by 'BUFR' for error message");

`$perl ./bufrread.pl t/short_truncated_temp_synop.bufr  --tablepath t/bt > t/outrea6 2> t/errrea6`;

$output = read_file('t/outrea6');
unlink 't/outrea6';
$expected = read_file('t/1xBUFRSYNOP-ed4.txt');
$expected =~ s/Message 1/Message 2/;
is($output, $expected, 'testing bufrread.pl on truncated temp with supposed length greater than rest of file (containing a synop)');

$output = read_file('t/errrea6');
unlink 't/errrea6';
$expected = read_file('t/short_truncated_temp_synop.err');
$output =~ s/line \d+[.]?/line/g;
$expected =~ s/line \d+[.]?/line/g;
is($output, $expected, 'testing bufrread.pl on truncated temp with supposed length greater than rest of file (containing a synop) for error message');

`$perl ./bufrread.pl t/long_truncated_temp_synop.bufr  --tablepath t/bt > t/outrea7 2> t/errrea7`;

$output = read_file('t/outrea7');
unlink 't/outrea7';
$expected = read_file('t/1xBUFRSYNOP-ed4.txt');
$expected =~ s/Message 1/Message 2/;
is($output, $expected, 'testing bufrread.pl on truncated temp supposed to end within next synop');

$output = read_file('t/errrea7');
unlink 't/errrea7';
$expected = read_file('t/long_truncated_temp_synop.err');
$output =~ s/line \d+[.]?/line/g;
$expected =~ s/line \d+[.]?/line/g;
is($output, $expected, 'testing bufrread.pl for error message on truncated temp supposed to end within next synop');

`$perl ./bufrread.pl t/long_truncated_temp_synop_temp.bufr  --tablepath t/bt > t/outrea8 2> t/errrea8`;

$output = read_file('t/outrea8');
unlink 't/outrea8';
$expected = read_file('t/long_truncated_temp_synop_temp.txt');
is($output, $expected, 'testing bufrread.pl on truncated temp supposed to end within next synop,'
. 'which is followed by new temp and with ahls included');

$output = read_file('t/errrea8');
unlink 't/errrea8';
$expected = read_file('t/long_truncated_temp_synop_temp.err');
$output =~ s/line \d+[.]?/line/g;
$expected =~ s/line \d+[.]?/line/g;
is($output, $expected, 'testing bufrread.pl for error message on truncated temp supposed to end within next synop,'
. 'which is followed by new temp and with ahls included');

$output = `$perl ./bufrread.pl --nodata t/long_truncated_temp_synop_temp.bufr --tablepath t/bt`;
$expected = read_file('t/long_truncated_temp_synop_temp_nodata.txt');
is($output, $expected, 'testing bufrread.pl --nodata on file starting with truncated temp');

`$perl ./bufrread.pl --ahl "ISXD99|ENMI|OKPR" --param t/param t/set_filter.bufr --tablepath t/bt > t/outrea9 2> t/errrea10`;

$output = read_file('t/outrea9');
unlink 't/outrea9';
$expected = read_file('t/set_filter.txt2');
is($output, $expected, 'testing bufrread.pl --ahl -p on test file also used in set_filter.t');

$output = read_file('t/errrea10');
unlink 't/errrea10';
$expected = read_file('t/set_filter.err2');
$output =~ s/line \d+[.]?/line/g;
$expected =~ s/line \d+[.]?/line/g;
is($output, $expected, 'testing bufrread.pl --ahl -p on test file also used in set_filter.t for error message');

$output = `$perl ./bufrread.pl --ahl "ISXD99|ENMI|OKPR" --nodata t/set_filter.bufr --tablepath t/bt`;
$expected = read_file('t/set_filter.txt3');
is($output, $expected, 'testing bufrread.pl --ahl --nodata on test file also used in set_filter.t');


# Read in text file
sub read_file {
    my $infile = shift;
    local $/; # Enable slurp mode
    open my $fh, '<', $infile or die "Can't open $infile: $!";
    return <$fh>;
};
