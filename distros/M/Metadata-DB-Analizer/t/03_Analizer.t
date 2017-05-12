use Test::Simple 'no_plan';
require './t/testlib.pl';
use strict;
use lib './lib';
use Metadata::DB::Analizer;


use Smart::Comments '###';

$Metadata::DB::Analizer::DEBUG = 1;

my $dbh = _get_new_handle();
ok($dbh, 'have database handle') or die;

my $a = Metadata::DB::Analizer->new({ DBH => $dbh });
ok($a, 'instanced') or die;



my $count = $a->get_records_count;
ok($count," have $count records");



my %test = (
   get_attributes => 'ARRAY',
   get_attributes_counts => 'HASH',
   get_attributes_ratios => 'HASH',
   get_attributes_by_ratio => 'ARRAY',
);

while ( my($method,$rtype) = each %test ){
   my $got;
   ok( $got = $a->$method, "method $method returns");
   ok( ref $got eq $rtype, "returns $rtype ref");
   ### $got


}


my $uniq = $a->get_attributes;
ok($uniq,'get_attributes() returns');
ok(scalar @$uniq > 10 ,'get_attributes() returns element ammount we expected');




