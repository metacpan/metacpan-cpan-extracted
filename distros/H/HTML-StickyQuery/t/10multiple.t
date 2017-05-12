
use Test::More tests => 2;
use HTML::StickyQuery;

# file
my $s = HTML::StickyQuery->new;
$s->sticky(
    file => './t/test.html',
    param => { SID => ['xxx', 'yyy'] }
);

like($s->output, qr/SID=xxx/);
like($s->output, qr/SID=yyy/);
