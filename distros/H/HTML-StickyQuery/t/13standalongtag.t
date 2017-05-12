
use Test::More tests => 1;
use HTML::StickyQuery;
use CGI;

my $s = HTML::StickyQuery->new;
my $q = CGI->new();
$s->sticky(
    file => './t/standalone.html',
    param => $q,
);

unlike($s->output, qr/z="z"/);

