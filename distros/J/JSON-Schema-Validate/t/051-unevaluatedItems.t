#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use lib './lib';
use open ':std' => 'utf8';
use Test::More;
use JSON ();

BEGIN
{
    use_ok( 'JSON::Schema::Validate' ) || BAIL_OUT( "Unable to load JSON::Schema::Validate" );
}

# prefixItems validates first 2, items validates the rest, therefore no unevaluated items left.
my $schema_ok =
{
    type => 'array',
    prefixItems => [
        { type => 'integer' },
        { type => 'string'  },
    ],
    items => { type => 'number' },
    unevaluatedItems => JSON::false,
};

my $js_ok = JSON::Schema::Validate->new( $schema_ok );
ok( $js_ok->validate( [ 1, 'a', 3.14, 0 ] ), 'all items evaluated; unevaluatedItems=false passes' ) or diag( $js_ok->error );

# Now remove 'items' so elements after index 1 are unevaluated ⇒ should fail.
my $schema_fail =
{
    type => 'array',
    prefixItems => [
        { type => 'integer' },
        { type => 'string'  },
    ],
    unevaluatedItems => JSON::false,
};

my $js_fail = JSON::Schema::Validate->new( $schema_fail );
ok( !$js_fail->validate( [ 1, 'a', 'extra' ] ), 'third item is unevaluated; unevaluatedItems=false fails' );

done_testing;

__END__
