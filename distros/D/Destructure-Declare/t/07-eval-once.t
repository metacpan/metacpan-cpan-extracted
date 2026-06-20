use strict;
use warnings;
use Test::More;
use Destructure::Declare;

# the right-hand side is evaluated exactly once, even with many bindings
my $calls = 0;
sub src { $calls++; return [1, 2, 3, 4] }

let [$a, $b, $c, @rest] = src();
is($calls, 1, 'RHS evaluated exactly once');
is($a, 1, 'a');
is(join(',', $b, $c, @rest), '2,3,4', 'rest of bindings correct');

# nested patterns still only evaluate the source once
$calls = 0;
sub src2 { $calls++; return {pos => [1, 2], tags => ['t']} }
let {pos => [$x, $y], tags => [$t]} = src2();
is($calls, 1, 'nested source evaluated once');
is("$x$y$t", '12t', 'nested bindings');

# RHS with side effects in scalar context
my @log;
sub track { push @log, $_[0]; $_[0] }
let [$v] = [ track('once') ];
is_deeply(\@log, ['once'], 'inner expr ran once');
is($v, 'once', 'value bound');

done_testing;
