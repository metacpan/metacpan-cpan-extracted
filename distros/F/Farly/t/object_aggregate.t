use strict;
use warnings;

use Test::Simple tests => 10;

use Farly::Object::List;
use Farly::Object;
use Farly::Value::String;
use Farly::Object::Aggregate qw(NEXTVAL);

my $ce1 = Farly::Object->new();
my $ce2 = Farly::Object->new();
my $ce3 = Farly::Object->new();
my $ce4 = Farly::Object->new();

$ce1->set( "S1", Farly::Value::String->new("string11") );
$ce1->set( "D1", Farly::Value::String->new("string12") );

$ce2->set( "S1", Farly::Value::String->new("string21") );
$ce2->set( "D1", Farly::Value::String->new("string22") );

$ce3->set( "S1", Farly::Value::String->new("string31") );
$ce3->set( "D1", Farly::Value::String->new("string32") );

$ce4->set( "S1", Farly::Value::String->new("string31") );
$ce4->set( "D1", Farly::Value::String->new("string32") );

my $container = Farly::Object::List->new();

$container->add($ce1);
$container->add($ce3);
$container->add($ce2);
$container->add($ce4);

my $agg = Farly::Object::Aggregate->new( $container );

$agg->groupby('S1', 'D1', 'C');

ok ( scalar( $agg->iter() ) == 0, "_has_defined_keys" );

$agg->groupby('S1', 'D1' );

ok ( scalar( $agg->iter() ) == 3, "two keys" );

$agg->groupby('S1' );

ok ( scalar( $agg->iter() ) == 3, "single key" );

my $it = $agg->list_iterator();

ok( ref($it) eq 'CODE', "list_iterator code ref");

my $set_count = 0;
my $object_count = 0;

while ( my $set = NEXTVAL($it) ) {
    $set_count++;
    $object_count += $set->size(); 
}

ok( $set_count == 3, "set list_iterator" );

ok( $object_count == 4, "set list_iterator objects" );

my $id = Farly::Object->new();

$id->set( "S1", Farly::Value::String->new("string31") );

my $result = $agg->matches( $id );

ok ($result->isa('Farly::Object::List'), "matches result type" );

ok ( $result->size() == 2, "matches" );

my $new = Farly::Object::List->new();
$new->add($ce4);

$agg->update( $id, $new );

$result = $agg->matches( $id );
ok ( $result->size() == 1, "update" );

my $id_it = $agg->id_iterator();

my $id_count = 0;

while ( my $obj = NEXTVAL($id_it) ) {
    $id_count++; 
}

ok ( $id_count == 3, "id iterator" );
