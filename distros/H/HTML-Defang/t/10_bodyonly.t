#!/usr/bin/perl -w

BEGIN { # CPAN users don't have ME::*, so use eval
  eval 'use ME::FindLibs'
}

use Test::More tests => 4;
use HTML::Defang;

use strict;
use warnings;

my $D = HTML::Defang->new_bodyonly();

my $R = $D->defang(<<'EOF');
<!DOCTYPE html><html><head><meta charset="utf-8"><title>A title</title>
<base href="http://example.com/"></head>
<body bgcolor="#eee"><p>Hello <a href="page.html">there</a></p></body></html>
EOF

unlike($R, qr{<!DOCTYPE|<html|<head|<meta|<body|</body|</html}i, "Document boilerplate removed");
unlike($R, qr{A title}, "Title text removed");
unlike($R, qr{<base}i, "<base> removed");
like($R, qr{<p>Hello <a href="page.html">there</a></p>}, "Body content kept");
