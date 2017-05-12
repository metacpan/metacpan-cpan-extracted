use strict;
use warnings;

use Test::Simple tests => 5;

use Farly::Object;

my $ce1 = Farly::Object->new();
my $ce2 = Farly::Object->new();
my $ce3 = Farly::Object->new();
my $search = Farly::Object->new();

$ce1->set( "S1", Farly::Value::String->new("string11") );
$ce1->set( "D1", Farly::Value::String->new("string12") );

$ce2->set( "S1", Farly::Value::String->new("string21") );
$ce2->set( "D1", Farly::Value::String->new("string22") );

$ce3->set( "S1", Farly::Value::String->new("string31") );
$ce3->set( "D1", Farly::Value::String->new("string32") );

$search->set( "S1", Farly::Value::String->new("string31") );
$search->set( "D1", Farly::Value::String->new("string32") );

my $container = Farly::Object::List->new();

$container->add($ce1);
$container->add($ce2);
$container->add($ce3);

my $search_result;
 
$search_result = Farly::Object::List->new();
$container->matches($search, $search_result);

ok ( scalar( $search_result->iter() ) == 1, "matches" );

$search_result = Farly::Object::List->new();
$container->contains($search, $search_result);

ok ( scalar( $search_result->iter() ) == 1, "contains" );

$search_result = Farly::Object::List->new();
$container->contained_by($search, $search_result);

ok ( scalar( $search_result->iter() ) == 1, "contained_by" );

$search_result = Farly::Object::List->new();
$container->search($search, $search_result);

ok ( scalar( $search_result->iter() ) == 1, "search" );

my $clone = $container->clone();

ok ( $clone->size() == $container->size() && ($clone ne $container), "clone");
