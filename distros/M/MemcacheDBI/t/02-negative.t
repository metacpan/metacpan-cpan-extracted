#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 8;
use Test::Deep;
use Data::Dumper;

use_ok('MemcacheDBI');

my $memd_server = $ENV{'memd_server'};
my $user = $ENV{'dbi_user'};
my $password = $ENV{'dbi_pass'};
my $database = $ENV{'dbi_table'} // 'test';
my $table = $ENV{'dbi_table'} // 'test';
my $data_source = $ENV{'dbi_source'} // "dbi:CSV:f_dir=./t";


my $dbh = eval{MemcacheDBI->connect('dbi:nodriverfailme:host=127.127.127.127', $user, $password, {
    'AutoCommit'         => 1,
    'ChopBlanks'         => 1,
    'ShowErrorStatement' => 1,
    'pg_enable_utf8'     => 1,
    'mysql_enable_utf8'  => 1,
})};

ok(!defined $dbh,'dbh should not be defined yet');
ok(!eval{$dbh->commit},'trying to commit should fail');

$dbh = MemcacheDBI->connect($data_source, $user, $password, {
    'AutoCommit'         => 1,
    'ChopBlanks'         => 1,
    'ShowErrorStatement' => 1,
    'pg_enable_utf8'     => 1,
    'mysql_enable_utf8'  => 1,
});
ok(defined $dbh,'dbh should be defined');

ok(!eval{$dbh->iamaninvalidcommand},'trying an invalid command should fail AUTOLOAD');
ok($@ =~ /02\-negative\.t/,'error message reported me');

ok(!eval{$dbh->iamaninvalidcommand},'trying an invalid command should fail SUB');
ok($@ =~ /02\-negative\.t/,'error message reported me');

1;
