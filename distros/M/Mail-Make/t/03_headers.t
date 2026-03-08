#!/usr/local/bin/perl
##----------------------------------------------------------------------------
## Mail Builder - t/03_headers.t
## Test suite for Mail::Make::Headers
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
    use ok( 'Mail::Make::Headers' );
};

# NOTE: Construction
subtest 'construction' => sub
{
    my $h = Mail::Make::Headers->new;
    ok( defined( $h ), 'new() returns object' );
};

# NOTE: set / get / has
subtest 'set and get' => sub
{
    my $h = Mail::Make::Headers->new;
    $h->set( 'X-Custom', 'hello' );
    is( $h->get( 'X-Custom' ), 'hello', 'get() returns value set by set()' );
    is( $h->get( 'x-custom' ), 'hello', 'get() is case-insensitive' );
};

subtest 'has' => sub
{
    my $h = Mail::Make::Headers->new;
    $h->set( 'X-Foo', 'bar' );
    ok( $h->has( 'X-Foo' ),   'has() returns true for existing header' );
    ok( $h->has( 'x-foo' ),   'has() is case-insensitive' );
    ok( !$h->has( 'X-None' ), 'has() returns false for missing header' );
};

subtest 'set replaces existing' => sub
{
    my $h = Mail::Make::Headers->new;
    $h->set( 'X-Val', 'first' );
    $h->set( 'X-Val', 'second' );
    is( $h->get( 'X-Val' ), 'second', 'set() replaces existing value' );
    # Count occurrences in as_string — should be only one
    my $s = $h->as_string;
    my $count = () = $s =~ /X-Val/gi;
    is( $count, 1, 'header appears exactly once after replacement' );
};

# NOTE: remove
subtest 'remove' => sub
{
    my $h = Mail::Make::Headers->new;
    $h->set( 'X-Remove', 'yes' );
    $h->remove( 'X-Remove' );
    ok( !$h->has( 'X-Remove' ), 'header removed successfully' );
    # Removing non-existent header is a no-op
    $h->remove( 'X-Never-Set' );
    pass( 'removing non-existent header does not croak' );
};

# NOTE: Injection prevention
subtest 'header injection: LF in value sanitised' => sub
{
    my $h  = Mail::Make::Headers->new;
    my $rv = $h->set( 'X-Inject', "value\nX-Evil: injected" );
    ok( defined( $rv ), 'LF in header value is sanitised, not rejected' );
    is( $h->header( 'X-Inject' ), 'value X-Evil: injected', 'LF replaced with space' );
};

subtest 'header injection: CR in value sanitised' => sub
{
    my $h  = Mail::Make::Headers->new;
    my $rv = $h->set( 'X-Inject', "value\rX-Evil: injected" );
    ok( defined( $rv ), 'CR in header value is sanitised, not rejected' );
    is( $h->header( 'X-Inject' ), 'value X-Evil: injected', 'CR replaced with space' );
};

subtest 'invalid field name: colon' => sub
{
    my $h  = Mail::Make::Headers->new;
    my $rv = $h->set( 'X-Bad:Name', 'value' );
    ok( !defined( $rv ), 'colon in field name rejected' );
    like( $h->error, qr/Invalid header field name/i, 'error mentions field name' );
};

subtest 'invalid field name: space' => sub
{
    my $h  = Mail::Make::Headers->new;
    my $rv = $h->set( 'X Bad', 'value' );
    ok( !defined( $rv ), 'space in field name rejected' );
};

# NOTE: Typed accessors
subtest 'content_type convenience accessor' => sub
{
    my $h = Mail::Make::Headers->new;
    $h->content_type( 'text/html; charset=utf-8' );
    is( $h->get( 'Content-Type' ), 'text/html; charset=utf-8', 'content_type stores correctly' );
    my $ct = $h->content_type;
    ok( defined( $ct ), 'content_type() getter returns typed object' );
    ok( $ct->isa( 'Mail::Make::Headers::ContentType' ), 'returned object is ContentType' );
};

subtest 'content_transfer_encoding: valid values' => sub
{
    my $h = Mail::Make::Headers->new;
    for my $enc ( qw( 7bit 8bit binary base64 quoted-printable ) )
    {
        my $rv = $h->content_transfer_encoding( $enc );
        ok( defined( $rv ), "encoding '$enc' accepted" );
        is( $h->get( 'Content-Transfer-Encoding' ), $enc, "encoding '$enc' stored correctly" );
    }
};

subtest 'content_transfer_encoding: mixed case normalised' => sub
{
    my $h = Mail::Make::Headers->new;
    $h->content_transfer_encoding( 'Base64' );
    is( $h->get( 'Content-Transfer-Encoding' ), 'base64', 'normalised to lowercase' );
};

subtest 'content_transfer_encoding: invalid value' => sub
{
    my $h  = Mail::Make::Headers->new;
    my $rv = $h->content_transfer_encoding( 'uuencode' );
    ok( !defined( $rv ), 'unknown encoding rejected' );
    like( $h->error, qr/Unknown Content-Transfer-Encoding/i, 'error mentions encoding name' );
};

subtest 'content_id normalises angle brackets' => sub
{
    my $h = Mail::Make::Headers->new;
    $h->content_id( 'part1@example.com' );
    is( $h->get( 'Content-ID' ), '<part1@example.com>', 'angle brackets added' );

    $h->content_id( '<already@bracketed.com>' );
    is( $h->get( 'Content-ID' ), '<already@bracketed.com>', 'existing brackets not doubled' );
};

subtest 'content_id rejects control characters' => sub
{
    my $h  = Mail::Make::Headers->new;
    my $rv = $h->content_id( "part1\x01bad\@example.com" );
    ok( !defined( $rv ), 'control character in Content-ID rejected' );
};

# NOTE: as_string
subtest 'as_string order preserved' => sub
{
    my $h = Mail::Make::Headers->new;
    $h->set( 'Content-Type',              'text/plain' );
    $h->set( 'Content-Transfer-Encoding', 'quoted-printable' );
    $h->set( 'Content-ID',               '<id@example.com>' );
    my $s = $h->as_string;
    my @lines = split( /\015?\012/, $s );
    is( $lines[0], 'Content-Type: text/plain',              'first header correct' );
    is( $lines[1], 'Content-Transfer-Encoding: quoted-printable', 'second header correct' );
    is( $lines[2], 'Content-ID: <id@example.com>',          'third header correct' );
};

subtest 'as_string uses CRLF by default' => sub
{
    my $h = Mail::Make::Headers->new;
    $h->set( 'X-Test', 'value' );
    my $s = $h->as_string;
    like( $s, qr/\015\012/, 'as_string uses CRLF' );
};

subtest 'as_string uses custom eol' => sub
{
    my $h = Mail::Make::Headers->new;
    $h->set( 'X-Test', 'value' );
    my $s = $h->as_string( "\n" );
    like( $s, qr/\n/, 'as_string uses provided LF' );
    unlike( $s, qr/\015/, 'no CR when LF requested' );
};

# NOTE: new_field factory
subtest 'new_field returns typed object for Content-Type' => sub
{
    my $h  = Mail::Make::Headers->new;
    my $ct = $h->new_field( 'Content-Type', 'image/png' );
    ok( defined( $ct ), 'new_field for Content-Type returns object' );
    ok( $ct->isa( 'Mail::Make::Headers::ContentType' ), 'correct class' );
    is( $ct->type, 'image/png', 'type set correctly' );
};

subtest 'new_field returns typed object for Content-Disposition' => sub
{
    my $h  = Mail::Make::Headers->new;
    my $cd = $h->new_field( 'Content-Disposition', 'inline' );
    ok( defined( $cd ), 'new_field for Content-Disposition returns object' );
    ok( $cd->isa( 'Mail::Make::Headers::ContentDisposition' ), 'correct class' );
};

done_testing();

__END__
