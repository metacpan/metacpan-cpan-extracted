
use Test::More;
use HTML::StickyQuery;
use CGI;

BEGIN{plan tests => 3}

my $s = HTML::StickyQuery->new;
my $q = CGI->new({ foo => ['bar', 'baz'], bar => 'baz'});
$s->sticky(
    file => './t/test.html',
    param => $q
);
like($s->output, qr/foo=bar/);
like($s->output, qr/foo=baz/);
like($s->output, qr/bar=baz/);
