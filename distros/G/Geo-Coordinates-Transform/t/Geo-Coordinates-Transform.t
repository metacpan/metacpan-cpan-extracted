#!/usr/bin/perl

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Geo-Coordinates-Transform.t'

#########################

#use lib '../lib';

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 1 + 16;
BEGIN { use_ok('Geo::Coordinates::Transform') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use Geo::Coordinates::Transform;
use Data::Dumper; 

my @lst = ( 47.9805, -116.5586, '47 58.8300', '-116 33.5160', '47 58 49', '-116 33 30', '47 58 49.5', '-116 33 30.5'); 
my $N=1;
 
my $cnv = new Geo::Coordinates::Transform();

my $test_ref = $cnv->cnv_to_dd(\@lst); 

my $out_ref; 
$out_ref = $cnv->cnv_to_ddm(\@lst); 
$out_ref = $cnv->cnv_to_dd($out_ref); 

test_compare($out_ref,$test_ref);

$out_ref = $cnv->cnv_to_dms(\@lst); 
$out_ref = $cnv->cnv_to_dd($out_ref); 

test_compare($test_ref,$out_ref);

sub test_compare
{
 $ref1 = shift @_;
 $ref2 = shift @_;

 for (my $i=0; $i<scalar @{$ref1}; $i++)
 {
   is($ref1->[$i],$ref2->[$i], "Transform of $lst[$i]\n"); 
   $N++; 
 }
}


__DATA__

# Change output format
# dd_fmt = Decimal-Degrees format
# dm_fmt = Decimal-Minutes format
# ds_fmt = Decimal-Second format
$cnv = new Geo::Coordinates::Transform( {dd_fmt=>'%3.2f', dm_fmt=>'%3.1f', ds_fmt=>'%d'} );

$out_ref = $cnv->cnv_to_ddm(\@lst); 
print "ddm\n"; 
print Dumper $out_ref; 

$out_ref = $cnv->cnv_to_dms(\@lst); 
print "\ndms\n"; 
print Dumper $out_ref; 

$out_ref = $cnv->cnv_to_dd(\@lst); 
print "\ndd\n"; 
print Dumper $out_ref; 

 