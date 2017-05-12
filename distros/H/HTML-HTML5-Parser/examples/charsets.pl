use utf8::all;
use HTML::HTML5::Parser;

my $U = HTML::HTML5::Parser->load_html(location => 'examples/html/utf-8.html');
my $X = HTML::HTML5::Parser->load_html(location => 'examples/html/utf-16.html');
my $W = HTML::HTML5::Parser->load_html(location => 'examples/html/iso-8859-15.html');

print "UTF-8...   ",
	$U->getElementsByTagName('p')->[0]->textContent,
	"\t",
	HTML::HTML5::Parser->charset($U),
	"\n";
print "UTF-16..   ",
	$X->getElementsByTagName('p')->[0]->textContent,
	"\t",
	HTML::HTML5::Parser->charset($X),
	"\n";
print "Western... ",
	$W->getElementsByTagName('p')->[0]->textContent,
	"\t",
	HTML::HTML5::Parser->charset($W),
	"\n";
