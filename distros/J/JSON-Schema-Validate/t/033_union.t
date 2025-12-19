#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use lib './lib';
use open ':std' => 'utf8';
use Test::More;
use JSON;

BEGIN
{
    use_ok( 'JSON::Schema::Validate' ) || BAIL_OUT( "Unable to load JSON::Schema::Validate" );
};

# Test that schema unions work.
# Primitive types are object, array, string, number, integer, boolean, null or any

my $js1 = JSON::Schema::Validate->new({
    type => 'object',
    additionalProperties => 0,
    properties => 
    {
        test => 
        {
            type => [ 'boolean', 'integer' ],
            required => 1
        }
    }
});

my $js2 = JSON::Schema::Validate->new({
    type => 'object',
    additionalProperties => 0,
    properties => 
    {
        test => 
        {
            type => [
                {
                    type => "object",
                    additionalProperties => 0,
                    properties =>
                    {
                        dog =>
                        {
                            type => "string",
                            required => 1
                        }
                    }
                },
                {
                    type => "object",
                    additionalProperties => 0,
                    properties => 
                    {
                        sound => 
                        {
                            type => 'string',
                            enum => [ "bark","meow","squeak" ],
                            required => 1
                        }
                    }
                }
            ],
            required => 1
        }
    }
});

my $js3 = JSON::Schema::Validate->new({
    type => 'object',
    additionalProperties => 0,
    properties =>
    {
        test =>
        {
            type => [ qw/object array string number integer boolean null/ ],
            required => 1
        }
    }
});

my $result = $js1->validate({ test => "strang" });
ok( !$result, 'boolean or integer against string' ) or diag( $js1->error );

$result = $js1->validate({ test => 1 });
ok( $result, 'boolean or integer against integer' ) or diag( $js1->error );

$result = $js1->validate({ test => [ 'array' ] });
ok( not($result), 'boolean or integer against array' ) or diag( $js1->error );

$result = $js1->validate({ test => { object => 'yipe' } });
ok( !$result, 'boolean or integer against object' ) or diag( $js1->error );

$result = $js1->validate({ test => 1.1 });
ok( not($result), 'boolean or integer against number' ) or diag( $js1->error );

$result = $js1->validate({ test => !!1 });
ok( $result, 'boolean or integer against boolean' ) or diag( $js1->error );

$result = $js1->validate({ test => undef });
ok( !$result, 'boolean or integer against null' ) or diag( $js1->error );

$result = $js2->validate({ test => { dog => "woof" } });
ok( $result, 'object or object against object a' ) or diag( $js2->error );

$result = $js2->validate({ test => { sound => "meow" } });
ok( $result, 'object or object against object b nested enum pass' ) or diag( $js2->error );

$result = $js2->validate({ test => { sound => "oink" } });
ok( not($result), 'object or object against object b enum fail' ) or diag( $js2->error );

$result = $js2->validate({ test => { audible => "meow" } });
ok( !$result, 'object or object against invalid object' ) or diag( $js2->error );

$result = $js2->validate({ test => 2 });
ok( !$result, 'object or object against integer' ) or diag( $js2->error );

$result = $js2->validate({ test => 2.2 });
ok( !$result, 'object or object against number' ) or diag( $js2->error );

$result = $js2->validate({ test => !1 });
ok( !$result, 'object or object against boolean' ) or diag( $js2->error );

$result = $js2->validate({ test => undef });
ok( !$result, 'object or object against null' ) or diag( $js2->error );

$result = $js2->validate({ test => { dog => undef } });
ok( not($result), 'object or object against object a bad inner type' ) or diag( $js2->error );

$result = $js3->validate({ test => { dog => undef } });
ok( $result, 'all types against object' ) or diag( $js3->error );

$result = $js3->validate({ test => [ 'dog' ] });
ok( $result, 'all types against array' ) or diag( $js3->error );

$result = $js3->validate({ test => 'dog' });
ok( $result, 'all types against string' ) or diag( $js3->error );

$result = $js3->validate({ test => 1.1 });
ok( $result, 'all types against number' ) or diag( $js3->error );

$result = $js3->validate({ test => 1 });
ok( $result, 'all types against integer' ) or diag( $js3->error );

$result = $js3->validate({ test => 1 });
ok( $result, 'all types against boolean' ) or diag( $js3->error );

$result = $js3->validate({ test => undef });
ok( $result, 'all types against null' ) or diag( $js3->error );

done_testing;

__END__
