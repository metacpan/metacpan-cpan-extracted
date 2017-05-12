
use Test::More tests => 2;
use HTML::StickyQuery;

my $s = HTML::StickyQuery->new;
$s->sticky(
    file => 't/test6.html',
    param => {a => 'xxx'}
);
like($s->output, qr/<!DOCTYPE/);
like($s->output, qr/<!-- foobar -->/);


