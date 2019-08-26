use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Any';
can_ok 'Data::Object::Any', 'detract';

subtest 'test the detract method' => sub {
  my $universal = Data::Object::Any->new(undef);
  is $universal->detract, undef;
};

ok 1 and done_testing;
