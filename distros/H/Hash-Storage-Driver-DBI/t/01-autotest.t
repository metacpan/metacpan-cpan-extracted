#!/usr/bin/perl

use Test::More;
use Hash::Storage::AutoTester;
use File::Temp qw/tmpnam/;
use DBI;

BEGIN {
    use_ok( 'Hash::Storage' ) || print "Bail out!\n";
    use_ok( 'Hash::Storage::Driver::DBI' ) || print "Bail out!\n";
}

my $dbh = DBI->connect( "dbi:SQLite:dbname=" . tmpnam(), "", "", {
    RaiseError     => 1,
    sqlite_unicode => 1,
} ) or die DBI->error;

$dbh->do( q{
    CREATE TABLE users (
        user_id    TEXT NOT NULL PRIMARY KEY,
        age        INTEGER NOT NULL DEFAULT 0,
        fname      TEXT    NOT NULL DEFAULT '',
        lname      TEXT    NOT NULL DEFAULT '',
        serialized BLOB    NOT NULL DEFAULT '',
        gender     TEXT    NOT NULL DEFAULT ''
    )
});

my $st = Hash::Storage->new( driver => [ DBI => { 
    dbh           => $dbh, 
    serializer    => 'JSON',
    table         => 'users',
    key_column    => 'user_id',
    data_column   => 'serialized',
    index_columns => ['age', 'fname', 'lname', 'gender']
} ]);

my $tester = Hash::Storage::AutoTester->new(storage => $st);
$tester->run();

done_testing;