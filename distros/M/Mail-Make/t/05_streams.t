#!/usr/local/bin/perl
##----------------------------------------------------------------------------
## Mail Builder - t/05_streams.t
## Test suite for Mail::Make::Stream::Base64 and Mail::Make::Stream::QuotedPrint
##----------------------------------------------------------------------------
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG );
    use Scalar::Util qw( blessed );
    use Test::More;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;

BEGIN
{
    use ok( 'Mail::Make::Body' );
    use ok( 'Mail::Make::Body::InCore' );
    use ok( 'Mail::Make::Stream::Base64' );
    use ok( 'Mail::Make::Stream::QuotedPrint' );
};

# NOTE: Helpers

# encode $from (scalar ref or Body object) to a scalar buffer, return scalar ref to the result.
sub b64_encode
{
    my( $b64, $from, %opts ) = @_;
    my $fh = ref( $from ) && blessed( $from ) && $from->isa( 'Mail::Make::Body' )
        ? $from->open
        : $from;
    my $out = '';
    $b64->encode( $fh => \$out, %opts ) || return( undef );
    return( \$out );
}

sub b64_decode
{
    my( $b64, $from_ref ) = @_;
    my $out = '';
    $b64->decode( $from_ref => \$out ) || return( undef );
    return( \$out );
}

sub qp_encode
{
    my( $qp, $from, %opts ) = @_;
    my $fh = ref( $from ) && blessed( $from ) && $from->isa( 'Mail::Make::Body' )
        ? $from->open
        : $from;
    my $out = '';
    $qp->encode( $fh => \$out, %opts ) || return( undef );
    return( \$out );
}

sub qp_decode
{
    my( $qp, $from_ref ) = @_;
    my $out = '';
    $qp->decode( $from_ref => \$out ) || return( undef );
    return( \$out );
}

# NOTE: Mail::Make::Stream::Base64
subtest 'Base64: encode/decode round-trip ASCII' => sub
{
    my $b64  = Mail::Make::Stream::Base64->new;
    my $body = Mail::Make::Body::InCore->new( "Hello, world!" );
    my $enc  = b64_encode( $b64, $body );
    diag( $b64->error ) if( !defined( $enc ) && $b64->error );
    ok( defined( $enc ) && ref( $enc ) eq 'SCALAR', 'encode returns scalar ref' );
    my $dec  = b64_decode( $b64, $enc );
    diag( $b64->error ) if( !defined( $dec ) && $b64->error );
    ok( defined( $dec ) && ref( $dec ) eq 'SCALAR', 'decode returns scalar ref' );
    is( $$dec, "Hello, world!", 'round-trip content matches' );
};

subtest 'Base64: encode/decode round-trip binary' => sub
{
    my $b64    = Mail::Make::Stream::Base64->new;
    my $binary = join( '', map { chr( $_ ) } 0..255 );
    my $body   = Mail::Make::Body::InCore->new( $binary );
    my $enc    = b64_encode( $b64, $body );
    diag( $b64->error ) if( !defined( $enc ) && $b64->error );
    my $dec    = b64_decode( $b64, $enc );
    diag( $b64->error ) if( !defined( $dec ) && $b64->error );
    is( $$dec, $binary, 'binary round-trip correct (all 256 byte values)' );
};

subtest 'Base64: lines not longer than 76 chars' => sub
{
    my $b64  = Mail::Make::Stream::Base64->new;
    my $data = 'A' x 1000;
    my $body = Mail::Make::Body::InCore->new( $data );
    my $enc  = b64_encode( $b64, $body );
    diag( $b64->error ) if( !defined( $enc ) && $b64->error );
    for my $line ( split( /\015?\012/, $$enc ) )
    {
        ok( length( $line ) <= 76, "line length " . length( $line ) . " <= 76" )
            if( length( $line ) );
    }
};

subtest 'Base64: encoded output uses CRLF line endings' => sub
{
    my $b64  = Mail::Make::Stream::Base64->new;
    my $body = Mail::Make::Body::InCore->new( "test" );
    my $enc  = b64_encode( $b64, $body );
    diag( $b64->error ) if( !defined( $enc ) && $b64->error );
    like( $$enc, qr/\015\012/, 'encoded output contains CRLF' );
};

subtest 'Base64: encode a plain scalar ref directly' => sub
{
    my $b64 = Mail::Make::Stream::Base64->new;
    my $raw = "Direct scalar";
    my $enc = b64_encode( $b64, \$raw );
    diag( $b64->error ) if( !defined( $enc ) && $b64->error );
    my $dec = b64_decode( $b64, $enc );
    diag( $b64->error ) if( !defined( $dec ) && $b64->error );
    is( $$dec, $raw, 'plain scalar ref input round-trips' );
};

subtest 'Base64: exportable encode_b64 / decode_b64 functions' => sub
{
    use Mail::Make::Stream::Base64 qw( encode_b64 decode_b64 );
    my $raw = "exported function test";
    my $enc = '';
    encode_b64( \$raw => \$enc ) || ok( 0, "encode_b64() failed: $Mail::Make::Stream::Base64::Base64Error" );
    ok( length( $enc ), 'encode_b64() produces output' );
    my $dec = '';
    decode_b64( \$enc => \$dec ) || ok( 0, "decode_b64() failed: $Mail::Make::Stream::Base64::Base64Error" );
    is( $dec, $raw, 'exported decode_b64() round-trips' );
};

# NOTE: Mail::Make::Stream::QuotedPrint
subtest 'QuotedPrint: encode/decode round-trip ASCII' => sub
{
    my $qp   = Mail::Make::Stream::QuotedPrint->new;
    my $body = Mail::Make::Body::InCore->new( "Hello, world!\n" );
    my $enc  = qp_encode( $qp, $body );
    diag( $qp->error ) if( !defined( $enc ) && $qp->error );
    ok( defined( $enc ) && ref( $enc ) eq 'SCALAR', 'encode returns scalar ref' );
    my $dec  = qp_decode( $qp, $enc );
    diag( $qp->error ) if( !defined( $dec ) && $qp->error );
    ok( defined( $dec ) && ref( $dec ) eq 'SCALAR', 'decode returns scalar ref' );
    is( $$dec, "Hello, world!\n", 'round-trip content matches' );
};

subtest 'QuotedPrint: non-ASCII characters encoded' => sub
{
    use Encode;
    my $qp   = Mail::Make::Stream::QuotedPrint->new;
    my $text = Encode::encode( 'utf-8', "Caf\x{E9}" );  # Café in UTF-8
    my $body = Mail::Make::Body::InCore->new( $text );
    my $enc  = qp_encode( $qp, $body );
    diag( $qp->error ) if( !defined( $enc ) && $qp->error );
    like( $$enc, qr/=/, 'encoded output contains = escapes for non-ASCII' );
    my $dec  = qp_decode( $qp, $enc );
    diag( $qp->error ) if( !defined( $dec ) && $qp->error );
    is( $$dec, $text, 'round-trip restores original UTF-8 bytes' );
};

subtest 'QuotedPrint: pure ASCII is unchanged' => sub
{
    my $qp   = Mail::Make::Stream::QuotedPrint->new;
    my $text = "Plain ASCII text. No escapes needed.\n";
    my $body = Mail::Make::Body::InCore->new( $text );
    my $enc  = qp_encode( $qp, $body );
    diag( $qp->error ) if( !defined( $enc ) && $qp->error );
    my $dec  = qp_decode( $qp, $enc );
    diag( $qp->error ) if( !defined( $dec ) && $qp->error );
    is( $$dec, $text, 'pure ASCII round-trips correctly' );
};

subtest 'QuotedPrint: encode accepts scalar ref directly' => sub
{
    my $qp  = Mail::Make::Stream::QuotedPrint->new;
    my $raw = "test scalar ref\n";
    my $enc = qp_encode( $qp, \$raw );
    diag( $qp->error ) if( !defined( $enc ) && $qp->error );
    my $dec = qp_decode( $qp, $enc );
    diag( $qp->error ) if( !defined( $dec ) && $qp->error );
    is( $$dec, $raw, 'scalar ref input round-trips' );
};

subtest 'QuotedPrint: exportable encode_qp / decode_qp functions' => sub
{
    use Mail::Make::Stream::QuotedPrint qw( encode_qp decode_qp );
    my $raw = "exported QP test\n";
    my $enc = '';
    encode_qp( \$raw => \$enc ) || ok( 0, "encode_qp() failed: $Mail::Make::Stream::QuotedPrint::QuotedPrintError" );
    ok( length( $enc ), 'encode_qp() produces output' );
    my $dec = '';
    decode_qp( \$enc => \$dec ) || ok( 0, "decode_qp() failed: $Mail::Make::Stream::QuotedPrint::QuotedPrintError" );
    is( $dec, $raw, 'exported decode_qp() round-trips' );
};

subtest 'QuotedPrint: custom eol option' => sub
{
    my $qp   = Mail::Make::Stream::QuotedPrint->new;
    my $body = Mail::Make::Body::InCore->new( "line one\nline two\n" );
    my $enc  = qp_encode( $qp, $body, eol => "\015\012" );
    diag( $qp->error ) if( !defined( $enc ) && $qp->error );
    ok( defined( $enc ), 'encode with explicit CRLF eol succeeds' );
};

done_testing();

__END__
