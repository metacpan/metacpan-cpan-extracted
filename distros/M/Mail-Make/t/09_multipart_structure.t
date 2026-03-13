#!/usr/local/bin/perl
##----------------------------------------------------------------------------
## Mail Builder - t/09_multipart_structure.t
## Deep structural tests for Mail::Make::Entity MIME assembly and RFC 2047
## address display-name encoding.
##
## These tests verify the *internal tree* produced by as_entity(), not just
## the top-level effective_type.  They also cover the address-encoding path
## that was absent from earlier test files.
##----------------------------------------------------------------------------
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG );
    use Test::More;
    use Encode ();
    use Module::Generic::File qw( tempfile );
    use MIME::Base64 ();
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;

BEGIN
{
    use ok( 'Mail::Make' );
    use ok( 'Mail::Make::Entity' );
};

# NOTE: Helper: create a small temp file with given content
sub tmp_file
{
    my $content = shift // "binary\x00data";
    my $path = tempfile( cleanup => 1, open => 1 );
    $path->binmode;
    $path->print( $content );
    $path->close;
    return( $path );
}

# NOTE: Helpers

# decode RFC 2047 encoded-word(s) in a string
sub decode_ew
{
    my $str = shift;
    $str =~ s{=\?([A-Za-z0-9_-]+)\?([BbQq])\?([^?]*)\?=}
    {
        my( $cs, $enc, $text ) = ( $1, $2, $3 );
        my $bytes = uc( $enc ) eq 'B'
            ? MIME::Base64::decode_base64( $text )
            : do { $text =~ s/_/ /g; $text =~ s/=([0-9A-Fa-f]{2})/chr(hex($1))/ge; $text };
        Encode::decode( $cs, $bytes );
    }ge;
    return( $str );
}

# NOTE: Single-part entities
subtest 'Single-part entities' => sub
{
    # NOTE: plain only
    {
        my $m = Mail::Make->new
            ->from(    'a@example.com' )
            ->to(      'b@example.com' )
            ->plain(   "Hello\n" );
        my $e = $m->as_entity;
        ok( defined( $e ), '1a: plain-only entity created' );
        is( $e->mime_type, 'text/plain', '1a: top is text/plain' );
        ok( !$e->is_multipart, '1a: not multipart' );
        is( scalar( @{ $e->parts } ), 0, '1a: no child parts' );
    }

    # NOTE: html only
    {
        my $m = Mail::Make->new
            ->from(    'a@example.com' )
            ->to(      'b@example.com' )
            ->html(    '<p>Hi</p>' );
        my $e = $m->as_entity;
        ok( defined( $e ), '1b: html-only entity created' );
        is( $e->mime_type, 'text/html', '1b: top is text/html' );
        ok( !$e->is_multipart, '1b: not multipart' );
    }
};

# NOTE: multipart/alternative: plain + html
subtest 'plain + html -> multipart/alternative' => sub
{
    my $m = Mail::Make->new
        ->from(  'a@example.com' )
        ->to(    'b@example.com' )
        ->plain( "text version\n" )
        ->html(  '<p>html version</p>' );
    my $e = $m->as_entity;
    ok( defined( $e ), 'entity created' );
    is( $e->mime_type, 'multipart/alternative', 'top is multipart/alternative' );

    my @parts = @{ $e->parts };
    is( scalar( @parts ), 2, 'exactly two child parts' );
    is( $parts[0]->mime_type, 'text/plain', 'first child is text/plain' );
    is( $parts[1]->mime_type, 'text/html',  'second child is text/html' );

    # Verify boundary in Content-Type
    my $ct = $e->headers->get( 'Content-Type' );
    ok( defined( $ct ) && length( $ct ), 'Content-Type present' );
    like( $ct, qr/boundary=/i, 'boundary parameter present' );
};

# NOTE: multipart/related: html + inline image
#    Expected tree:
#      multipart/related
#      ├── text/html
#      └── image/png  (inline, has Content-ID)
subtest 'html + inline -> multipart/related' => sub
{
    my $img_path = tmp_file( "\x89PNG\r\n" );

    my $m = Mail::Make->new
        ->from(  'a@example.com' )
        ->to(    'b@example.com' )
        ->html(  '<img src="cid:img@test">' )
        ->attach_inline(
            path => $img_path,
            type => 'image/png',
            cid  => 'img@test',
        );
    my $e = $m->as_entity;
    ok( defined( $e ), 'entity created' );
    is( $e->mime_type, 'multipart/related', 'top is multipart/related' );

    my @parts = @{ $e->parts };
    is( scalar( @parts ), 2, 'two child parts' );
    is( $parts[0]->mime_type, 'text/html',  'first child is text/html' );
    is( $parts[1]->mime_type, 'image/png',  'second child is image/png' );
    like( $parts[1]->headers->header( 'Content-ID' ) // '',
          qr/img\@test/, 'Content-ID correct on image part' );
};

# NOTE: full structure: plain + html + inline image
#    Expected tree:
#      multipart/related
#      ├── multipart/alternative
#      │   ├── text/plain
#      │   └── text/html
#      └── image/png  (inline)
subtest 'plain + html + inline -> multipart/related wrapping multipart/alternative' => sub
{
    my $img_path = tmp_file( "\x89PNG\r\n" );

    my $m = Mail::Make->new
        ->from(  'a@example.com' )
        ->to(    'b@example.com' )
        ->plain( "plain version\n" )
        ->html(  '<p>html version <img src="cid:logo@test"></p>' )
        ->attach_inline(
            path => $img_path,
            type => 'image/png',
            cid  => 'logo@test',
        );
    my $e = $m->as_entity;
    ok( defined( $e ), 'entity created' );
    is( $e->mime_type, 'multipart/related', 'top is multipart/related' );

    my @top_parts = @{ $e->parts };
    is( scalar( @top_parts ), 2, 'top has two children' );

    # First child: multipart/alternative
    my $alt = $top_parts[0];
    is( $alt->mime_type, 'multipart/alternative', 'first child of related is multipart/alternative' );

    my @alt_parts = @{ $alt->parts };
    is( scalar( @alt_parts ), 2, 'alternative has two children' );
    is( $alt_parts[0]->mime_type, 'text/plain', 'first alt child is text/plain' );
    is( $alt_parts[1]->mime_type, 'text/html',  'second alt child is text/html' );

    # Second child: the inline image
    my $img = $top_parts[1];
    is( $img->mime_type, 'image/png', 'second child of related is image/png' );
    like( $img->headers->header( 'Content-ID' ) // '',
          qr/logo\@test/, '4: Content-ID on inline image correct' );
};

# NOTE: plain + attachment -> multipart/mixed
#    Expected tree:
#      multipart/mixed
#      ├── text/plain
#      └── application/pdf  (attachment)
subtest 'plain + attachment -> multipart/mixed' => sub
{
    my $pdf_path = tmp_file( "%PDF-1.4" );

    my $m = Mail::Make->new
        ->from(  'a@example.com' )
        ->to(    'b@example.com' )
        ->plain( "See attachment.\n" )
        ->attach(
            path     => $pdf_path,
            type     => 'application/pdf',
            filename => 'report.pdf',
        );
    my $e = $m->as_entity;
    ok( defined( $e ), 'entity created' );
    is( $e->mime_type, 'multipart/mixed', 'top is multipart/mixed' );

    my @parts = @{ $e->parts };
    is( scalar( @parts ), 2, 'two child parts' );
    is( $parts[0]->mime_type, 'text/plain',       'first child is text/plain' );
    is( $parts[1]->mime_type, 'application/pdf',  'second child is application/pdf' );

    # Attachment filename
    my $cd = $parts[1]->headers->get( 'Content-Disposition' ) // '';
    like( $cd, qr/attachment/i,    'disposition is attachment' );
    like( $cd, qr/filename/i,      'filename parameter present' );
    like( $cd, qr/report\.pdf/,    'filename value correct' );
};

# NOTE: full scenario: plain + html + inline + attachment
#    Expected tree:
#      multipart/mixed
#      ├── multipart/related
#      │   ├── multipart/alternative
#      │   │   ├── text/plain
#      │   │   └── text/html
#      │   └── image/png  (inline)
#      └── application/pdf  (attachment)
subtest 'plain + html + inline + attachment -> full nested structure' => sub
{
    note( "plain + html + inline + attachment -> full nested structure" );

    my $img_path = tmp_file( "\x89PNG\r\n" );
    my $pdf_path = tmp_file( "%PDF-1.4" );

    my $m = Mail::Make->new
        ->from(  'a@example.com' )
        ->to(    'b@example.com' )
        ->plain( "plain\n" )
        ->html(  '<img src="cid:img@test">' )
        ->attach_inline(
            path => $img_path,
            type => 'image/png',
            cid  => 'img@test',
        )
        ->attach(
            path     => $pdf_path,
            type     => 'application/pdf',
            filename => 'invoice.pdf',
        );
    my $e = $m->as_entity;
    ok( defined( $e ), 'entity created' );
    is( $e->mime_type, 'multipart/mixed', 'top is multipart/mixed' );

    my @top = @{ $e->parts };
    is( scalar( @top ), 2, 'top has two children (related + pdf)' );

    my $related = $top[0];
    is( $related->mime_type, 'multipart/related', 'first child of mixed is multipart/related' );

    my @rel_parts = @{ $related->parts };
    is( scalar( @rel_parts ), 2, 'related has two children (alternative + image)' );

    my $alt = $rel_parts[0];
    is( $alt->mime_type, 'multipart/alternative', 'first child of related is multipart/alternative' );

    my @alt_parts = @{ $alt->parts };
    is( scalar( @alt_parts ), 2,             'alternative has two children' );
    is( $alt_parts[0]->mime_type, 'text/plain', 'alt first child is text/plain' );
    is( $alt_parts[1]->mime_type, 'text/html',  'alt second child is text/html' );

    is( $rel_parts[1]->mime_type, 'image/png', 'second child of related is image/png' );

    is( $top[1]->mime_type, 'application/pdf', 'second child of mixed is application/pdf' );
};

# NOTE: Serialisation: full nested message serialises without error
subtest 'Serialisation of nested structure' => sub
{
    my $img_path = tmp_file( "\x89PNG\r\n" . ( "X" x 200 ) );
    my $pdf_path = tmp_file( "%PDF-1.4 " . ( "Y" x 200 ) );

    my $m = Mail::Make->new
        ->from(    'sender@example.com' )
        ->to(      'recipient@example.com' )
        ->subject( 'Full MIME test' )
        ->plain(   "Text version\n" )
        ->html(    '<p>HTML version <img src="cid:img@test"></p>' )
        ->attach_inline(
            path => $img_path,
            type => 'image/png',
            cid  => 'img@test',
        )
        ->attach(
            path     => $pdf_path,
            type     => 'application/pdf',
            filename => 'document.pdf',
        );
    my $str = $m->as_string;
    ok( defined( $str ) && length( $str ), 'as_string returns non-empty string' );

    # Envelope headers
    like( $str, qr{^From: sender\@example\.com}mi,    'From header present' );
    like( $str, qr{^To: recipient\@example\.com}mi,   'To header present' );
    like( $str, qr{^Subject: Full MIME test}mi,       'Subject header present' );
    like( $str, qr{^MIME-Version: 1\.0}mi,            'MIME-Version present' );

    # MIME structure markers
    like( $str, qr{multipart/mixed}i,       'multipart/mixed in message' );
    like( $str, qr{multipart/related}i,     'multipart/related in message' );
    like( $str, qr{multipart/alternative}i, 'multipart/alternative in message' );
    like( $str, qr{text/plain}i,            'text/plain part present' );
    like( $str, qr{text/html}i,             'text/html part present' );
    like( $str, qr{image/png}i,             'image/png part present' );
    like( $str, qr{application/pdf}i,       'application/pdf part present' );

    # Encoding correctness
    unlike( $str, qr{Content-Transfer-Encoding:\s*binary}i,
        'no part is encoded as binary' );
    like( $str, qr{Content-Transfer-Encoding:\s*quoted-printable}i,
        'at least one text part uses quoted-printable' );
    like( $str, qr{Content-Transfer-Encoding:\s*base64}i,
        'binary parts use base64' );
};

# NOTE: RFC 2047 display-name encoding in address headers
subtest 'RFC 2047 display-name encoding' => sub
{
    # NOTE: ASCII display name: quoted but not RFC 2047 encoded
    {
        my $m = Mail::Make->new
            ->from(    'John Smith <john@example.com>' )
            ->to(      'Jane Doe <jane@example.com>' )
            ->subject( 'Hello' )
            ->plain(   "Hi\n" );
        my $str = $m->as_string;
        ok( defined( $str ), 'ASCII display name message assembled' );
        like( $str, qr{From:.*John Smith}i,   'plain ASCII name preserved in From' );
        unlike( $str, qr{From:.*=\?UTF-8},    'ASCII name NOT encoded' );
    }

    # NOTE: non-ASCII display name in From: encoded with RFC 2047
    {
        my $name = "Jacques D\x{e9}guest";
        my $m = Mail::Make->new
            ->from(    "${name} <jack\@deguest.jp>" )
            ->to(      'b@example.com' )
            ->subject( 'Test' )
            ->plain(   "body\n" );
        my $str = $m->as_string;
        ok( defined( $str ), 'non-ASCII From name message assembled' );
        like( $str, qr{^From: =\?UTF-8\?B\?}mi,
            'non-ASCII From name is RFC 2047 encoded' );
        # Verify the addr-spec is untouched
        like( $str, qr{<jack\@deguest\.jp>},
            'addr-spec unchanged after encoding' );
        # Verify round-trip decode restores the name
        my( $from_line ) = ( $str =~ /^(From: .+)$/mi );
        my $decoded = decode_ew( $from_line );
        like( $decoded, qr{$name}, 'decoded From name matches original' );
    }

    # NOTE: non-ASCII display name in To: list
    {
        my $japanese_name = "\x{7530}\x{4e2d}\x{592a}\x{90ce}";  # 田中太郎
        my $m = Mail::Make->new
            ->from( 'a@example.com' )
            ->to(   "${japanese_name} <tanaka\@example.jp>" )
            ->subject( 'Test' )
            ->plain( "body\n" );
        my $str = $m->as_string;
        ok( defined( $str ), 'Japanese display name message assembled' );
        like( $str, qr{^To: =\?UTF-8\?B\?}mi,
            'Japanese To name is RFC 2047 encoded' );
        like( $str, qr{<tanaka\@example\.jp>},
            'Japanese addr-spec unchanged' );
    }

    # NOTE: bare addr-spec (no display name): passed through unchanged
    {
        my $m = Mail::Make->new
            ->from( 'plain@example.com' )
            ->to(   'bare@example.com' )
            ->subject( 'Test' )
            ->plain( "body\n" );
        my $str = $m->as_string;
        ok( defined( $str ), 'bare addr-spec message assembled' );
        like( $str, qr{^From: plain\@example\.com\015?$}mi,
            'bare From addr-spec preserved as-is' );
        unlike( $str, qr{^From:.*=\?}mi,
            'bare addr-spec not RFC 2047 encoded' );
    }

    # NOTE: mixed To list: one encoded, one plain
    {
        my $kanji_name = "\x{5c71}\x{7530}\x{82b1}\x{5b50}";  # 山田花子
        my $m = Mail::Make->new
            ->from( 'a@example.com' )
            ->to(   "${kanji_name} <yamada\@example.jp>" )
            ->to(   'Plain Person <plain@example.com>' )
            ->subject( 'Test' )
            ->plain( "body\n" );
        my $str = $m->as_string;
        ok( defined( $str ), 'mixed To list message assembled' );
        like( $str, qr{<yamada\@example\.jp>},  'Japanese addr-spec preserved' );
        like( $str, qr{<plain\@example\.com>},  'plain addr-spec preserved' );
    }
};

# NOTE: Non-ASCII subject RFC 2047 encoding (integration)
subtest 'Non-ASCII subject encoding' => sub
{
    my $subject = "\x{30cb}\x{30e5}\x{30fc}\x{30b9}\x{30ec}\x{30bf}\x{30fc}";
    # ニュースレター

    my $m = Mail::Make->new
        ->from(    'a@example.com' )
        ->to(      'b@example.com' )
        ->subject( $subject )
        ->plain(   "body\n" );
    my $str = $m->as_string;
    ok( defined( $str ), 'Japanese subject message assembled' );
    like( $str, qr{^Subject: =\?UTF-8\?B\?}mi,
        'Japanese subject is RFC 2047 encoded' );

    # Encoded-words must be <= 75 chars each
    for my $ew ( $str =~ /(=\?[^?]+\?[BbQq]\?[^?]*\?=)/g )
    {
        ok( length( $ew ) <= 75,
            "encoded-word length " . length( $ew ) . " <= 75" );
    }

    # Round-trip: decode the Subject line back
    my( $subj_line ) = ( $str =~ /^(Subject: .+?)(?:\015?\012(?![ \t]))/ms );
    if( defined( $subj_line ) )
    {
        $subj_line =~ s/^Subject: //;
        # Collapse folding
        $subj_line =~ s/\015?\012[ \t]//g;
        my $decoded = decode_ew( $subj_line );
        is( $decoded, $subject, 'decoded subject matches original Japanese text' );
    }
    else
    {
        fail( 'could not extract Subject line from message' );
    }
};

# NOTE: Comma-in-filename: the original bug
subtest 'Comma-in-filename (the original bug)' => sub
{
    my $img_path = tmp_file( "\x89PNG\r\n" . ( "X" x 100 ) );

    my $m = Mail::Make->new
        ->from(  'hello@yamato-inc.com' )
        ->to(    'client@example.com' )
        ->subject( 'Hello from Yamato, Inc.' )
        ->plain( "Dear client,\n\nPlease see our logo.\n" )
        ->html(  '<p>Dear client,</p><p><img src="cid:logo@yamato-inc"></p>' )
        ->attach_inline(
            path     => $img_path,
            type     => 'image/png',
            filename => 'Yamato,Inc-Logo.png',
            cid      => 'logo@yamato-inc',
        );
    my $str = $m->as_string;
    ok( defined( $str ) && length( $str ),
        'message with comma-in-filename assembled' );

    # THE CORE FIX: text parts must not be encoded as binary
    unlike( $str, qr{Content-Transfer-Encoding:\s*binary}i,
        'NO text part encoded as binary (the bug is fixed)' );

    # Text parts must use quoted-printable
    like( $str, qr{Content-Transfer-Encoding:\s*quoted-printable}i,
        'text parts use quoted-printable' );

    # Image must use base64
    like( $str, qr{Content-Transfer-Encoding:\s*base64}i,
        'image uses base64' );

    # Comma must be percent-encoded in filename*
    like( $str, qr{filename\*=.*Yamato%2CInc}i,
        'comma percent-encoded as %2C in RFC 2231 filename*' );

    # No bare comma in filename= value
    unlike( $str, qr{filename=Yamato,Inc}i,
        'no bare comma in filename= parameter' );

    # Subject with comma must be ASCII and untouched (comma is ASCII)
    like( $str, qr{^Subject: Hello from Yamato, Inc\.}mi,
        'ASCII subject with comma preserved unchanged' );
};

done_testing();

__END__
