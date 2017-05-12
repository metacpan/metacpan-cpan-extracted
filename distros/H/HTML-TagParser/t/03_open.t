# ----------------------------------------------------------------
    use strict;
    use Test::More tests => 5;
    BEGIN { use_ok('HTML::TagParser') };
# ----------------------------------------------------------------
    my $FILE = "t/sample/hello.html";
# ----------------------------------------------------------------
    my $html1 = HTML::TagParser->new();
    my $num = $html1->open( $FILE );
    ok( $num, "open by open()" );

    my $elem1 = $html1->getElementsByTagName( "title" );
    my $title = $elem1->innerText() if ref $elem1;
    is( $title, "Hello, World!", "title" );
# ----------------------------------------------------------------
    my $html2 = HTML::TagParser->new( $FILE );
    ok( ref $html2, "open by new()" );

    my $elem2 = $html2->getElementsByTagName( "body" );
    my $body = $elem2->innerText() if ref $elem2;
    is( $body, "World, Hello!", "body" );
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------
