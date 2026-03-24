#!/usr/bin/perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG );
    use Test2::V0;
    use Module::Generic::File qw( file tempfile );
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;

use ok( 'HTTP::Promise::Parser' );
use ok( 'HTTP::Promise::Body::Form::Data' );
use ok( 'HTTP::Promise::Stream' );
use ok( 'HTTP::Promise::Entity' );

# NOTE: Parsing an existing multipart/form-data POST fixture
my $p = HTTP::Promise::Parser->new( debug => $DEBUG ) ||
    bail_out( HTTP::Promise::Parser->error );
my $ent = $p->parse( 't/testin/post-multipart-form-data-07.txt' );
isa_ok( $ent => ['HTTP::Promise::Entity'], 'parser returns an HTTP::Promise::Entity object' );
diag( "Parsing failed: ", $p->error ) if( $DEBUG && !defined( $ent ) );

SKIP:
{
    skip( 'parser failed', 4 ) if( !defined( $ent ) );
    $ent->debug( $DEBUG );
    is( $ent->headers->type, 'multipart/form-data', 'type is multipart/form-data' );
    is( $ent->parts->length, 4, 'number of parts' );
    my $form = $ent->as_form_data;
    isa_ok( $form => ['HTTP::Promise::Body::Form::Data'], 'as_form_data' );
    SKIP:
    {
        is( $form->size, 4, '4 fields found for form-data' );
        diag( "Fields set in \$form are: ", $form->keys->join( ', ' )->scalar ) if( $DEBUG );
        isa_ok( $form->{category}->body, ['HTTP::Promise::Body::Scalar'], 'field category body' );
        isa_ok( $form->{location}->body, ['HTTP::Promise::Body::Scalar'], 'field location body' );
        isa_ok( $form->{tengu}->body, ['HTTP::Promise::Body'], 'field tengu body' );
        isa_ok( $form->{oni}->body, ['HTTP::Promise::Body'], 'field oni body' );
        is( $form->{category}->name, 'category', 'field category name' );
        is( $form->{location}->name, 'location', 'field location name' );
        is( $form->{tengu}->name, 'tengu', 'field tengu name' );
        is( $form->{oni}->name, 'oni', 'field oni name' );
        is( $form->{category}->value, 'Folklore', 'field category body' );
        is( $form->{location}->value, 'Japan', 'field location body' );
        is( $form->{tengu}->body->length, 843, 'file #1 (Tengu) size' );
        is( $form->{oni}->body->length, 1017, 'file #2 (Oni) size' );
        is( $form->{tengu}->headers->content_type, 'image/png', 'file #1 (Tengu) mime-type' );
        is( $form->{oni}->headers->content_type, 'image/png', 'file #2 (Oni) mime-type' );
        is( $form->{tengu}->headers->content_encoding, 'base64', 'file #1 (Tengu) encoding' );
        is( $form->{oni}->headers->content_encoding, 'base64', 'file #2 (Oni) encoding' );
        my $res = $form->as_string( boundary => $ent->headers->boundary, fields => [qw( category location tengu oni )] );
        diag( "Error as_string: ", $form->error ) if( $DEBUG );
        diag( $res ) if( $DEBUG );
        is( $res, $ent->body_as_string, 'as_string round-trips correctly' );
    };
};

# NOTE: HTTP::Promise::Stream - mime2encoding()
subtest 'HTTP::Promise::Stream - mime2encoding()' => sub
{
    my $stream = HTTP::Promise::Stream->new( \'' ) ||
        bail_out( HTTP::Promise::Stream->error );

    # Known compression wrappers
    is( $stream->mime2encoding( 'application/gzip' ),   'gzip',   'mime2encoding: application/gzip -> gzip' );
    is( $stream->mime2encoding( 'application/x-gzip' ), 'gzip',   'mime2encoding: application/x-gzip -> gzip' );
    is( $stream->mime2encoding( 'application/x-bzip2' ),'bzip2',  'mime2encoding: application/x-bzip2 -> bzip2' );
    is( $stream->mime2encoding( 'application/x-xz' ),   'xz',     'mime2encoding: application/x-xz -> xz' );
    is( $stream->mime2encoding( 'application/zstd' ),   'zstd',   'mime2encoding: application/zstd -> zstd' );
    is( $stream->mime2encoding( 'application/x-compress' ), 'lzw','mime2encoding: application/x-compress -> lzw' );

    # Parameters in MIME string must be stripped
    is( $stream->mime2encoding( 'application/gzip; charset=binary' ), 'gzip',
        'mime2encoding strips ; parameters before lookup' );

    # Case-insensitive
    is( $stream->mime2encoding( 'Application/GZIP' ), 'gzip',
        'mime2encoding is case-insensitive' );

    # Unknown type returns undef, no error
    is( $stream->mime2encoding( 'image/png' ), undef,
        'mime2encoding returns undef for non-encoding MIME type' );
    is( $stream->mime2encoding( 'application/octet-stream' ), undef,
        'mime2encoding returns undef for application/octet-stream' );

    # Missing argument must return an error
    my $ret = $stream->mime2encoding( '' );
    ok( !defined( $ret ) && $stream->error, 'mime2encoding returns error on empty argument' );
};

# NOTE: HTTP::Promise::Stream - _encoding2suffix_map()
# Returns a *copy* - mutating it must not affect subsequent calls.
subtest 'HTTP::Promise::Stream - _encoding2suffix_map()' => sub
{
    my $stream = HTTP::Promise::Stream->new( \'' ) ||
        bail_out( HTTP::Promise::Stream->error );

    my $map1 = $stream->_encoding2suffix_map;
    ok( ref( $map1 ), 'HASH', '_encoding2suffix_map returns a hashref' );
    ok( exists( $map1->{gzip} ),  '_encoding2suffix_map contains gzip' );
    ok( exists( $map1->{bzip2} ), '_encoding2suffix_map contains bzip2' );
    ok( exists( $map1->{xz} ),    '_encoding2suffix_map contains xz' );
    ok( exists( $map1->{zstd} ),  '_encoding2suffix_map contains zstd' );

    # Verify it is a copy - poisoning it must not leak into the next call
    $map1->{__poison__} = 'test';
    my $map2 = $stream->_encoding2suffix_map;
    ok( !exists( $map2->{__poison__} ), '_encoding2suffix_map returns an independent copy' );
};

# NOTE: HTTP::Promise::Stream - suffix2encoding()
# Includes the .Z -> lzw alias added in v0.7.3.
subtest 'HTTP::Promise::Stream - suffix2encoding()' => sub
{
    my $stream = HTTP::Promise::Stream->new( \'' ) ||
        bail_out( HTTP::Promise::Stream->error );

    # Single encoding
    my $e = $stream->suffix2encoding( 'archive.gz' );
    is( $e->length, 1, 'suffix2encoding: archive.gz yields 1 encoding' );
    is( $e->[0], 'gzip', 'suffix2encoding: archive.gz -> gzip' );

    # .tar.gz - two extensions but only one is an encoding suffix (.gz),
    # .tar is the inner format and stops iteration
    $e = $stream->suffix2encoding( 'archive.tar.gz' );
    is( $e->length, 1, 'suffix2encoding: archive.tar.gz yields 1 encoding' );
    is( $e->[0], 'gzip', 'suffix2encoding: archive.tar.gz -> gzip' );

    # .tar.bz2
    $e = $stream->suffix2encoding( 'archive.tar.bz2' );
    is( $e->length, 1, 'suffix2encoding: archive.tar.bz2 yields 1 encoding' );
    is( $e->[0], 'bzip2', 'suffix2encoding: archive.tar.bz2 -> bzip2' );

    # .tar.xz
    $e = $stream->suffix2encoding( 'archive.tar.xz' );
    is( $e->length, 1, 'suffix2encoding: archive.tar.xz yields 1 encoding' );
    is( $e->[0], 'xz', 'suffix2encoding: archive.tar.xz -> xz' );

    # .tar.zst
    $e = $stream->suffix2encoding( 'archive.tar.zst' );
    is( $e->length, 1, 'suffix2encoding: archive.tar.zst yields 1 encoding' );
    is( $e->[0], 'zstd', 'suffix2encoding: archive.tar.zst -> zstd' );

    # Legacy Unix .Z (LZW) - alias added in v0.7.3
    $e = $stream->suffix2encoding( 'archive.Z' );
    is( $e->length, 1, 'suffix2encoding: archive.Z yields 1 encoding' );
    is( $e->[0], 'lzw', 'suffix2encoding: archive.Z -> lzw' );

    # Multiple stacked encoding suffixes (e.g. .gz.b64)
    $e = $stream->suffix2encoding( 'archive.tar.gz.b64' );
    is( $e->length, 2, 'suffix2encoding: archive.tar.gz.b64 yields 2 encodings' );
    is( $e->[0], 'gzip',   'suffix2encoding: inner encoding is gzip' );
    is( $e->[1], 'base64', 'suffix2encoding: outer encoding is base64' );

    # No known encoding suffix
    $e = $stream->suffix2encoding( 'document.pdf' );
    is( $e->length, 0, 'suffix2encoding: document.pdf yields 0 encodings' );
};

# NOTE: make_parts() - Content-Type / Content-Encoding split for
# compressed tar archives passed as Module::Generic::File objects.
# We create a temporary .tar.gz file so Module::Generic::File can detect it.
subtest 'make_parts()' => sub
{
    # Helper: build a tiny but valid .tar.gz in memory and write it to a
    # temp file so that libmagic can fingerprint it correctly.

    # A real .tar.gz would be ideal, but for unit-testing purposes a file
    # whose magic bytes satisfy libmagic is sufficient. We write the gzip
    # magic header (1f 8b) followed by valid gzip-compressed content.
    # NOTE: gzip
    SKIP:
    {
        local $@;
        eval{ require IO::Compress::Gzip; };
        if( $@ )
        {
            skip( "IO::Compress::Gzip is missing", 1 );
        }

        my $make_tar_gz = sub
        {
            my $fname = tempfile( suffix => '.tar.gz', cleanup => 1, open => 1 );
            $fname->binmode;
            my $fh = $fname->handle;
            # Compress a minimal tar-like payload (content does not need to be
            # a fully valid tar for MIME detection - the gzip wrapper is what
            # libmagic inspects first).
            my $payload = "test payload\n";
            IO::Compress::Gzip::gzip( \$payload, $fh ) or
                die( "gzip failed: $IO::Compress::Gzip::GzipError" );
            close( $fh );
            return( $fname );
        };
    
        my $tar_gz_path;
        eval { $tar_gz_path = $make_tar_gz->() };
        skip( "Could not create temp .tar.gz: $@", 12 ) if( $@ );
    
        my $file = Module::Generic::File->new( $tar_gz_path );
        skip( 'Module::Generic::File->new failed', 12 ) unless( defined( $file ) );
    
        my $form = HTTP::Promise::Body::Form::Data->new({
            upload => $file,
        }) || bail_out( HTTP::Promise::Body::Form::Data->error );
    
        my $parts = $form->make_parts;
        ok( defined( $parts ), 'make_parts returns a value for .tar.gz file field' ) ||
            skip( 'make_parts failed: ' . ( $form->error // '' ), 11 );
        is( $parts->length, 1, 'make_parts yields exactly 1 part' );
    
        my $part = $parts->[0];
        isa_ok( $part, ['HTTP::Promise::Entity'], 'part is an HTTP::Promise::Entity' );
    
        my $ct = $part->headers->content_type;
        my $ce = $part->headers->content_encoding;
    
        diag( "Content-Type: $ct" ) if( $DEBUG );
        diag( "Content-Encoding: ", ( $ce // 'undef' ) ) if( $DEBUG );
    
        is( $ct, 'application/x-tar',
            'make_parts: .tar.gz -> Content-Type: application/x-tar' );
        is( $ce, 'gzip',
            'make_parts: .tar.gz -> Content-Encoding: gzip' );
    
        # Content-Disposition must carry the original filename
        my $cd = $part->headers->content_disposition;
        like( $cd, qr/\.tar\.gz/, 'Content-Disposition includes .tar.gz filename' );
    };

    # NOTE: bzip2
    SKIP:
    {
        local $@;
        eval{ require IO::Compress::Bzip2; };
        if( $@ )
        {
            skip( "IO::Compress::Bzip2 is missing", 1 );
        }

        # NOTE: Same test for .tar.bz2
        my $make_tar_bz2 = sub
        {
            require IO::Compress::Bzip2;
            my( $fh2, $fname2 ) = File::Temp::tempfile(
                'test_XXXXXXXX',
                SUFFIX => '.tar.bz2',
                UNLINK => 1,
            );
            binmode( $fh2 );
            my $payload2 = "test payload bz2\n";
            IO::Compress::Bzip2::bzip2( \$payload2, $fh2 )
                or die( "bzip2 failed: $IO::Compress::Bzip2::Bzip2Error" );
            close( $fh2 );
            return( $fname2 );
        };

        my $tar_bz2_path;
        eval{ $tar_bz2_path = $make_tar_bz2->() };

        skip( "Could not create temp .tar.bz2: $@", 5 ) if( $@ );
        my $file2 = Module::Generic::File->new( $tar_bz2_path );
        skip( 'Module::Generic::File->new for .tar.bz2 failed', 5 ) unless( defined( $file2 ) );

        my $form2 = HTTP::Promise::Body::Form::Data->new({ upload => $file2 }) ||
            skip( 'Form::Data->new for .tar.bz2 failed', 5 );
        my $parts2 = $form2->make_parts;
        ok( defined( $parts2 ), 'make_parts returns a value for .tar.bz2 file field' )
            || skip( 'make_parts failed for .tar.bz2', 4 );

        my $part2 = $parts2->[0];
        my $ct2 = $part2->headers->content_type;
        my $ce2 = $part2->headers->content_encoding;

        is( $ct2, 'application/x-tar',
            'make_parts: .tar.bz2 -> Content-Type: application/x-tar' );
        is( $ce2, 'bzip2',
            'make_parts: .tar.bz2 -> Content-Encoding: bzip2' );
    };

    # NOTE: Plain .gz (not a tar) - must NOT get application/x-tar
    SKIP:
    {
        my $make_gz = sub
        {
            require IO::Compress::Gzip;
            my( $fh3, $fname3 ) = File::Temp::tempfile(
                'test_XXXXXXXX',
                SUFFIX => '.gz',
                UNLINK => 1,
            );
            binmode( $fh3 );
            my $payload3 = "plain gzip content\n";
            IO::Compress::Gzip::gzip( \$payload3, $fh3 )
                or die( "gzip failed: $IO::Compress::Gzip::GzipError" );
            close( $fh3 );
            return( $fname3 );
        };

        my $gz_path;
        eval { $gz_path = $make_gz->() };
        skip( "Could not create temp .gz: $@", 3 ) if( $@ );
        my $file3 = Module::Generic::File->new( $gz_path );
        skip( 'Module::Generic::File->new for .gz failed', 3 ) unless( defined( $file3 ) );

        my $form3 = HTTP::Promise::Body::Form::Data->new({ upload => $file3 }) ||
            skip( 'Form::Data->new for plain .gz failed', 3 );
        my $parts3 = $form3->make_parts;
        ok( defined( $parts3 ), 'make_parts returns a value for plain .gz file field' )
            || skip( 'make_parts failed for plain .gz', 2 );

        my $part3  = $parts3->[0];
        my $ct3    = $part3->headers->content_type;

        isnt( $ct3, 'application/x-tar',
            'make_parts: plain .gz does NOT get Content-Type: application/x-tar' );
        is( $ct3, 'application/gzip',
            'make_parts: plain .gz -> Content-Type: application/gzip' );
    };
};

done_testing();

__END__
