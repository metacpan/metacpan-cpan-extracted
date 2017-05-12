# ----------------------------------------------------------------
    use strict;
    use Test::More tests => 10;
    BEGIN { use_ok('HTML::TagParser') };
# ----------------------------------------------------------------
    my $URL1 = "http://search.cpan.org/~kawasaki/";
    my $REX1 = qr/Yusuke/i;
    my $URL2 = "http://www.cpan.org/";
    my $REX2 = qr/Comprehensive/i;
# ----------------------------------------------------------------
    my $FILES = {
        "t/sample/charset-jp-sjis.html" =>  "Shift_JIS",
        "t/sample/charset-jp-euc.html"  =>  "EUC-JP",
        "t/sample/charset-jp-utf8.html" =>  "UTF-8",
    };
# ----------------------------------------------------------------
    &test_japanese();
# ----------------------------------------------------------------
sub test_japanese {
    my $prev;
    foreach my $file ( keys %$FILES ) {
        my $code = $FILES->{$file};
        my $html = HTML::TagParser->new( $file );
        ok( ref $html, "$code open" );
        is( $html->{charset}, $code, "$code charset" );
        my $titletag = $html->getElementsByTagName("title");
        if ( $prev ) {
            is( $titletag->innerText(), $prev, "$code title (match)" );
        } else {
            $prev ||= $titletag->innerText();
            ok( length($prev) > 6, "$code title (length)" );
        }
    }
}
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------
