use strict;
use warnings;

use Test::More 0.88;
eval "use JSON::Any qw(Syck)";
plan skip_all => "JSON::Syck not installed: $@" if $@;

ok( JSON::Any->new->objToJson( { foo => 1 } ) );
ok( JSON::Any->new->jsonToObj('{ "foo" : 1 }') );

done_testing;
