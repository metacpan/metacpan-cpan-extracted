use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

call

=usage

  # given sub { (shift // 0) + 1 }

  $code->call; # 1
  $code->call(0); # 1
  $code->call(1); # 2
  $code->call(2); # 3

=description

The call method executes and returns the result of the code. This method returns
a data type object to be determined after execution.

=signature

call(Any $arg1) : Any

=type

method

=cut

# TESTING

use_ok 'Data::Object::Code';

my $data = Data::Object::Code->new(sub { (shift // 0) + 1 });

is_deeply $data->call(), 1;

is_deeply $data->call(0), 1;

is_deeply $data->call(1), 2;

is_deeply $data->call(2), 3;

ok 1 and done_testing;
