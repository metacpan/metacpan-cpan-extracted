#!perl -T

use Test::More tests => 6;
use HTML::WikiConverter::Normalizer;
use HTML::TreeBuilder;

is(
  normalize('<p><font style="font-style:italic;font-weight:bold">text</font></p>'),
            '<p><font><b><i>text</i></b></font></p>',
            'bold italic'
);

is(
  normalize('<p><span style="font-style: italic;">asdf</span><span style="font-style: italic;">asdf</span></p>'),
            '<p><span><i>asdf</i></span><span><i>asdf</i></span></p>',
            'multiple italic'
);

is(
  normalize('<span style="color:#ccc">text</span>'),
            '<span><font color="#ccc">text</font></span>',
            'font color'
);

is(
  normalize('<div align="center">text</div>'),
            '<div><center>text</center></div>',
            'center'
);

is(
  normalize('<p style="font-weight:bold">text</p>'),
            '<p><b>text</b></p>',
            'bold within para'
);

is(
  normalize('<span style="font-family: Symbol;">text</span>'),
            '<span><font face="Symbol">text</font></span>',
            'font-family'
);

sub normalize {
  my $html = shift;

  my $tree = new HTML::TreeBuilder();
  $tree->parse($html);

  my $norm = new HTML::WikiConverter::Normalizer();
  $norm->normalize($tree);

  $tree->deobjectify_text();
  chomp( my $dumped_html = $tree->as_HTML(undef, '', {}) );

  $dumped_html =~ s~^<html><head></head><body>~~;
  $dumped_html =~ s~</body></html>$~~;

  return $dumped_html;
}
