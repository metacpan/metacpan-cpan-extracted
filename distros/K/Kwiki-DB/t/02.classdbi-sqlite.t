#!/usr/bin/perl
# -*- mode: cperl -*-

use lib 't/lib';
use Kwiki;
use DBI;
use Test::More;
use Kwiki::DB::Test;

eval 'require DBD::SQLite;require Class::DBI;';

if($@) {
    plan skip_all => 'Test require DBD::SQLite and Class::DBI';
} else {
    plan tests => 4;
}

{
my $dbh = DBI->connect("dbi:SQLite:t/classdbi-dbfile");
$dbh->do("CREATE TABLE artist (artistid, name);");
$dbh->do("CREATE TABLE cd (cdid, artist, title, year)");
$dbh->disconnect;
}

my $hub = Kwiki::DB::Test::load_hub('t/config.classdbi.yaml');

ok($hub->db);
my $db = $hub->db;

$db->base("Kwiki::DB::Music");

$db->entity(artist => "Kwiki::DB::Music::Artist");
$db->entity(cd     => "Kwiki::DB::Music::CD");

$db->connection("dbi:SQLite:t/classdbi-dbfile");

my $artist = $db->artist->create({artistid => 1, name => 'U2'});

ok($artist);

my $cd = $artist->add_to_cds({ cdid => 1, title => 'October', year => 1980 });
ok($cd);

$cd->year(1981);
$cd->update;

ok($cd->year == 1981);

unlink("t/classdbi-dbfile");


