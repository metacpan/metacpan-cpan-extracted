
use Test::More tests => 2;
use HTML::StickyQuery;
use CGI;

my $s = HTML::StickyQuery->new;
my $q = CGI->new();
$s->sticky(
    file => './t/xhtml.html',
    param => $q,
);

like($s->output, qr/<\?xml version="1.0" encoding="utf-8"\?>/);
like($s->output, qr(<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1\.0 Transitional//EN"));


