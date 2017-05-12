
BEGIN {
  unless (eval {; require JSON::PP; 1 } && !$@ ) {
    require Test::More;
    Test::More::plan(skip_all => 
      'these tests require JSON::PP'
    );
  }
}

use Test::More;
use strict; use warnings FATAL => 'all';

use JSON::PP;
use List::Objects::WithUtils;

my $js = JSON::PP->new;
$js->convert_blessed(1);

{ my $obj = array(1,2,3);
  ok my $res = $js->encode($obj), 'encoded array';
  my $arr = $js->decode($res);
  is_deeply $arr, [ 1, 2, 3 ], 'round-tripped array';
}

{ my $obj = immarray(1,2,3);
  ok my $res = $js->encode($obj), 'encoded immarray';
  my $arr = $js->decode($res);
  is_deeply $arr, [ 1, 2, 3 ], 'round-tripped immarray';
}

{ my $obj = array( 1, 2, array(3, 4) );
  ok my $res = $js->encode($obj), 'encoded (deep) array';
  my $arr = $js->decode($res);
  is_deeply $arr, [ 1, 2, [ 3, 4 ] ], 'round-tripped (deep) array';
}

{ my $obj = hash(foo => 'bar');
  ok my $res = $js->encode($obj), 'encoded hash';
  my $hash = $js->decode($res);
  is_deeply $hash, +{ foo => 'bar' }, 'round-tripped hash';
}

{ my $obj = hash( foo => hash(bar => 1), bar => array(1,2) );
  ok my $res = $js->encode($obj), 'encoded (deep) hash';
  my $hash = $js->decode($res);
  is_deeply 
    $hash, 
    +{
      foo => +{ bar => 1 },
      bar => [ 1, 2 ],
    },
    'round-tripped (deep) hash';
}

done_testing;
