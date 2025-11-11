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

# This test focuses on register_content_decoder and register_media_validator.
# We simulate a custom "rot13" contentEncoding and a permissive media validator.

my $schema =
{
    '$schema' => 'https://json-schema.org/draft/2020-12/schema',
    type      => 'object',
    required  => [ 'bin' ],
    properties =>
    {
        bin =>
        {
            type             => 'string',
            contentEncoding  => 'rot13',
            contentMediaType => 'text/plain; charset=utf-8',
        },
    },
    additionalProperties => JSON::false,
};

my $js = JSON::Schema::Validate->new( $schema );

# Custom decoder: rot13
$js->register_content_decoder( 'rot13', sub
{
    my( $s ) = @_;
    $s =~ tr/A-Za-z/N-ZA-Mn-za-m/;
    return( 1, undef, $s ); # (ok, msg, decoded)
});

# Custom media validator: only accept strings that start with "OK:"
$js->register_media_validator( 'text/plain', sub
{
    my( $bytes, $params ) = @_;
    return( 0, 'not plain bytes' ) if( ref( $bytes ) );
    return( $bytes =~ /\AOK:/ ? ( 1, undef, $bytes ) : ( 0, 'payload must start with OK:' ) );
});

# With content checks disabled, any rot13/plaintext passes
ok(
    $js->validate({ bin => 'Bx:Uryyb' }), # rot13("Ok:Hello")
    'without content checks, media/decoder not enforced'
) or diag( $js->error );

# Enable assertions and now enforce the flow
$js->enable_content_checks(1);

# Good: decodes to "Ok:Hello" which matches /^OK:/ case-insensitive? Our validator expects "OK:", so use uppercase
my $good = 'BX:URYYB'; # rot13("OK:HELLO")
ok( $js->validate({ bin => $good }), 'rot13 decode + media validator passes' ) or diag( $js->error );

# Bad: still rot13 but decodes to "NOPE:HELLO"
my $bad  = 'ABCR:URYYB'; # rot13("NOPE:HELLO")
ok( !$js->validate({ bin => $bad }), 'media validator rejects unexpected prefix' );
like( $js->error.'', qr/payload must start with OK:/, 'media failure message propagated' );

done_testing();

__END__
