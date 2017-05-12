use strict;
use warnings;

use Test::Simple tests => 13;

use Farly::Object::Set;
use Farly::Object;
use Farly::Value::String;

my $s1 = Farly::Object->new();
my $s2 = Farly::Object->new();
my $s3 = Farly::Object->new();
my $s4 = Farly::Object->new();
my $s5 = Farly::Object->new();

$s1->set( "OBJECT", Farly::Value::String->new("10.1.2.3") );
$s2->set( "OBJECT", Farly::Value::String->new("10.1.2.3") );
$s3->set( "OBJECT", Farly::Value::String->new("10.1.1.3") );
$s4->set( "OBJECT", Farly::Value::String->new("10.1.3.3") );
$s5->set( "OBJECT", Farly::Value::String->new("10.1.3.4") );

ok( $s1->equals($s2), "equals" );

my $set1 = Farly::Object::Set->new();
my $set2 = Farly::Object::Set->new();

$set1->add($s1);
$set2->add($s2);

ok( $set1->equals($set2), "equals" );

$set2->add($s3);

ok( !$set1->equals($set2), "!equals - Set" );

ok( $set2->contains($set1), "contains - Set" );

ok( !$set1->contains($set2), "!contains - Set" );

ok( !$set1->equals($s1), "!equals - object" );

my $union = $set1->union($set2);

ok( $union->equals($set2), "union" );

my $isect = $set1->intersection($set2);

ok( $isect->includes($s1) && $isect->size() == 1, "intersection" );

my $diff = $set2->difference($set1);

ok( $diff->includes($s3) && $diff->size() == 1, "difference" );

my $set3 = Farly::Object::Set->new();

$set3->add($s4);
$set3->add($s5);

ok( $set1->disjoint($set3), "disjoint" );

$set3->add($s2);
$set3->add($s3);

ok( $set3->size() == 4, "size" );

ok( $set3->includes($s2), "includes string" );

ok( $set3->includes($set2), "includes set" );

