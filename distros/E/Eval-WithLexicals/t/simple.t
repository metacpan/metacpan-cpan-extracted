use strictures 1;
use Test::More;
use Eval::WithLexicals;

my $eval = Eval::WithLexicals->new;

is_deeply(
  [ $eval->eval('my $x; $x++; $x;') ],
  [ 1 ],
  'Basic eval ok'
);

is_deeply(
  $eval->lexicals, { '$x' => \1 },
  'Lexical stored ok'
);

is_deeply(
  [ $eval->eval('$x+1') ],
  [ 2 ],
  'Use lexical ok'
);

is_deeply(
  [ $eval->eval('{ my $x = 0 }; $x') ],
  [ 1 ],
  'Inner scope plus lexical ok'
);

is_deeply(
  [ $eval->eval('{ my $y = 0 }; $x') ],
  [ 1 ],
  'Inner scope and other lexical ok'
);

is_deeply(
  [ keys %{$eval->lexicals} ],
  [ '$x' ],
  'No capture of invisible $y'
);

$eval->eval('my $y = sub { $_[0]+1 }');

is_deeply(
  [ $eval->eval('$y->(2)') ],
  [ 3 ],
  'Sub created ok'
);

done_testing;
