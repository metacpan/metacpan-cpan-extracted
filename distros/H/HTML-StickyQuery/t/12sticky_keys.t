
use Test::More tests => 4;
use HTML::StickyQuery;
use CGI;

my $s = HTML::StickyQuery->new;
my $q = CGI->new({ foo => ['bar', 'baz'], bar => 'baz', aaa => 'bbb'});
$s->sticky(
    file => './t/test.html',
    param => $q,
    sticky_keys => [qw(foo aaa)]
);

like($s->output, qr/foo=bar/);
like($s->output, qr/foo=baz/);
like($s->output, qr/aaa=bbb/);
unlike($s->output, qr/bar=baz/);
