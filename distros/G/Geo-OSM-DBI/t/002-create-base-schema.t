#!/usr/bin/perl
#
#  See inkscape created file t/002-data.svg for what's being
#  loaded with this script.
#

use strict;
use warnings;

use Test::Simple tests => 3;
use Test::More;
use DBI;

use Geo::OSM::DBI;

use t::helper;

my $db_test = 'test.db';

unlink $db_test if -f $db_test;

my $dbh = DBI->connect("dbi:SQLite:dbname=$db_test") or die "Could not create $db_test";
$dbh->{AutoCommit} = 0;

is_deeply([Geo::OSM::DBI::_schema_dot_from_opts({schema=>'foo'}       )], ['foo', 'foo.']); 
is_deeply([Geo::OSM::DBI::_schema_dot_from_opts({bla   =>'foo'}       )], [''   , ''    ]);
is_deeply([Geo::OSM::DBI::_schema_dot_from_opts({bla   =>'foo'}, 'bla')], ['foo', 'foo.']);


my $osm_db = Geo::OSM::DBI->new($dbh);
 
$osm_db->create_base_schema_tables();

t::helper::exec_sql_stmts_in_file($osm_db->{dbh}, 't/002-fill-base-schema.sql');
 
# open (my $sql, '<', 't/002-fill-base-schema.sql') or die "Could not open t/002-fill-base-schema.sql";
# 
# while (my $stmt = <$sql>) {
#   chomp $stmt;
#   $stmt =~ s/--.*//;
#   next unless $stmt =~ /\S/;
#   print "$stmt\n";
#   $osm_db->{dbh}->do($stmt) or die "Could not execute $stmt";
# }
# 
# 
# close $sql;
 
$osm_db->create_base_schema_indexes();

$dbh->commit;
