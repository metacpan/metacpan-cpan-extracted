use Test::More;
use strict; use warnings FATAL => 'all';

my $class = 'IRC::Mode::Set';


use_ok( $class );

my $from_string = new_ok( $class =>
  [
    mode_string => '+o-o+v avenj Joah Gilded',
  ],
);

my $array = $from_string->mode_array;
is_deeply( $array,
  [
    [ '+', 'o', 'avenj' ],
    [ '-', 'o', 'Joah'  ],
    [ '+', 'v', 'Gilded' ],
  ],
  'mode_array looks ok'
) or diag explain $array;

is_deeply(  $from_string->next, 
  [ '+', 'o', 'avenj' ], 
  'next(1) mode looks ok'
);
is_deeply( $from_string->next,
  [ '-', 'o', 'Joah' ],
  'next(2) mode looks ok'
);
is_deeply( $from_string->reset->next,
  [ '+', 'o', 'avenj' ],
  'reset looks ok'
);

my $mobj = $from_string->next(as_object => 1);
isa_ok($mobj, 'IRC::Mode::Single',
  'next(as_object => 1) returned obj'
);

$from_string->reset;

my $from_array = new_ok( $class =>
  [
    mode_array => $array,
  ],
);
my $this_mstr = $from_array->mode_string;
cmp_ok( $this_mstr, 'eq', '+o-o+v avenj Joah Gilded',
  'mode_string looks ok'
);
cmp_ok( $from_array->as_string, 'eq', $this_mstr,
  'as_string alias ok'
);

my $long = new_ok( $class =>
  [
    mode_string => 
      '+o-o+o-o+vv-b avenj avenj Joah Joah Gilded miniCruzer some@mask',
  ],
);

my $expected_long = [
    [ '+', 'o', 'avenj' ],
    [ '-', 'o', 'avenj' ],
    [ '+', 'o', 'Joah'  ],
    [ '-', 'o', 'Joah'  ],
    [ '+', 'v', 'Gilded' ],
    [ '+', 'v', 'miniCruzer' ],
    [ '-', 'b', 'some@mask' ],
];

is_deeply( $long->mode_array, $expected_long,
  'long-string mode_array() looks ok'
) or diag explain $long->mode_array;

my @splitm = $long->split_mode_set(4);
cmp_ok(@splitm, '==', 2, 'split_mode_set spawned 2 sets' )
  or diag explain \@splitm;

cmp_ok($splitm[0]->mode_string, 'eq', '+o-o+o-o avenj avenj Joah Joah',
  'split mode_string 1 looks ok'
);
cmp_ok($splitm[1]->mode_string, 'eq', '+vv-b Gilded miniCruzer some@mask',
  'split mode_string 2 looks ok'
);

my $cloned = $long->clone;
isa_ok( $cloned, 'IRC::Mode::Set', 'clone() returned obj' );
is_deeply( $cloned->mode_array, $expected_long,
  'cloned obj looks ok'
);

my $from_match = $long->clone_from_mode('v');
isa_ok($from_match, $class, 'clone_from_mode returned obj' );
cmp_ok($from_match->mode_string, 'eq', '+vv Gilded miniCruzer', 
  'clone_from_mode mode_string looks ok'
);

$from_match = $long->clone_from_params(qr/Gilded/);
isa_ok($from_match, $class, 'clone_from_params returned obj' );
cmp_ok($from_match->mode_string, 'eq', '+v Gilded',
  'clone_from_params mode_string looks ok'
);

for my $item ($splitm[0]->modes_as_objects) {
  isa_ok($item, 'IRC::Mode::Single')
}

my $funkyopts = IRC::Mode::Set->new(
  mode_string  => '+z-o+mg things stuff',
  param_on_set => 'zg',
  param_always => 't',
);
isa_ok( $funkyopts, $class, 'created obj with weird params' );
is_deeply( $funkyopts->mode_array,
  [
    [ '+', 'z', 'things' ],
    [ '-', 'o' ],
    [ '+', 'm' ],
    [ '+', 'g', 'stuff' ],
  ],
  'obj with weird params looks ok'
);
is_deeply( $funkyopts->params,
  [ 'things', 'stuff' ],
  'params() looks ok'
);

use IRC::Toolkit::Modes 'array_to_mode';
cmp_ok array_to_mode($funkyopts), 'eq', '+z-o+mg things stuff',
  'array_to_mode on IRC::Mode::Set ok';

done_testing;
