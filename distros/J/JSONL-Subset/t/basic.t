use strict;
use warnings;

use File::Temp qw(tempfile);
use Test::More tests => 29;
use JSONL::Subset qw(subset_jsonl);

my $FIXTURE = "t/fixtures/sample.jsonl";
my $WINDOWS_FIXTURE = "t/fixtures/windows.jsonl";

ok(defined &subset_jsonl, 'subset_jsonl is defined');

# Start mode
my ($fh_out_s, $filename_out_s) = tempfile();
subset_jsonl(
	infile => $FIXTURE,
	outfile => $filename_out_s,
	percent => 30,
	mode => "start"
);
open my $s, "<", $filename_out_s or die $!;
my @start_out = <$s>;
close $s;
is(scalar(@start_out), 3, "start: got exactly 3 lines");
is_deeply(\@start_out, ["{ \"id\": 1 }\n", "{ \"id\": 2 }\n", "{ \"id\": 3 }\n"], "start: got the right lines");

# End mode
my ($fh_out_e, $filename_out_e) = tempfile();
subset_jsonl(
	infile => $FIXTURE,
	outfile => $filename_out_e,
	percent => 30,
	mode => "end"
);
open my $e, "<", $filename_out_e or die $!;
my @end_out = <$e>;
close $e;
is(scalar(@end_out), 3, "end: got exactly 3 lines");
is_deeply(\@end_out, ["{ \"id\": 8 }\n", "{ \"id\": 9 }\n", "{ \"id\": 10 }\n"], "end: got the right lines");

# Random mode
my ($fh_out_r, $filename_out_r) = tempfile();
subset_jsonl(
	infile => $FIXTURE,
	outfile => $filename_out_r,
	percent => 30,
	mode => "random",
	seed => 1337
);
open my $r, "<", $filename_out_r or die $!;
my @rand_out = <$r>;
close $r;
is(scalar(@rand_out), 3, "random: got exactly 3 lines");
is_deeply(\@rand_out, ["{ \"id\": 9 }\n", "{ \"id\": 6 }\n", "{ \"id\": 7 }\n"], "random: got the right lines");

# Start mode (streaming)
my ($fh_out_ss, $filename_out_ss) = tempfile();
subset_jsonl(
	infile => $FIXTURE,
	outfile => $filename_out_ss,
	percent => 30,
	mode => "start",
	streaming => 1
);
open my $ss, "<", $filename_out_ss or die $!;
my @start_out_s = <$ss>;
close $ss;
is(scalar(@start_out_s), 3, "start (streaming): got exactly 3 lines");
is_deeply(\@start_out_s, ["{ \"id\": 1 }\n", "{ \"id\": 2 }\n", "{ \"id\": 3 }\n"], "start (streaming): got the right lines");

# End mode (streaming)
my ($fh_out_es, $filename_out_es) = tempfile();
subset_jsonl(
	infile => $FIXTURE,
	outfile => $filename_out_es,
	percent => 30,
	mode => "end",
	streaming => 1
);
open my $es, "<", $filename_out_es or die $!;
my @end_out_s = <$es>;
close $es;
is(scalar(@end_out_s), 3, "end (streaming): got exactly 3 lines");
is_deeply(\@end_out_s, ["{ \"id\": 8 }\n", "{ \"id\": 9 }\n", "{ \"id\": 10 }\n"], "end (streaming): got the right lines");

# Random mode (streaming)
my ($fh_out_rs, $filename_out_rs) = tempfile();
subset_jsonl(
	infile => $FIXTURE,
	outfile => $filename_out_rs,
	percent => 30,
	mode => "random",
	seed => 1337,
	streaming => 1
);
open my $rs, "<", $filename_out_rs or die $!;
my @rand_out_s = <$rs>;
close $rs;
is(scalar(@rand_out_s), 3, "random (streaming): got exactly 3 lines");
is_deeply(\@rand_out_s, ["{ \"id\": 4 }\n", "{ \"id\": 7 }\n", "{ \"id\": 10 }\n"], "random (streaming): got the right lines");

# Start mode (lines)
my ($fh_out_sl, $filename_out_sl) = tempfile();
subset_jsonl(
	infile => $FIXTURE,
	outfile => $filename_out_sl,
	lines => 3,
	mode => "start"
);
open my $sl, "<", $filename_out_sl or die $!;
my @start_out_l = <$sl>;
close $sl;
is(scalar(@start_out_l), 3, "start (lines): got exactly 3 lines");
is_deeply(\@start_out_l, ["{ \"id\": 1 }\n", "{ \"id\": 2 }\n", "{ \"id\": 3 }\n"], "start (lines): got the right lines");

# End mode (lines)
my ($fh_out_el, $filename_out_el) = tempfile();
subset_jsonl(
	infile => $FIXTURE,
	outfile => $filename_out_el,
	lines => 3,
	mode => "end"
);
open my $el, "<", $filename_out_el or die $!;
my @end_out_l = <$el>;
close $el;
is(scalar(@end_out_l), 3, "end (lines): got exactly 3 lines");
is_deeply(\@end_out_l, ["{ \"id\": 8 }\n", "{ \"id\": 9 }\n", "{ \"id\": 10 }\n"], "end (lines): got the right lines");

# Random mode (lines)
my ($fh_out_rl, $filename_out_rl) = tempfile();
subset_jsonl(
	infile => $FIXTURE,
	outfile => $filename_out_rl,
	lines => 3,
	mode => "random",
	seed => 1337
);
open my $rl, "<", $filename_out_rl or die $!;
my @rand_out_l = <$rl>;
close $rl;
is(scalar(@rand_out_l), 3, "random (lines): got exactly 3 lines");
is_deeply(\@rand_out_l, ["{ \"id\": 9 }\n", "{ \"id\": 6 }\n", "{ \"id\": 7 }\n"], "random (lines): got the right lines");

# Start mode (streaming & lines)
my ($fh_out_ss_l, $filename_out_ss_l) = tempfile();
subset_jsonl(
	infile => $FIXTURE,
	outfile => $filename_out_ss_l,
	lines => 3,
	mode => "start",
	streaming => 1
);
open my $ss_l, "<", $filename_out_ss_l or die $!;
my @start_out_sl = <$ss_l>;
close $ss_l;
is(scalar(@start_out_sl), 3, "start (streaming & lines): got exactly 3 lines");
is_deeply(\@start_out_sl, ["{ \"id\": 1 }\n", "{ \"id\": 2 }\n", "{ \"id\": 3 }\n"], "start (streaming & lines): got the right lines");

# End mode (streaming & lines)
my ($fh_out_es_l, $filename_out_es_l) = tempfile();
subset_jsonl(
	infile => $FIXTURE,
	outfile => $filename_out_es_l,
	lines => 3,
	mode => "end",
	streaming => 1
);
open my $es_l, "<", $filename_out_es_l or die $!;
my @end_out_sl = <$es_l>;
close $es_l;
is(scalar(@end_out_sl), 3, "end (streaming & lines): got exactly 3 lines");
is_deeply(\@end_out_sl, ["{ \"id\": 8 }\n", "{ \"id\": 9 }\n", "{ \"id\": 10 }\n"], "end (streaming & lines): got the right lines");

# Random mode (streaming & lines)
my ($fh_out_rs_l, $filename_out_rs_l) = tempfile();
subset_jsonl(
	infile => $FIXTURE,
	outfile => $filename_out_rs_l,
	lines => 3,
	mode => "random",
	seed => 1337,
	streaming => 1
);
open my $rs_l, "<", $filename_out_rs_l or die $!;
my @rand_out_sl = <$rs_l>;
close $rs_l;
is(scalar(@rand_out_sl), 3, "random (streaming & lines): got exactly 3 lines");
is_deeply(\@rand_out_sl, ["{ \"id\": 4 }\n", "{ \"id\": 7 }\n", "{ \"id\": 10 }\n"], "random (streaming & lines): got the right lines");

# Random mode (Windows line endings)
my ($fh_out_r_win, $filename_out_r_win) = tempfile();
subset_jsonl(
	infile => $WINDOWS_FIXTURE,
	outfile => $filename_out_r_win,
	percent => 30,
	mode => "random",
	seed => 1337
);
open my $r_win, "<", $filename_out_r_win or die $!;
my @rand_out_win = <$r_win>;
close $r_win;
is(scalar(@rand_out_win), 3, "random: got exactly 3 lines");
is_deeply(\@rand_out_win, ["{ \"id\": 9 }\r\n", "{ \"id\": 6 }\r\n", "{ \"id\": 7 }\r\n"], "random: got the right lines");

# Random mode (streaming, Windows line endings)
my ($fh_out_rs_win, $filename_out_rs_win) = tempfile();
subset_jsonl(
	infile => $WINDOWS_FIXTURE,
	outfile => $filename_out_rs_win,
	percent => 30,
	mode => "random",
	seed => 1337,
	streaming => 1
);
open my $rs_win, "<", $filename_out_rs_win or die $!;
my @rand_out_s_win = <$rs_win>;
close $rs_win;
is(scalar(@rand_out_s_win), 3, "random (streaming): got exactly 3 lines");
is_deeply(\@rand_out_s_win, ["{ \"id\": 4 }\r\n", "{ \"id\": 7 }\r\n", "{ \"id\": 10 }\r\n"], "random (streaming): got the right lines");

