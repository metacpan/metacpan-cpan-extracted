use strict;
use warnings;
use Test::More;
use Loo;

my $dd = Loo->new([{ z => 1, a => 2 }]);
$dd->{use_colour} = 0;

my $ret = $dd
    ->Indent(1)
    ->Pad('> ')
    ->Varname('X')
    ->Terse(0)
    ->Purity(1)
    ->Useqq(1)
    ->Quotekeys(0)
    ->Sortkeys(1)
    ->Maxdepth(0)
    ->Maxrecurse(200)
    ->Pair(' => ')
    ->Trailingcomma(1)
    ->Deepcopy(0)
    ->Freezer('')
    ->Toaster('')
    ->Bless('bless')
    ->Deparse(0)
    ->Sparseseen(1);

is($ret, $dd, 'long chain returns self');
is($dd->Indent, 1, 'indent set');
is($dd->Pad, '> ', 'pad set');
is($dd->Varname, 'X', 'varname set');
is($dd->Purity, 1, 'purity set');
is($dd->Useqq, 1, 'useqq set');
is($dd->Quotekeys, 0, 'quotekeys set');
is($dd->Sortkeys, 1, 'sortkeys set');
is($dd->Maxrecurse, 200, 'maxrecurse set');
is($dd->Trailingcomma, 1, 'trailingcomma set');
is($dd->Sparseseen, 1, 'sparseseen set');

my $out = $dd->Dump;
like($out, qr/^> \$X1/m, 'chain options affect output prefix and varname');
like($out, qr/a => 2/s, 'quotekeys off reflected');

done_testing;
