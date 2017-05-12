#!/usr/bin/env perl
use strict;
use warnings;
use above 'Genome';
use Test::More tests => 14;

use Genome::Sys;

sub mdir($) {
    system "mkdir -p $_[0]";
    ok(-d $_[0], "created directory $_[0]") or die "cannot continue!";
}

my $tmp = Genome::Sys->create_temp_directory("foo");
ok($tmp, "made temp directory $tmp");

my $tmp1 = $tmp . '/set1';
mdir($tmp1);
ok($tmp1, "made temp directory $tmp1");

my $tmp2 = $tmp . '/set2';
mdir($tmp2);
ok($tmp2, "made temp directory $tmp2");

$ENV{GENOME_DB} = join(":",$tmp1,$tmp2);

mdir($tmp1 . '/db1/1.0');
mdir($tmp1 . '/db1/2.1'); # the others are noise
mdir($tmp1 . '/db2/123');
mdir($tmp1 . '/db2/4');

my $ret = Genome::Sys->dbpath('db1','2.1');
is($ret, $tmp1 . '/db1/2.1', "path returns correctly");

mdir($tmp2 . '/db1/2.1'); # hidden by set 1

$ret = Genome::Sys->dbpath('db1','2.1');
is($ret, $tmp1 . '/db1/2.1', "path for db1 2.1 is the same as the last time because the new db is 2nd in the path");

rmdir $tmp1 . '/db1/2.1';
ok(! -d $tmp1 . '/db1/2.1', "removed the first database dir $tmp1/db1/2.1") or diag $!;

$ret = Genome::Sys->dbpath('db1','2.1');
is($ret, $tmp2 . '/db1/2.1', "path is the second db because the new db was removed") or diag $ret;



