######################################################################
#
# 0007-ltsv-io.t - LTSV file I/O tests (FromLTSV, ToLTSV)
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

my $tmpdir   = File::Spec->tmpdir();
my $ltsv_in  = File::Spec->catfile($tmpdir, "jsonlinq_ltsvin_$$.ltsv");
my $ltsv_out = File::Spec->catfile($tmpdir, "jsonlinq_ltsvout_$$.ltsv");

# Setup: write a sample LTSV file (bareword FH, raw bytes)
local *LTSV_IN_FH;
open(LTSV_IN_FH, "> $ltsv_in") or die "Cannot create $ltsv_in: $!";
binmode LTSV_IN_FH;
print LTSV_IN_FH "id:1\tname:Alice\tage:30\n";
print LTSV_IN_FH "id:2\tname:Bob\tage:25\n";
print LTSV_IN_FH "id:3\tname:Carol\tage:35\n";
print LTSV_IN_FH "\n";                         # blank line, must be skipped
print LTSV_IN_FH "id:4\tname:Dave\tage:40\n";
close LTSV_IN_FH;

my @tests = (
    # 1: FromLTSV record count (blank line skipped)
    sub {
        my @r = JSON::LINQ->FromLTSV($ltsv_in)->ToArray();
        ok(@r == 4, 'FromLTSV: blank line skipped, 4 records');
    },

    # 2: FromLTSV first record fields
    sub {
        my @r = JSON::LINQ->FromLTSV($ltsv_in)->ToArray();
        ok($r[0]{id} eq '1' && $r[0]{name} eq 'Alice' && $r[0]{age} eq '30',
           'FromLTSV: first record fields parsed');
    },

    # 3: FromLTSV + Where
    sub {
        my @r = JSON::LINQ->FromLTSV($ltsv_in)
                    ->Where(sub { $_[0]{age} >= 30 })
                    ->ToArray();
        ok(@r == 3, 'FromLTSV + Where: age >= 30 count correct');
    },

    # 4: FromLTSV + Select
    sub {
        my @n = JSON::LINQ->FromLTSV($ltsv_in)
                    ->Select(sub { $_[0]{name} })
                    ->ToArray();
        ok(join(',', @n) eq 'Alice,Bob,Carol,Dave', 'FromLTSV + Select: names extracted in order');
    },

    # 5: FromLTSV + Count
    sub {
        ok(JSON::LINQ->FromLTSV($ltsv_in)->Count() == 4, 'FromLTSV: Count = 4');
    },

    # 6: FromLTSV + Take (early exit, lazy)
    sub {
        my @r = JSON::LINQ->FromLTSV($ltsv_in)->Take(2)->ToArray();
        ok(@r == 2, 'FromLTSV + Take: lazy early exit');
    },

    # 7: FromLTSV + Sum
    sub {
        my $s = JSON::LINQ->FromLTSV($ltsv_in)->Sum(sub { $_[0]{age} });
        ok($s == 30 + 25 + 35 + 40, 'FromLTSV + Sum: 30+25+35+40 = 130');
    },

    # 8: ToLTSV returns 1
    sub {
        my @data = ({id => 1, name => 'X'}, {id => 2, name => 'Y'});
        ok(JSON::LINQ->From(\@data)->ToLTSV($ltsv_out) == 1, 'ToLTSV: returns 1');
    },

    # 9: ToLTSV + FromLTSV round-trip
    sub {
        my @r = JSON::LINQ->FromLTSV($ltsv_out)->ToArray();
        ok(@r == 2 && $r[0]{name} eq 'X' && $r[1]{id} eq '2',
           'ToLTSV + FromLTSV: round-trip preserves data');
    },

    # 10: ToLTSV emits keys in alphabetical order (deterministic)
    sub {
        my $tmpf = File::Spec->catfile($tmpdir, "ltsv_order_$$.ltsv");
        JSON::LINQ->From([{ z => 1, a => 2, m => 3 }])->ToLTSV($tmpf);
        local *ORD_FH;
        open(ORD_FH, "< $tmpf") or die $!;
        binmode ORD_FH;
        my $line = <ORD_FH>;
        close ORD_FH;
        chomp $line;
        $line =~ s/\r\z//;
        unlink $tmpf;
        ok($line eq "a:2\tm:3\tz:1", 'ToLTSV: keys emitted alphabetically');
    },

    # 11: ToLTSV sanitizes TAB/CR/LF in values
    sub {
        my $tmpf = File::Spec->catfile($tmpdir, "ltsv_sanitize_$$.ltsv");
        JSON::LINQ->From([{ id => 1, msg => "a\tb\nc\rd" }])->ToLTSV($tmpf);
        local *SAN_FH;
        open(SAN_FH, "< $tmpf") or die $!;
        binmode SAN_FH;
        my $line = <SAN_FH>;
        close SAN_FH;
        chomp $line;
        $line =~ s/\r\z//;
        unlink $tmpf;
        ok($line eq "id:1\tmsg:a b c d",
           'ToLTSV: TAB/CR/LF in values sanitized to space');
    },

    # 12: FromLTSV + Where (DSL form)
    sub {
        my @r = JSON::LINQ->FromLTSV($ltsv_in)
                    ->Where(name => 'Bob')
                    ->ToArray();
        ok(@r == 1 && $r[0]{id} eq '2', 'FromLTSV + Where DSL: matches Bob');
    },

    # 13: FromLTSV + OrderByNum
    sub {
        my @s = JSON::LINQ->FromLTSV($ltsv_in)
                    ->OrderByNum(sub { $_[0]{age} })
                    ->Select(sub { $_[0]{name} })
                    ->ToArray();
        ok($s[0] eq 'Bob' && $s[-1] eq 'Dave', 'FromLTSV + OrderByNum: ascending by age');
    },

    # 14: ToLTSV + undef value -> empty
    sub {
        my $tmpf = File::Spec->catfile($tmpdir, "ltsv_undef_$$.ltsv");
        JSON::LINQ->From([{ id => 1, x => undef }])->ToLTSV($tmpf);
        local *UND_FH;
        open(UND_FH, "< $tmpf") or die $!;
        binmode UND_FH;
        my $line = <UND_FH>;
        close UND_FH;
        chomp $line;
        $line =~ s/\r\z//;
        unlink $tmpf;
        ok($line eq "id:1\tx:", 'ToLTSV: undef value emitted as empty string');
    },

    # 15: ToLTSV with label_order option
    sub {
        my $tmpf = File::Spec->catfile($tmpdir, "ltsv_label_order_$$.ltsv");
        JSON::LINQ->From([{ z => 1, a => 2, m => 3 }])
                  ->ToLTSV($tmpf, label_order => [qw(z m a)]);
        local *LO_FH;
        open(LO_FH, "< $tmpf") or die $!;
        binmode LO_FH;
        my $line = <LO_FH>;
        close LO_FH;
        chomp $line;
        $line =~ s/\r\z//;
        unlink $tmpf;
        ok($line eq "z:1\tm:3\ta:2", 'ToLTSV label_order: keys emitted in specified order');
    },

    # 16: ToLTSV with headers alias
    sub {
        my $tmpf = File::Spec->catfile($tmpdir, "ltsv_headers_$$.ltsv");
        JSON::LINQ->From([{ z => 1, a => 2, m => 3 }])
                  ->ToLTSV($tmpf, headers => [qw(m a)]);
        local *HD_FH;
        open(HD_FH, "< $tmpf") or die $!;
        binmode HD_FH;
        my $line = <HD_FH>;
        close HD_FH;
        chomp $line;
        $line =~ s/\r\z//;
        unlink $tmpf;
        ok($line eq "m:3\ta:2", 'ToLTSV headers alias: works as label_order alias');
    },

    # 17: ToLTSV label_order skips labels not in record
    sub {
        my $tmpf = File::Spec->catfile($tmpdir, "ltsv_skip_$$.ltsv");
        JSON::LINQ->From([{ name => 'Alice', age => 30 }])
                  ->ToLTSV($tmpf, label_order => [qw(name score age)]);
        local *SK_FH;
        open(SK_FH, "< $tmpf") or die $!;
        binmode SK_FH;
        my $line = <SK_FH>;
        close SK_FH;
        chomp $line;
        $line =~ s/\r\z//;
        unlink $tmpf;
        ok($line eq "name:Alice\tage:30", 'ToLTSV label_order: missing label silently skipped');
    },
);

print "1.." . scalar(@tests) . "\n";
$_->() for @tests;

END {
    unlink $ltsv_in, $ltsv_out;
    print "# $PASS passed, $FAIL failed out of $T\n";
}
