# ----------------------------------------------------------------
    use strict;
    use Test::More tests => 5;
    BEGIN { use_ok('HTML::TagParser') };
# ----------------------------------------------------------------
    my $URL1 = "http://search.cpan.org/~kawasaki/";
    my $REX1 = qr/Yusuke/i;
    my $URL2 = "http://www.cpan.org/";
    my $REX2 = qr/Comprehensive/i;
# ----------------------------------------------------------------
SKIP: {
    local $@;
    eval { require URI::Fetch; };
    if ( ! defined $URI::Fetch::VERSION ) {
        skip( "URI::Fetch is not loaded.", 4 );
    }
    &test_uri_fetch1();
    &test_uri_fetch2();
}
# ----------------------------------------------------------------
sub test_uri_fetch1 {
    my $html = HTML::TagParser->new();
    my $tags = $html->fetch( $URL1 );
    ok( $tags, "fetch by fetch() $URL1" );
    my $elem = $html->getElementsByTagName( "title" );
    my $title = $elem->innerText() if ref $elem;
    like( $title, $REX1, "title" );
}
# ----------------------------------------------------------------
sub test_uri_fetch2 {
    my $html = HTML::TagParser->new( $URL2 );
    ok( ref $html, "fetch by new() $URL2" );
    my $elem = $html->getElementsByTagName( "body" );
    my $body = $elem->innerText() if ref $elem;
    like( $body, $REX2, "body" );
}
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------
