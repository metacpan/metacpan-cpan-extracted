#!/usr/local/bin/perl
##----------------------------------------------------------------------------
## Mail Builder - t/01_headers_content_type.t
## Test suite for Mail::Make::Headers::ContentType
##----------------------------------------------------------------------------
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG );
    use Test::More;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;

BEGIN
{
    use ok( 'Mail::Make::Headers::ContentType' );
};

# NOTE: Construction
subtest 'construction: valid type' => sub
{
    my $ct = Mail::Make::Headers::ContentType->new( 'text/plain' );
    ok( defined( $ct ), 'new() with text/plain returns object' );
    is( $ct->type, 'text/plain', 'type() returns correct value' );
    is( "$ct", 'text/plain', 'stringification works' );
};

subtest 'construction: no argument' => sub
{
    my $ct = Mail::Make::Headers::ContentType->new;
    ok( defined( $ct ), 'new() with no args returns object' );
    is( $ct->type, '', 'type() returns empty string when not set' );
};

subtest 'construction: invalid type' => sub
{
    my $ct = Mail::Make::Headers::ContentType->new( 'not-a-mime-type' );
    ok( !defined( $ct ) || $ct->type eq 'not-a-mime-type',
        'invalid type either fails or is stored (validation on type() setter)' );
    # Validate via the type() setter
    my $ct2 = Mail::Make::Headers::ContentType->new( 'text/plain' );
    my $rv = $ct2->type( 'no_slash_here' );
    ok( !defined( $rv ), 'type() setter rejects format without slash' );
    like( $ct2->error, qr/Invalid MIME type/i, 'error message mentions Invalid MIME type' );
};

# NOTE: charset
subtest 'charset: valid values' => sub
{
    my $ct = Mail::Make::Headers::ContentType->new( 'text/plain' );
    $ct->charset( 'utf-8' );
    is( $ct->charset, 'utf-8', 'charset utf-8 accepted and returned' );

    $ct->charset( 'UTF-8' );
    is( $ct->charset, 'utf-8', 'charset normalised to lowercase' );

    $ct->charset( 'utf8' );
    is( $ct->charset, 'utf-8', 'utf8 normalised to utf-8' );

    $ct->charset( 'iso-8859-1' );
    is( $ct->charset, 'iso-8859-1', 'iso-8859-1 accepted' );
};

subtest 'charset: unknown value' => sub
{
    my $ct = Mail::Make::Headers::ContentType->new( 'text/plain' );
    my $rv = $ct->charset( 'x-made-up-99' );
    ok( !defined( $rv ), 'unknown charset rejected' );
    like( $ct->error, qr/unsupported charset/i, 'error mentions charset' );
};

# NOTE: boundary
subtest 'boundary: valid' => sub
{
    my $ct = Mail::Make::Headers::ContentType->new( 'multipart/mixed' );
    $ct->boundary( 'abc123' );
    is( $ct->boundary, 'abc123', 'simple alphanumeric boundary accepted' );

    $ct->boundary( 'a' x 70 );
    is( length( $ct->boundary ), 70, '70-char boundary accepted' );
};

subtest 'boundary: too long' => sub
{
    my $ct = Mail::Make::Headers::ContentType->new( 'multipart/mixed' );
    my $rv = $ct->boundary( 'a' x 71 );
    ok( !defined( $rv ), '71-char boundary rejected' );
    like( $ct->error, qr/Invalid boundary/i, 'error mentions Invalid boundary' );
};

subtest 'boundary: illegal characters' => sub
{
    my $ct = Mail::Make::Headers::ContentType->new( 'multipart/mixed' );
    my $rv = $ct->boundary( "foo\x00bar" );
    ok( !defined( $rv ), 'boundary with NUL byte rejected' );
};

subtest 'boundary: trailing space' => sub
{
    my $ct = Mail::Make::Headers::ContentType->new( 'multipart/mixed' );
    my $rv = $ct->boundary( 'abc ' );
    ok( !defined( $rv ), 'boundary with trailing space rejected' );
};

# NOTE: make_boundary
subtest 'make_boundary' => sub
{
    my $ct = Mail::Make::Headers::ContentType->new( 'multipart/mixed' );
    my $b  = $ct->make_boundary;
    ok( defined( $b ) && length( $b ), 'make_boundary returns non-empty string' );
    ok( length( $b ) <= 70, 'generated boundary is <= 70 chars' );
    unlike( $b, qr/ $/, 'generated boundary has no trailing space' );
};

# NOTE: field_name
subtest 'field_name' => sub
{
    my $ct = Mail::Make::Headers::ContentType->new( 'text/plain' );
    is( $ct->field_name, 'Content-Type', 'field_name returns Content-Type' );
};

# NOTE: type setter / getter
subtest 'type setter validation' => sub
{
    my $ct = Mail::Make::Headers::ContentType->new( 'text/plain' );
    my $rv = $ct->type( 'image/png' );
    ok( defined( $rv ), 'type() accepts image/png' );
    is( $ct->type, 'image/png', 'type updated to image/png' );

    $rv = $ct->type( '' );
    ok( !defined( $rv ), 'type() rejects empty string' );
};

# NOTE: as_string with parameters
subtest 'as_string with charset' => sub
{
    my $ct = Mail::Make::Headers::ContentType->new( 'text/html' );
    $ct->charset( 'utf-8' );
    my $s = "$ct";
    like( $s, qr{^text/html}, 'starts with text/html' );
    like( $s, qr{charset}, 'contains charset parameter' );
};

done_testing();

__END__
