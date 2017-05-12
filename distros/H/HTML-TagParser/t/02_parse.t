# ----------------------------------------------------------------
    use strict;
    use Test::More tests => 5;
    BEGIN { use_ok('HTML::TagParser') };
# ----------------------------------------------------------------
    my $SOURCE = <<EOT;
<html>
<head>
<title>Hello, World!</title>
</head>
<body>
World, Hello!
</body>
</html>
EOT
# ----------------------------------------------------------------
    my $html1 = HTML::TagParser->new();
    my $num = $html1->parse( $SOURCE );
    ok( $num, "parse by parse()" );

    my $elemt = $html1->getElementsByTagName( "title" );
    my $title = $elemt->innerText() if ref $elemt;
    is( $title, "Hello, World!", "title" );
# ----------------------------------------------------------------
    my $html2 = HTML::TagParser->new( $SOURCE );
    ok( ref $html2, "parse by new()" );

    my $elemb = $html2->getElementsByTagName( "body" );
    my $body = $elemb->innerText() if ref $elemb;
    is( $body, "World, Hello!", "body" );
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------
