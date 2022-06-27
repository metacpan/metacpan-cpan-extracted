#!/usr/local/bin/perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG );
    use Test2::V0;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;

BEGIN
{
    use ok( 'HTTP::Promise::Stream' );
};

subtest "suffix" => sub
{
    my @s2e_tests = (
        [ 'file.bz2.b64' => [qw( bzip2 base64 )] ],
        [ 'file.br' => [qw( brotli )] ],
        [ 'file.zz' => [qw( deflate )] ],
        [ '/some/where/file.tar.gz' => [qw( gzip )] ],
        [ 'file.lzf' => [qw( lzf )] ],
        [ 'file.lz' => [qw( lzip )] ],
        [ 'file.lzma' => [qw( lzma )] ],
        [ 'file.lzop' => [qw( lzop )] ],
        [ 'file.lzw' => [qw( lzw )] ],
        [ 'file.qp' => [qw( qp )] ],
        [ 'file.rzz' => [qw( rawdeflate )] ],
        [ 'file.uu' => [qw( uu )] ],
        [ 'file.xz' => [qw( xz )] ],
        [ 'file.zip' => [qw( zip )] ],
        [ 'file.zstd' => [qw( zstd )] ],
        [ 'file.unknown' => [] ],
    );
    my $s = HTTP::Promise::Stream->new( \'', { debug => $DEBUG } );
    foreach( @s2e_tests )
    {
        my( $file, $expected ) = @$_;
        # my $res = HTTP::Promise::Stream->suffix2encoding( $file );
        my $res = $s->suffix2encoding( $file );
        is( "@$res", "@$expected", $file );
    }

    my @e2s_tests = (
        [ [qw( bzip2 base64 )] => [qw( bz2 b64 )] ],
        [ [qw( brotli )] => [qw( br )] ],
        [ [qw( deflate )] => [qw( zz )] ],
        [ [qw( gzip )] => [qw( gz )] ],
        [ [qw( lzf )] => [qw( lzf )] ],
        [ [qw( lzip )] => [qw( lz )] ],
        [ [qw( lzma )] => [qw( lzma )] ],
        [ [qw( lzop )] => [qw( lzop )] ],
        [ [qw( lzw )] => [qw( lzw )] ],
        [ [qw( qp )] => [qw( qp )] ],
        [ [qw( rawdeflate )] => [qw( rzz )] ],
        [ [qw( uu )] => [qw( uu )] ],
        [ [qw( xz )] => [qw( xz )] ],
        [ [qw( zip )] => [qw( zip )] ],
        [ [qw( zstd )] => [qw( zstd )] ],
        [ [qw( unknown )] => undef ],
    );
    foreach( @e2s_tests )
    {
        my( $enc, $expected ) = @$_;
        # my $res = HTTP::Promise::Stream->suffix2encoding( $file );
        my $res = $s->encoding2suffix( $enc );
        if( $enc->[0] eq 'unknown' )
        {
            is( $res, undef, join( ',', @$enc ) );
        }
        else
        {
            is( "@$res", "@$expected", join( ',', @$enc ) );
        }
    }
};

done_testing();

__END__

