use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Hash';

# deprecated
# ok Data::Object::Hash->does('Data::Object::Rule::Collection');
# ok Data::Object::Hash->does('Data::Object::Rule::Comparison');
# ok Data::Object::Hash->does('Data::Object::Rule::Defined');
ok Data::Object::Hash->does('Data::Object::Role::Detract');
ok Data::Object::Hash->does('Data::Object::Role::Dumper');
# deprecated
# ok Data::Object::Hash->does('Data::Object::Rule::List');
ok Data::Object::Hash->does('Data::Object::Role::Output');
ok Data::Object::Hash->does('Data::Object::Role::Throwable');

# deprecated
# can_ok 'Data::Object::Hash', 'clear';
# deprecated
# can_ok 'Data::Object::Hash', 'count';
# deprecated
# can_ok 'Data::Object::Hash', 'data';
# deprecated
# can_ok 'Data::Object::Hash', 'defined';
# deprecated
# can_ok 'Data::Object::Hash', 'delete';
# deprecated
# can_ok 'Data::Object::Hash', 'detract';
# deprecated
# can_ok 'Data::Object::Hash', 'dump';
# deprecated
# can_ok 'Data::Object::Hash', 'each';
# deprecated
# can_ok 'Data::Object::Hash', 'each_key';
# deprecated
# can_ok 'Data::Object::Hash', 'each_n_values';
# deprecated
# can_ok 'Data::Object::Hash', 'each_value';
# deprecated
# can_ok 'Data::Object::Hash', 'empty';
# deprecated
# can_ok 'Data::Object::Hash', 'eq';
# deprecated
# can_ok 'Data::Object::Hash', 'exists';
# deprecated
# can_ok 'Data::Object::Hash', 'filter_exclude';
# deprecated
# can_ok 'Data::Object::Hash', 'filter_include';
# deprecated
# can_ok 'Data::Object::Hash', 'fold';
# deprecated
# can_ok 'Data::Object::Hash', 'ge';
# deprecated
# can_ok 'Data::Object::Hash', 'get';
# deprecated
# can_ok 'Data::Object::Hash', 'grep';
# deprecated
# can_ok 'Data::Object::Hash', 'gt';
# deprecated
# can_ok 'Data::Object::Hash', 'head';
# deprecated
# can_ok 'Data::Object::Hash', 'invert';
# deprecated
# can_ok 'Data::Object::Hash', 'iterator';
# deprecated
# can_ok 'Data::Object::Hash', 'join';
# deprecated
# can_ok 'Data::Object::Hash', 'keys';
# deprecated
# can_ok 'Data::Object::Hash', 'le';
# deprecated
# can_ok 'Data::Object::Hash', 'length';
# deprecated
# can_ok 'Data::Object::Hash', 'list';
# deprecated
# can_ok 'Data::Object::Hash', 'lookup';
# deprecated
# can_ok 'Data::Object::Hash', 'lt';
# deprecated
# can_ok 'Data::Object::Hash', 'map';
# deprecated
# can_ok 'Data::Object::Hash', 'merge';
# deprecated
# can_ok 'Data::Object::Hash', 'ne';
# deprecated
# can_ok 'Data::Object::Hash', 'new';
# deprecated
# can_ok 'Data::Object::Hash', 'pairs';
# deprecated
# can_ok 'Data::Object::Hash', 'print';
# deprecated
# can_ok 'Data::Object::Hash', 'reset';
# deprecated
# can_ok 'Data::Object::Hash', 'reverse';
# deprecated
# can_ok 'Data::Object::Hash', 'roles';
# deprecated
# can_ok 'Data::Object::Hash', 'say';
# deprecated
# can_ok 'Data::Object::Hash', 'set';
# deprecated
# can_ok 'Data::Object::Hash', 'slice';
# deprecated
# can_ok 'Data::Object::Hash', 'sort';
# deprecated
# can_ok 'Data::Object::Hash', 'tail';
# deprecated
# can_ok 'Data::Object::Hash', 'throw';
# deprecated
# can_ok 'Data::Object::Hash', 'type';
# deprecated
# can_ok 'Data::Object::Hash', 'unfold';
# deprecated
# can_ok 'Data::Object::Hash', 'values';

subtest 'test instantiation' => sub {
  my $h0 = Data::Object::Hash->new;
  is_deeply $h0, {};

  eval { Data::Object::Hash->new(1) };
  like $@, qr/Instantiation Error/;

  # argument lists are deprecated
  # my $h1 = Data::Object::Hash->new(1, 2);
  # is_deeply $h1, {1, 2};

  eval { Data::Object::Hash->new(1, 2) };
  like $@, qr/Instantiation Error/;

  my $h2 = Data::Object::Hash->new({1, 2});
  is_deeply $h2, {1, 2};

  my $h3 = Data::Object::Hash->new($h2);
  is_deeply $h3, {1, 2};
};

ok 1 and done_testing;
