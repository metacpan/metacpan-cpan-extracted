use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Code';
can_ok 'Data::Object::Code', 'dump';

subtest 'test the dump method' => sub {
  my $code = Data::Object::Code->new(sub {1});
  my $dump = $code->dump;
  like $dump, qr/sub.*package.*Data::Object.*goto \$data/;
};

ok 1 and done_testing;
