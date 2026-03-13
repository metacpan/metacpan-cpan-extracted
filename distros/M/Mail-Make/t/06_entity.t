#!/usr/local/bin/perl
##----------------------------------------------------------------------------
## Mail Builder - t/06_entity.t
## Test suite for Mail::Make::Entity
##----------------------------------------------------------------------------
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG );
    use Test::More;
    use Module::Generic::File qw( tempfile );
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;

BEGIN
{
    use ok( 'Mail::Make::Entity' );
};

# NOTE: build(): basic single-part entities
subtest 'build: text/plain with data' => sub
{
    my $e = Mail::Make::Entity->build(
        type    => 'text/plain',
        charset => 'utf-8',
        data    => "Hello!\n",
    );
    ok( defined( $e ), 'build() returns entity' );
    is( $e->mime_type,     'text/plain', 'mime_type correct' );
    is( $e->effective_type,'text/plain', 'effective_type correct' );
    my $h = $e->headers;
    like( $h->get( 'Content-Type' ), qr{text/plain}, 'Content-Type set' );
    like( $h->get( 'Content-Type' ), qr{charset},    'charset in Content-Type' );
    is(   $h->get( 'Content-Transfer-Encoding' ), 'quoted-printable',
          'QP encoding auto-selected for text/*' );
};

subtest 'build: image/png with path' => sub
{
    # Create a temp file to use as path
    my $path = tempfile( cleanup => 1, open => 1 );
    diag( "tempfile() returned $path" );
    $path->print( "PNG\x89" );
    $path->close;

    my $e = Mail::Make::Entity->build(
        type        => 'image/png',
        disposition => 'inline',
        path        => $path,
        id          => 'logo@example.com',
    );
    diag( Mail::Make::Entity->error ) if( !defined( $e ) && Mail::Make::Entity->error );
    ok( defined( $e ), 'build() returns entity for image/png' );
    is( $e->mime_type, 'image/png', 'mime_type correct' );
    my $h = $e->headers;
    is( $h->get( 'Content-Transfer-Encoding' ), 'base64',
        'base64 encoding auto-selected for image/*' );
    is( $h->get( 'Content-ID' ), '<logo@example.com>',
        'Content-ID set with angle brackets' );
    like( $h->get( 'Content-Disposition' ), qr/inline/, 'disposition is inline' );
};

# NOTE: build(): filename handling - the core fix
subtest 'build: plain ASCII filename' => sub
{
    my $path = tempfile( cleanup => 1, open => 1 );
    $path->close;

    my $e = Mail::Make::Entity->build(
        type        => 'image/png',
        path        => $path,
        filename    => 'logo.png',
        disposition => 'attachment',
    );
    ok( defined( $e ), 'build with plain ASCII filename succeeds' );
    my $cd = $e->headers->get( 'Content-Disposition' );
    like( $cd, qr/filename="logo\.png"/, 'plain filename quoted correctly' );
};

subtest 'build: filename with comma uses RFC 2231' => sub
{
    my $path = tempfile( cleanup => 1, open => 1 );
    $path->close;

    my $e = Mail::Make::Entity->build(
        type        => 'image/png',
        path        => $path,
        filename    => 'Yamato,Inc-Logo.png',
        disposition => 'attachment',
    );
    ok( defined( $e ), 'build with comma filename succeeds' );
    my $cd = $e->headers->get( 'Content-Disposition' );
    unlike( $cd, qr/filename="Yamato,Inc/, 'comma not left bare' );
    like(   $cd, qr/filename\*=/,          'RFC 2231 filename* used' );
    like(   $cd, qr/%2C/i,                 'comma percent-encoded' );
};

subtest 'build: filename derived from path' => sub
{
    my $path = tempfile( cleanup => 1, open => 1 );
    my $e = Mail::Make::Entity->build(
        type        => 'image/png',
        path        => $path,
        disposition => 'attachment',
    );
    diag( "Error instantiating Mail::Make::Entity: ", Mail::Make::Entity->error ) if( !defined( $e ) && Mail::Make::Entity->error );
    ok( defined( $e ), 'build without explicit filename succeeds' );
    my $cd = $e->headers->get( 'Content-Disposition' );
    # Filename should contain the basename portion
    like( $cd, qr/filename/, 'filename parameter present' );
};

# NOTE: build(): validation errors
subtest 'build: data + path mutually exclusive' => sub
{
    my $path = tempfile( cleanup => 1 );
    my $e = Mail::Make::Entity->build(
        type => 'text/plain',
        data => "text",
        path => $path,
    );
    ok( !defined( $e ), 'build() rejects data + path together' );
    like( Mail::Make::Entity->error, qr/mutually exclusive/i, 'error mentions mutually exclusive' );
};

subtest 'build: encoding not allowed for multipart' => sub
{
    my $e = Mail::Make::Entity->build(
        type     => 'multipart/mixed',
        encoding => 'base64',
        ( $DEBUG ? ( debug => $DEBUG ) : () ),
    );
    # The original test expected a failure, because one cannot specify an encoding when multipart, but the Mail::Make::Entity class silently removes the encoding if this is a multipart...
    ok( !defined( $e ), 'build() rejects encoding for multipart' );
    like( Mail::Make::Entity->error, qr/not permitted/i, 'error mentions not permitted' );
};

subtest 'build: unknown encoding rejected' => sub
{
    my $e = Mail::Make::Entity->build(
        type     => 'text/plain',
        encoding => 'uuencode',
        data     => "x",
    );
    ok( !defined( $e ), 'build() rejects unknown encoding' );
    like( Mail::Make::Entity->error, qr/unknown/i, 'error mentions unknown' );
};

subtest 'build: invalid disposition rejected' => sub
{
    my $e = Mail::Make::Entity->build(
        type        => 'text/plain',
        disposition => 'bogus',
        data        => "x",
    );
    ok( !defined( $e ), 'build() rejects invalid disposition' );
    like( Mail::Make::Entity->error, qr/invalid disposition/i, 'error mentions invalid disposition' );
};

subtest 'build: invalid boundary rejected' => sub
{
    my $e = Mail::Make::Entity->build(
        type     => 'multipart/mixed',
        boundary => "bad\x00boundary",
    );
    ok( !defined( $e ), 'build() rejects boundary with NUL' );
};

# NOTE: multipart entity
subtest 'multipart: add_part and serialisation' => sub
{
    my $top = Mail::Make::Entity->build( type => 'multipart/mixed' );
    ok( defined( $top ), 'multipart entity created' );
    ok( $top->is_multipart, 'is_multipart is true' );

    my $child = Mail::Make::Entity->build(
        type => 'text/plain',
        data => "child part",
    );
    ok( defined( $child ), 'child part created' );
    $top->add_part( $child );
    is( scalar( @{ $top->parts } ), 1, 'one part added' );

    my $s = $top->as_string;
    if( !ok( defined( $s ), 'as_string' ) )
    {
        diag( $top->error ) if( $top->error );
    }
    ok( !ref( $s ), 'as_string returns a plain string' );
    like( $s, qr/Content-Type: multipart\/mixed/, 'multipart Content-Type present' );
    like( $s, qr/--/, 'boundary markers present' );
    like( $s, qr/child part/, 'child part content present' );

    my $s2 = $top->as_string_ref;
    if( !ok( defined( $s2 ), 'as_string' ) )
    {
        diag( $top->error ) if( $top->error );
    }
    SKIP:
    {
        if( !ok( ref( $s2 ) eq 'SCALAR', 'as_string returns scalar ref' ) )
        {
            skip( "as_string_ref() did not return a scalar reference.", 1 );
        }
        like( $$s2, qr/Content-Type: multipart\/mixed/, 'multipart Content-Type present' );
        like( $$s2, qr/--/, 'boundary markers present' );
        like( $$s2, qr/child part/, 'child part content present' );
    };
};

subtest 'multipart: add_part rejects non-entity' => sub
{
    my $top = Mail::Make::Entity->build( type => 'multipart/mixed' );
    my $rv  = $top->add_part( "not an entity" );
    ok( !defined( $rv ), 'add_part() rejects non-entity' );
    like( $top->error, qr/argument must be a Mail::Make::Entity/i, 'error message correct' );
};

# NOTE: as_string: single-part encoding applied
subtest 'as_string: base64 encoding applied for image' => sub
{
    my $path = tempfile( cleanup => 1, open => 1 );
    $path->binmode;
    $path->print( "\x89PNG\r\n\x1a\n" );  # PNG magic bytes
    $path->close;

    my $e = Mail::Make::Entity->build(
        type => 'image/png',
        path => $path,
    );
    my $s = $e->as_string;
    ok( defined( $s ), 'as_string succeeds' );
    # Base64 output should only contain valid base64 chars
    my( $headers, $body ) = split( /\015\012\015\012/, $s, 2 );
    $body =~ s/\015?\012//g;
    like( $body, qr{^[A-Za-z0-9+/=]+$}, 'body is valid base64' );
};

subtest 'as_string: quoted-printable for text/html' => sub
{
    my $e = Mail::Make::Entity->build(
        type    => 'text/html',
        charset => 'utf-8',
        data    => "<html><body>Test</body></html>\n",
    );
    my $s = $e->as_string;
    ok( defined( $s ), 'as_string succeeds' );
    like( $s, qr/Content-Transfer-Encoding: quoted-printable/, 'QP encoding in headers' );
};

# NOTE: make_multipart
subtest 'make_multipart promotes single-part' => sub
{
    my $e = Mail::Make::Entity->build(
        type => 'text/plain',
        data => "original",
    );
    ok( !$e->is_multipart, 'starts as single-part' );
    $e->make_multipart( 'mixed' );
    ok(  $e->is_multipart, 'becomes multipart after make_multipart()' );
    like( $e->effective_type, qr{multipart/mixed}, 'effective_type updated' );
    is( scalar( @{ $e->parts } ), 1, 'original body wrapped as child part' );
};

subtest 'make_multipart is idempotent' => sub
{
    my $e = Mail::Make::Entity->build( type => 'multipart/mixed' );
    $e->make_multipart( 'mixed' );
    ok( $e->is_multipart, 'still multipart after second make_multipart() call' );
};

# NOTE: purge
subtest 'purge clears body' => sub
{
    my $e = Mail::Make::Entity->build(
        type => 'text/plain',
        data => "some content",
    );
    ok( defined( $e->body ), 'body present before purge' );
    $e->purge;
    ok( !defined( $e->body ), 'body cleared after purge' );
};

done_testing();

__END__
