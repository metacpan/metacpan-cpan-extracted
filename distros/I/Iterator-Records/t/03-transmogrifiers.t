#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use Iterator::Records;
use Data::Dumper;

my $i = Iterator::Records->new([[1, 2], [3, 4]], ['field1', 'field2']);

my $where = $i->where (sub {$_[0] == 3}, 'field1');
is_deeply ($where->fields(), ['field1', 'field2'], "check where field list");
my $ii = $where->iter();
is_deeply ($where->load(), [[3, 4]], "check where results");

my $select = $i->select ('field2');
is_deeply($select->fields(), ['field2'], "check select field list");
is_deeply($select->load(), [[2], [4]], "check select results");

my $calc = $i->calc (sub { $_[0] + $_[1] }, 'total', 'field1', 'field2');
is_deeply($calc->fields(), ['field1', 'field2', 'total'], "check calc field list");
is_deeply($calc->load(), [[1, 2, 3], [3, 4, 7]], "check calc results");

my $fixup = $i->fixup (sub { $_[0] + $_[1] }, 'field2', 'field1', 'field2');
is_deeply($fixup->fields(), ['field1', 'field2'], "check fixup field list");
is_deeply($fixup->load(), [[1, 3], [3, 7]], "check fixup results");

my $dedupe = $i->dedupe ('field1');
is_deeply ($dedupe->fields(), ['field1', 'field2'], "check dedupe field list");
is_deeply ($dedupe->load(), [[1, 2], [3, 4]], 'check dedupe results without dupe');

$i = Iterator::Records->new([[1, 2], [1, 8], [3, 4]], ['field1', 'field2']);
$dedupe = $i->dedupe ('field1');
is_deeply ($dedupe->fields(), ['field1', 'field2'], "check dedupe field list");
is_deeply ($dedupe->load(), [[1, 2], ['', 8], [3, 4]], 'check dedupe results with dupe');

# Now let's try a bigger one.

my $c = $i->transmogrify ( ['calc',   sub { $_[0] + $_[1] }, 'total', 'field1', 'field2'],
                            ['select', 'field2', 'total', 'field1'],
                            ['where',  sub { $_[0] < 3 }, 'field1'],
                            ['rename', 'field1', 'x', 'field2', 'y'] );
                            
is_deeply ($c->fields(), ['y', 'total', 'x'], "check compound field list");
is_deeply ($c->load(), [[2, 3, 1], [8, 9, 1]]);
is_deeply ($c->load(), [[2, 3, 1], [8, 9, 1]]);

# Now let's verify that we croak on an unknown transmogrifier.

ok (not eval { $c = $i->transmogrify ( ['wrong_thing', 'blah', 'blah'] ); }); 
like ($@, qr/Unknown transmogrifier 'wrong_thing'/, 'error message identifies unknown transmogrifer');

# And let's also verify that we croak on an unknown field in a known transmogrifier.

ok (not eval { $c = $i->transmogrify ( ['calc',   sub { $_[0] + $_[1] }, 'total', 'field1', 'foo'] ); }); 
like ($@, qr/Unknown field 'foo'/, 'error message identifies unknown field');

# New transmogrifiers 2019-02-23 - gethashval, count, limit.
sub make_counter {
   my $count = shift() - 1;
   sub {
      $count += 1;
      { count => $count };
   }
}

$i = Iterator::Records->new ([['a'], ['b'], ['c'], ['d']], ['letter']);
$c = $i->transmogrify ( ['calc', make_counter(1), 'value_hash'],
                         ['gethashval', 'value_hash', 'count'],
                         ['select', 'letter', 'count'],
                       );
is_deeply ($c->load(), [['a', 1], ['b', 2], ['c', 3], ['d', 4]], 'gethashval test');


# New transmogrifier 'count' (basically what we just did for gethashval)
$i = Iterator::Records->new ([['a'], ['b'], ['c'], ['d']], ['letter']);
$c = $i->transmogrify ( ['count', 'counter', 1] );
is_deeply ($c->load(), [['a', 1], ['b', 2], ['c', 3], ['d', 4]], 'counter test');

# New transmogrifier 'limit'
$i = Iterator::Records->new ([['a'], ['b'], ['c'], ['d']], ['letter']);
$c = $i->transmogrify ( ['limit', 2] );
is_deeply ($c->load(), [['a'], ['b']], 'limit test');
is_deeply ($c->load(), [['a'], ['b']], 'limit test');  # Look, it works twice!


# New transmogrifier 'walk' (the machinery for walking a tree)
sub testwalker {
   my ($fields, $newfields, $infields, $offsets) = @_; # We're not actually going to use any of these, but just for the purposes of documentation, this is what we'll see.
   sub {
      my $rec = shift;
      if ($rec->[0] eq 'c') {
         return ([0, @$rec], [1, @$rec]);
      }
      [0, @$rec];
   };
}

$i = Iterator::Records->new ([['a'], ['b'], ['c'], ['d']], ['letter']);
$c = $i->transmogrify ( ['walk', \&testwalker, ['level'], 'letter'] );
#diag (Dumper($c->load()));
is_deeply ($c->load(), [[0, 'a'], [0, 'b'], [0, 'c'], [1, 'c'], [0, 'd']]);

# Now let's try it with a subiterator.
sub testwalker2 {
   my ($fields, $newfields, $infields, $offsets) = @_;
   sub {
      my $rec = shift;
      if ($rec->[0] eq 'c') {
         return ([0, @$rec], Iterator::Records->new ([[1, 'e'], [1, 'f']], ['level', 'letter']));
      }
      [0, @$rec];
   };
}

$i = Iterator::Records->new ([['a'], ['b'], ['c'], ['d']], ['letter']);
$c = $i->transmogrify ( ['walk', \&testwalker2, ['level'], 'letter'] );
#diag (Dumper($c->load()));
is_deeply ($c->load(), [[0, 'a'], [0, 'b'], [0, 'c'], [1, 'e'], [1, 'f'], [0, 'd']]);


done_testing();

