use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Array';

# deprecated
# ok Data::Object::Array->does('Data::Object::Rule::Collection');
# ok Data::Object::Array->does('Data::Object::Rule::Comparison');
# ok Data::Object::Array->does('Data::Object::Rule::Defined');
ok Data::Object::Array->does('Data::Object::Role::Detract');
ok Data::Object::Array->does('Data::Object::Role::Dumper');
# deprecated
# ok Data::Object::Array->does('Data::Object::Rule::List');
ok Data::Object::Array->does('Data::Object::Role::Output');
ok Data::Object::Array->does('Data::Object::Role::Throwable');

# deprecated
# can_ok 'Data::Object::Array', 'all';
# deprecated
# can_ok 'Data::Object::Array', 'any';
# deprecated
# can_ok 'Data::Object::Array', 'clear';
# deprecated
# can_ok 'Data::Object::Array', 'count';
# deprecated
# can_ok 'Data::Object::Array', 'data';
# deprecated
# can_ok 'Data::Object::Array', 'defined';
# deprecated
# can_ok 'Data::Object::Array', 'delete';
# deprecated
# can_ok 'Data::Object::Array', 'detract';
# deprecated
# can_ok 'Data::Object::Array', 'dump';
# deprecated
# can_ok 'Data::Object::Array', 'each';
# deprecated
# can_ok 'Data::Object::Array', 'each_key';
# deprecated
# can_ok 'Data::Object::Array', 'each_n_values';
# deprecated
# can_ok 'Data::Object::Array', 'each_value';
# deprecated
# can_ok 'Data::Object::Array', 'empty';
# deprecated
# can_ok 'Data::Object::Array', 'eq';
# deprecated
# can_ok 'Data::Object::Array', 'exists';
# deprecated
# can_ok 'Data::Object::Array', 'first';
# deprecated
# can_ok 'Data::Object::Array', 'ge';
# deprecated
# can_ok 'Data::Object::Array', 'get';
# deprecated
# can_ok 'Data::Object::Array', 'grep';
# deprecated
# can_ok 'Data::Object::Array', 'gt';
# deprecated
# can_ok 'Data::Object::Array', 'hash';
# deprecated
# can_ok 'Data::Object::Array', 'hashify';
# deprecated
# can_ok 'Data::Object::Array', 'head';
# deprecated
# can_ok 'Data::Object::Array', 'invert';
# deprecated
# can_ok 'Data::Object::Array', 'iterator';
# deprecated
# can_ok 'Data::Object::Array', 'join';
# deprecated
# can_ok 'Data::Object::Array', 'keyed';
# deprecated
# can_ok 'Data::Object::Array', 'keys';
# deprecated
# can_ok 'Data::Object::Array', 'last';
# deprecated
# can_ok 'Data::Object::Array', 'le';
# deprecated
# can_ok 'Data::Object::Array', 'length';
# deprecated
# can_ok 'Data::Object::Array', 'list';
# deprecated
# can_ok 'Data::Object::Array', 'lt';
# deprecated
# can_ok 'Data::Object::Array', 'map';
# deprecated
# can_ok 'Data::Object::Array', 'max';
# deprecated
# can_ok 'Data::Object::Array', 'min';
# deprecated
# can_ok 'Data::Object::Array', 'ne';
# deprecated
# can_ok 'Data::Object::Array', 'new';
# deprecated
# can_ok 'Data::Object::Array', 'none';
# deprecated
# can_ok 'Data::Object::Array', 'nsort';
# deprecated
# can_ok 'Data::Object::Array', 'one';
# deprecated
# can_ok 'Data::Object::Array', 'pairs';
# deprecated
# can_ok 'Data::Object::Array', 'pairs_array';
# deprecated
# can_ok 'Data::Object::Array', 'pairs_hash';
# deprecated
# can_ok 'Data::Object::Array', 'part';
# deprecated
# can_ok 'Data::Object::Array', 'pop';
# deprecated
# can_ok 'Data::Object::Array', 'print';
# deprecated
# can_ok 'Data::Object::Array', 'push';
# deprecated
# can_ok 'Data::Object::Array', 'random';
# deprecated
# can_ok 'Data::Object::Array', 'reverse';
# deprecated
# can_ok 'Data::Object::Array', 'rnsort';
# deprecated
# can_ok 'Data::Object::Array', 'roles';
# deprecated
# can_ok 'Data::Object::Array', 'rotate';
# deprecated
# can_ok 'Data::Object::Array', 'rsort';
# deprecated
# can_ok 'Data::Object::Array', 'say';
# deprecated
# can_ok 'Data::Object::Array', 'set';
# deprecated
# can_ok 'Data::Object::Array', 'shift';
# deprecated
# can_ok 'Data::Object::Array', 'size';
# deprecated
# can_ok 'Data::Object::Array', 'slice';
# deprecated
# can_ok 'Data::Object::Array', 'sort';
# deprecated
# can_ok 'Data::Object::Array', 'sum';
# deprecated
# can_ok 'Data::Object::Array', 'tail';
# deprecated
# can_ok 'Data::Object::Array', 'throw';
# deprecated
# can_ok 'Data::Object::Array', 'type';
# deprecated
# can_ok 'Data::Object::Array', 'unique';
# deprecated
# can_ok 'Data::Object::Array', 'unshift';
# deprecated
# can_ok 'Data::Object::Array', 'values';

subtest 'test instantiation' => sub {
  my $a0 = Data::Object::Array->new;
  is_deeply $a0, [];

  eval { Data::Object::Array->new(1) };
  like $@, qr/Instantiation Error/;

  # argument lists are deprecated
  # my $a1 = Data::Object::Array->new(1, 2);
  # is_deeply $a1, [1, 2];

  eval { Data::Object::Array->new(1, 2) };
  like $@, qr/Instantiation Error/;

  my $a2 = Data::Object::Array->new([1, 2]);
  is_deeply $a2, [1, 2];

  my $a3 = Data::Object::Array->new($a2);
  is_deeply $a3, [1, 2];
};

ok 1 and done_testing;
