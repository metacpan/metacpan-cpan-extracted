######################################################################
#
# 0002-json-io.t - JSON file I/O tests (FromJSON, FromJSONL, ToJSON, ToJSONL)
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
my $json_in  = File::Spec->catfile($tmpdir, "jsonlinq_in_$$.json");
my $jsonl_in = File::Spec->catfile($tmpdir, "jsonlinq_in_$$.jsonl");
my $json_out = File::Spec->catfile($tmpdir, "jsonlinq_out_$$.json");
my $jsonl_out= File::Spec->catfile($tmpdir, "jsonlinq_out_$$.jsonl");

# Setup: bareword filehandles (Perl 5.005_03: open() requires bareword FH)
local *JSON_IN_FH;
open(JSON_IN_FH, "> $json_in") or die "Cannot create $json_in: $!";
binmode JSON_IN_FH;
print JSON_IN_FH '[{"name":"Alice","age":30,"active":true},{"name":"Bob","age":25,"active":false},{"name":"Carol","age":35,"active":true}]';
close JSON_IN_FH;

local *JSONL_IN_FH;
open(JSONL_IN_FH, "> $jsonl_in") or die "Cannot create $jsonl_in: $!";
binmode JSONL_IN_FH;
print JSONL_IN_FH '{"id":1,"level":"INFO","msg":"started"}' . "\n";
print JSONL_IN_FH '{"id":2,"level":"ERROR","msg":"failed"}' . "\n";
print JSONL_IN_FH '{"id":3,"level":"INFO","msg":"done"}' . "\n";
print JSONL_IN_FH '{"id":4,"level":"ERROR","msg":"timeout"}' . "\n";
close JSONL_IN_FH;

my @tests = (
    # 1: FromJSON record count
    sub {
        my @r = JSON::LINQ->FromJSON($json_in)->ToArray();
        ok(@r == 3, 'FromJSON: reads correct number of records');
    },

    # 2: FromJSON first record
    sub {
        my @r = JSON::LINQ->FromJSON($json_in)->ToArray();
        ok($r[0]{name} eq 'Alice', 'FromJSON: correct first record name');
    },

    # 3: FromJSON + Where
    sub {
        my @r = JSON::LINQ->FromJSON($json_in)->Where(sub { $_[0]{age} >= 30 })->ToArray();
        ok(@r == 2, 'FromJSON + Where: correct count');
    },

    # 4: FromJSON boolean filtering
    sub {
        my @r = JSON::LINQ->FromJSON($json_in)->Where(sub { $_[0]{active} })->ToArray();
        ok(@r == 2, 'FromJSON: boolean filtering');
    },

    # 5: FromJSON + Select
    sub {
        my @n = JSON::LINQ->FromJSON($json_in)->Select(sub { $_[0]{name} })->ToArray();
        ok(join(',', @n) eq 'Alice,Bob,Carol', 'FromJSON + Select: names extracted');
    },

    # 6: FromJSONL record count
    sub {
        my @r = JSON::LINQ->FromJSONL($jsonl_in)->ToArray();
        ok(@r == 4, 'FromJSONL: reads correct number of records');
    },

    # 7: FromJSONL first record id
    sub {
        my @r = JSON::LINQ->FromJSONL($jsonl_in)->ToArray();
        ok($r[0]{id} == 1, 'FromJSONL: correct first record id');
    },

    # 8: FromJSONL + Where errors
    sub {
        my @r = JSON::LINQ->FromJSONL($jsonl_in)->Where(sub { $_[0]{level} eq 'ERROR' })->ToArray();
        ok(@r == 2, 'FromJSONL + Where: error count correct');
    },

    # 9: FromJSONL Count
    sub { ok(JSON::LINQ->FromJSONL($jsonl_in)->Count() == 4, 'FromJSONL Count') },

    # 10: FromJSONL Take
    sub {
        my @r = JSON::LINQ->FromJSONL($jsonl_in)->Take(2)->ToArray();
        ok(@r == 2, 'FromJSONL Take: early exit works');
    },

    # 11: ToJSON returns 1
    sub {
        my @data = ({name => 'X', val => 1}, {name => 'Y', val => 2});
        ok(JSON::LINQ->From(\@data)->ToJSON($json_out) == 1, 'ToJSON: returns 1');
    },

    # 12: ToJSON + FromJSON round-trip
    sub {
        my @r = JSON::LINQ->FromJSON($json_out)->ToArray();
        ok(@r == 2 && $r[0]{name} eq 'X', 'ToJSON + FromJSON round-trip');
    },

    # 13: ToJSONL returns 1
    sub {
        my @data = ({name => 'X', val => 1}, {name => 'Y', val => 2});
        ok(JSON::LINQ->From(\@data)->ToJSONL($jsonl_out) == 1, 'ToJSONL: returns 1');
    },

    # 14: ToJSONL + FromJSONL round-trip
    sub {
        my @r = JSON::LINQ->FromJSONL($jsonl_out)->ToArray();
        ok(@r == 2 && $r[0]{name} eq 'X', 'ToJSONL + FromJSONL round-trip');
    },

    # 15: FromJSONL blank lines skipped
    sub {
        my $tmpf = File::Spec->catfile($tmpdir, "blank_$$.jsonl");
        local *BLANK_FH;
        open(BLANK_FH, "> $tmpf") or die $!;
        binmode BLANK_FH;
        print BLANK_FH '{"id":1}' . "\n" . "\n" . '{"id":2}' . "\n";
        close BLANK_FH;
        my @r = JSON::LINQ->FromJSONL($tmpf)->ToArray();
        unlink $tmpf;
        ok(@r == 2, 'FromJSONL: blank lines skipped');
    },

    # 16: JSON null -> undef
    sub {
        my $tmpf = File::Spec->catfile($tmpdir, "null_$$.json");
        local *NULL_FH;
        open(NULL_FH, "> $tmpf") or die $!;
        binmode NULL_FH;
        print NULL_FH '[{"id":1,"val":null},{"id":2,"val":42}]';
        close NULL_FH;
        my @r = JSON::LINQ->FromJSON($tmpf)->ToArray();
        unlink $tmpf;
        ok(!defined($r[0]{val}) && $r[1]{val} == 42, 'FromJSON: null decoded as undef');
    },

    # 17: Sum via FromJSONL
    sub {
        ok(JSON::LINQ->FromJSONL($jsonl_in)->Sum(sub { $_[0]{id} }) == 10,
           'FromJSONL Sum: 1+2+3+4=10');
    },

    # 18: OrderByNum via FromJSON
    sub {
        my @s = JSON::LINQ->FromJSON($json_in)
            ->OrderByNum(sub { $_[0]{age} })
            ->Select(sub { $_[0]{name} })
            ->ToArray();
        ok($s[0] eq 'Bob' && $s[-1] eq 'Carol', 'FromJSON OrderByNum: correct order');
    },
);

print "1.." . scalar(@tests) . "\n";
$_->() for @tests;

END {
    unlink $json_in, $jsonl_in, $json_out, $jsonl_out;
    print "# $PASS passed, $FAIL failed out of $T\n";
}
