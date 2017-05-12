
use Test::More tests => 1;
use HTML::StickyQuery;

# arrayref
open(FILE,"./t/test.html") or die $!;
my @data = <FILE>;
close(FILE);

my $s = HTML::StickyQuery->new;
$s->sticky(
    arrayref => \@data,
    param => {SID => 'xxx'}
);

like($s->output, qr#<a href="\./test\.cgi\?SID=xxx">#);
