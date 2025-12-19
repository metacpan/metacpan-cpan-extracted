#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use open ':std' => 'utf8';
use lib './lib';
use Test::More;
use JSON ();

BEGIN
{
    use_ok( 'JSON::Schema::Validate' ) || BAIL_OUT( "Unable to load JSON::Schema::Validate" );
};

# Schema that uses contentEncoding + contentMediaType + contentSchema
my $schema =
{
    '$schema' => 'https://json-schema.org/draft/2020-12/schema',
    type      => 'object',
    required  => [ 'payload' ],
    properties =>
    {
        payload =>
        {
            type              => 'string',
            contentEncoding   => 'base64',
            contentMediaType  => 'application/json; charset=utf-8',
            contentSchema     =>
            {
                type       => 'object',
                required   => [ 'name', 'age' ],
                properties =>
                {
                    name => { type => 'string', minLength => 1 },
                    age  => { type => 'integer', minimum => 0 },
                },
                additionalProperties => JSON::false,
            },
        },
    },
    additionalProperties => JSON::false,
};

# Build valid instance: JSON -> base64
my $inner = { name => 'Alice', age => 7 };
my $inner_json = JSON->new->canonical(1)->encode( $inner );

my $have_base64 = eval{ require MIME::Base64; 1 } ? 1 : 0;

SKIP:
{
    if( !$have_base64 )
    {
        skip( 'MIME::Base64 not installed; skipping base64 content check tests', 4 );
    }
    my $b64 = MIME::Base64::encode_base64( $inner_json, '' );
    
    # 1) content checks disabled (default): invalid base64 is NOT an error
    {
        my $js = JSON::Schema::Validate->new( $schema )->register_builtin_formats;
    
        my $ok1 = $js->validate({ payload => $b64 });
        ok( $ok1, 'valid base64+JSON passes with default content checks' ) or diag( $js->error );
    
        my $ok2 = $js->validate({ payload => '!!!not-base64!!!' });
        ok( $ok2, 'invalid base64 is tolerated when content checks are disabled' ) or diag( $js->error );
    }
    
    # 2) content checks enabled: invalid base64 must fail; valid must pass
    {
        my $js = JSON::Schema::Validate->new( $schema )->register_builtin_formats;
        $js->enable_content_checks(1);
    
        my $ok1 = $js->validate({ payload => $b64 });
        ok( $ok1, 'valid base64+JSON passes with content checks enabled' ) or diag( $js->error );
    
        my $ok2 = $js->validate({ payload => '!!!not-base64!!!' });
        ok( !$ok2, 'invalid base64 fails when content checks are enabled' );
        like( $js->error.'', qr/contentEncoding 'base64' decode failed/i, 'error mentions base64 decode failure' );
    }
    
    # 3) content checks enabled + JSON decodes but violates contentSchema
    {
        my $js = JSON::Schema::Validate->new( $schema )->register_builtin_formats;
        $js->enable_content_checks(1);
    
        # Missing required "age"
        my $bad_json = JSON->new->encode({ name => 'Bob' });
        my $bad_b64  = MIME::Base64::encode_base64( $bad_json, '' );
    
        my $ok = $js->validate({ payload => $bad_b64 });
        ok( !$ok, 'violating contentSchema fails with content checks enabled' );
        like( $js->error . '', qr/required property 'age' is missing/, 'first error is about missing age' );
    }
};

done_testing();

__END__
