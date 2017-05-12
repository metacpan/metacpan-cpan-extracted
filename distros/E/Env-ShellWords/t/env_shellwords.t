use Test2::Bundle::Extended;
use Env::ShellWords;

subtest 'fetch' => sub {

  local $ENV{FOO} = 'one two\\ two three';

  tie my @FOO, 'Env::ShellWords', 'FOO';
  
  is $FOO[0], 'one';
  is $FOO[1], 'two two';
  is $FOO[2], 'three';

  is \@FOO, ['one', 'two two', 'three'];

};

subtest 'store' => sub {

  local $ENV{FOO} = 'one two\\ two three four five six';

  tie my @FOO, 'Env::ShellWords', 'FOO';

  $FOO[2] = 'three three';
  $FOO[3] = '4';
  
  is $ENV{FOO}, 'one two\\ two three\\ three 4 five six';

  $FOO[7] = 'seven';
  
  is $ENV{FOO}, 'one two\\ two three\\ three 4 five six \'\' seven';

};

subtest 'fetchsize' => sub {

  local $ENV{FOO} = 'one two\\ two three four five six';

  tie my @FOO, 'Env::ShellWords', 'FOO';

  is $#FOO, 5;
};

subtest 'storesize' => sub {

  local $ENV{FOO} = 'one two\\ two three four five six';

  tie my @FOO, 'Env::ShellWords', 'FOO';

  is $#FOO = 7, 7;

  is $ENV{FOO}, 'one two\\ two three four five six \'\' \'\'';
};

subtest 'clear' => sub {

  local $ENV{FOO} = 'one two\\ two three four five six';

  tie my @FOO, 'Env::ShellWords', 'FOO';

  @FOO = ();
  
  is $ENV{FOO}, '';

};

subtest 'push' => sub {

  local $ENV{FOO} = 'one two\\ two three four five six';

  tie my @FOO, 'Env::ShellWords', 'FOO';

  is push(@FOO, 'roger', 'wilco'), 8;;

  is $ENV{FOO}, 'one two\\ two three four five six roger wilco';
};

subtest 'pop' => sub {

  local $ENV{FOO} = 'one two\\ two three four five six';

  tie my @FOO, 'Env::ShellWords', 'FOO';

  is pop(@FOO), 'six';

  is $ENV{FOO}, 'one two\\ two three four five';

  $ENV{FOO} = 'one two\\ two three four five six\\ six';

  is pop(@FOO), 'six six';

  is $ENV{FOO}, 'one two\\ two three four five';

};

subtest 'pop' => sub {

  local $ENV{FOO} = 'one two\\ two three four five six';

  tie my @FOO, 'Env::ShellWords', 'FOO';

  is shift(@FOO), 'one';
  
  is $ENV{FOO}, 'two\\ two three four five six';
  
  is shift(@FOO), 'two two';

  is $ENV{FOO}, 'three four five six';

};

subtest 'unshift' => sub {

  local $ENV{FOO} = 'one two\\ two three four five six';

  tie my @FOO, 'Env::ShellWords', 'FOO';

  is unshift(@FOO, qw( roger wilco )), 8;
  
  is $ENV{FOO}, 'roger wilco one two\\ two three four five six';

  is unshift(@FOO, 'roger wilco'), 9;

  is $ENV{FOO}, 'roger\\ wilco roger wilco one two\\ two three four five six';  

};

subtest 'delete' => sub {

  local $ENV{FOO} = 'one two\\ two three four five six';

  tie my @FOO, 'Env::ShellWords', 'FOO';

  is delete($FOO[1]), 'two two';
  
  is $ENV{FOO}, 'one \'\' three four five six';

};

subtest 'exists' => sub {

  local $ENV{FOO} = 'one two\\ two three four five six';
  
  tie my @FOO, 'Env::ShellWords', 'FOO';

  is exists($FOO[1]), T();
  is exists($FOO[99]), F();
};

subtest 'export' => sub {

  use Env::ShellWords qw( @BAR );

  local $ENV{BAR} = 'one two\\ two three four five six';

  is $BAR[1], 'two two';

};

done_testing;
