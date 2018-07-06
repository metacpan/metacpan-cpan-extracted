#!/usr/bin/perl -w

BEGIN { # CPAN users don't have ME::*, so use eval
  eval 'use ME::FindLibs'
}

use utf8;
use Test::More tests => 19;
use HTML::Defang;
use Encode;
use Devel::Peek;
use strict;

my ($Res, $H);
my ($DefangString, $CommentStartText, $CommentEndText) = ('defang_', ' ', ' ');

#################################
#  Check unicodeness is preserved despite internal non-unicode magic
#################################

my $Defang = HTML::Defang->new(
  tags_to_callback => [ qw(a p) ],
  tags_callback => sub {
    my ($Context, $Defang, $Angle, $Tag, $IsEndTag, $AttributeHash, $AttributesEnd, $HtmlR, $OutR) = @_;
    if ($Tag eq 'a' && !$IsEndTag) {
      ok(Encode::is_utf8(${$AttributeHash->{href}}), "attr is unicode");
      is(${$AttributeHash->{href}}, 'http://blah.com/ø', "attr unicode is correct");
      ${$AttributeHash->{href}} = 'http://blah.com/ø';
      ok(Encode::is_utf8(${$AttributeHash->{href}}), "attr is unicode2");
    } elsif ($Tag eq 'p' && !$IsEndTag) {
      ok(Encode::is_utf8($$HtmlR), "html ref is unicode");
      ok($$HtmlR =~ /\G(?=岡)/gc, "html ref unicode is correct");
    }
    return 1;
  }
);
$H = <<EOF;
<p>岡</p>
<a href="http://blah.com/ø" class="û">non-english href</a>
EOF
ok(Encode::is_utf8($H), "input is unicode");
$Res = $Defang->defang($H);
ok(Encode::is_utf8($Res), "output is unicode");
like($Res, qr{^<!--defang_p-->岡<!--/defang_p-->}, "defang preserves unicode");
like($Res, qr{^<!--defang_a href="http://blah\.com/ø" defang_class="û"-->non-english href<!--/defang_a-->}m, "defang preserves unicode2");
$H = <<EOF;
<p>岡</p>
<a href="http://blah.com/ø" class="&#251;">non-english href</a>
<style>a { color:red&#251;; }</style>
EOF
ok(Encode::is_utf8($H), "input2 is unicode");
$Res = $Defang->defang($H);
ok(Encode::is_utf8($Res), "output2 is unicode");
like($Res, qr{^<!--defang_p-->岡<!--/defang_p-->}, "defang2 preserves unicode");
like($Res, qr{^<!--defang_a href="http://blah\.com/ø" defang_class="û"-->non-english href<!--/defang_a-->}m, "defang2 preserves unicode2");
like($Res, qr(^<style><!--${CommentStartText}a \{ /\*color:redû;\*/ \}${CommentEndText}--></style>)m, "style unicode correct");

