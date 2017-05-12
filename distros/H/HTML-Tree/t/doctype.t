#!/usr/bin/perl -T

use warnings;
use strict;
use Test::More tests => 4;

use HTML::TreeBuilder;

my $html = <<'EOHTML';
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
"http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
</head>
<body>
blah blah
</body>
</html>
EOHTML

WITH_DECLARATION: {    # Check default state
    my $tree = HTML::TreeBuilder->new;
    isa_ok( $tree, "HTML::TreeBuilder" );

    $tree->parse($html);
    $tree->eof;

    my @lines = split( "\n", $tree->as_HTML( undef, " " ) );

    like( $lines[0], qr/DOCTYPE/, "DOCTYPE is in the first line" );
}

WITHOUT_DECLARATION: {
    my $tree = HTML::TreeBuilder->new;
    isa_ok( $tree, "HTML::TreeBuilder" );

    $tree->store_declarations(0);

    $tree->parse($html);
    $tree->eof;

    my @lines = split( "\n", $tree->as_HTML( undef, " " ) );

    unlike( $lines[0], qr/DOCTYPE/, "DOCTYPE is NOT in the first line" );
}
