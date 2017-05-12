
use Test::More tests => 1;
use HTML::StickyQuery;

my $s = HTML::StickyQuery->new(
			       regexp => '^/cgi-bin/'
			      );
$s->sticky(
	    file => './t/test3.html',
	    param => {SID => 'xxx'}
	   );
is($s->output,
   '<a href="./test.cgi?foo=bar"><a href="/cgi-bin/test.cgi?SID=xxx">');
