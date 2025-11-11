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
    use_ok( 'JSON::Schema::Validate' ) || BAIL_OUT( 'Cannot load JSON::Schema::Validate' );
}

my $EXT_ID  = 'https://example.com/ext.json';
my $EXT_DOC =
{
    '$schema' => 'https://json-schema.org/draft/2020-12/schema',
    '$id'     => $EXT_ID,
    '$defs'   => 
    {
        Thing => 
        {
            type       => 'object',
            required   => [ 'x' ],
            properties => 
            {
                x => { type => 'string', minLength => 1 },
            },
            additionalProperties => JSON::false,
        },
    },
};

my $ROOT =
{
    '$schema' => 'https://json-schema.org/draft/2020-12/schema',
    type      => 'object',
    properties => 
    {
        t => { '$ref' => $EXT_ID . '#/$defs/Thing' },
    },
    additionalProperties => JSON::false,
};

my $js = JSON::Schema::Validate->new( $ROOT )
    ->set_resolver(sub
    {
        my( $abs ) = @_;
        ( my $no_frag = $abs ) =~ s/\#.*$//;
        return( ( $no_frag eq $EXT_ID ) ? $EXT_DOC : undef );
    });

ok( $js, 'validator created' );

ok( $js->validate({ t => { x => 'ok' } }), 'valid instance passes' ) or diag( $js->error );

ok( !$js->validate({ t => { } }), 'missing t.x fails' );
like( $js->error->as_string, qr{required property 'x' is missing}, 'error mentions missing x' );

ok( !$js->validate({ t => { x => '' } }), 'minLength violation fails' );
like( $js->error->as_string, qr{string shorter than minLength 1}, 'error mentions minLength' );

done_testing();

__END__
