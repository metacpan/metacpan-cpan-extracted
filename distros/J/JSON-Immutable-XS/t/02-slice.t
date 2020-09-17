use 5.020;
use Test::More;
use Test::Deep;

BEGIN {
    use_ok('JSON::Immutable::XS');
}

my $dict = JSON::Immutable::XS->new('t/var/dict/slice.json');

my $res = $dict->get('levels')->slice('goal');
note explain $res;
cmp_deeply $res,
  {
    '1' => 42,
    '2' => undef,
    '3' => {
        'test' => 23
    }
  };

$res = $dict->get('test_arr')->slice('goal');
note explain $res;
cmp_deeply $res,
  [
      42, undef, 'fgd'
  ];


$res = $dict->get('levels_long')->slice('nesty','goal');
note explain $res;
cmp_deeply $res,
  {
    '1' => 42,
    '2' => undef,
    '3' => {
        'test' => 23
    }
  };
note explain $dict->get('levels_long')->slice();
is $dict->get('levels_long')->slice(), undef;

done_testing();
