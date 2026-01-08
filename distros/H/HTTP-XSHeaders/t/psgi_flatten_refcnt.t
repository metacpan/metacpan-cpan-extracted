use strict;
use warnings;

use Test::More;
use Devel::Peek qw<SvREFCNT>;
use HTTP::XSHeaders;

my $v = 'value';
my $ref = \$v;
my $h = HTTP::XSHeaders->new(foo => $ref);

my $cnt_before = SvREFCNT($v);
{
    my $flat = $h->psgi_flatten;
    my $cnt_during = SvREFCNT($v);
    is($cnt_during, $cnt_before + 1, 'psgi_flatten adds one temporary refcount');
}
my $cnt_after = SvREFCNT($v);
is($cnt_after, $cnt_before, 'psgi_flatten refcount restored');

{
    my $flat = $h->psgi_flatten_without_sort;
    my $cnt_during = SvREFCNT($v);
    is($cnt_during, $cnt_before + 1, 'psgi_flatten_without_sort adds one temporary refcount');
}
$cnt_after = SvREFCNT($v);
is($cnt_after, $cnt_before, 'psgi_flatten_without_sort refcount restored');

done_testing();
