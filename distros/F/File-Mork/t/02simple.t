use strict;
use Test::More tests => 18;
use File::Mork;

my $filename = "examples/history.dat";

my $mork;
my @entries;

ok($mork = File::Mork->new($filename), "Instantiated file");
ok(!defined $File::Mork::ERROR, "No error message");
ok(@entries = $mork->entries, "Got entries");
is(@entries, 7, "There are 7");


my @keys    = qw(42 41 40 3F 2 E 1);
my %entries = map { $_->ID => $_ } @entries;

ok(exists($entries{$_}), "Got $_") for @keys;


is($entries{'3F'}->URL,            "http://www.mozilla.org/start/1.6/", "URL");
is($entries{'2'}->Hidden,          1,                                   "Hidden");
is($entries{'2'}->VisitCount,      7,                                   "VisitCount");
is($entries{'40'}->Hostname,       "www.whitehouse.org",                "Hostname");
is($entries{'41'}->Name,           "Limecat",                           "Name");
is($entries{'42'}->FirstVisitDate, 1099665649,                          "FirstVisitDate");
is($entries{'42'}->LastVisitDate,  1099665649,                          "LastVisitDate");

