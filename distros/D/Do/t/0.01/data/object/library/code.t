use strict;
use warnings;

use Test::More;
use Test::TypeTiny;

use Data::Object::Utility;
use Data::Object::Library qw(
  CodeObj
  CodeObject
  Object
);

ok_subtype Object, CodeObj;
ok_subtype Object, CodeObject;

my $data1 = sub { };
my $data2 = Data::Object::Utility::Deduce sub { };

should_fail($data1, CodeObj);
should_pass($data2, CodeObj);

should_fail($data1, CodeObject);
should_pass($data2, CodeObject);

ok 1 and done_testing;
