# ----------------------------------------------------------------
    use strict;
    use Test::More tests => 10;
    BEGIN { use_ok('HTML::TagParser') };
# ----------------------------------------------------------------
    my $SOURCE = <<EOT;
<html>
<body>
<div id="quot" title="&quot;&quot;">&quot;&quot;&quot;</span>
<div id="amp" title="&amp;&amp;">&amp;&amp;&amp;</span>
<div id="lt" title="&lt;&lt;">&lt;&lt;&lt;</span>
<div id="gt" title="&gt;&gt;">&gt;&gt;&gt;</span>
</body>
</html>
EOT
# ----------------------------------------------------------------
    my $html = HTML::TagParser->new( $SOURCE );
    ok( ref $html, 'new()' );

    my $amp = $html->getElementById( 'amp' );
    is( $amp->innerText(), '&&&', 'amp text' );
    is( $amp->getAttribute('title'), '&&', 'amp title' );

    my $quot = $html->getElementById( 'quot' );
    is( $quot->innerText(), '"""', 'quot text' );
    is( $quot->getAttribute('title'), '""', 'quot title' );

    my $lt = $html->getElementById( 'lt' );
    is( $lt->innerText(), '<<<', 'lt text' );
    is( $lt->getAttribute('title'), '<<', 'lt title' );

    my $gt = $html->getElementById( 'gt' );
    is( $gt->innerText(), '>>>', 'gt text' );
    is( $gt->getAttribute('title'), '>>', 'gt title' );
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------
