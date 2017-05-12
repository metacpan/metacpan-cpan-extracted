#!/usr/bin/perl -w
use strict;

use Test::More;

BEGIN {
    eval { require DBI };
    plan skip_all => 'DBI required to use MP3::Find::DB backend' if $@;
    eval { require DBD::SQLite };
    plan skip_all => 'DBD::SQLite required to use MP3::Find::DB backend' if $@;
    eval { require SQL::Abstract };
    plan skip_all => 'SQL::Abstract required to use MP3::Find::DB backend' if $@;

    plan tests => 8;
    use_ok('MP3::Find::DB') 
};

my $SEARCH_DIR = 't/mp3s';
my $DB_FILE = 't/mp3.db';
my $MP3_COUNT = 1;

# exercise the object

my $finder = MP3::Find::DB->new(
    status_callback => sub {},  # be quiet about updates
);
isa_ok($finder, 'MP3::Find::DB');

eval { $finder->create_db()  };
ok($@, 'create_db dies when not given a database name');
eval { $finder->update_db()  };
ok($@, 'update_db dies when not given a database name');
eval { $finder->destroy_db() };
ok($@, 'destroy_db dies when not given a database name');


# create a test db
unlink $DB_FILE;
$finder->create_db($DB_FILE);
ok(-e $DB_FILE, 'db file is there');

my $count = $finder->update_db($DB_FILE, $SEARCH_DIR);
is($count, $MP3_COUNT, 'added all the mp3s to the db');

# remove the db
$finder->destroy_db($DB_FILE);
ok(!-e $DB_FILE, 'db file is gone');

#TODO: get some test mp3s
#TODO: write a set of common set of test querys and counts for all the backends
