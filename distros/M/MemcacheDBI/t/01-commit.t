#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 16;
use Test::Deep;
use Data::Dumper;

use_ok('MemcacheDBI');

my $memd_server = $ENV{'memd_server'};
my $user = $ENV{'dbi_user'};
my $password = $ENV{'dbi_pass'};
my $database = $ENV{'dbi_table'} // 'test';
my $table = $ENV{'dbi_table'} // 'test';
my $data_source = $ENV{'dbi_source'} // "dbi:CSV:f_dir=./t";

SKIP: {
    skip 'This test is designed for the DBI:Pg driver', 15 unless $data_source =~ /^DBI:Pg:/;
    foreach my $autocommit ( 0, 1 ) {
        local $SIG{__WARN__} = sub{}; # eat warnings about autocommit, it will fail with DBD:CSV
        my $dbh = eval{MemcacheDBI->connect($data_source, $user, $password, {
            'AutoCommit'         => $autocommit,
            'ChopBlanks'         => 1,
            'ShowErrorStatement' => 1,
            'pg_enable_utf8'     => 1,
            'mysql_enable_utf8'  => 1,
        })};

        #this is specifically to test that commit works without memcache being initialized
        my $test = $dbh->commit;
        ok($dbh->{'AutoCommit'} ? !$test : $test, 'commit');
    }

    SKIPMEMD: {
        skip 'This test is requires the memd_server ENV varaiable', 13 unless defined $memd_server;
        my $dbh = eval{MemcacheDBI->connect($data_source, $user, $password, {
            'AutoCommit'         => 1,
            'ChopBlanks'         => 1,
            'ShowErrorStatement' => 1,
            'pg_enable_utf8'     => 1,
            'mysql_enable_utf8'  => 1,
        })};
        $dbh->memd_init({servers=>['localhost:11211']});

        my $dbh2 = eval{MemcacheDBI->connect($data_source, $user, $password, {
            'AutoCommit'         => 1,
            'ChopBlanks'         => 1,
            'ShowErrorStatement' => 1,
            'pg_enable_utf8'     => 1,
            'mysql_enable_utf8'  => 1,
        })};
        $dbh2->memd_init({servers=>['localhost:11211']});

        $dbh->memd->set('test_me',1);
        cmp_ok($dbh->memd->get('test_me'),'eq','1','test 1');
        $dbh->{'AutoCommit'} = 0;
        cmp_ok($dbh->memd->get('test_me'),'eq','1','test 1');

        $dbh->memd->set('test_me',2);
        cmp_ok($dbh->memd->get('test_me'),'eq','2','test 2 dbh1');
        cmp_ok($dbh2->memd->get('test_me'),'eq','1','test 1 dbh2');

        $dbh->memd->set('test_me',3);
        cmp_ok($dbh->memd->get('test_me'),'eq','3','test 3');

        $dbh->rollback;
        cmp_ok($dbh->memd->get('test_me'),'eq','1','test 1 dbh1');
        cmp_ok($dbh2->memd->get('test_me'),'eq','1','test 1 dbh2');

        $dbh->memd->set('test_me',4);
        cmp_ok($dbh->memd->get('test_me'),'eq','4','test 4');
        cmp_ok($dbh2->memd->get('test_me'),'eq','1','test 1 dbh2');

        $dbh->commit;
        cmp_ok($dbh->memd->get('test_me'),'eq','4','test 4 dbh1');
        cmp_ok($dbh2->memd->get('test_me'),'eq','4','test 4 dbh2');

        $dbh2->memd->set('test_me',5);
        cmp_ok($dbh->memd->get('test_me'),'eq','5','test 5');
        cmp_ok($dbh2->memd->get('test_me'),'eq','5','test 5 dbh2');
    }
}
