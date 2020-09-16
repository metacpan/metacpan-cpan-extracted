#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use Iterator::Records;
use Data::Dumper;

my $i = Iterator::Records->new([[1, 2], [3, 4]], ['field1', 'field2']);

my $load = $i->load(1);
is_deeply ($load, [[1, 2]], "limited load");
$load = $i->load();
is_deeply ($load, [[1, 2], [3, 4]], "full load");

my $iter = $i->report ("%.1f - %d");
my $ret = $iter->();
is ($ret, "1.0 - 2", "report line 0");
$ret = $iter->();
is ($ret, "3.0 - 4", "report line 1");
$ret = $iter->();
ok (not defined $ret);

# Now let's load an iterator that requires parameters.
sub foo {
  my $max = shift;
  my $i = 0;
  sub {
    return if $i > $max;
    return [$i++, $max-$i+1];
  }
}
$i = Iterator::Records->new(\&foo, ['count', 'remaining']);
is_deeply ($i->load_parms(2), [[0, 2], [1, 1], [2, 0]]);
is_deeply ($i->load_lparms(2, 2), [[0, 2], [1, 1]]);

# And load an iterator that's already been started.
$iter = $i->iter(1);
is_deeply ($i->load_iter($iter), [[0, 1], [1, 0]]);

done_testing ();
