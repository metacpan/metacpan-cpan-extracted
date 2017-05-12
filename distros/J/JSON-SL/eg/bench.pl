#!/usr/bin/perl
use strict;
use warnings;
use blib;
use JSON::SL;
use Data::Dumper::Concise;
use JSON::XS qw(decode_json);
use Getopt::Long;
use Benchmark qw(:all);
use Carp qw(confess);

$SIG{__DIE__} = \&confess;

GetOptions(
    'i|iterations=i' => \my $Iterations,
    'x|jsonxs' => \my $TestJsonxs,
    's|jsonsl' => \my $TestJsonsl,
    'j|jpr' => \my $TestJsonpointer,
    'c|chunked=i' => \my $TestChunks,
    'f|file=s'  => \my $TESTFILE,
    'r|recursion=i' => \my $RecursionLimit,
    'd|dump'    => \my $DumpTree,
    'U|no-unescape' => \my $DontUnescape,
    'h|help' => \my $PrintHelp
);

if ($PrintHelp) {
    print STDERR <<EOF;
$0 [options]
    -i --iterations=NUM Number of iterations
    -x --jsonxs             Benchmark JSON::XS
    -s --jsonsl             Benchmark JSON::SL
    -j --jpr                Test JSONPointer functionality
    -f --file=FILE          Run benchmarks on FILE
    -c --chunked=SIZE       Test incremental chunks of SIZE bytes
    -r --recursion=LEVEL    Set JSON::SL recursion limit
    -d --dump               Dump object tree on completion
    -U --no-unescape        Don't have JSON::SL unescape strings
EOF
    exit(1);
}

$Iterations ||= 20;

if ($ENV{PERL_JSONSL_DEFAULTS}) {
    $TestJsonsl = 1;
    $TestJsonxs = 1;
    $TestJsonpointer = 1;
    $TestChunks = 8192;
}

$TESTFILE ||= "share/auction";
$RecursionLimit ||= 256;

my $o = JSON::SL->new($RecursionLimit);
open my $fh, "<", $TESTFILE or die "$TESTFILE: $!";
my $txt = join("", <$fh>);
close($fh);

if ($TestJsonpointer) {
    $o->set_jsonpointer(["/alliance/auctions/^/auc"]);
    my $copy = substr($txt, 0, 246);
    my @all = $o->feed($copy);
    print $copy ."\n";
    print Dumper(\@all);
    print Dumper($o->root);
}

my @Chunks;
if ($TestChunks) {
    printf("Splitting file into chunks..\n");
    @Chunks = unpack("(a$TestChunks)*", $txt);
}

my $sl_incr = JSON::SL->new($RecursionLimit);
my $xs_incr = JSON::XS->new();

sub jsonsl_complete {
    JSON::SL::decode_json($txt);
}

sub jsonsl_incr {
    $sl_incr->reset();
    my $res = $sl_incr->feed($_) for @Chunks;
}

sub jsonxs_complete {
    JSON::XS::decode_json($txt);
}

sub jsonxs_incr {
    $xs_incr->incr_reset();
    my $res = $xs_incr->incr_parse($_) for @Chunks;
}

my %SimpleTests;
my %IncrTests;

if ($TestJsonxs) {
    $SimpleTests{'JSON::XS decode_json'} = \&jsonxs_complete;
    if (@Chunks) {
        $IncrTests{'JSON::XS incr_parse'} = \&jsonxs_incr;
    }
}

if ($TestJsonsl) {
    $SimpleTests{'JSON::SL decode_json'} = \&jsonsl_complete;
    if (@Chunks) {
        $IncrTests{'JSON::SL feed'} = \&jsonsl_incr;
    }
}

printf("Running decode_json tests with input of %d bytes\n", length($txt));
cmpthese($Iterations, \%SimpleTests);
if (@Chunks) {

    print "Running incremental tests\n";
    cmpthese($Iterations, \%IncrTests);
}
