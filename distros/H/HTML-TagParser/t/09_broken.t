# ----------------------------------------------------------------
    use strict;
    use Test::More tests => 7;
    BEGIN { use_ok('HTML::TagParser') };
# ----------------------------------------------------------------
    my $SOURCE = <<EOT;
<html>
<body>
    AAA
<p id="foo">
    BBB
    <span>CCC</span>
    DDD
<p id="bar">
    EEE
</p>
    FFF
</div>
    GGG
<div id="hoge">
    HHH
</body>
</html>
EOT
# ----------------------------------------------------------------
    my $html = HTML::TagParser->new( $SOURCE );
    ok( ref $html, "new()" );

    my $body = $html->getElementsByTagName( "body" );
    like( $body->innerText(), qr/AAA.*HHH/s, "body" );

    my $foo = $html->getElementById( "foo" );
    like( $foo->innerText(), qr/BBB.*CCC.*DDD/s, "foo" );

    my $bar = $html->getElementById( "bar" );
    like( $bar->innerText(), qr/EEE/s, "bar" );

    my $div = $html->getElementsByTagName( "div" );
    like( $div->innerText(), qr/HHH/s, "div" );

    my $hoge = $html->getElementById( "hoge" );
    like( $hoge->innerText(), qr/HHH/s, "hoge" );
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------
