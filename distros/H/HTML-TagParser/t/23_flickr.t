# ----------------------------------------------------------------
    use strict;
    use Test::More tests => 10;
    BEGIN { use_ok('HTML::TagParser') };
# ----------------------------------------------------------------
    my $FILE = "t/sample/flickr.html";
# ----------------------------------------------------------------
    &test_main();
# ----------------------------------------------------------------
sub test_main {
    my $html = HTML::TagParser->new( $FILE );
    ok( ref $html, "open by new()" );

    my $title = $html->getElementsByTagName('title');
    like( $title->innerText(), qr/^Flickr/i, 'title' );

    my $desc = $html->getElementsByName('description');
    like( $desc->getAttribute('content'), qr/^Flickr/i, 'description' );

    my $atom = $html->getElementsByAttribute('type','application/atom+xml');
    like( $atom->getAttribute('href'), qr/format=atom/i, 'application/atom+xml' );

    my $top = $html->getElementsByName('top');
    is( $top->tagName(), 'a', 'a name top' );

    my $input = $html->getElementById('header_search_q');
    is( $input->tagName(), 'input', 'input id header_search_q' );

    my $show = $html->getElementsByAttribute('href','/photos/u-suke/show/');
    like( $show->innerText(), qr/View as slideshow/i, 'a href /View as slideshow/' );

    my $topnavi = $html->getElementsByClassName('About');
    like( $topnavi->innerText(), qr/Copyright/i, 'class About /Copyright/' );

    my @privacy = $html->getElementsByClassName('Privacy');
    ok( scalar @privacy, 'class Privacy' );
}
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------
