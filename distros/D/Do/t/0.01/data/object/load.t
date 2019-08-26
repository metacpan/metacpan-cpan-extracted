use strict;
use warnings;
use Test::More;

use Data::Object::Export;
use Scalar::Util 'refaddr';

can_ok 'Data::Object::Export', 'load';
subtest 'test the load function' => sub {
  my $class1 = Data::Object::Export::load('Memoize');
  is $class1, 'Memoize';

  eval { Data::Object::Export::load('Dummy::ZzZzZzZ') };
  like $@, qr{ Can't locate Dummy/ZzZzZzZ.pm };
};

ok 1 and done_testing;
