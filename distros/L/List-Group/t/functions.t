use Test::More qw[no_plan];
use Test::Deep;
BEGIN {
  use_ok 'List::Group', qw[group];
}

can_ok 'main', 'group';

my @list = qw[
  mouse rat cat dog lion bear rhino elephant giraffe
];

my @two_cols = (
  [ 'mouse', 'rat' ],
  [ 'cat', 'dog' ],
  [ 'lion', 'bear' ],
  [ 'rhino', 'elephant' ],
  [ 'giraffe' ]
);

my @two_rows = (
  [ qw[mouse rat cat dog lion] ],
  [ qw[bear rhino elephant giraffe] ],
);

cmp_deeply( [group \@list, cols => 2], \@two_cols );
cmp_deeply( [group \@list, rows => 2], \@two_rows );

