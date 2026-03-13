#!/usr/local/bin/perl
##----------------------------------------------------------------------------
## Mail Builder - t/02_headers_content_disposition.t
## Test suite for Mail::Make::Headers::ContentDisposition
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
    use ok( 'Mail::Make::Headers::ContentDisposition' );
};

# NOTE: Construction
subtest 'construction: inline' => sub
{
    my $cd = Mail::Make::Headers::ContentDisposition->new( 'inline' );
    ok( defined( $cd ), 'new(inline) returns object' );
    is( $cd->disposition, 'inline', 'disposition() returns inline' );
};

subtest 'construction: attachment' => sub
{
    my $cd = Mail::Make::Headers::ContentDisposition->new( 'attachment' );
    ok( defined( $cd ), 'new(attachment) returns object' );
    is( $cd->disposition, 'attachment', 'disposition() returns attachment' );
};

subtest 'construction: no argument' => sub
{
    my $cd = Mail::Make::Headers::ContentDisposition->new;
    ok( !defined( $cd ), 'new() with no args returns undef' );
};

# NOTE: disposition validation
subtest 'disposition: valid values' => sub
{
    my $cd = Mail::Make::Headers::ContentDisposition->new( 'inline' );
    for my $d ( qw( inline attachment form-data INLINE ATTACHMENT ) )
    {
        my $rv = $cd->disposition( $d );
        ok( defined( $rv ), "disposition '$d' accepted" );
        is( $cd->disposition, lc( $d ), "disposition normalised to lowercase" );
    }
};

subtest 'disposition: invalid value' => sub
{
    my $cd = Mail::Make::Headers::ContentDisposition->new( 'inline' );
    my $rv = $cd->disposition( 'bogus' );
    ok( !defined( $rv ), 'disposition bogus rejected' );
    like( $cd->error, qr/invalid disposition/i, 'error mentions invalid disposition' );
};

# NOTE: filename: pure ASCII
subtest 'filename: plain ASCII' => sub
{
    my $cd = Mail::Make::Headers::ContentDisposition->new( 'inline' );
    $cd->filename( 'logo.png' );
    my $s = "$cd";
    like( $s, qr/filename="logo\.png"/, 'plain ASCII filename quoted correctly' );
    is( $cd->filename, 'logo.png', 'filename() getter returns correct value' );
};

# NOTE: filename: comma (the bug that started it all)
subtest 'filename: comma triggers RFC 2231 encoding' => sub
{
    my $cd = Mail::Make::Headers::ContentDisposition->new( 'inline' );
    $cd->filename( 'Yamato,Inc-Logo.png' );
    my $s = "$cd";
    # Must NOT appear as plain filename= with unquoted comma
    unlike( $s, qr/filename="Yamato,Inc/, 'comma not left bare in filename=' );
    # Must use filename* extended notation
    like( $s, qr/filename\*=/, 'RFC 2231 filename* notation used' );
    like( $s, qr/UTF-8/, 'charset indicated in filename*' );
    like( $s, qr/%2C/i, 'comma is percent-encoded' );
};

# NOTE: filename: other RFC 2045 special chars
subtest 'filename: parenthesis triggers RFC 2231 encoding' => sub
{
    my $cd = Mail::Make::Headers::ContentDisposition->new( 'attachment' );
    $cd->filename( 'file(1).pdf' );
    my $s = "$cd";
    like( $s, qr/filename\*=/, 'RFC 2231 used for parenthesis in filename' );
};

subtest 'filename: at-sign triggers RFC 2231 encoding' => sub
{
    my $cd = Mail::Make::Headers::ContentDisposition->new( 'attachment' );
    $cd->filename( 'user@domain.txt' );
    my $s = "$cd";
    like( $s, qr/filename\*=/, 'RFC 2231 used for @ in filename' );
};

# NOTE: filename: non-ASCII (Japanese)
subtest 'filename: Japanese characters encoded via RFC 2231' => sub
{
    my $cd = Mail::Make::Headers::ContentDisposition->new( 'attachment' );
    $cd->filename( "\x{30D5}\x{30A1}\x{30A4}\x{30EB}.txt" );  # ファイル.txt
    my $s = "$cd";
    like( $s, qr/filename\*=/, 'RFC 2231 used for non-ASCII filename' );
    like( $s, qr/UTF-8/i, 'charset is UTF-8' );
};

# NOTE: filename: with language tag
subtest 'filename: language tag included when filename_lang set' => sub
{
    my $cd = Mail::Make::Headers::ContentDisposition->new( 'attachment' );
    $cd->filename_lang( 'ja-JP' );
    $cd->filename( "\x{30D5}\x{30A1}\x{30A4}\x{30EB}.txt" );  # ファイル.txt
    my $s = "$cd";
    like( $s, qr/ja-JP/, 'language tag ja-JP present in filename*' );
};

# NOTE: filename: undef removal
subtest 'filename: setting undef removes parameter' => sub
{
    my $cd = Mail::Make::Headers::ContentDisposition->new( 'attachment' );
    $cd->filename( 'test.txt' );
    $cd->filename( undef );
    my $s = "$cd";
    unlike( $s, qr/filename/, 'filename parameter removed after setting undef' );
};

# NOTE: filename_charset
subtest 'filename_charset: only utf-8 accepted' => sub
{
    my $cd = Mail::Make::Headers::ContentDisposition->new( 'inline' );
    my $rv = $cd->filename_charset( 'utf-8' );
    ok( defined( $rv ), 'utf-8 accepted' );
    is( "$rv", 'UTF-8', 'normalised to uppercase UTF-8' );

    $rv = $cd->filename_charset( 'iso-8859-1' );
    ok( !defined( $rv ), 'iso-8859-1 rejected' );
    like( $cd->error, qr/utf-8/i, 'error mentions utf-8' );
};

# NOTE: name
subtest 'name parameter' => sub
{
    my $cd = Mail::Make::Headers::ContentDisposition->new( 'form-data' );
    $cd->name( 'fileField' );
    is( $cd->name, 'fileField', 'name() getter returns correct value' );
    like( "$cd", qr/name=/, 'name= present in stringification' );
};

# NOTE: field_name

subtest 'field_name' => sub
{
    my $cd = Mail::Make::Headers::ContentDisposition->new( 'inline' );
    is( $cd->field_name, 'Content-Disposition', 'field_name returns Content-Disposition' );
};

done_testing();

__END__
