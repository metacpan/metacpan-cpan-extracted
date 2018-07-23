
use strict;
use warnings;

use Test::More tests => 4;

use HO::class ();

my $class = 'T::one';

my @args = (_ro => hw => '$', init => 'hash');

{
  local $HO::accessor::class = $class;
  HO::class->import(@args);
}

my $obj;
eval { $obj = T::one->new(hw => 'Hallo Welt!') };

ok(!$@,'constructor call works');
isa_ok($obj,$class);
is($obj->hw,"Hallo Welt!",'accessor works');

eval {
  local $HO::accessor::class = $class;
  HO::class->import(@args);
};

like($@,qr/^HO::accessor::import already called for class T::one\./,
  'second class build throws exception');
