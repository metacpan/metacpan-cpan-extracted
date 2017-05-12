# ----------------------------------------------------------------
    use strict;
    use Test::More tests => 10;
    BEGIN { use_ok('HTML::TagParser') };
# ----------------------------------------------------------------
    my $FILE = "t/sample/yahoo.html";
# ----------------------------------------------------------------
    &test_main();
# ----------------------------------------------------------------
sub test_main {
    my $html = HTML::TagParser->new( $FILE );
    ok( ref $html, "open by new()" );

    my $pf_img = $html->getElementById('pf_img');
    like( $pf_img->getAttribute('alt'), qr/\)$/, 'pf_img' );

    my $title = $html->getElementsByTagName('title');
    like( $title->innerText(), qr/^Yahoo!/i, 'title' );

    my @script = $html->getElementsByAttribute('language','javascript');
    is( scalar @script, 3, 'script language javascript' );

    my $body = $html->getElementsByTagName('body');
    is( $body->getAttribute('class'), 'bg', 'body class=bg' );

    my $sbox = $html->getElementById('fav_list');
    is( $sbox->tagName(), 'table', 'fav_list' );

    my $sf1 = $html->getElementsByName('id_profile');
    is( $sf1->tagName(), 'img', 'id_profile' );

    my @spacer = $html->getElementsByClassName('small');
    ok( scalar @spacer, 'class small' );

    my @small = $html->getElementsByTagName('small');
    my $small = pop( @small );
    like( $small->innerText, qr/Copyright/i, 'small' );
}
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------
