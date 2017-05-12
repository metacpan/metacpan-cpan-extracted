use strict;
use warnings;

use Test::Simple tests => 11;

use Farly::Object::Ref;
use Farly::Value::String;

my $keys;

# ce = configuration element or container element

my $ce = Farly::Object::Ref->new();
	
$ce->set( "S1", Farly::Value::String->new("stringA1"));
$ce->set( "D1", Farly::Value::String->new("stringB2") );

my $search = Farly::Object::Ref->new();
	
$search->set( "S1", Farly::Value::String->new("stringA1"));
$search->set( "D1", Farly::Value::String->new("stringB2") );

ok( $ce->matches($search), "matches");
ok( $ce->equals($search), "equals");

$keys = join(" ", $ce->get_keys());

ok( $keys =~ /D1/ && $keys =~ /S1/, "get_keys" );

ok ( $ce->get("S1")->as_string() eq "stringA1", "get");

$ce->delete_key("D1");

$keys = join(" ", $ce->get_keys());

ok( $keys eq "S1", "delete_key" );

ok( $search->matches($ce), "matches smaller");

my $clone = $search->clone();

ok ( $clone->equals($search) && ($clone ne $search), "clone");

ok ( $search->contains($ce), "contains");

ok ( $search->contained_by($ce), "contained_by");

ok ( !$ce->contains($search), "!contains");

ok ( !$ce->contains("a string"), "!contains other type");
