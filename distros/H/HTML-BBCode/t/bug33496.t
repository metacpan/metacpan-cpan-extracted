#########################

use Test::More tests => 3;
BEGIN { use_ok 'HTML::BBCode'; }

#########################

use strict;

my $bbc = new HTML::BBCode;
isa_ok($bbc, 'HTML::BBCode');

my $text = "[url=http://ru.wikipedia.org/wiki/%D0%93%D1%80%D0%B5%D0%B1%D0%B5%D0%BD%D1%87%D0%B0%D1%82%D1%8B%D0%B9_%D1%82%D1%80%D0%B8%D1%82%D0%BE%D0%BD]2000 should be enough for everybody[/url]";
is($bbc->parse($text), '<a href="http://ru.wikipedia.org/wiki/%D0%93%D1%80%D0%B5%D0%B1%D0%B5%D0%BD%D1%87%D0%B0%D1%82%D1%8B%D0%B9_%D1%82%D1%80%D0%B8%D1%82%D0%BE%D0%BD">2000 should be enough for everybody</a>');
