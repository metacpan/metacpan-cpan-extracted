# ----------------------------------------------------------------
    use strict;
    use Test::More tests => 22;
    BEGIN { use_ok('HTML::TagParser') };
# ----------------------------------------------------------------
    my $SOURCE = <<EOT;
<html>
<body>
<p id="foo" class="pomu">AAA</p>
<p name="hoge" width="100%">BBB</p>
<div id="bar" width="100%">CCC</div>
<div name="hoge" class="pomu">DDD</div>
</body>
</html>
EOT
# ----------------------------------------------------------------
    my $html = HTML::TagParser->new( $SOURCE );
    ok( ref $html, "new()" );

    my $ptag1 = $html->getElementsByTagName( "p" );
    my @ptag2 = $html->getElementsByTagName( "p" );
    ok( ref $ptag1, "scalar getElementsByTagName()" );
    is( scalar @ptag2, 2, "array getElementsByTagName()" );
    is( $ptag1->innerText(),    "AAA", "tag 1st" );
    is( $ptag2[1]->innerText(), "BBB", "tag 1nd" );

    my $foo1 = $html->getElementById( "foo" );
    my @foo2 = $html->getElementById( "bar" );
    ok( ref $foo1, "scalar getElementById()" );
    is( scalar @foo2, 1, "array getElementById()" );
    is( $foo1->innerText(),    "AAA", "id 1st" );
    is( $foo2[0]->innerText(), "CCC", "id 2nd" );

    my $hoge1 = $html->getElementsByName( "hoge" );
    my @hoge2 = $html->getElementsByName( "hoge" );
    ok( ref $hoge1, "scalar getElementsByName()" );
    is( scalar @hoge2, 2, "array getElementsByName()" );
    is( $hoge1->innerText(),    "BBB", "name 1st" );
    is( $hoge2[1]->innerText(), "DDD", "name 2nd" );

    my $pomu1 = $html->getElementsByClassName( "pomu" );
    my @pomu2 = $html->getElementsByClassName( "pomu" );
    ok( ref $pomu1, "scalar getElementsByClassName()" );
    is( scalar @pomu2, 2, "array getElementsByClassName()" );
    is( $pomu1->innerText(),    "AAA", "class 1st" );
    is( $pomu2[1]->innerText(), "DDD", "class 2nd" );

    my $width1 = $html->getElementsByAttribute( "width", "100%" );
    my @width2 = $html->getElementsByAttribute( "width", "100%" );
    ok( ref $width1, "scalar getElementsByClassName()" );
    is( scalar @width2, 2, "array getElementsByClassName()" );
    is( $width1->innerText(),    "BBB", "class 1st" );
    is( $width2[1]->innerText(), "CCC", "class 2nd" );
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------
