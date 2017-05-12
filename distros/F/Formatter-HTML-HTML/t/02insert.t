use strict;
use warnings;
use Test::More tests => 7;

use_ok ('Formatter::HTML::HTML');


my $data = <<'_EOD_';
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
<title>Tidy Formatter test</title>
</head>
<body lang="en">
<p>
This is a test of Formatter::HTML::HTML, which can be found at<br>
<a href="http://search.cpan.org/dist/Formatter-HTML-HTML/">CPAN</a>
<p>
It <b>has <i>been</b> written</i> by <a href="http://www.kjetil.kjernsmo.net/">Kjetil <b>Kjernsmo</b></a> in the hope it will be useful for someone.
</body>
</html>
_EOD_

my $fragexpected = <<'_EOD_';

<p>This is a test of Formatter::HTML::HTML, which can be found at<br>
<a href="http://search.cpan.org/dist/Formatter-HTML-HTML/">CPAN</a></p>
<p>It <b>has <i>been</i> written</b> by <a href="http://www.kjetil.kjernsmo.net/">Kjetil <b>Kjernsmo</b></a> in the hope it will be useful for someone.</p>
_EOD_



my $docexpected = <<'_EOD_';
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
"http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
<meta name="generator" content="HTML Tidy for Linux/x86 (vers 12 April 2005), see www.w3.org">
<title>Tidy Formatter test</title>
</head>
<body lang="en">
<p>This is a test of Formatter::HTML::HTML, which can be found at<br>
<a href="http://search.cpan.org/dist/Formatter-HTML-HTML/">CPAN</a></p>
<p>It <b>has <i>been</i> written</b> by <a href="http://www.kjetil.kjernsmo.net/">Kjetil <b>Kjernsmo</b></a> in the hope it will be useful for someone.</p>
</body>
</html>
_EOD_

my $text = Formatter::HTML::HTML->format($data);
isa_ok( $text, 'Formatter::HTML::HTML' );

ok($text->fragment eq $fragexpected, 'Fragment comes out as expected');

TODO: {
  local $TODO = "This currently depends on having the same version of tidy as the developer";
  ok($text->document eq $docexpected, 'Document comes out as expected');
}

ok($text->title eq 'Tidy Formatter test', 'Title is correct');

ok(my $links = $text->links, 'Assigning links');

my $expectedlinks = [
		     {
		      'title' => 'CPAN',
		      'url' => 'http://search.cpan.org/dist/Formatter-HTML-HTML/'
		     },
		     {
		      'title' => 'Kjetil Kjernsmo',
		      'url' => 'http://www.kjetil.kjernsmo.net/'
		     }];

ok(eq_array($expectedlinks, $links), 'All links and titles match');
