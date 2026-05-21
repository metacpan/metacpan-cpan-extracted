######################################################################
#
# 0010-csv-io.t - CSV file I/O tests (FromCSV, ToCSV)
#
######################################################################

use strict;
BEGIN { if ($] < 5.006) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/../lib";
use JSON::LINQ;
use File::Spec ();

my ($PASS, $FAIL, $T) = (0, 0, 0);
sub ok { my($c,$n)=@_; $T++; $c ? ($PASS++, print "ok $T - $n\n") : ($FAIL++, print "not ok $T - $n\n") }

my $tmpdir  = File::Spec->tmpdir();
my $csv_in  = File::Spec->catfile($tmpdir, "jsonlinq_csvin_$$.csv");
my $csv_out = File::Spec->catfile($tmpdir, "jsonlinq_csvout_$$.csv");

# Setup: write a sample CSV file (bareword FH, 2-arg open)
local *CSV_IN_FH;
open(CSV_IN_FH, "> $csv_in") or die "Cannot create $csv_in: $!";
print CSV_IN_FH "name,age,city\n";
print CSV_IN_FH "Alice,30,Tokyo\n";
print CSV_IN_FH "Bob,25,Osaka\n";
print CSV_IN_FH "Carol,35,Tokyo\n";
print CSV_IN_FH "Dave,40,Nagoya\n";
close CSV_IN_FH;

my @tests = (

    # 1: FromCSV - record count
    sub {
        my @r = JSON::LINQ->FromCSV($csv_in)->ToArray();
        ok(@r == 4, 'FromCSV: 4 records read');
    },

    # 2: FromCSV - first record name field
    sub {
        my @r = JSON::LINQ->FromCSV($csv_in)->ToArray();
        ok($r[0]{name} eq 'Alice', 'FromCSV: first record name = Alice');
    },

    # 3: FromCSV - first record age field
    sub {
        my @r = JSON::LINQ->FromCSV($csv_in)->ToArray();
        ok($r[0]{age} eq '30', 'FromCSV: first record age = 30');
    },

    # 4: FromCSV - last record city field
    sub {
        my @r = JSON::LINQ->FromCSV($csv_in)->ToArray();
        ok($r[3]{city} eq 'Nagoya', 'FromCSV: last record city = Nagoya');
    },

    # 5: FromCSV + Where (DSL)
    sub {
        my @r = JSON::LINQ->FromCSV($csv_in)->Where(city => 'Tokyo')->ToArray();
        ok(@r == 2, 'FromCSV + Where DSL: Tokyo count = 2');
    },

    # 6: FromCSV + Where DSL - first match name
    sub {
        my @r = JSON::LINQ->FromCSV($csv_in)->Where(city => 'Tokyo')->ToArray();
        ok($r[0]{name} eq 'Alice', 'FromCSV + Where DSL: first Tokyo = Alice');
    },

    # 7: FromCSV + Where DSL - second match name
    sub {
        my @r = JSON::LINQ->FromCSV($csv_in)->Where(city => 'Tokyo')->ToArray();
        ok($r[1]{name} eq 'Carol', 'FromCSV + Where DSL: second Tokyo = Carol');
    },

    # 8: FromCSV + Where (code ref)
    sub {
        my @r = JSON::LINQ->FromCSV($csv_in)
                    ->Where(sub { $_[0]{age} >= 30 })
                    ->ToArray();
        ok(@r == 3, 'FromCSV + Where coderef: age >= 30 count = 3');
    },

    # 9: FromCSV + Select
    sub {
        my @n = JSON::LINQ->FromCSV($csv_in)
                    ->Select(sub { $_[0]{name} })
                    ->ToArray();
        ok(join(',', @n) eq 'Alice,Bob,Carol,Dave',
            'FromCSV + Select: names in order');
    },

    # 10: FromCSV + Count
    sub {
        ok(JSON::LINQ->FromCSV($csv_in)->Count() == 4,
            'FromCSV + Count: 4');
    },

    # 11: FromCSV + Take (lazy early exit)
    sub {
        my @r = JSON::LINQ->FromCSV($csv_in)->Take(2)->ToArray();
        ok(@r == 2, 'FromCSV + Take: lazy early exit, 2 records');
    },

    # 12: FromCSV + Sum
    sub {
        my $s = JSON::LINQ->FromCSV($csv_in)->Sum(sub { $_[0]{age} });
        ok($s == 30 + 25 + 35 + 40, 'FromCSV + Sum: 30+25+35+40 = 130');
    },

    # 13: FromCSV + OrderByNum
    sub {
        my @s = JSON::LINQ->FromCSV($csv_in)
                    ->OrderByNum(sub { $_[0]{age} })
                    ->Select(sub { $_[0]{name} })
                    ->ToArray();
        ok($s[0] eq 'Bob' && $s[-1] eq 'Dave',
            'FromCSV + OrderByNum: ascending by age');
    },

    # 14: ToCSV - returns 1
    sub {
        my @data = ({name => 'X', id => 1}, {name => 'Y', id => 2});
        ok(JSON::LINQ->From(\@data)->ToCSV($csv_out) == 1,
            'ToCSV: returns 1');
    },

    # 15: ToCSV - line count (header + data)
    sub {
        JSON::LINQ->FromCSV($csv_in)
                  ->Where(city => 'Tokyo')
                  ->ToCSV($csv_out);
        local *RD;
        open(RD, $csv_out) or die $!;
        my @lines = <RD>;
        close RD;
        ok(@lines == 3, 'ToCSV: 3 lines (1 header + 2 data)');
    },

    # 16: ToCSV - default header (sorted keys)
    sub {
        JSON::LINQ->FromCSV($csv_in)
                  ->Where(city => 'Tokyo')
                  ->ToCSV($csv_out);
        local *RD;
        open(RD, $csv_out) or die $!;
        my $hdr = <RD>;
        close RD;
        $hdr =~ s/\r?\n\z//;
        ok($hdr eq 'age,city,name', 'ToCSV: default header = age,city,name');
    },

    # 17: ToCSV - first data row matches default sort
    sub {
        JSON::LINQ->FromCSV($csv_in)
                  ->Where(city => 'Tokyo')
                  ->ToCSV($csv_out);
        local *RD;
        open(RD, $csv_out) or die $!;
        my @lines = <RD>;
        close RD;
        $lines[1] =~ s/\r?\n\z//;
        ok($lines[1] eq '30,Tokyo,Alice',
            'ToCSV: first data row with default sort');
    },

    # 18: ToCSV - headers option controls column order
    sub {
        JSON::LINQ->FromCSV($csv_in)
                  ->Where(city => 'Tokyo')
                  ->ToCSV($csv_out, headers => [qw(name city age)]);
        local *RD;
        open(RD, $csv_out) or die $!;
        my $hdr = <RD>;
        close RD;
        $hdr =~ s/\r?\n\z//;
        ok($hdr eq 'name,city,age', 'ToCSV headers option: header order');
    },

    # 19: ToCSV - headers option data values
    sub {
        JSON::LINQ->FromCSV($csv_in)
                  ->Where(city => 'Tokyo')
                  ->ToCSV($csv_out, headers => [qw(name city age)]);
        local *RD;
        open(RD, $csv_out) or die $!;
        my @lines = <RD>;
        close RD;
        $lines[1] =~ s/\r?\n\z//;
        ok($lines[1] eq 'Alice,Tokyo,30',
            'ToCSV headers option: data values in order');
    },

    # 20: ToCSV - label_order alias (header)
    sub {
        JSON::LINQ->FromCSV($csv_in)
                  ->Where(city => 'Tokyo')
                  ->ToCSV($csv_out, label_order => [qw(city name age)]);
        local *RD;
        open(RD, $csv_out) or die $!;
        my $hdr = <RD>;
        close RD;
        $hdr =~ s/\r?\n\z//;
        ok($hdr eq 'city,name,age', 'ToCSV label_order alias: header order');
    },

    # 21: ToCSV - label_order alias (data values)
    sub {
        JSON::LINQ->FromCSV($csv_in)
                  ->Where(city => 'Tokyo')
                  ->ToCSV($csv_out, label_order => [qw(city name age)]);
        local *RD;
        open(RD, $csv_out) or die $!;
        my @lines = <RD>;
        close RD;
        $lines[1] =~ s/\r?\n\z//;
        ok($lines[1] eq 'Tokyo,Alice,30',
            'ToCSV label_order alias: data values in order');
    },

    # 22: ToCSV - no_header option
    sub {
        JSON::LINQ->FromCSV($csv_in)
                  ->Where(city => 'Tokyo')
                  ->ToCSV($csv_out, no_header => 1,
                          headers => [qw(name age city)]);
        local *RD;
        open(RD, $csv_out) or die $!;
        my @lines = <RD>;
        close RD;
        ok(@lines == 2, 'ToCSV no_header: 2 lines (no header row)');
    },

    # 23: ToCSV round-trip - count preserved
    sub {
        JSON::LINQ->FromCSV($csv_in)
                  ->ToCSV($csv_out, headers => [qw(name age city)]);
        my @r = JSON::LINQ->FromCSV($csv_out)
                    ->Where(city => 'Tokyo')
                    ->ToArray();
        ok(@r == 2, 'ToCSV round-trip: Tokyo count = 2');
    },

    # 24: ToCSV round-trip - data value preserved
    sub {
        JSON::LINQ->FromCSV($csv_in)
                  ->ToCSV($csv_out, headers => [qw(name age city)]);
        my @r = JSON::LINQ->FromCSV($csv_out)
                    ->Where(city => 'Tokyo')
                    ->ToArray();
        ok($r[0]{name} eq 'Alice', 'ToCSV round-trip: first name = Alice');
    },

    # 25: TSV support (sep => "\t") - count
    sub {
        my $tsv = File::Spec->catfile($tmpdir, "jsonlinq_tsv_$$.tsv");
        local *TSV_FH;
        open(TSV_FH, "> $tsv") or die $!;
        print TSV_FH "name\tage\tcity\n";
        print TSV_FH "Alice\t30\tTokyo\n";
        print TSV_FH "Bob\t25\tOsaka\n";
        close TSV_FH;
        my @r = JSON::LINQ->FromCSV($tsv, sep => "\t")->ToArray();
        unlink $tsv;
        ok(@r == 2, 'TSV sep=tab: 2 records');
    },

    # 26: TSV support - field value
    sub {
        my $tsv = File::Spec->catfile($tmpdir, "jsonlinq_tsv_$$.tsv");
        local *TSV_FH;
        open(TSV_FH, "> $tsv") or die $!;
        print TSV_FH "name\tage\tcity\n";
        print TSV_FH "Alice\t30\tTokyo\n";
        print TSV_FH "Bob\t25\tOsaka\n";
        close TSV_FH;
        my @r = JSON::LINQ->FromCSV($tsv, sep => "\t")->ToArray();
        unlink $tsv;
        ok($r[1]{city} eq 'Osaka', 'TSV sep=tab: second city = Osaka');
    },

    # 27: TSV ToCSV with sep => "\t"
    sub {
        my $tsv_out = File::Spec->catfile($tmpdir, "jsonlinq_tsvout_$$.tsv");
        JSON::LINQ->FromCSV($csv_in)
                  ->Take(2)
                  ->ToCSV($tsv_out, sep => "\t",
                          headers => [qw(name age city)]);
        local *RD;
        open(RD, $tsv_out) or die $!;
        my $hdr = <RD>;
        close RD;
        $hdr =~ s/\r?\n\z//;
        unlink $tsv_out;
        ok($hdr eq "name\tage\tcity", 'ToCSV sep=tab: header is tab-separated');
    },

    # 28: Quoted field with embedded comma
    sub {
        my $qcsv = File::Spec->catfile($tmpdir, "jsonlinq_qcsv_$$.csv");
        local *QFH;
        open(QFH, "> $qcsv") or die $!;
        print QFH "name,note\n";
        print QFH "Alice,\"hello, world\"\n";
        print QFH "Bob,normal\n";
        close QFH;
        my @r = JSON::LINQ->FromCSV($qcsv)->ToArray();
        unlink $qcsv;
        ok($r[0]{note} eq 'hello, world',
            'FromCSV: quoted field with embedded comma');
    },

    # 29: Quoted field with embedded double-quote ("")
    sub {
        my $qcsv = File::Spec->catfile($tmpdir, "jsonlinq_qcsv2_$$.csv");
        local *QFH2;
        open(QFH2, "> $qcsv") or die $!;
        print QFH2 "name,note\n";
        print QFH2 "Alice,\"say \"\"hi\"\"\"\n";
        close QFH2;
        my @r = JSON::LINQ->FromCSV($qcsv)->ToArray();
        unlink $qcsv;
        ok($r[0]{note} eq 'say "hi"',
            'FromCSV: quoted field with embedded double-quote');
    },

    # 30: ToCSV quoting - field with comma gets quoted
    sub {
        my $tmpf = File::Spec->catfile($tmpdir, "jsonlinq_qtmp_$$.csv");
        JSON::LINQ->From([{ name => 'Alice', note => 'hello, world' }])
                  ->ToCSV($tmpf, headers => [qw(name note)]);
        local *RD;
        open(RD, $tmpf) or die $!;
        my @lines = <RD>;
        close RD;
        unlink $tmpf;
        $lines[1] =~ s/\r?\n\z//;
        ok($lines[1] eq 'Alice,"hello, world"',
            'ToCSV: field with comma is quoted');
    },

    # 31: ToCSV quoting - field with double-quote
    sub {
        my $tmpf = File::Spec->catfile($tmpdir, "jsonlinq_qtmp2_$$.csv");
        JSON::LINQ->From([{ name => 'Alice', note => 'say "hi"' }])
                  ->ToCSV($tmpf, headers => [qw(name note)]);
        local *RD;
        open(RD, $tmpf) or die $!;
        my @lines = <RD>;
        close RD;
        unlink $tmpf;
        $lines[1] =~ s/\r?\n\z//;
        ok($lines[1] eq 'Alice,"say ""hi"""',
            'ToCSV: field with double-quote is escaped');
    },

    # 32: ToCSV - undef value emitted as empty string
    sub {
        my $tmpf = File::Spec->catfile($tmpdir, "jsonlinq_undef_$$.csv");
        JSON::LINQ->From([{ id => 1, x => undef }])
                  ->ToCSV($tmpf, headers => [qw(id x)]);
        local *RD;
        open(RD, $tmpf) or die $!;
        my @lines = <RD>;
        close RD;
        unlink $tmpf;
        $lines[1] =~ s/\r?\n\z//;
        ok($lines[1] eq '1,', 'ToCSV: undef value emitted as empty string');
    },

    # 33: headers option with explicit column list (headerless CSV)
    sub {
        my $hcsv = File::Spec->catfile($tmpdir, "jsonlinq_hcsv_$$.csv");
        local *HFH;
        open(HFH, "> $hcsv") or die $!;
        print HFH "Alice,30,Tokyo\n";
        print HFH "Bob,25,Osaka\n";
        close HFH;
        my @r = JSON::LINQ->FromCSV($hcsv,
                    headers => [qw(name age city)])
                    ->ToArray();
        unlink $hcsv;
        ok(@r == 2 && $r[0]{name} eq 'Alice' && $r[1]{city} eq 'Osaka',
            'FromCSV headers option: headerless CSV, 2 records parsed');
    },

    # 34: headers + skip_header - skip existing header in file
    sub {
        my @r = JSON::LINQ->FromCSV($csv_in,
                    headers     => [qw(name age city)],
                    skip_header => 1)
                    ->ToArray();
        ok(@r == 4 && $r[0]{name} eq 'Alice',
            'FromCSV skip_header: existing header skipped, 4 records');
    },

    # 35: concurrent FromCSV (Join)
    sub {
        my $f1 = File::Spec->catfile($tmpdir, "jsonlinq_c1_$$.csv");
        my $f2 = File::Spec->catfile($tmpdir, "jsonlinq_c2_$$.csv");
        local *C1; local *C2;
        open(C1, "> $f1") or die $!;
        print C1 "id,name\n1,Alice\n2,Bob\n";
        close C1;
        open(C2, "> $f2") or die $!;
        print C2 "id,city\n1,Tokyo\n2,Osaka\n";
        close C2;
        my @r = JSON::LINQ->FromCSV($f1)->Join(
            JSON::LINQ->FromCSV($f2),
            sub { $_[0]{id} }, sub { $_[0]{id} },
            sub { { name => $_[0]{name}, city => $_[1]{city} } }
        )->ToArray();
        unlink $f1, $f2;
        ok(@r == 2, 'concurrent FromCSV Join: 2 results');
    },

    # 36: concurrent FromCSV Join - first result
    sub {
        my $f1 = File::Spec->catfile($tmpdir, "jsonlinq_c1b_$$.csv");
        my $f2 = File::Spec->catfile($tmpdir, "jsonlinq_c2b_$$.csv");
        local *C1B; local *C2B;
        open(C1B, "> $f1") or die $!;
        print C1B "id,name\n1,Alice\n2,Bob\n";
        close C1B;
        open(C2B, "> $f2") or die $!;
        print C2B "id,city\n1,Tokyo\n2,Osaka\n";
        close C2B;
        my @r = JSON::LINQ->FromCSV($f1)->Join(
            JSON::LINQ->FromCSV($f2),
            sub { $_[0]{id} }, sub { $_[0]{id} },
            sub { { name => $_[0]{name}, city => $_[1]{city} } }
        )->ToArray();
        unlink $f1, $f2;
        ok($r[0]{name} eq 'Alice' && $r[0]{city} eq 'Tokyo',
            'concurrent FromCSV Join: first = Alice/Tokyo');
    },

    # 37: concurrent FromCSV Join - second result
    sub {
        my $f1 = File::Spec->catfile($tmpdir, "jsonlinq_c1c_$$.csv");
        my $f2 = File::Spec->catfile($tmpdir, "jsonlinq_c2c_$$.csv");
        local *C1C; local *C2C;
        open(C1C, "> $f1") or die $!;
        print C1C "id,name\n1,Alice\n2,Bob\n";
        close C1C;
        open(C2C, "> $f2") or die $!;
        print C2C "id,city\n1,Tokyo\n2,Osaka\n";
        close C2C;
        my @r = JSON::LINQ->FromCSV($f1)->Join(
            JSON::LINQ->FromCSV($f2),
            sub { $_[0]{id} }, sub { $_[0]{id} },
            sub { { name => $_[0]{name}, city => $_[1]{city} } }
        )->ToArray();
        unlink $f1, $f2;
        ok($r[1]{name} eq 'Bob' && $r[1]{city} eq 'Osaka',
            'concurrent FromCSV Join: second = Bob/Osaka');
    },

    # 38: GroupBy on FromCSV
    sub {
        my @g = JSON::LINQ->FromCSV($csv_in)
                    ->GroupBy(sub { $_[0]{city} })
                    ->ToArray();
        my %by_city = map { $_->{Key} => scalar(@{$_->{Elements}}) } @g;
        ok($by_city{Tokyo} == 2 && $by_city{Osaka} == 1 && $by_city{Nagoya} == 1,
            'FromCSV + GroupBy: city counts correct');
    },

    # 39: Distinct on CSV column
    sub {
        my @cities = JSON::LINQ->FromCSV($csv_in)
                        ->Select(sub { $_[0]{city} })
                        ->Distinct()
                        ->OrderByStr(sub { $_[0] })
                        ->ToArray();
        ok(join(',', @cities) eq 'Nagoya,Osaka,Tokyo',
            'FromCSV + Select + Distinct: 3 unique cities');
    },

    # 40: CSV to JSON (FromCSV -> ToJSON round-trip via file)
    sub {
        my $json_out = File::Spec->catfile($tmpdir, "jsonlinq_csvjson_$$.json");
        JSON::LINQ->FromCSV($csv_in)
                  ->Where(city => 'Tokyo')
                  ->ToJSON($json_out);
        my @r = JSON::LINQ->FromJSON($json_out)->ToArray();
        unlink $json_out;
        ok(@r == 2 && $r[0]{name} eq 'Alice',
            'FromCSV->ToJSON: 2 Tokyo records, first = Alice');
    },
);

print "1.." . scalar(@tests) . "\n";
$_->() for @tests;

END {
    unlink $csv_in, $csv_out;
    print "# $PASS passed, $FAIL failed out of $T\n";
}
