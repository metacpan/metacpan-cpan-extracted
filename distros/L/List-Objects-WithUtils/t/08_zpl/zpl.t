
BEGIN {
  unless (eval {; require Text::ZPL; 1 } && !$@ ) {
    require Test::More;
    Test::More::plan(skip_all => 
      'these tests require Text::ZPL'
    );
  }
}

use Test::More;
use strict; use warnings FATAL => 'all';

use Text::ZPL;
use List::Objects::WithUtils;


{ my $obj = hash(foo => 'bar');
  ok my $res = encode_zpl($obj), 'encoded hash';
  my $hash = decode_zpl($res);
  is_deeply $hash, +{ foo => 'bar' }, 'round-tripped hash';
}

{ my $obj = hash( foo => hash(bar => 1), bar => array(1,2) );
  ok my $res = encode_zpl($obj), 'encoded (deep) hash';
  my $hash = decode_zpl($res);
  is_deeply 
    $hash, 
    +{
      foo => +{ bar => 1 },
      bar => [ 1, 2 ],
    },
    'round-tripped (deep) hash';
}

done_testing;
