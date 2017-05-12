use strict;
use File::Cache::Persistent;
use Test::More qw(no_plan);

my $cache = new File::Cache::Persistent;

ok(
    $cache->get('t/1.txt') eq "test\n1\n" &&
    $cache->status == $File::Cache::Persistent::FILE,
    "Initial reading of 1.txt"
);

ok(
    $cache->get('t/2.txt') eq "test\n2\n" &&
    $cache->status == $File::Cache::Persistent::FILE,
    "Initial reading of 2.txt"
);

ok(
    $cache->get('t/3.txt') eq "test\n3\n" &&
    $cache->status == $File::Cache::Persistent::FILE,
    "Initial reading of 3.txt"
);

ok(
    $cache->get('t/1.txt') eq "test\n1\n" &&
    $cache->status == $File::Cache::Persistent::CACHE + $File::Cache::Persistent::NOT_MODIFIED,
    "Cached version of 1.txt"
);

cp('t/1.txt', 't/t.txt');
ok(
    $cache->get('t/t.txt') eq "test\n1\n" &&
    $cache->status == $File::Cache::Persistent::FILE,
    "Reading copy t.txt"
);

unlink 't/t.txt';
ok(
    $cache->get('t/t.txt') eq "test\n1\n" &&
    $cache->status == $File::Cache::Persistent::CACHE + $File::Cache::Persistent::NO_FILE,
    "Using cache for deleted t.txt"
);

$cache = new File::Cache::Persistent(
    prefix => 't'
);

ok(
    $cache->get('2.txt') eq "test\n2\n" &&
    $cache->status == $File::Cache::Persistent::FILE,
    "Initial reading of 2.txt; using prefix"
);

$cache->remove('2.txt');
ok(
    $cache->get('2.txt') eq "test\n2\n" &&
    $cache->status == $File::Cache::Persistent::FILE,
    "Reading 2.txt again"
);

ok(
    $cache->get('2.txt') eq "test\n2\n" &&
    $cache->status == $File::Cache::Persistent::CACHE + $File::Cache::Persistent::NOT_MODIFIED,
    "Cached version of 2.txt"
);

$cache = new File::Cache::Persistent(
    prefix => 't',
    timeout => 2,
);

ok(
    $cache->get('3.txt') eq "test\n3\n" &&
    $cache->status == $File::Cache::Persistent::FILE,
    "Initial reading of 3.txt for time cache"
);

ok(
    $cache->get('3.txt') eq "test\n3\n" &&
    $cache->status == $File::Cache::Persistent::CACHE + $File::Cache::Persistent::TIME_CACHE,
    "Cached version of 3.txt; within allowed timeout"
);

cp('t/1.txt', 't/a.txt');
cp('t/2.txt', 't/b.txt');
$cache->get('a.txt');
$cache->get('b.txt');

sleep 3;

ok(
    $cache->get('3.txt') eq "test\n3\n" &&
    $cache->status == $File::Cache::Persistent::CACHE + $File::Cache::Persistent::TIME_CACHE + $File::Cache::Persistent::NOT_MODIFIED + $File::Cache::Persistent::PROLONG + $File::Cache::Persistent::TIMEOUT,
    "Cached version of 3.txt; prolonging cache time"
);

ok(
    $cache->get('3.txt') eq "test\n3\n" &&
    $cache->status == $File::Cache::Persistent::CACHE + $File::Cache::Persistent::TIME_CACHE,
    "Re-reading 3.txt; before timeout"
);

unlink 't/a.txt';
cp('t/1.txt', 't/a.txt');

ok(
    $cache->get('a.txt') eq "test\n1\n" &&
    $cache->status == $File::Cache::Persistent::FILE + $File::Cache::Persistent::TIMEOUT,
    "Accessing a.txt; timeout happened + file was modified"
);

unlink 't/b.txt';

ok(
    $cache->get('b.txt') eq "test\n2\n" &&
    $cache->status == $File::Cache::Persistent::CACHE + $File::Cache::Persistent::TIME_CACHE + $File::Cache::Persistent::TIMEOUT + $File::Cache::Persistent::NO_FILE,
    "Accessing b.txt; timeout happened + file was deleted"
);

unlink 't/a.txt';

$cache = new File::Cache::Persistent(
    reader => \&my_reader
);

ok($cache->get("t/1.txt") eq "[t/1.txt]", "Using external file reader");

sub my_reader {
    my $path = shift;
    
    return "[$path]";
}

sub cp {
    my ($patha, $pathb) = @_;
    
    local $/;
    undef $/;
    
    open my $filea, '<', $patha;
    my $data = <$filea>;
    close $filea;

    open my $fileb, '>', $pathb;
    print $fileb $data;
    close $fileb;
}
