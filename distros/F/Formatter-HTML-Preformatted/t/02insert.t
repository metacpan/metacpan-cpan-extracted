use strict;
use warnings;
use Test::More tests => 7;

use_ok ('Formatter::HTML::Preformatted');


my $data = <<'_EOD_';
This is a test of Formatter::HTML::Preformatted, which can be found at
http://search.cpan.org/dist/Formatter-HTML-Preformatted/
It has been written by http://www.kjetil.kjernsmo.net/ in the hope
it will be useful for someone.
_EOD_

my $fragexpected = <<'_EOD_';
<pre>
This is a test of Formatter::HTML::Preformatted, which can be found at
<a href="http://search.cpan.org/dist/Formatter-HTML-Preformatted/">http://search.cpan.org/dist/Formatter-HTML-Preformatted/</a>
It has been written by <a href="http://www.kjetil.kjernsmo.net/">http://www.kjetil.kjernsmo.net/</a> in the hope
it will be useful for someone.

</pre>
_EOD_



my $docexpected = <<'_EOD_';
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
</head>
<body>
<pre>
This is a test of Formatter::HTML::Preformatted, which can be found at
<a href="http://search.cpan.org/dist/Formatter-HTML-Preformatted/">http://search.cpan.org/dist/Formatter-HTML-Preformatted/</a>
It has been written by <a href="http://www.kjetil.kjernsmo.net/">http://www.kjetil.kjernsmo.net/</a> in the hope
it will be useful for someone.

</pre>

</body>
</html>
_EOD_

my $text = Formatter::HTML::Preformatted->format($data);
isa_ok( $text, 'Formatter::HTML::Preformatted' );

ok($text->fragment eq $fragexpected, 'Fragment comes out as expected');
ok($text->document('iso-8859-1') eq $docexpected, 'Document comes out as expected');

ok(my $links = $text->links, 'Assigning links');


ok(${$links}[0]->{url} eq 'http://search.cpan.org/dist/Formatter-HTML-Preformatted/', 'Link 1');

ok(${$links}[1]->{url} eq 'http://www.kjetil.kjernsmo.net/', 'Link 2');
