
use Test::More tests => 1;
use HTML::StickyQuery;

# scalarref
open(FILE,"./t/test.html") or die $!;
my $data = join('',<FILE>);
close(FILE);

my $s = HTML::StickyQuery->new;
$s->sticky(
	   scalarref => \$data,
	   param => {SID => 'xxx'}
	   );

like($s->output, qr#<a href="\./test\.cgi\?SID=xxx">#);

