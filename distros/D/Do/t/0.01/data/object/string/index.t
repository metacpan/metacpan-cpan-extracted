use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::String';
# deprecated
# can_ok 'Data::Object::String', 'index';

use Scalar::Util 'refaddr';

subtest 'test the index method' => sub {
  my $answer;
  my $string = Data::Object::String->new('unexplainable');

  $answer = $string->index('explain');
  is $$answer,    2;                        # 2
  isa_ok $string, 'Data::Object::String';
  isa_ok $answer, 'Data::Object::Number';

  $answer = $string->index('explain', 0);
  is $$answer,    2;                        # 2
  isa_ok $string, 'Data::Object::String';
  isa_ok $answer, 'Data::Object::Number';

  $answer = $string->index('explain', 1);
  is $$answer,    2;                        # 2
  isa_ok $string, 'Data::Object::String';
  isa_ok $answer, 'Data::Object::Number';

  $answer = $string->index('explain', 2);
  is $$answer,    2;                        # 2
  isa_ok $string, 'Data::Object::String';
  isa_ok $answer, 'Data::Object::Number';

  $answer = $string->index('explain', 3);
  is $$answer,    -1;                        # -1
  isa_ok $string, 'Data::Object::String';
  isa_ok $answer, 'Data::Object::Number';

  $answer = $string->index('explained');
  is $$answer,    -1;                        # -1
  isa_ok $string, 'Data::Object::String';
  isa_ok $answer, 'Data::Object::Number';
};

ok 1 and done_testing;
