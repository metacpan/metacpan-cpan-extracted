#!/usr/local/bin/perl
##----------------------------------------------------------------------------
## Mail Builder - t/12_html_to_inline.t
## Test suite for Mail::Make html_to_inline() and url_to_inline()
##
## All tests use file:// URIs or in-memory data to avoid network access.
## The test structure mirrors the actual MIME tree rather than just scanning
## the serialised string, so parser regressions are caught early.
##----------------------------------------------------------------------------
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG );
    use Test::More;
    use Module::Generic::File qw( tempfile tempdir );
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;

BEGIN
{
    local $@;
    my $has_html_obj  = eval{ require HTML::Object::DOM; 1 };
    my $has_html_tree = eval{ require HTML::TreeBuilder; 1 };
    unless( $has_html_obj || $has_html_tree )
    {
        plan( skip_all => 'Neither HTML::Object::DOM nor HTML::TreeBuilder is available' );
    }
};

BEGIN
{
    use_ok( 'Mail::Make' ) or BAIL_OUT( 'Unable to load Mail::Make' );
};

# NOTE: Minimal 1x1 PNG bytes - valid enough for MIME typing
use constant PNG_BYTES => "\x89PNG\x0D\x0A\x1A\x0A\x00\x00\x00\x0DIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90wS\xDE\x00\x00\x00\x0CIDATx\x9Cc\xF8\xFF\xFF?\x00\x05\xFE\x02\xFE\x0D\xEFF\xB8\x00\x00\x00\x00IEND\xAEB`\x82"; # valid 1x1 RGB PNG, 69 bytes
use constant CSS_BYTES => "body { color: red; }\n";
use constant GIF_BYTES => "GIF89a\x01\x00\x01\x00\x00\xff\x00,\x00\x00\x00\x00\x01\x00\x01\x00\x00\x02\x00;";


# NOTE: Helper: write content to a new temp file, return path object
sub tmp_file
{
    my( $content, $suffix ) = @_;
    $suffix //= '';
    my $path = tempfile( cleanup => 1, open => 1, ( length( $suffix ) ? ( suffix => $suffix ) : () ) );
    $path->binmode;
    $path->print( $content );
    $path->close;
    return( $path );
}

# NOTE: Helper: create a temp directory, return path object
sub tmp_dir
{
    return( tempdir( cleanup => 1 ) );
}

# NOTE: Helper: build a file:// URI from a path object or string
sub file_uri
{
    my $path = shift( @_ );
    # Stringify in case $path is a Module::Generic::File object
    return( "file://" . ( ref( $path ) ? "$path" : $path ) );
}

# NOTE: Helper: count how many inline parts a Mail::Make object has
sub count_inline
{
    my $m = shift;
    my $e = $m->as_entity or return(-1);
    my $count = 0;
    _count_inline_in( $e, \$count );
    return( $count );
}

sub _count_inline_in
{
    my( $e, $ref ) = @_;
    if( $e->is_multipart )
    {
        _count_inline_in( $_, $ref ) for( @{$e->parts} );
    }
    elsif( ( $e->headers->get( 'Content-ID' ) // '' ) ne '' )
    {
        $$ref++;
    }
}

# html_to_inline() - basic usage with file:// base_url
# NOTE: html_to_inline: img src resolved via file:// base_url
subtest 'html_to_inline: img src resolved via file:// base_url' => sub
{
    my $img  = tmp_file( PNG_BYTES, '.png' );
    my $dir  = $img->parent;
    my $name = $img->basename;

    my $html = qq{<html><body><img src="${name}"></body></html>};

    my $m = Mail::Make->new( debug => $DEBUG )
        ->from(    'a@example.com' )
        ->to(      'b@example.com' )
        ->subject( 'test' )
        ->html_to_inline(
            html     => $html,
            base_url => file_uri( $dir ) . '/',
        );
    ok( defined( $m ), 'html_to_inline() returns $self' );

    my $e = $m->as_entity;
    if( !ok( defined( $e ), 'as_entity() succeeds' ) )
    {
        diag( "Failed as_entity: ", $m->error );
    }

    # Structure: multipart/related( text/html, image/png )
    is( $e->mime_type, 'multipart/related', 'top is multipart/related' );
    my @parts = @{$e->parts};
    if( is( scalar( @parts ), 2, 'two parts' ) )
    {
        is( $parts[0]->mime_type, 'text/html',  'first part is text/html' );
        is( $parts[1]->mime_type, 'image/png',  'second part is image/png' );
        my $cid = $parts[1]->headers->get( 'Content-ID' ) // '';
        ok( length( $cid ), 'inline image has Content-ID' );
    
        # The HTML must have been rewritten to use the cid:
        my $html_body = ${$parts[0]->body->as_string};
        like( $html_body, qr/cid:/, 'HTML src attribute rewritten to cid:' );
        unlike( $html_body, qr/\Q$name\E/, 'original filename no longer in HTML' );
    }
};

# NOTE: html_to_inline: plain + html_to_inline -> multipart/alternative wrapping multipart/related
subtest 'html_to_inline: plain + html_to_inline -> multipart/alternative wrapping multipart/related' => sub
{
    my $img  = tmp_file( PNG_BYTES, '.png' );
    my $dir  = $img->parent;
    my $name = $img->basename;

    my $m = Mail::Make->new( debug => $DEBUG )
        ->from(    'a@example.com' )
        ->to(      'b@example.com' )
        ->subject( 'test' )
        ->plain(   "Hello.\n" )
        ->html_to_inline(
            html     => qq{<html><body><img src="${name}"></body></html>},
            base_url => file_uri( $dir ) . '/',
        );

    my $e = $m->as_entity;
    ok( defined( $e ), 'as_entity() succeeds' );
    is( $e->mime_type, 'multipart/alternative', 'top is multipart/alternative' );

    my @top = @{$e->parts};
    if( is( scalar( @top ), 2, 'two children' ) )
    {
        is( $top[0]->mime_type, 'text/plain',        'first child is text/plain' );
        is( $top[1]->mime_type, 'multipart/related', 'second child is multipart/related' );
    }
    my @rel = @{$top[1]->parts};
    if( is( scalar( @rel ), 2, 'related has two children' ) )
    {
        is( $rel[0]->mime_type, 'text/html', 'first related child is text/html' );
        is( $rel[1]->mime_type, 'image/png', 'second related child is image/png' );
    }
};

# NOTE: html_to_inline: absolute file:// src in HTML
subtest 'html_to_inline: absolute file:// src in HTML' => sub
{
    my $img = tmp_file( PNG_BYTES, '.png' );
    my $uri = file_uri( $img );

    my $m = Mail::Make->new( debug => $DEBUG )
        ->from(    'a@example.com' )
        ->to(      'b@example.com' )
        ->subject( 'test' )
        ->html_to_inline(
            html     => qq{<html><body><img src="${uri}"></body></html>},
            base_url => 'file:///nonexistent/',  # should not be needed for absolute URI
        );
    ok( defined( $m ), 'html_to_inline() with absolute file:// src succeeds' );
    is( count_inline( $m ), 1, 'one inline part embedded' );
};

# NOTE: html_to_inline: same URL used twice shares one Content-ID
subtest 'html_to_inline: same URL used twice shares one Content-ID' => sub
{
    my $img  = tmp_file( PNG_BYTES, '.png' );
    my $dir  = $img->parent;
    my $name = $img->basename;

    my $html = qq{<html><body><img src="${name}"><img src="${name}"></body></html>};

    my $m = Mail::Make->new( debug => $DEBUG )
        ->from(    'a@example.com' )
        ->to(      'b@example.com' )
        ->subject( 'test' )
        ->html_to_inline(
            html     => $html,
            base_url => file_uri( $dir ) . '/',
        );
    ok( defined( $m ), 'html_to_inline() succeeds with duplicate src' );
    is( count_inline( $m ), 1, 'only one inline part despite two identical src' );

    my $e = $m->as_entity;
    if( defined( $e ) && $e->is_multipart )
    {
        my $html_part = $e->parts->[0]->is_multipart
            ? $e->parts->[0]->parts->[0]
            : $e->parts->[0];
        my $html_out = ${$html_part->body->as_string};
        my @cids = ( $html_out =~ /cid:([^\s"']+)/g );
        is( scalar( @cids ), 2, 'two cid: references in rewritten HTML' );
        is( $cids[0], $cids[1], 'both cid: references are identical' );
    }
};

# NOTE: html_to_inline: unfetchable asset is left unchanged with warning
subtest 'html_to_inline: unfetchable asset is left unchanged with warning' => sub
{
    # Use a file:// URL pointing to a non-existent file to avoid any network
    # connection and the TCP timeout that would come with it.
    my $missing = 'file:///tmp/no-such-image-' . time() . '.png';
    my $html    = qq{<html><body><img src="${missing}"></body></html>};

    my @warnings;
    local $SIG{__WARN__} = sub { push( @warnings, @_ ) };

    {
        no warnings 'Mail::Make';
        my $m = Mail::Make->new( debug => $DEBUG )
            ->from(    'a@example.com' )
            ->to(      'b@example.com' )
            ->subject( 'test' )
            ->html_to_inline( html => $html );
        if( !ok( defined( $m ), 'html_to_inline() succeeds even when an asset cannot be fetched' ) )
        {
            diag( "Error: ", Mail::Make->error );
        }
        is( count_inline( $m ), 0, 'no inline parts (fetch failed)' );

        # The original URL should still be in the HTML
        my $e        = $m->as_entity;
        my $body_ref = $e->body->as_string;
        my $html_out = ref( $body_ref ) ? $$body_ref : "$body_ref";
        like( $html_out, qr{no-such-image}, 'original URL preserved in HTML when fetch fails' );
    }
};

# NOTE: html_to_inline: missing html option returns error
subtest 'html_to_inline: missing html option returns error' => sub
{
    no warnings 'Mail::Make';
    my $m = Mail::Make->new( debug => $DEBUG );
    my $rv = $m->html_to_inline( base_url => 'https://www.example.com' );
    ok( !defined( $rv ), 'returns undef when html is missing' );
    like( $m->error . '', qr/html.*required/i, 'error message mentions html' );
};

# NOTE: html_to_inline: relative URL without base_url skipped with warning
subtest 'html_to_inline: relative URL without base_url skipped with warning' => sub
{
    my $html = '<html><body><img src="/images/logo.png"></body></html>';

    my @warnings;
    local $SIG{__WARN__} = sub { push( @warnings, @_ ) };

    # No base_url provided - relative URL cannot be resolved
    my $m = Mail::Make->new( debug => $DEBUG )
        ->from(    'a@example.com' )
        ->to(      'b@example.com' )
        ->subject( 'test' )
        ->html_to_inline( html => $html );
    if( !ok( defined( $m ), 'html_to_inline() without base_url does not die' ) )
    {
        diag( "Error: ", Mail::Make->error );
    }
    is( count_inline( $m ), 0, 'no inline parts when relative URL cannot be resolved' );
};

# NOTE: html_to_inline: body background attribute embedded
subtest 'html_to_inline: body background attribute embedded' => sub
{
    my $img  = tmp_file( PNG_BYTES, '.png' );
    my $dir  = $img->parent;
    my $name = $img->basename;

    my $html = qq{<html><body background="${name}"><p>Hello</p></body></html>};

    my $m = Mail::Make->new( debug => $DEBUG )
        ->from(    'a@example.com' )
        ->to(      'b@example.com' )
        ->subject( 'test' )
        ->html_to_inline(
            html     => $html,
            base_url => file_uri( $dir ) . '/',
        );
    ok( defined( $m ), 'html_to_inline() with body background succeeds' );
    is( count_inline( $m ), 1, 'background image embedded as inline part' );

    my $e        = $m->as_entity;
    if( ok( scalar( @{$e->parts} ), 'has parts' ) )
    {
        my $html_out = ${$e->parts->[0]->body->as_string};
        like( $html_out, qr/background="cid:/, 'background attribute rewritten to cid:' );
    }
};

# NOTE: html_to_inline: embed_css embeds stylesheet
subtest 'html_to_inline: embed_css embeds stylesheet' => sub
{
    my $css  = tmp_file( CSS_BYTES, '.css' );
    my $dir  = $css->parent;
    my $name = $css->basename;

    my $html = qq{<html><head><link rel="stylesheet" href="${name}"></head><body><p>Hello</p></body></html>};

    my $m = Mail::Make->new( debug => $DEBUG )
        ->from(    'a@example.com' )
        ->to(      'b@example.com' )
        ->subject( 'test' )
        ->html_to_inline(
            html      => $html,
            base_url  => file_uri( $dir ) . '/',
            embed_css => 1,
        );
    ok( defined( $m ), 'html_to_inline() with embed_css succeeds' );
    is( count_inline( $m ), 1, 'stylesheet embedded as inline part' );
};

# NOTE: html_to_inline: embed_css disabled by default
subtest 'html_to_inline: embed_css disabled by default' => sub
{
    my $css  = tmp_file( CSS_BYTES, '.css' );
    my $dir  = $css->parent;
    my $name = $css->basename;

    my $html = qq{<html><head><link rel="stylesheet" href="${name}"></head><body><p>Hello</p></body></html>};

    my $m = Mail::Make->new( debug => $DEBUG )
        ->from(    'a@example.com' )
        ->to(      'b@example.com' )
        ->subject( 'test' )
        ->html_to_inline(
            html     => $html,
            base_url => file_uri( $dir ) . '/',
            # embed_css not set - should default to 0
        );
    ok( defined( $m ), 'html_to_inline() without embed_css succeeds' );
    is( count_inline( $m ), 0, 'stylesheet not embedded when embed_css is false' );
};

# NOTE: html_to_inline: persistent cache writes sidecar json
subtest 'html_to_inline: persistent cache writes sidecar json' => sub
{
    # cache_dir only applies to HTTP/HTTPS assets; file:// assets are read
    # directly from disk and do not produce cache files. This test verifies
    # that cache_dir is accepted without error and that the asset is still
    # embedded correctly.
    my $img     = tmp_file( PNG_BYTES, '.png' );
    my $dir     = $img->parent;
    my $name    = $img->basename;
    my $cache_d = tmp_dir();

    my $m = Mail::Make->new( debug => $DEBUG )
        ->from(    'a@example.com' )
        ->to(      'b@example.com' )
        ->subject( 'test' )
        ->html_to_inline(
            html      => qq{<html><body><img src="${name}"></body></html>},
            base_url  => file_uri( $dir ) . '/',
            cache_dir => "$cache_d",
        );
    ok( defined( $m ), 'html_to_inline() with cache_dir succeeds' );
    is( count_inline( $m ), 1, 'asset embedded even when cache_dir is set' );
};

# NOTE: html_to_inline: via build() key
subtest 'html_to_inline: via build() key' => sub
{
    my $img  = tmp_file( PNG_BYTES, '.png' );
    my $dir  = $img->parent;
    my $name = $img->basename;

    my $m = Mail::Make->build(
        from           => 'a@example.com',
        to             => 'b@example.com',
        subject        => 'test',
        plain          => "Hello.\n",
        html_to_inline => {
            html     => qq{<html><body><img src="${name}"></body></html>},
            base_url => file_uri( $dir ) . '/',
        },
        debug => $DEBUG,
    );
    ok( defined( $m ), 'build() with html_to_inline key succeeds' );
    is( count_inline( $m ), 1, 'one inline part embedded' );

    my $e = $m->as_entity;
    is( $e->mime_type, 'multipart/alternative', 'top is multipart/alternative' );
    is( $e->parts->[1]->mime_type, 'multipart/related', 'second child is multipart/related' );
};

# html_to_inline() - multiple images including GIF
# NOTE: html_to_inline: multiple images of different types
subtest 'html_to_inline: multiple images of different types' => sub
{
    my $png = tmp_file( PNG_BYTES, '.png' );
    my $gif = tmp_file( GIF_BYTES, '.gif' );
    my $dir = $png->parent;

    my $html = sprintf(
        '<html><body><img src="%s"><img src="%s"></body></html>',
        $png->basename,
        $gif->basename,
    );

    my $m = Mail::Make->new( debug => $DEBUG )
        ->from(    'a@example.com' )
        ->to(      'b@example.com' )
        ->subject( 'test' )
        ->html_to_inline(
            html     => $html,
            base_url => file_uri( $dir ) . '/',
        );
    ok( defined( $m ), 'html_to_inline() with two different images succeeds' );
    is( count_inline( $m ), 2, 'two distinct inline parts' );
};

# NOTE: html_to_inline + attachment -> multipart/mixed
subtest 'html_to_inline + attachment -> multipart/mixed' => sub
{
    my $img = tmp_file( PNG_BYTES, '.png' );
    my $pdf = tmp_file( '%PDF-1.4 fake', '.pdf' );
    my $dir = $img->parent;

    my $m = Mail::Make->new( debug => $DEBUG )
        ->from(    'a@example.com' )
        ->to(      'b@example.com' )
        ->subject( 'test' )
        ->plain(   "Hello.\n" )
        ->html_to_inline(
            html     => sprintf( '<html><body><img src="%s"></body></html>', $img->basename ),
            base_url => file_uri( $dir ) . '/',
        )
        ->attach( "$pdf" );

    my $e = $m->as_entity;
    ok( defined( $e ), 'as_entity() succeeds' );
    is( $e->mime_type, 'multipart/mixed', 'top is multipart/mixed' );

    my @top = @{$e->parts};
    is( scalar( @top ), 2, 'two children of mixed' );
    is( $top[0]->mime_type, 'multipart/alternative', 'first child is multipart/alternative' );
    is( $top[1]->mime_type, 'application/pdf',        'second child is application/pdf' );

    my @alt = @{$top[0]->parts};
    is( $alt[1]->mime_type, 'multipart/related', 'alt second child is multipart/related' );
};

# NOTE: url_to_inline: fetches HTML and embeds assets from file:// URL
subtest 'url_to_inline: fetches HTML and embeds assets from file:// URL' => sub
{
    my $img  = tmp_file( PNG_BYTES, '.png' );
    my $dir  = $img->parent;
    my $name = $img->basename;

    # Write a small HTML page referencing the image by relative path
    my $html_file = $dir->child( 'page.html' );
    $html_file->save( qq{<html><body><img src="${name}"></body></html>} );

    my $m = Mail::Make->new( debug => $DEBUG )
        ->from(    'a@example.com' )
        ->to(      'b@example.com' )
        ->subject( 'test' )
        ->url_to_inline( url => file_uri( $html_file ) );

    ok( defined( $m ), 'url_to_inline() returns $self' );
    is( count_inline( $m ), 1, 'one inline part embedded' );

    my $e = $m->as_entity;
    ok( defined( $e ), 'as_entity() succeeds' );
    is( $e->mime_type, 'multipart/related', 'top is multipart/related' );

    my @parts = @{$e->parts};
    if( ok( scalar( @parts ), 'has parts' ) )
    {
        is( $parts[0]->mime_type, 'text/html', 'first part is text/html' );
        is( $parts[1]->mime_type, 'image/png', 'second part is image/png' );

        # Verify the src attribute was rewritten
        my $html_body = ${$parts[0]->body->as_string};
        like( $html_body, qr/cid:/, 'src attribute rewritten to cid:' );
    }
};

# NOTE: url_to_inline: base_url deduced from page URL
subtest 'url_to_inline: base_url deduced from page URL' => sub
{
    my $img  = tmp_file( PNG_BYTES, '.png' );
    my $dir  = $img->parent;
    my $name = $img->basename;

    # Page in a subdirectory, image referenced by relative path
    my $html_file = $dir->child( 'page.html' );
    $html_file->save( qq{<html><body><img src="${name}"></body></html>} );

    # No explicit base_url - should be deduced as the page's directory
    my $m = Mail::Make->new( debug => $DEBUG )
        ->from(    'a@example.com' )
        ->to(      'b@example.com' )
        ->subject( 'test' )
        ->url_to_inline( url => file_uri( $html_file ) );

    ok( defined( $m ), 'url_to_inline() without explicit base_url succeeds' );
    is( count_inline( $m ), 1, 'relative image resolved against deduced base_url' );
};

# NOTE: url_to_inline: explicit base_url overrides deduced one
subtest 'url_to_inline: explicit base_url overrides deduced one' => sub
{
    my $img  = tmp_file( PNG_BYTES, '.png' );
    my $dir  = $img->parent;
    my $name = $img->basename;

    my $html_file = $dir->child( 'page2.html' );
    $html_file->save( qq{<html><body><img src="${name}"></body></html>} );

    my $m = Mail::Make->new( debug => $DEBUG )
        ->from(    'a@example.com' )
        ->to(      'b@example.com' )
        ->subject( 'test' )
        ->url_to_inline(
            url      => file_uri( $html_file ),
            base_url => file_uri( $dir ) . '/',
        );

    ok( defined( $m ), 'url_to_inline() with explicit base_url succeeds' );
    is( count_inline( $m ), 1, 'image resolved using explicit base_url' );
};

# NOTE: url_to_inline: missing url option returns error
subtest 'url_to_inline: missing url option returns error' => sub
{
    no warnings 'Mail::Make';
    my $m = Mail::Make->new( debug => $DEBUG );
    my $rv = $m->url_to_inline( base_url => 'https://www.example.com' );
    ok( !defined( $rv ), 'returns undef when url is missing' );
    like( $m->error . '', qr/url.*required/i, 'error message mentions url' );
};

# NOTE: url_to_inline: plain + url_to_inline -> multipart/alternative
subtest 'url_to_inline: plain + url_to_inline -> multipart/alternative' => sub
{
    my $img  = tmp_file( PNG_BYTES, '.png' );
    my $dir  = $img->parent;
    my $name = $img->basename;

    my $html_file = $dir->child( 'page3.html' );
    $html_file->save( qq{<html><body><img src="${name}"></body></html>} );

    my $m = Mail::Make->new( debug => $DEBUG )
        ->from(    'a@example.com' )
        ->to(      'b@example.com' )
        ->subject( 'test' )
        ->plain(   "Hello.\n" )
        ->url_to_inline( url => file_uri( $html_file ) );

    my $e = $m->as_entity;
    ok( defined( $e ), 'as_entity() succeeds' );
    is( $e->mime_type, 'multipart/alternative', 'top is multipart/alternative' );
    is( $e->parts->[1]->mime_type, 'multipart/related', 'second child is multipart/related' );
};

# NOTE: url_to_inline: via build() key
subtest 'url_to_inline: via build() key' => sub
{
    my $img  = tmp_file( PNG_BYTES, '.png' );
    my $dir  = $img->parent;
    my $name = $img->basename;

    my $html_file = $dir->child( 'page4.html' );
    $html_file->save( qq{<html><body><img src="${name}"></body></html>} );

    my $m = Mail::Make->build(
        from          => 'a@example.com',
        to            => 'b@example.com',
        subject       => 'test',
        url_to_inline => { url => file_uri( $html_file ) },
        debug         => $DEBUG,
    );
    ok( defined( $m ), 'build() with url_to_inline key succeeds' );
    is( count_inline( $m ), 1, 'one inline part embedded' );
};

done_testing();

__END__
