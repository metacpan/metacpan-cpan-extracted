#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use lib './lib';
use Test::More;
use JSON ();
use MIME::Base64 ();
use Encode ();

BEGIN
{
    use_ok( 'JSON::Schema::Validate' ) || BAIL_OUT( "Unable to load JSON::Schema::Validate" );
};

for my $compile ( 0, 1 )
{
    subtest "compile=$compile" => sub
    {
        my $check = sub
        {
            my( $schema, $data, $expected, $label, @opts ) = @_;
            my $js = JSON::Schema::Validate->new( $schema, compile => $compile, @opts );
            is( $js->validate( $data ) ? 1 : 0, $expected, $label ) or diag( $js->error );
            return( $js );
        };
        $check->( JSON::true, undef, 1, 'true root schema' );
        $check->( JSON::false, 1, 0, 'false root schema' );
        my $schema = { properties => { nested => { type => 'object', required => ['value'] } } };
        $check->( $schema, {}, 1, 'nested required array does not require its parent' );
        $check->( $schema, { nested => {} }, 0, 'nested required array still applies' );
        $check->( { properties => { a => { required => JSON::true } } }, {}, 0, 'property-level required extension remains supported' );
        $check->( { multipleOf => 2 }, -4, 1, 'negative multiple' );
        $check->( { multipleOf => 0.01 }, -19.99, 1, 'negative decimal multiple' );
        $check->( { multipleOf => 1 }, 1e-10, 0, 'small non-multiple cannot be rounded to zero' );
        $check->( { multipleOf => 0.1 }, 0.3, 1, 'decimal multiple' );
        $check->( { multipleOf => 0.1 }, 0.31, 0, 'decimal non-multiple' );
        $check->( { type => 'integer' }, 1e20, 1, 'integer in exponential notation' );
        $check->( { type => 'integer' }, -1.5, 0, 'fraction is not an integer' );
        $check->( { minLength => 3, pattern => '^abc$' }, 1, 1, 'string keywords do not apply to numbers' );
        $check->( { minLength => 2 }, 'éé', 1, 'Latin-1 range characters count as characters' );
        $check->( { maxLength => 1 }, '𠮷', 1, 'astral character counts once' );
        my $js = $check->( { type => [{ minimum => 10 }, 'number'] }, 5, 1, 'inline type alternatives isolate errors' );
        is( scalar( @{$js->errors} ), 0, 'successful union has no stale errors' );
        $schema = { anyOf => [{ type => 'string' }, { type => 'array' }, { type => 'object' }] };
        $js = $check->( $schema, 1, 0, 'error limit does not turn failure into success', max_errors => 1 );
        is( scalar( @{$js->errors} ), 1, 'combinator respects error limit' );
        $js = $check->( $schema, 1, 0, 'unlimited error collection', max_errors => 0 );
        is( scalar( @{$js->errors} ), 4, 'all branch and combinator errors recorded' );

        $schema = { '$id' => 'folder/root.json', '$ref' => 'other.json' };
        my @uris;
        $js = JSON::Schema::Validate->new( $schema, compile => $compile );
        $js->set_resolver( sub
        {
            push( @uris, $_[0] );
            return( $_[0] eq 'folder/other.json' ? { type => 'integer' } : undef );
        });
        ok( $js->validate(1), 'relative root identifier is applied once' );
        is_deeply( \@uris, ['folder/other.json'], 'relative resource URI' );
        $schema =
        {
            '$id' => 'https://example.test/root',
            '$defs' => { x => { type => 'integer' }, inner => { '$id' => 'inner', '$ref' => '#/$defs/x' } },
            '$ref' => 'inner',
        };
        $check->( $schema, 1, 0, 'missing resource-local pointer never falls back to containing document' );
        $schema->{'$defs'}->{inner}->{'$defs'} = { x => { type => 'string' } };
        $check->( $schema, 'x', 1, 'embedded resource uses its own definitions' );
        $check->( $schema, 1, 0, 'embedded resource rejects wrong type' );
        $schema = { '$id' => 'https://example.test/a/root.json', '$ref' => '../external.json#/$defs/x' };
        $js = JSON::Schema::Validate->new( $schema, compile => $compile );
        my $calls = 0;
        $js->set_resolver( sub
        {
            $calls++;
            return unless( $_[0] eq 'https://example.test/external.json#/$defs/x' );
            return({ '$defs' => { x => { '$ref' => '#/$defs/y' }, y => { type => 'integer' } } });
        });
        ok( $js->validate(1), 'external resource resolves local pointer and relative path' );
        ok( !$js->validate('x'), 'external local reference enforces type' );
        is( $calls, 2, 'resolver answers are not cached across validations' );
        $js->set_resolver( sub{ JSON::false } );
        ok( !$js->validate(1), 'replacing resolver cannot reuse previous answer' );
        $schema = { '$defs' => { '' => JSON::false }, '$ref' => '#/$defs/' };
        $check->( $schema, 1, 0, 'trailing empty pointer token retained' );
        $schema = { '$defs' => { 'é' => { type => 'integer' } }, '$ref' => '#/$defs/%C3%A9' };
        $check->( $schema, 1, 1, 'percent-encoded pointer is decoded as UTF-8' );
        $check->( $schema, 'x', 0, 'percent-encoded pointer constraint enforced' );
        $schema = { '$defs' => { x => { '$dynamicAnchor' => 'item', type => 'integer' } }, '$dynamicRef' => '#item' };
        $check->( $schema, 1, 1, 'dynamic anchor is resolvable before its schema is visited' );
        $check->( $schema, 'x', 0, 'dynamic anchor constraint enforced' );
        $schema->{'$ref'} = delete( $schema->{'$dynamicRef'} );
        $check->( $schema, 1, 1, 'dynamic anchor is also a plain anchor' );
        $schema =
        {
            '$id' => 'https://example.test/strict', '$dynamicAnchor' => 'node',
            '$defs' =>
            {
                tree => { '$id' => 'tree', '$dynamicAnchor' => 'node', type => 'object', properties => { children => { type => 'array', items => { '$dynamicRef' => '#node' } } } },
            },
            '$ref' => 'tree', required => ['value'],
        };
        $check->( $schema, { value => 1, children => [{ value => 2 }] }, 1, 'outer dynamic scope applies to descendants' );
        $check->( $schema, { value => 1, children => [{}] }, 0, 'outer dynamic anchor requires value in descendant' );
        $schema = { '$id' => 'https://example.test/root', '$defs' => { x => { type => 'integer' } }, allOf => [{ '$ref' => '#/$defs/x' }, { enum => [{ '$id' => 'https://example.test/root' }] }] };
        $check->( $schema, 1, 0, 'literal identifiers cannot pollute schema resources' );
        $schema = { '$ref' => '#', type => 'integer' };
        $check->( $schema, 1, 1, 'self-reference with a sibling terminates' );
        $check->( $schema, 'x', 0, 'self-reference does not bypass sibling' );

        $schema = { contentSchema => { type => 'integer' } };
        $check->( $schema, '"x"', 1, 'content schema is not asserted by default' );
        $check->( $schema, '"x"', 0, 'content schema is asserted when enabled', content_assert => 1 );
        $check->( { contentSchema => { type => 'null' } }, 'null', 1, 'JSON null is a successfully decoded payload', content_assert => 1 );
        $schema = { contentEncoding => 'base64', contentMediaType => 'application/json', contentSchema => { type => 'string', maxLength => 2 } };
        my $b64 = MIME::Base64::encode_base64( Encode::encode( 'UTF-8', '"日本"' ), '' );
        $check->( $schema, $b64, 1, 'base64 JSON is decoded as UTF-8', content_assert => 1 );
        $b64 = MIME::Base64::encode_base64( Encode::encode( 'UTF-8', '"日本語"' ), '' );
        $check->( $schema, $b64, 0, 'decoded JSON string length is enforced', content_assert => 1 );
        $js = JSON::Schema::Validate->new( { contentEncoding => 'base64', contentMediaType => 'application/json' }, compile => $compile );
        my $original = Encode::encode( 'UTF-8', '"日本"' );
        $js->register_media_validator( 'application/json' => sub{ return( $_[0] eq $original && !utf8::is_utf8( $_[0] ), 'custom validator expects octets' ); } );
        $js->enable_content_checks(1);
        ok( $js->validate( MIME::Base64::encode_base64( $original, '' ) ), 'custom media callback receives original octets' );
    };
}

done_testing();

__END__
