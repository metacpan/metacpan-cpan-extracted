#!/usr/bin/perl -w

BEGIN { # CPAN users don't have ME::*, so use eval
  eval 'use ME::FindLibs'
}

use Test::More tests => 33;
use HTML::Defang;
use strict;

# Tests taken from http://imfo.ru/csstest/css_hacks/import.php

my ($Res, $H);
my ($DefangString, $CommentStartText, $CommentEndText) = ('defang_', ' ', ' ');

my $Defang = HTML::Defang->new();

$H = <<EOF;
<style>\@import url(&#34;style.css&#34;);</style>
EOF
$Res = $Defang->defang($H);
like($Res, qr{^<style><!--${CommentStartText}${CommentEndText}--></style>$}, "Test 1");

$H = <<EOF;
<style>\@import url(style.css);</style>
EOF
$Res = $Defang->defang($H);
like($Res, qr{^<style><!--${CommentStartText}${CommentEndText}--></style>$}, "Test 2");

$H = <<EOF;
<style>\@import &#34;style.css&#34;;</style>
EOF
$Res = $Defang->defang($H);
like($Res, qr{^<style><!--${CommentStartText}${CommentEndText}--></style>$}, "Test 3");

$H = <<EOF;
<style>\@import url(&#34;style.css&#34;) all;</style>
EOF
$Res = $Defang->defang($H);
like($Res, qr{^<style><!--${CommentStartText}${CommentEndText}--></style>$}, "Test 4");

$H = <<EOF;
<style>\@import url(&#34;&#38;#115;tyle.css&#34;);</style>
EOF
$Res = $Defang->defang($H);
like($Res, qr{^<style><!--${CommentStartText}${CommentEndText}--></style>$}, "Test 5");

$H = <<EOF;
<style>&#38;#64;import url(&#34;style.css&#34;);</style>
EOF
$Res = $Defang->defang($H);
like($Res, qr{^<style><!--${CommentStartText}${CommentEndText}--></style>$}, "Test 6");

$H = <<EOF;
<style>\@import url(&#34;style.%63ss&#34;);</style>
EOF
$Res = $Defang->defang($H);
like($Res, qr{^<style><!--${CommentStartText}${CommentEndText}--></style>$}, "Test 7");

$H = <<EOF;
<style>\@import/**/&#34;style.css&#34;;</style>
EOF
$Res = $Defang->defang($H);
like($Res, qr{^<style><!--${CommentStartText}${CommentEndText}--></style>$}, "Test 8");

$H = <<EOF;
<style>\@import &#34;style.css&#34;/**/;</style>
EOF
$Res = $Defang->defang($H);
like($Res, qr{^<style><!--${CommentStartText}${CommentEndText}--></style>$}, "Test 9");

$H = <<EOF;
<style>\@import url(/**/&#34;style.css&#34;);</style>
EOF
$Res = $Defang->defang($H);
like($Res, qr{^<style><!--${CommentStartText}${CommentEndText}--></style>$}, "Test 10");

$H = <<EOF;
<style>\@imp\6F rt url(&#34;style.css&#34;);</style>
EOF
$Res = $Defang->defang($H);
like($Res, qr{^<style><!--${CommentStartText}${CommentEndText}--></style>$}, "Test 11");

$H = <<EOF;
<style>\@import\**\&#34;style.css&#34;;</style>
EOF
$Res = $Defang->defang($H);
like($Res, qr{^<style><!--${CommentStartText}${CommentEndText}--></style>$}, "Test 12");

$H = <<EOF;
<style>\@im\\port url(&#34;style.css&#34;);</style>
EOF
$Res = $Defang->defang($H);
like($Res, qr{^<style><!--${CommentStartText}${CommentEndText}--></style>$}, "Test 13");

$H = <<EOF;
<style>\@import\ url(&#34;style.css&#34;);</style>
EOF
$Res = $Defang->defang($H);
like($Res, qr{^<style><!--${CommentStartText}${CommentEndText}--></style>$}, "Test 14");

$H = <<EOF;
<style>\@import_url(&#34;style.css&#34;);</style>
EOF
$Res = $Defang->defang($H);
like($Res, qr{^<style><!--${CommentStartText}${CommentEndText}--></style>$}, "Test 15");

$H = <<EOF;
<style>\@import &#34;style.css&#34;;</style>
EOF
$Res = $Defang->defang($H);
like($Res, qr{^<style><!--${CommentStartText}${CommentEndText}--></style>$}, "Test 16");

$H = <<EOF;
<style> \@import &#34;style.css&#34;;</style>
EOF
$Res = $Defang->defang($H);
like($Res, qr{^<style><!--${CommentStartText}${CommentEndText}--></style>$}, "Test 17");

$H = <<EOF;
<style>\@import &#34;style.css&#34; ;</style>
EOF
$Res = $Defang->defang($H);
like($Res, qr{^<style><!--${CommentStartText}${CommentEndText}--></style>$}, "Test 18");

$H = <<EOF;
<style>\@import url (&#34;style.css&#34;);</style>
EOF
$Res = $Defang->defang($H);
like($Res, qr{^<style><!--${CommentStartText}${CommentEndText}--></style>$}, "Test 19");

$H = <<EOF;
<style>\@import: url(&#34;style.css&#34;);</style>
EOF
$Res = $Defang->defang($H);
like($Res, qr{^<style><!--${CommentStartText}${CommentEndText}--></style>$}, "Test 20");

$H = <<EOF;
<style>\@ import url(&#34;style.css&#34;);</style>
EOF
$Res = $Defang->defang($H);
like($Res, qr{^<style><!--${CommentStartText}${CommentEndText}--></style>$}, "Test 21");

$H = <<EOF;
<style>\@import url (&#34;style.css&#34;);</style>
EOF
$Res = $Defang->defang($H);
like($Res, qr{^<style><!--${CommentStartText}${CommentEndText}--></style>$}, "Test 22");

$H = <<EOF;
<style>\@import style.css;</style>
EOF
$Res = $Defang->defang($H);
like($Res, qr{^<style><!--${CommentStartText}${CommentEndText}--></style>$}, "Test 23");

$H = <<EOF;
<style>_\@import &#34;style.css&#34;;</style>
EOF
$Res = $Defang->defang($H);
like($Res, qr{^<style><!--${CommentStartText}${CommentEndText}--></style>$}, "Test 24");

$H = <<EOF;
<style>\@import url(&#34;style.css&#34;)_;</style>
EOF
$Res = $Defang->defang($H);
like($Res, qr{^<style><!--${CommentStartText}${CommentEndText}--></style>$}, "Test 25");

$H = <<EOF;
<style>em{color:red};\@import url(&#34;style.css&#34;);</style>
EOF
$Res = $Defang->defang($H);
like($Res, qr{^<style><!--${CommentStartText}em{color:red}${CommentEndText}--></style>$}, "Test 26");

$H = <<EOF;
<style>\@import url(&#34;style.css&#34;);</style>
EOF
$Res = $Defang->defang($H);
like($Res, qr{^<style><!--${CommentStartText}${CommentEndText}--></style>$}, "Test 27");

$H = <<EOF;
<style>\@import url\ (&#34;style.css&#34;);</style>
EOF
$Res = $Defang->defang($H);
like($Res, qr{^<style><!--${CommentStartText}${CommentEndText}--></style>$}, "Test 28");

$H = <<EOF;
<style>\@import ur\6C (&#34;style.css&#34;);</style>
EOF
$Res = $Defang->defang($H);
like($Res, qr{^<style><!--${CommentStartText}${CommentEndText}--></style>$}, "Test 29");

$H = <<EOF;
<style>\@import(style.css);</style>
EOF
$Res = $Defang->defang($H);
like($Res, qr{^<style><!--${CommentStartText}${CommentEndText}--></style>$}, "Test 30");

$H = <<EOF;
<style>\@import url(&#34;style.\63 ss&#34;);</style>
EOF
$Res = $Defang->defang($H);
like($Res, qr{^<style><!--${CommentStartText}${CommentEndText}--></style>$}, "Test 31");

$H = <<EOF;
<style>\@import url(&#34;style.css&#34;);</style>
EOF
$Res = $Defang->defang($H);
like($Res, qr{^<style><!--${CommentStartText}${CommentEndText}--></style>$}, "Test 32");

$H = <<EOF;
<style>\@import url(&#34;style.\css&#34;);</style>
EOF
$Res = $Defang->defang($H);
like($Res, qr{^<style><!--${CommentStartText}${CommentEndText}--></style>$}, "Test 33");

