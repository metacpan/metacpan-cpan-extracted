#########################

use Test::More tests => 5;
BEGIN { use_ok 'HTML::BBCode'; }

#########################

use strict;

my $bbc = new HTML::BBCode;
isa_ok($bbc, 'HTML::BBCode');

my $text = "[url=http://search.cpan.org/perldoc?HTML::BBCode]HTML::BBCode[/url]";
is($bbc->parse($text), '<a href="http://search.cpan.org/perldoc?HTML%3A%3ABBCode">HTML::BBCode</a>');

$text = "[url=http://search.cpan.org/perldoc?HTML%3A%3ABBCode]HTML::BBCode[/url]";
is($bbc->parse($text), '<a href="http://search.cpan.org/perldoc?HTML%3A%3ABBCode">HTML::BBCode</a>');

$text = "[url=http://search.cpan.org/perldoc?HTML%3A:BBCode]HTML::BBCode[/url]";
is($bbc->parse($text), '<a href="http://search.cpan.org/perldoc?HTML%3A%3ABBCode">HTML::BBCode</a>');
