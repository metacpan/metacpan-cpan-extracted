#!/usr/local/bin/perl
##----------------------------------------------------------------------------
## Mail Builder - t/04_body.t
## Test suite for Mail::Make::Body::InCore and Mail::Make::Body::File
##----------------------------------------------------------------------------
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG );
    use Test::More;
    use Encode;
    use Module::Generic::File qw( tempfile );
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;

BEGIN
{
    use ok( 'Mail::Make::Body' );
    use ok( 'Mail::Make::Body::File' );
    use ok( 'Mail::Make::Body::InCore' );
};

# NOTE: Mail::Make::Body::InCore
subtest 'InCore: construction with scalar' => sub
{
    my $b = Mail::Make::Body::InCore->new( "Hello, world!" );
    ok( defined( $b ), 'new() with scalar returns object' );
    my $ref = $b->as_string;
    ok( ref( $ref ) eq 'SCALAR', 'as_string returns scalar ref' );
    is( $$ref, "Hello, world!", 'content correct' );
};

subtest 'InCore: construction with scalar ref' => sub
{
    my $data = "Binary\x00Data";
    my $b    = Mail::Make::Body::InCore->new( \$data );
    ok( defined( $b ), 'new() with scalar ref returns object' );
    is( ${ $b->as_string }, $data, 'content correct including NUL byte' );
};

subtest 'InCore: construction empty' => sub
{
    my $b = Mail::Make::Body::InCore->new;
    ok( defined( $b ), 'new() with no args returns object' );
    is( ${ $b->as_string }, '', 'empty content returned' );
};

subtest 'InCore: construction with invalid ref type' => sub
{
    my $b = Mail::Make::Body::InCore->new( [1,2,3] );
    ok( !defined( $b ), 'array ref rejected' );
};

subtest 'InCore: length' => sub
{
    my $b = Mail::Make::Body::InCore->new( "Hello" );
    is( $b->length, 5, 'length() returns byte count' );

    # Multi-byte UTF-8
    my $jp = "\x{3053}\x{3093}\x{306B}\x{3061}\x{306F}";  # こんにちは
    my $bytes = Encode::encode( 'utf-8', $jp );
    my $b2    = Mail::Make::Body::InCore->new( $bytes );
    is( $b2->length, length( $bytes ), 'length() returns byte count for UTF-8' );
};

subtest 'InCore: set()' => sub
{
    my $b = Mail::Make::Body::InCore->new( "original" );
    $b->set( "replaced" );
    is( ${ $b->as_string }, "replaced", 'set() replaces content' );
};

subtest 'InCore: purge()' => sub
{
    my $b = Mail::Make::Body::InCore->new( "data" );
    $b->purge;
    is( ${ $b->as_string }, '', 'purge() empties content' );
};

subtest 'InCore: is_in_core / is_on_file flags' => sub
{
    my $b = Mail::Make::Body::InCore->new( "x" );
    ok(  $b->is_in_core, 'is_in_core is true' );
    ok( !$b->is_on_file, 'is_on_file is false' );
};

# NOTE: Mail::Make::Body::File
subtest 'File: construction with valid path' => sub
{
    my $path = tempfile( cleanup => 1, open => 1 );
    $path->print( "file content" );
    $path->close;

    my $b = Mail::Make::Body::File->new( $path );
    ok( defined( $b ), 'new() with valid path returns object' );
    is( $b->path, $path, 'path() getter returns correct path' );
};

subtest 'File: as_string reads file' => sub
{
    my $path = tempfile( cleanup => 1, open => 1 );
    $path->print( "file data" );
    $path->close;

    my $b   = Mail::Make::Body::File->new( $path );
    my $ref = $b->as_string;
    ok( ref( $ref ) eq 'SCALAR', 'as_string returns scalar ref' );
    is( $$ref, "file data", 'content matches file content' );
};

subtest 'File: binary content preserved' => sub
{
    my $path = tempfile( cleanup => 1, open => 1 );
    $path->binmode;
    my $binary = join( '', map { chr( $_ ) } 0..255 );
    $path->print( $binary );
    $path->close;

    my $b   = Mail::Make::Body::File->new( $path );
    my $ref = $b->as_string;
    is( $$ref, $binary, 'binary content round-trips correctly' );
};

subtest 'File: nonexistent path rejected' => sub
{
    my $b = Mail::Make::Body::File->new( '/no/such/file/ever.bin' );
    ok( !defined( $b ), 'nonexistent path rejected' );
    like( Mail::Make::Body::File->error, qr/does not exist/i, 'error mentions does not exist' );
};

subtest 'File: path() setter validates' => sub
{
    my $path = tempfile( cleanup => 1, open => 1 );
    my $b  = Mail::Make::Body::File->new( $path );
    diag( Mail::Make::Body::File->error ) if( !defined( $b ) && Mail::Make::Body::File->error );
    my $rv = $b->path( '/no/such/path.bin' );
    ok( !defined( $rv ), 'path() setter rejects nonexistent path' );
};

subtest 'File: is_in_core / is_on_file flags' => sub
{
    my $path = tempfile( cleanup => 1, open => 1 );
    my $b = Mail::Make::Body::File->new( $path );
    ok( !$b->is_in_core, 'is_in_core is false' );
    ok(  $b->is_on_file, 'is_on_file is true' );
};

subtest 'File: length' => sub
{
    my $path = tempfile( cleanup => 1, open => 1 );
    $path->print( "12345" );
    $path->close;
    my $b = Mail::Make::Body::File->new( $path );
    is( $b->length, 5, 'length() returns correct byte count' );
};

done_testing();

__END__
