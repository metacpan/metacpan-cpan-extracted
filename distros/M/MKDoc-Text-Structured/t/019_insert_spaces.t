use warnings;
use strict;
use Test::More 'no_plan';
use lib ('lib', '../lib');
use MKDoc::Text::Structured::Inline;

my $text;
my $l = 10;

like ('& amp;', '/&[^;]* /');
like ('&a mp;', '/&[^;]* /');
like ('&am p;', '/&[^;]* /');
like ('&amp ;', '/&[^;]* /');
like ('& #247;', '/&[^;]* /');
like ('&# 247;', '/&[^;]* /');
like ('&#2 47;', '/&[^;]* /');
unlike ('a short series of short words', "/\\S\\S{$l}/");
unlike ('some abounding nine letter embodying words', "/\\S\\S{$l}/");
unlike ('some abrogative words of ten abominable letters', "/\\S\\S{$l}/");
like ('some mothproofed words of more than ten agitational letters', "/\\S\\S{$l}/");

$text = "a long url: http://www.example.com/path/to/a/very/very/deep/placed/document/deep/in/the/heirarchy/cgi-bin/foo.cgi?a=b&amp;c=d\n";
$text = MKDoc::Text::Structured::Inline::_insert_spaces ($text, $l);
unlike ($text, '/&[^;]* /');
$text =~ s/&[#[:alnum:]]+;/./g;
unlike ($text, "/\\S\\S{$l}/");

$text = "some looo&gt;&#247;&#247;&#247;&#247;&#247;&#247;&#247;&#247;&#247;&#247;&#247;&#247;&#247;&#247;&#247;&#247;&#247;&#247;&#247;&#247;&#247;&#247;&#247;&#247;&gt;&gt;&gt;&gt;&gt;&gt;&gt;&gt;&gt;&gt;&gt;&gt;&gt;ooooooooooooooooooooooooooooooong words\n";
$text = MKDoc::Text::Structured::Inline::_insert_spaces ($text, $l);
unlike ($text, '/&[^;]* /');
$text =~ s/&[#[:alnum:]]+;/./g;
unlike ($text, "/\\S\\S{$l}/");

$text = "some looo&gt;&gt;&gt;&gt;&gt;&gt;&gt;&gt;&gt;&gt;&gt;&gt;&gt;&gt;ooooooooooooooooooooooooooooooong words\n";
$text = MKDoc::Text::Structured::Inline::_insert_spaces ($text, $l);
unlike ($text, '/&[^;]* /');
$text =~ s/&[#[:alnum:]]+;/./g;
unlike ($text, "/\\S\\S{$l}/");

$text = "some loooo&gt;o&gt;o&gt;o&gt;o&gt;o&gt;o&gt;o&gt;o&gt;o&gt;o&gt;o&gt;o&gt;o&gt;ooooooooooooooooong words\n";
$text = MKDoc::Text::Structured::Inline::_insert_spaces ($text, $l);
unlike ($text, '/&[^;]* /');
$text =~ s/&[#[:alnum:]]+;/./g;
unlike ($text, "/\\S\\S{$l}/");

$text = "some looooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooong woooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooords\n";
$text = MKDoc::Text::Structured::Inline::_insert_spaces ($text, $l);
unlike ($text, '/&[^;]* /');
$text =~ s/&[#[:alnum:]]+;/./g;
unlike ($text, "/\\S\\S{$l}/");


unlike ("<p>telnetters</p>", "/>[^<]*[^<[:space:]][^<[:space:]]{$l}/");
like ("<p>comtelnetters</p>", "/>[^<]*[^<[:space:]][^<[:space:]]{$l}/");

$MKDoc::Text::Structured::Inline::Text = "<p class=\"supercalifragilisticexpialicocioussupercalifragilisticexpialicocioussupercalifragilisticexpialicocioussupercalifragilisticexpialicocioussupercalifragilisticexpialicocioussupercalifragilisticexpialicocious\">Some fantasticallysupercalifragilisticexpialicocioussupercalifragilisticexpialicocioussupercalifragilisticexpialicocioussupercalifragilisticexpialicocioussupercalifragilisticexpialicocious <a href=\"http://www.example.com/some/long/supercalifragilisticexpialicocioussupercalifragilisticexpialicocioussupercalifragilisticexpialicocioussupercalifragilisticexpialicocioussupercalifragilisticexpialicocious/apologetically/wordings/\">http://www.example.com/some/long/supercalifragilisticexpialicocioussupercalifragilisticexpialicocioussupercalifragilisticexpialicocioussupercalifragilisticexpialicocioussupercalifragilisticexpialicocious/apologetically/wordings/</a></p>\n";
$MKDoc::Text::Structured::Inline::LongestWord = $l;
MKDoc::Text::Structured::Inline::_break_long_words ();
unlike ($MKDoc::Text::Structured::Inline::Text, '/&[^;]* /');
$MKDoc::Text::Structured::Inline::Text =~ s/&[#[:alnum:]]+;/./g;
unlike ($MKDoc::Text::Structured::Inline::Text, "/>[^<]*[^<[:space:]][^<[:space:]]{$l}/");

$MKDoc::Text::Structured::Inline::Text = "<p class=\"supercalifragilisticexpialicocioussupercalifragilisticexpialicocioussupercalifragilisticexpialicocioussupercalifragilisticexpialicocioussupercalifragilisticexpialicocioussupercalifragilisticexpialicocious\">Some fantasticallysupercalifragilisticexpialicocioussupercalifragilisticexpialicocioussupercalifragilisticexpialicocioussupercalifragilisticexpialicocioussupercalifragilisticexpialicocious <a href=\"http://www.example.com/some/long/supercalifragilisticexpialicocioussupercalifragilisticexpialicocioussupercalifragilisticexpialicocioussupercalifragilisticexpialicocioussupercalifragilisticexpialicocious/apologetically/wordings/\">http://www.example.com/some/long/supercalifragilisticexpialicocioussupercalifragilisticexpialicocioussupercalifragilisticexpialicocioussupercalifragilisticexpialicocioussupercalifragilisticexpialicocious/apologetically/wordings/</a></p>\n";
$MKDoc::Text::Structured::Inline::LongestWord = 0;
MKDoc::Text::Structured::Inline::_break_long_words ();
like ($MKDoc::Text::Structured::Inline::Text, '/supercalifragilisticexpialicocioussupercalifragilisticexpialicocioussupercalifragilisticexpialicocioussupercalifragilisticexpialicocioussupercalifragilisticexpialicocioussupercalifragilisticexpialicocious\">Some fantasticallysupercalifragilisticexpialicocioussupercalifragilisticexpialicocioussupercalifragilisticexpialicocioussupercalifragilisticexpialicocioussupercalifragilisticexpialicocious/');

1;

__END__
