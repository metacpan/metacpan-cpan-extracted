#!/usr/local/bin/perl
##----------------------------------------------------------------------------
## Mail Builder - t/08_headers_subject.t
## Test suite for Mail::Make::Headers::Subject (RFC 2047 encoding)
##----------------------------------------------------------------------------
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG );
    use Test::More;
    use Encode ();
    use MIME::Base64 ();
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;

BEGIN
{
    use ok( 'Mail::Make::Headers::Subject' );
};

# NOTE: Helper: decode an RFC 2047 encoded-word back to raw bytes for comparison
sub ew_decode
{
    my $str = shift( @_ );
    $str =~ s/=\?([A-Za-z0-9_-]+)\?([BbQq])\?([^?]*)\?=/
        do {
            my( $cs, $enc, $text ) = ( $1, $2, $3 );
            uc($enc) eq 'B'
                ? MIME::Base64::decode_base64( $text )
                : do { $text =~ s|_| |g; $text =~ s|=([0-9A-Fa-f]{2})|chr(hex($1))|ge; $text }
        }
    /ge;
    return( $str );
}

# NOTE: 1. Pure ASCII - no encoding applied
subtest 'pure ASCII: unchanged' => sub
{
    my $s = Mail::Make::Headers::Subject->new;
    $s->value( 'Quarterly Report' );
    is( $s->as_string, 'Quarterly Report', 'pure ASCII passes through unchanged' );
};

subtest 'pure ASCII: empty string' => sub
{
    my $s = Mail::Make::Headers::Subject->new;
    $s->value( '' );
    is( $s->as_string, '', 'empty string passes through unchanged' );
};

subtest 'pure ASCII: printable symbols' => sub
{
    my $s = Mail::Make::Headers::Subject->new;
    $s->value( 'Re: [ticket #123] Fix & deploy!' );
    my $out = $s->as_string;
    is( $out, 'Re: [ticket #123] Fix & deploy!', 'printable ASCII with symbols unchanged' );
    unlike( $out, qr/=\?/, 'no encoded-word markers present' );
};

# NOTE: 2. Non-ASCII - encoding applied
subtest 'non-ASCII: encoded-word markers present' => sub
{
    my $s = Mail::Make::Headers::Subject->new;
    $s->value( "Yamato, Inc. \x{2014} Newsletter" );   # em dash U+2014
    my $out = $s->as_string;
    like( $out, qr/=\?UTF-8\?B\?/, 'encoded-word header present' );
    like( $out, qr/\?=$/,          'encoded-word properly closed' );
};

subtest 'non-ASCII: French accents round-trip' => sub
{
    my $s    = Mail::Make::Headers::Subject->new;
    my $orig = "Lettre d'information - Résultats du 3\x{e8}me trimestre";
    $s->value( $orig );
    my $wire    = $s->as_string;
    my $decoded = $s->decode( $wire );
    is( $decoded, $orig, 'French text round-trips correctly' );
};

subtest 'non-ASCII: Japanese round-trip' => sub
{
    my $s    = Mail::Make::Headers::Subject->new;
    my $orig = "\x{682a}\x{5f0f}\x{4f1a}\x{793e}\x{30a8}\x{30f3}\x{30b8}\x{30a7}\x{30eb}\x{30ba}";
    # 株式会社エンジェルズ
    $s->value( $orig );
    my $wire    = $s->as_string;
    my $decoded = $s->decode( $wire );
    is( $decoded, $orig, 'Japanese text round-trips correctly' );
};

subtest 'non-ASCII: Arabic round-trip' => sub
{
    my $s    = Mail::Make::Headers::Subject->new;
    my $orig = "\x{0646}\x{0634}\x{0631}\x{0629} \x{0625}\x{062e}\x{0628}\x{0627}\x{0631}\x{064a}\x{0629}";
    $s->value( $orig );
    my $wire    = $s->as_string;
    my $decoded = $s->decode( $wire );
    is( $decoded, $orig, 'Arabic text round-trips correctly' );
};

# NOTE: 3. Encoded-word length constraints
subtest 'encoded-word: each word <= 75 chars' => sub
{
    my $s = Mail::Make::Headers::Subject->new;
    # Force a value that will produce multiple encoded-words
    $s->value( "\x{3053}" x 30 );  # 30 × こ (3 bytes each = 90 bytes total)
    my $wire = $s->as_string;
    for my $ew ( $wire =~ /(=\?[^?]+\?[BbQq]\?[^?]*\?=)/g )
    {
        ok( length( $ew ) <= 75, "encoded-word '$ew' is <= 75 chars (got " . length($ew) . ")" );
    }
};

subtest 'encoded-word: no UTF-8 sequence split across words' => sub
{
    my $s = Mail::Make::Headers::Subject->new;
    # Carefully chosen: 45-byte chunks must not split a 3-byte CJK sequence.
    # 15 CJK chars = 45 bytes exactly; 16th would start a new chunk cleanly.
    my $orig = "\x{4e2d}\x{6587}" x 16;   # 中文 × 16 = 32 chars, 96 bytes
    $s->value( $orig );
    my $wire    = $s->as_string;
    my $decoded = $s->decode( $wire );
    is( $decoded, $orig, 'no sequence split: round-trip correct for 96-byte CJK string' );
};

# NOTE: 4. Folding
subtest 'folding: CRLF SP between encoded-words' => sub
{
    my $s = Mail::Make::Headers::Subject->new;
    $s->value( "\x{65e5}\x{672c}\x{8a9e}" x 20 );  # 60 chars Japanese = 180 bytes
    my $wire = $s->as_string;
    if( $wire =~ /\?=/ && $wire =~ /=\?/ && index( $wire, '?=' ) < length( $wire ) - 2 )
    {
        like( $wire, qr/\?=\015\012 =\?/, 'CRLF SP fold separator present between encoded-words' );
    }
    else
    {
        # Single encoded-word: nothing to fold
        pass( 'single encoded-word, no fold needed' );
    }
};

subtest 'folding: folded value decodes correctly' => sub
{
    my $s    = Mail::Make::Headers::Subject->new;
    my $orig = "\x{30CB}\x{30e5}\x{30fc}\x{30b9}\x{30ec}\x{30bf}\x{30fc}" x 10;
    # ニュースレター × 10 = 70 chars = 210 bytes
    $s->value( $orig );
    my $wire    = $s->as_string;
    my $decoded = $s->decode( $wire );
    is( $decoded, $orig, 'multi-word folded subject decodes back to original' );
};

# NOTE: 5. Decode method
subtest 'decode: handles ?B? (Base64) form' => sub
{
    my $s       = Mail::Make::Headers::Subject->new;
    my $encoded = '=?UTF-8?B?SGVsbG8gV29ybGQ=?=';  # "Hello World"
    my $decoded = $s->decode( $encoded );
    is( $decoded, 'Hello World', '?B? decoded correctly' );
};

subtest 'decode: handles ?Q? (Quoted-Printable) form' => sub
{
    my $s       = Mail::Make::Headers::Subject->new;
    # "Café" encoded in ?Q? form
    my $encoded = '=?UTF-8?Q?Caf=C3=A9?=';
    my $decoded = $s->decode( $encoded );
    is( $decoded, "Caf\x{e9}", '?Q? decoded correctly' );
};

subtest 'decode: collapses whitespace between encoded-words (RFC 2047 §6.2)' => sub
{
    my $s   = Mail::Make::Headers::Subject->new;
    # Two consecutive encoded-words separated by whitespace - whitespace discarded
    my $w1  = '=?UTF-8?B?' . MIME::Base64::encode_base64( Encode::encode('UTF-8', "\x{3053}\x{3093}"), '' ) . '?=';
    my $w2  = '=?UTF-8?B?' . MIME::Base64::encode_base64( Encode::encode('UTF-8', "\x{306b}\x{3061}\x{306f}"), '' ) . '?=';
    my $enc = "${w1} ${w2}";
    my $dec = $s->decode( $enc );
    is( $dec, "\x{3053}\x{3093}\x{306b}\x{3061}\x{306f}", 'inter-word whitespace discarded: こんにちは' );
};

subtest 'decode: pure ASCII passthrough' => sub
{
    my $s = Mail::Make::Headers::Subject->new;
    is( $s->decode( 'Hello World' ), 'Hello World', 'plain ASCII decoded unchanged' );
};

# NOTE: 6. Accessors
subtest 'value() getter returns Perl string, not encoded form' => sub
{
    my $s    = Mail::Make::Headers::Subject->new;
    my $orig = "Yamato \x{2014} Inc.";
    $s->value( $orig );
    is( $s->value,   $orig, 'value() returns original Perl string' );
    is( $s->raw,     $orig, 'raw() also returns original Perl string' );
    isnt( $s->as_string, $orig, 'as_string() returns encoded form (different)' );
};

subtest 'field_name' => sub
{
    my $s = Mail::Make::Headers::Subject->new;
    is( $s->field_name, 'Subject', 'field_name() returns Subject' );
};

subtest 'cache invalidation on re-assignment' => sub
{
    my $s = Mail::Make::Headers::Subject->new;
    $s->value( "First \x{2014} value" );
    my $first = $s->as_string;
    $s->value( "Second \x{2014} value" );
    my $second  = $s->as_string;
    isnt( $first, $second, 'as_string updated after value() re-assignment' );
    my $decoded = Encode::decode( 'MIME-Header', $second );
    like( $decoded, qr/Second/, 'new encoded value contains new content after decode' );
};

# NOTE: 7. Integration: Mail::Make uses Subject encoding for subject()
subtest 'Mail::Make: ASCII subject passed through unchanged' => sub
{
    use Mail::Make;
    my $mail = Mail::Make->new
        ->from(    'a@example.com' )
        ->to(      'b@example.com' )
        ->subject( 'Plain ASCII Subject' )
        ->plain(   "body" );
    my $str = $mail->as_string;
    ok( defined( $str ), 'message assembled successfully' );
    like( $str, qr/Subject: Plain ASCII Subject/, 'ASCII subject in message unchanged' );
};

subtest 'Mail::Make: non-ASCII subject encoded' => sub
{
    use Mail::Make;
    my $mail = Mail::Make->new
        ->from(    'a@example.com' )
        ->to(      'b@example.com' )
        ->subject( "\x{30cb}\x{30e5}\x{30fc}\x{30b9}\x{30ec}\x{30bf}\x{30fc}" )  # ニュースレター
        ->plain(   "body" );
    my $str = $mail->as_string;
    ok( defined( $str ), 'message with Japanese subject assembled successfully' );
    like( $str, qr/Subject: =\?UTF-8\?B\?/, 'Japanese subject encoded in message' );
    unlike( $str, qr/Subject:.*\x{30cb}/,   'raw Japanese bytes not present unencoded' );
};

subtest 'Mail::Make: long non-ASCII subject folded' => sub
{
    use Mail::Make;
    # 50 CJK chars × 3 bytes = 150 bytes - will require at least 4 encoded-words
    my $long = "\x{4e2d}\x{6587}" x 25;
    my $mail = Mail::Make->new
        ->from(    'a@example.com' )
        ->to(      'b@example.com' )
        ->subject( $long )
        ->plain(   "body" );
    my $str = $mail->as_string;
    ok( defined( $str ), 'message with long CJK subject assembled' );
    # Verify the encoded-words are all within 75 chars
    for my $ew ( $str =~ /(=\?[^?]+\?[BbQq]\?[^?]*\?=)/g )
    {
        ok( length( $ew ) <= 75,
            "encoded-word in message is <= 75 chars (got " . length($ew) . ")" );
    }
};

done_testing();

__END__
