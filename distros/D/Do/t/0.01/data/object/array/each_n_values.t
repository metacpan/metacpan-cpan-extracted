use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Array';
# deprecated
# can_ok 'Data::Object::Array', 'each_n_values';

use Scalar::Util 'refaddr';

subtest 'test the each_n_values method' => sub {
  my $array = Data::Object::Array->new(['a' .. 'g']);

  my $values        = [];
  my @argument      = (4, sub { push @{$values}, shift for 1 .. 6; scalar @$values });
  my $each_n_values = $array->each_n_values(@argument);

  # deprecated
  # is refaddr($array), refaddr($each_n_values);

  # updated: return value is a collection
  is_deeply $each_n_values, [6,12];

  is_deeply $values,
    [qw(a b c d), undef, undef, qw(e f g), undef, undef, undef];

  isa_ok $array,         'Data::Object::Array';
  isa_ok $each_n_values, 'Data::Object::Array';
};

ok 1 and done_testing;
