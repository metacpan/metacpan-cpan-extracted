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
};

# Root schema references external $id with a JSON Pointer fragment:
#   https://ext.example/s/defs.json#/defs/age
#
# The resolver will return a document with $id and a defs block.

my $root =
{
    '$schema' => 'https://json-schema.org/draft/2020-12/schema',
    type      => 'object',
    required  => [ 'name', 'age' ],
    properties =>
    {
        name => { type => 'string', minLength => 1 },
        age  => { '$ref' => 'https://ext.example/s/defs.json#/defs/age' },
    },
    additionalProperties => JSON::false,
};

my $ext_doc =
{
    '$id'  => 'https://ext.example/s/defs.json',
    'defs' =>
    {
        'age' =>
        {
            type    => 'integer',
            minimum => 18,
        },
    },
};

my $js = JSON::Schema::Validate->new( $root )->register_builtin_formats;

$js->set_resolver( sub
{
    my( $abs ) = @_;
    return( $ext_doc ) if( $abs =~ /\Ahttps:\/\/ext\.example\/s\/defs\.json/ );
    return; # not found
});

# Valid: age = 20
ok(
    $js->validate({ name => 'Alice', age => 20 }),
    'external $ref with JSON Pointer fragment resolves and validates'
) or diag( $js->error );

# Invalid: age < 18
ok(
    !$js->validate({ name => 'Bob', age => 12 }),
    'age constraint enforced from external schema'
);
like( $js->error.'', qr/number less than minimum 18|not greater than/i, 'error mentions minimum' );

done_testing();

__END__
