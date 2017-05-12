
use Test::More tests => 1;
use HTML::StickyQuery;

# file
my $s = HTML::StickyQuery->new;
$s->sticky(
	   file => './t/test.html',
	   param => {SID => 'xxx'}
	   );
like($s->output,qr#<a href="\./test\.cgi\?SID=xxx">#);
