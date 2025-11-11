#!/usr/bin/perl
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

my $schema =
{
    '$schema' => 'https://json-schema.org/draft/2020-12/schema',
    '$id'     => 'https://example.org/s/root.json',
    type      => 'object',
    properties =>
    {
        id => { '$ref' => '#/$defs/uuid' },
    },
    '$defs' =>
    {
        uuid => { type => 'string', format => 'uuid' },
    },
    additionalProperties => JSON::false,
};

my $js = JSON::Schema::Validate->new( $schema );

ok( ! $js->{compiled}, 'not compiled yet (lazy)' );
$js->compile;
ok( $js->{compiled}, 'compiled after explicit compile()' );

# Now validate something simple (format not installed → no assertion)
ok( $js->validate({ id => 'not-a-uuid' }), 'format unchecked without builtins registered' );

$js->register_builtin_formats;
ok( ! $js->validate({ id => 'not-a-uuid' }), 'fails after registering built-in uuid format' );

done_testing();

__END__
