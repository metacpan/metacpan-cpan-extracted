#!perl

use strict;
use warnings;

use Math::Matrix;
use Test::More tests => 1096;

my $x;

# 2-by-3 matrix

note(<<'EOF');
$x = Math::Matrix -> new([[1, 2, 3],
                          [4, 5, 6]]);
EOF

$x = Math::Matrix -> new([[1, 2, 3],
                          [4, 5, 6]]);

cmp_ok($x -> is_empty(),         '==', 0, '$x -> is_empty()');
cmp_ok($x -> is_scalar(),        '==', 0, '$x -> is_scalar()');
cmp_ok($x -> is_vector(),        '==', 0, '$x -> is_vector()');
cmp_ok($x -> is_row(),           '==', 0, '$x -> is_row()');
cmp_ok($x -> is_col(),           '==', 0, '$x -> is_col()');
cmp_ok($x -> is_square(),        '==', 0, '$x -> is_square()');
cmp_ok($x -> is_symmetric(),     '==', 0, '$x -> is_symmetric()');
cmp_ok($x -> is_antisymmetric(), '==', 0, '$x -> is_antisymmetric()');
cmp_ok($x -> is_persymmetric(),  '==', 0, '$x -> is_persymmetric()');
cmp_ok($x -> is_hankel(),        '==', 0, '$x -> is_hankel()');
cmp_ok($x -> is_zero(),          '==', 0, '$x -> is_zero()');
cmp_ok($x -> is_one(),           '==', 0, '$x -> is_one()');
cmp_ok($x -> is_constant(),      '==', 0, '$x -> is_constant()');
cmp_ok($x -> is_identity(),      '==', 0, '$x -> is_identity()');
cmp_ok($x -> is_exchg(),         '==', 0, '$x -> is_exchg()');
cmp_ok($x -> is_bool(),          '==', 0, '$x -> is_bool()');
cmp_ok($x -> is_perm(),          '==', 0, '$x -> is_perm()');
cmp_ok($x -> is_int(),           '==', 1, '$x -> is_int()');
cmp_ok($x -> is_diag(),          '==', 0, '$x -> is_diag()');
cmp_ok($x -> is_adiag(),         '==', 0, '$x -> is_adiag()');
cmp_ok($x -> is_tridiag(),       '==', 0, '$x -> is_tridiag()');
cmp_ok($x -> is_atridiag(),      '==', 0, '$x -> is_atridiag()');
cmp_ok($x -> is_pentadiag(),     '==', 0, '$x -> is_pentadiag()');
cmp_ok($x -> is_apentadiag(),    '==', 0, '$x -> is_apentadiag()');
cmp_ok($x -> is_heptadiag(),     '==', 0, '$x -> is_heptadiag()');
cmp_ok($x -> is_aheptadiag(),    '==', 0, '$x -> is_aheptadiag()');
cmp_ok($x -> is_band(0),         '==', 0, '$x -> is_band(0)');
cmp_ok($x -> is_aband(0),        '==', 0, '$x -> is_aband(0)');
cmp_ok($x -> is_band(1),         '==', 0, '$x -> is_band(1)');
cmp_ok($x -> is_aband(1),        '==', 0, '$x -> is_aband(1)');
cmp_ok($x -> is_band(2),         '==', 0, '$x -> is_band(2)');
cmp_ok($x -> is_aband(2),        '==', 0, '$x -> is_aband(2)');
cmp_ok($x -> is_band(3),         '==', 0, '$x -> is_band(3)');
cmp_ok($x -> is_aband(3),        '==', 0, '$x -> is_aband(3)');
cmp_ok($x -> is_band(4),         '==', 0, '$x -> is_band(4)');
cmp_ok($x -> is_aband(4),        '==', 0, '$x -> is_aband(4)');
cmp_ok($x -> is_triu(),          '==', 0, '$x -> is_triu()');
cmp_ok($x -> is_striu(),         '==', 0, '$x -> is_striu()');
cmp_ok($x -> is_tril(),          '==', 0, '$x -> is_tril()');
cmp_ok($x -> is_stril(),         '==', 0, '$x -> is_stril()');
cmp_ok($x -> is_atriu(),         '==', 0, '$x -> is_atriu()');
cmp_ok($x -> is_satriu(),        '==', 0, '$x -> is_satriu()');
cmp_ok($x -> is_atril(),         '==', 0, '$x -> is_atril()');
cmp_ok($x -> is_satril(),        '==', 0, '$x -> is_satril()');

# row vector

note(<<'EOF');
$x = Math::Matrix -> new([[1, 2, 3]]);
EOF

$x = Math::Matrix -> new([[1, 2, 3]]);

cmp_ok($x -> is_empty(),         '==', 0, '$x -> is_empty()');
cmp_ok($x -> is_scalar(),        '==', 0, '$x -> is_scalar()');
cmp_ok($x -> is_vector(),        '==', 1, '$x -> is_vector()');
cmp_ok($x -> is_row(),           '==', 1, '$x -> is_row()');
cmp_ok($x -> is_col(),           '==', 0, '$x -> is_col()');
cmp_ok($x -> is_square(),        '==', 0, '$x -> is_square()');
cmp_ok($x -> is_symmetric(),     '==', 0, '$x -> is_symmetric()');
cmp_ok($x -> is_antisymmetric(), '==', 0, '$x -> is_antisymmetric()');
cmp_ok($x -> is_persymmetric(),  '==', 0, '$x -> is_persymmetric()');
cmp_ok($x -> is_hankel(),        '==', 0, '$x -> is_hankel()');
cmp_ok($x -> is_zero(),          '==', 0, '$x -> is_zero()');
cmp_ok($x -> is_one(),           '==', 0, '$x -> is_one()');
cmp_ok($x -> is_constant(),      '==', 0, '$x -> is_constant()');
cmp_ok($x -> is_identity(),      '==', 0, '$x -> is_identity()');
cmp_ok($x -> is_exchg(),         '==', 0, '$x -> is_exchg()');
cmp_ok($x -> is_bool(),          '==', 0, '$x -> is_bool()');
cmp_ok($x -> is_perm(),          '==', 0, '$x -> is_perm()');
cmp_ok($x -> is_int(),           '==', 1, '$x -> is_int()');
cmp_ok($x -> is_diag(),          '==', 0, '$x -> is_diag()');
cmp_ok($x -> is_adiag(),         '==', 0, '$x -> is_adiag()');
cmp_ok($x -> is_tridiag(),       '==', 0, '$x -> is_tridiag()');
cmp_ok($x -> is_atridiag(),      '==', 0, '$x -> is_atridiag()');
cmp_ok($x -> is_pentadiag(),     '==', 0, '$x -> is_pentadiag()');
cmp_ok($x -> is_apentadiag(),    '==', 0, '$x -> is_apentadiag()');
cmp_ok($x -> is_heptadiag(),     '==', 0, '$x -> is_heptadiag()');
cmp_ok($x -> is_aheptadiag(),    '==', 0, '$x -> is_aheptadiag()');
cmp_ok($x -> is_band(0),         '==', 0, '$x -> is_band(0)');
cmp_ok($x -> is_aband(0),        '==', 0, '$x -> is_aband(0)');
cmp_ok($x -> is_band(1),         '==', 0, '$x -> is_band(1)');
cmp_ok($x -> is_aband(1),        '==', 0, '$x -> is_aband(1)');
cmp_ok($x -> is_band(2),         '==', 0, '$x -> is_band(2)');
cmp_ok($x -> is_aband(2),        '==', 0, '$x -> is_aband(2)');
cmp_ok($x -> is_band(3),         '==', 0, '$x -> is_band(3)');
cmp_ok($x -> is_aband(3),        '==', 0, '$x -> is_aband(3)');
cmp_ok($x -> is_band(4),         '==', 0, '$x -> is_band(4)');
cmp_ok($x -> is_aband(4),        '==', 0, '$x -> is_aband(4)');
cmp_ok($x -> is_triu(),          '==', 0, '$x -> is_triu()');
cmp_ok($x -> is_striu(),         '==', 0, '$x -> is_striu()');
cmp_ok($x -> is_tril(),          '==', 0, '$x -> is_tril()');
cmp_ok($x -> is_stril(),         '==', 0, '$x -> is_stril()');
cmp_ok($x -> is_atriu(),         '==', 0, '$x -> is_atriu()');
cmp_ok($x -> is_satriu(),        '==', 0, '$x -> is_satriu()');
cmp_ok($x -> is_atril(),         '==', 0, '$x -> is_atril()');
cmp_ok($x -> is_satril(),        '==', 0, '$x -> is_satril()');

# column vector

note(<<'EOF');
$x = Math::Matrix -> new([[1], [2], [3]]);
EOF

$x = Math::Matrix -> new([[1], [2], [3]]);

cmp_ok($x -> is_empty(),         '==', 0, '$x -> is_empty()');
cmp_ok($x -> is_scalar(),        '==', 0, '$x -> is_scalar()');
cmp_ok($x -> is_vector(),        '==', 1, '$x -> is_vector()');
cmp_ok($x -> is_row(),           '==', 0, '$x -> is_row()');
cmp_ok($x -> is_col(),           '==', 1, '$x -> is_col()');
cmp_ok($x -> is_square(),        '==', 0, '$x -> is_square()');
cmp_ok($x -> is_symmetric(),     '==', 0, '$x -> is_symmetric()');
cmp_ok($x -> is_antisymmetric(), '==', 0, '$x -> is_antisymmetric()');
cmp_ok($x -> is_persymmetric(),  '==', 0, '$x -> is_persymmetric()');
cmp_ok($x -> is_hankel(),        '==', 0, '$x -> is_hankel()');
cmp_ok($x -> is_zero(),          '==', 0, '$x -> is_zero()');
cmp_ok($x -> is_one(),           '==', 0, '$x -> is_one()');
cmp_ok($x -> is_constant(),      '==', 0, '$x -> is_constant()');
cmp_ok($x -> is_identity(),      '==', 0, '$x -> is_identity()');
cmp_ok($x -> is_exchg(),         '==', 0, '$x -> is_exchg()');
cmp_ok($x -> is_bool(),          '==', 0, '$x -> is_bool()');
cmp_ok($x -> is_perm(),          '==', 0, '$x -> is_perm()');
cmp_ok($x -> is_int(),           '==', 1, '$x -> is_int()');
cmp_ok($x -> is_diag(),          '==', 0, '$x -> is_diag()');
cmp_ok($x -> is_adiag(),         '==', 0, '$x -> is_adiag()');
cmp_ok($x -> is_tridiag(),       '==', 0, '$x -> is_tridiag()');
cmp_ok($x -> is_atridiag(),      '==', 0, '$x -> is_atridiag()');
cmp_ok($x -> is_pentadiag(),     '==', 0, '$x -> is_pentadiag()');
cmp_ok($x -> is_apentadiag(),    '==', 0, '$x -> is_apentadiag()');
cmp_ok($x -> is_heptadiag(),     '==', 0, '$x -> is_heptadiag()');
cmp_ok($x -> is_aheptadiag(),    '==', 0, '$x -> is_aheptadiag()');
cmp_ok($x -> is_band(0),         '==', 0, '$x -> is_band(0)');
cmp_ok($x -> is_aband(0),        '==', 0, '$x -> is_aband(0)');
cmp_ok($x -> is_band(1),         '==', 0, '$x -> is_band(1)');
cmp_ok($x -> is_aband(1),        '==', 0, '$x -> is_aband(1)');
cmp_ok($x -> is_band(2),         '==', 0, '$x -> is_band(2)');
cmp_ok($x -> is_aband(2),        '==', 0, '$x -> is_aband(2)');
cmp_ok($x -> is_band(3),         '==', 0, '$x -> is_band(3)');
cmp_ok($x -> is_aband(3),        '==', 0, '$x -> is_aband(3)');
cmp_ok($x -> is_band(4),         '==', 0, '$x -> is_band(4)');
cmp_ok($x -> is_aband(4),        '==', 0, '$x -> is_aband(4)');
cmp_ok($x -> is_triu(),          '==', 0, '$x -> is_triu()');
cmp_ok($x -> is_striu(),         '==', 0, '$x -> is_striu()');
cmp_ok($x -> is_tril(),          '==', 0, '$x -> is_tril()');
cmp_ok($x -> is_stril(),         '==', 0, '$x -> is_stril()');
cmp_ok($x -> is_atriu(),         '==', 0, '$x -> is_atriu()');
cmp_ok($x -> is_satriu(),        '==', 0, '$x -> is_satriu()');
cmp_ok($x -> is_atril(),         '==', 0, '$x -> is_atril()');
cmp_ok($x -> is_satril(),        '==', 0, '$x -> is_satril()');

# scalar

note(<<'EOF');
$x = Math::Matrix -> new([[3]]);
EOF

$x = Math::Matrix -> new([[3]]);

cmp_ok($x -> is_empty(),         '==', 0, '$x -> is_empty()');
cmp_ok($x -> is_scalar(),        '==', 1, '$x -> is_scalar()');
cmp_ok($x -> is_vector(),        '==', 1, '$x -> is_vector()');
cmp_ok($x -> is_row(),           '==', 1, '$x -> is_row()');
cmp_ok($x -> is_col(),           '==', 1, '$x -> is_col()');
cmp_ok($x -> is_square(),        '==', 1, '$x -> is_square()');
cmp_ok($x -> is_symmetric(),     '==', 1, '$x -> is_symmetric()');
cmp_ok($x -> is_antisymmetric(), '==', 0, '$x -> is_antisymmetric()');
cmp_ok($x -> is_persymmetric(),  '==', 1, '$x -> is_persymmetric()');
cmp_ok($x -> is_hankel(),        '==', 1, '$x -> is_hankel()');
cmp_ok($x -> is_zero(),          '==', 0, '$x -> is_zero()');
cmp_ok($x -> is_one(),           '==', 0, '$x -> is_one()');
cmp_ok($x -> is_constant(),      '==', 1, '$x -> is_constant()');
cmp_ok($x -> is_identity(),      '==', 0, '$x -> is_identity()');
cmp_ok($x -> is_exchg(),         '==', 0, '$x -> is_exchg()');
cmp_ok($x -> is_bool(),          '==', 0, '$x -> is_bool()');
cmp_ok($x -> is_perm(),          '==', 0, '$x -> is_perm()');
cmp_ok($x -> is_int(),           '==', 1, '$x -> is_int()');
cmp_ok($x -> is_diag(),          '==', 1, '$x -> is_diag()');
cmp_ok($x -> is_adiag(),         '==', 1, '$x -> is_adiag()');
cmp_ok($x -> is_tridiag(),       '==', 0, '$x -> is_tridiag()');
cmp_ok($x -> is_atridiag(),      '==', 0, '$x -> is_atridiag()');
cmp_ok($x -> is_pentadiag(),     '==', 0, '$x -> is_pentadiag()');
cmp_ok($x -> is_apentadiag(),    '==', 0, '$x -> is_apentadiag()');
cmp_ok($x -> is_heptadiag(),     '==', 0, '$x -> is_heptadiag()');
cmp_ok($x -> is_aheptadiag(),    '==', 0, '$x -> is_aheptadiag()');
cmp_ok($x -> is_band(0),         '==', 1, '$x -> is_band(0)');
cmp_ok($x -> is_aband(0),        '==', 1, '$x -> is_aband(0)');
cmp_ok($x -> is_band(1),         '==', 0, '$x -> is_band(1)');
cmp_ok($x -> is_aband(1),        '==', 0, '$x -> is_aband(1)');
cmp_ok($x -> is_band(2),         '==', 0, '$x -> is_band(2)');
cmp_ok($x -> is_aband(2),        '==', 0, '$x -> is_aband(2)');
cmp_ok($x -> is_band(3),         '==', 0, '$x -> is_band(3)');
cmp_ok($x -> is_aband(3),        '==', 0, '$x -> is_aband(3)');
cmp_ok($x -> is_band(4),         '==', 0, '$x -> is_band(4)');
cmp_ok($x -> is_aband(4),        '==', 0, '$x -> is_aband(4)');
cmp_ok($x -> is_triu(),          '==', 1, '$x -> is_triu()');
cmp_ok($x -> is_striu(),         '==', 0, '$x -> is_striu()');
cmp_ok($x -> is_tril(),          '==', 1, '$x -> is_tril()');
cmp_ok($x -> is_stril(),         '==', 0, '$x -> is_stril()');
cmp_ok($x -> is_atriu(),         '==', 1, '$x -> is_atriu()');
cmp_ok($x -> is_satriu(),        '==', 0, '$x -> is_satriu()');
cmp_ok($x -> is_atril(),         '==', 1, '$x -> is_atril()');
cmp_ok($x -> is_satril(),        '==', 0, '$x -> is_satril()');

# scalar

note(<<'EOF');
$x = Math::Matrix -> new([[1]]);
EOF

$x = Math::Matrix -> new([[1]]);

cmp_ok($x -> is_empty(),         '==', 0, '$x -> is_empty()');
cmp_ok($x -> is_scalar(),        '==', 1, '$x -> is_scalar()');
cmp_ok($x -> is_vector(),        '==', 1, '$x -> is_vector()');
cmp_ok($x -> is_row(),           '==', 1, '$x -> is_row()');
cmp_ok($x -> is_col(),           '==', 1, '$x -> is_col()');
cmp_ok($x -> is_square(),        '==', 1, '$x -> is_square()');
cmp_ok($x -> is_symmetric(),     '==', 1, '$x -> is_symmetric()');
cmp_ok($x -> is_antisymmetric(), '==', 0, '$x -> is_antisymmetric()');
cmp_ok($x -> is_persymmetric(),  '==', 1, '$x -> is_persymmetric()');
cmp_ok($x -> is_hankel(),        '==', 1, '$x -> is_hankel()');
cmp_ok($x -> is_zero(),          '==', 0, '$x -> is_zero()');
cmp_ok($x -> is_one(),           '==', 1, '$x -> is_one()');
cmp_ok($x -> is_constant(),      '==', 1, '$x -> is_constant()');
cmp_ok($x -> is_identity(),      '==', 1, '$x -> is_identity()');
cmp_ok($x -> is_exchg(),         '==', 1, '$x -> is_exchg()');
cmp_ok($x -> is_bool(),          '==', 1, '$x -> is_bool()');
cmp_ok($x -> is_perm(),          '==', 1, '$x -> is_perm()');
cmp_ok($x -> is_int(),           '==', 1, '$x -> is_int()');
cmp_ok($x -> is_diag(),          '==', 1, '$x -> is_diag()');
cmp_ok($x -> is_adiag(),         '==', 1, '$x -> is_adiag()');
cmp_ok($x -> is_tridiag(),       '==', 0, '$x -> is_tridiag()');
cmp_ok($x -> is_atridiag(),      '==', 0, '$x -> is_atridiag()');
cmp_ok($x -> is_pentadiag(),     '==', 0, '$x -> is_pentadiag()');
cmp_ok($x -> is_apentadiag(),    '==', 0, '$x -> is_apentadiag()');
cmp_ok($x -> is_heptadiag(),     '==', 0, '$x -> is_heptadiag()');
cmp_ok($x -> is_aheptadiag(),    '==', 0, '$x -> is_aheptadiag()');
cmp_ok($x -> is_band(0),         '==', 1, '$x -> is_band(0)');
cmp_ok($x -> is_aband(0),        '==', 1, '$x -> is_aband(0)');
cmp_ok($x -> is_band(1),         '==', 0, '$x -> is_band(1)');
cmp_ok($x -> is_aband(1),        '==', 0, '$x -> is_aband(1)');
cmp_ok($x -> is_band(2),         '==', 0, '$x -> is_band(2)');
cmp_ok($x -> is_aband(2),        '==', 0, '$x -> is_aband(2)');
cmp_ok($x -> is_band(3),         '==', 0, '$x -> is_band(3)');
cmp_ok($x -> is_aband(3),        '==', 0, '$x -> is_aband(3)');
cmp_ok($x -> is_band(4),         '==', 0, '$x -> is_band(4)');
cmp_ok($x -> is_aband(4),        '==', 0, '$x -> is_aband(4)');
cmp_ok($x -> is_triu(),          '==', 1, '$x -> is_triu()');
cmp_ok($x -> is_striu(),         '==', 0, '$x -> is_striu()');
cmp_ok($x -> is_tril(),          '==', 1, '$x -> is_tril()');
cmp_ok($x -> is_stril(),         '==', 0, '$x -> is_stril()');
cmp_ok($x -> is_atriu(),         '==', 1, '$x -> is_atriu()');
cmp_ok($x -> is_satriu(),        '==', 0, '$x -> is_satriu()');
cmp_ok($x -> is_atril(),         '==', 1, '$x -> is_atril()');
cmp_ok($x -> is_satril(),        '==', 0, '$x -> is_satril()');

# empty

note(<<'EOF');
$x = Math::Matrix -> new([]);
EOF

$x = Math::Matrix -> new([]);

cmp_ok($x -> is_empty(),         '==', 1, '$x -> is_empty()');
cmp_ok($x -> is_scalar(),        '==', 0, '$x -> is_scalar()');
cmp_ok($x -> is_vector(),        '==', 0, '$x -> is_vector()');
cmp_ok($x -> is_row(),           '==', 0, '$x -> is_row()');
cmp_ok($x -> is_col(),           '==', 0, '$x -> is_col()');
cmp_ok($x -> is_square(),        '==', 1, '$x -> is_square()');
cmp_ok($x -> is_symmetric(),     '==', 1, '$x -> is_symmetric()');
cmp_ok($x -> is_antisymmetric(), '==', 1, '$x -> is_antisymmetric()');
cmp_ok($x -> is_zero(),          '==', 1, '$x -> is_zero()');
cmp_ok($x -> is_one(),           '==', 1, '$x -> is_one()');
cmp_ok($x -> is_constant(),      '==', 1, '$x -> is_constant()');
cmp_ok($x -> is_identity(),      '==', 1, '$x -> is_identity()');
cmp_ok($x -> is_exchg(),         '==', 1, '$x -> is_exchg()');
cmp_ok($x -> is_bool(),          '==', 1, '$x -> is_bool()');
cmp_ok($x -> is_perm(),          '==', 1, '$x -> is_perm()');
cmp_ok($x -> is_int(),           '==', 1, '$x -> is_int()');
cmp_ok($x -> is_diag(),          '==', 0, '$x -> is_diag()');
cmp_ok($x -> is_adiag(),         '==', 0, '$x -> is_adiag()');
cmp_ok($x -> is_tridiag(),       '==', 0, '$x -> is_tridiag()');
cmp_ok($x -> is_atridiag(),      '==', 0, '$x -> is_atridiag()');
cmp_ok($x -> is_pentadiag(),     '==', 0, '$x -> is_pentadiag()');
cmp_ok($x -> is_apentadiag(),    '==', 0, '$x -> is_apentadiag()');
cmp_ok($x -> is_heptadiag(),     '==', 0, '$x -> is_heptadiag()');
cmp_ok($x -> is_aheptadiag(),    '==', 0, '$x -> is_aheptadiag()');
cmp_ok($x -> is_band(0),         '==', 0, '$x -> is_band(0)');
cmp_ok($x -> is_aband(0),        '==', 0, '$x -> is_aband(0)');
cmp_ok($x -> is_band(1),         '==', 0, '$x -> is_band(1)');
cmp_ok($x -> is_aband(1),        '==', 0, '$x -> is_aband(1)');
cmp_ok($x -> is_band(2),         '==', 0, '$x -> is_band(2)');
cmp_ok($x -> is_aband(2),        '==', 0, '$x -> is_aband(2)');
cmp_ok($x -> is_band(3),         '==', 0, '$x -> is_band(3)');
cmp_ok($x -> is_aband(3),        '==', 0, '$x -> is_aband(3)');
cmp_ok($x -> is_band(4),         '==', 0, '$x -> is_band(4)');
cmp_ok($x -> is_aband(4),        '==', 0, '$x -> is_aband(4)');
cmp_ok($x -> is_triu(),          '==', 1, '$x -> is_triu()');
cmp_ok($x -> is_striu(),         '==', 1, '$x -> is_striu()');
cmp_ok($x -> is_tril(),          '==', 1, '$x -> is_tril()');
cmp_ok($x -> is_stril(),         '==', 1, '$x -> is_stril()');
cmp_ok($x -> is_atriu(),         '==', 1, '$x -> is_atriu()');
cmp_ok($x -> is_satriu(),        '==', 1, '$x -> is_satriu()');
cmp_ok($x -> is_atril(),         '==', 1, '$x -> is_atril()');
cmp_ok($x -> is_satril(),        '==', 1, '$x -> is_satril()');

# symmetric

note(<<'EOF');
$x = Math::Matrix -> new([[1, 2, 3],
                          [2, 4, 5],
                          [3, 5, 6]]);
EOF

$x = Math::Matrix -> new([[1, 2, 3],
                          [2, 4, 5],
                          [3, 5, 6]]);

cmp_ok($x -> is_empty(),         '==', 0, '$x -> is_empty()');
cmp_ok($x -> is_scalar(),        '==', 0, '$x -> is_scalar()');
cmp_ok($x -> is_vector(),        '==', 0, '$x -> is_vector()');
cmp_ok($x -> is_row(),           '==', 0, '$x -> is_row()');
cmp_ok($x -> is_col(),           '==', 0, '$x -> is_col()');
cmp_ok($x -> is_square(),        '==', 1, '$x -> is_square()');
cmp_ok($x -> is_symmetric(),     '==', 1, '$x -> is_symmetric()');
cmp_ok($x -> is_antisymmetric(), '==', 0, '$x -> is_antisymmetric()');
cmp_ok($x -> is_persymmetric(),  '==', 0, '$x -> is_persymmetric()');
cmp_ok($x -> is_hankel(),        '==', 0, '$x -> is_hankel()');
cmp_ok($x -> is_zero(),          '==', 0, '$x -> is_zero()');
cmp_ok($x -> is_one(),           '==', 0, '$x -> is_one()');
cmp_ok($x -> is_constant(),      '==', 0, '$x -> is_constant()');
cmp_ok($x -> is_identity(),      '==', 0, '$x -> is_identity()');
cmp_ok($x -> is_exchg(),         '==', 0, '$x -> is_exchg()');
cmp_ok($x -> is_bool(),          '==', 0, '$x -> is_bool()');
cmp_ok($x -> is_perm(),          '==', 0, '$x -> is_perm()');
cmp_ok($x -> is_int(),           '==', 1, '$x -> is_int()');
cmp_ok($x -> is_diag(),          '==', 0, '$x -> is_diag()');
cmp_ok($x -> is_adiag(),         '==', 0, '$x -> is_adiag()');
cmp_ok($x -> is_tridiag(),       '==', 0, '$x -> is_tridiag()');
cmp_ok($x -> is_atridiag(),      '==', 0, '$x -> is_atridiag()');
cmp_ok($x -> is_pentadiag(),     '==', 1, '$x -> is_pentadiag()');
cmp_ok($x -> is_apentadiag(),    '==', 1, '$x -> is_apentadiag()');
cmp_ok($x -> is_heptadiag(),     '==', 0, '$x -> is_heptadiag()');
cmp_ok($x -> is_aheptadiag(),    '==', 0, '$x -> is_aheptadiag()');
cmp_ok($x -> is_band(0),         '==', 0, '$x -> is_band(0)');
cmp_ok($x -> is_aband(0),        '==', 0, '$x -> is_aband(0)');
cmp_ok($x -> is_band(1),         '==', 0, '$x -> is_band(1)');
cmp_ok($x -> is_aband(1),        '==', 0, '$x -> is_aband(1)');
cmp_ok($x -> is_band(2),         '==', 1, '$x -> is_band(2)');
cmp_ok($x -> is_aband(2),        '==', 1, '$x -> is_aband(2)');
cmp_ok($x -> is_band(3),         '==', 0, '$x -> is_band(3)');
cmp_ok($x -> is_aband(3),        '==', 0, '$x -> is_aband(3)');
cmp_ok($x -> is_band(4),         '==', 0, '$x -> is_band(4)');
cmp_ok($x -> is_aband(4),        '==', 0, '$x -> is_aband(4)');
cmp_ok($x -> is_triu(),          '==', 0, '$x -> is_triu()');
cmp_ok($x -> is_striu(),         '==', 0, '$x -> is_striu()');
cmp_ok($x -> is_tril(),          '==', 0, '$x -> is_tril()');
cmp_ok($x -> is_stril(),         '==', 0, '$x -> is_stril()');
cmp_ok($x -> is_atriu(),         '==', 0, '$x -> is_atriu()');
cmp_ok($x -> is_satriu(),        '==', 0, '$x -> is_satriu()');
cmp_ok($x -> is_atril(),         '==', 0, '$x -> is_atril()');
cmp_ok($x -> is_satril(),        '==', 0, '$x -> is_satril()');

# antisymmetric

note(<<'EOF');
$x = Math::Matrix -> new([[ 0,  1, -2],
                          [-1,  0,  3],
                          [ 2, -3,  0]]);
EOF

$x = Math::Matrix -> new([[ 0,  1, -2],
                          [-1,  0,  3],
                          [ 2, -3,  0]]);

cmp_ok($x -> is_empty(),         '==', 0, '$x -> is_empty()');
cmp_ok($x -> is_scalar(),        '==', 0, '$x -> is_scalar()');
cmp_ok($x -> is_vector(),        '==', 0, '$x -> is_vector()');
cmp_ok($x -> is_row(),           '==', 0, '$x -> is_row()');
cmp_ok($x -> is_col(),           '==', 0, '$x -> is_col()');
cmp_ok($x -> is_square(),        '==', 1, '$x -> is_square()');
cmp_ok($x -> is_symmetric(),     '==', 0, '$x -> is_symmetric()');
cmp_ok($x -> is_antisymmetric(), '==', 1, '$x -> is_antisymmetric()');
cmp_ok($x -> is_zero(),          '==', 0, '$x -> is_zero()');
cmp_ok($x -> is_one(),           '==', 0, '$x -> is_one()');
cmp_ok($x -> is_constant(),      '==', 0, '$x -> is_constant()');
cmp_ok($x -> is_identity(),      '==', 0, '$x -> is_identity()');
cmp_ok($x -> is_exchg(),         '==', 0, '$x -> is_exchg()');
cmp_ok($x -> is_bool(),          '==', 0, '$x -> is_bool()');
cmp_ok($x -> is_perm(),          '==', 0, '$x -> is_perm()');
cmp_ok($x -> is_int(),           '==', 1, '$x -> is_int()');
cmp_ok($x -> is_diag(),          '==', 0, '$x -> is_diag()');
cmp_ok($x -> is_adiag(),         '==', 0, '$x -> is_adiag()');
cmp_ok($x -> is_tridiag(),       '==', 0, '$x -> is_tridiag()');
cmp_ok($x -> is_atridiag(),      '==', 1, '$x -> is_atridiag()');
cmp_ok($x -> is_pentadiag(),     '==', 1, '$x -> is_pentadiag()');
cmp_ok($x -> is_apentadiag(),    '==', 1, '$x -> is_apentadiag()');
cmp_ok($x -> is_heptadiag(),     '==', 0, '$x -> is_heptadiag()');
cmp_ok($x -> is_aheptadiag(),    '==', 0, '$x -> is_aheptadiag()');
cmp_ok($x -> is_band(0),         '==', 0, '$x -> is_band(0)');
cmp_ok($x -> is_aband(0),        '==', 0, '$x -> is_aband(0)');
cmp_ok($x -> is_band(1),         '==', 0, '$x -> is_band(1)');
cmp_ok($x -> is_aband(1),        '==', 1, '$x -> is_aband(1)');
cmp_ok($x -> is_band(2),         '==', 1, '$x -> is_band(2)');
cmp_ok($x -> is_aband(2),        '==', 1, '$x -> is_aband(2)');
cmp_ok($x -> is_band(3),         '==', 0, '$x -> is_band(3)');
cmp_ok($x -> is_aband(3),        '==', 0, '$x -> is_aband(3)');
cmp_ok($x -> is_band(4),         '==', 0, '$x -> is_band(4)');
cmp_ok($x -> is_aband(4),        '==', 0, '$x -> is_aband(4)');
cmp_ok($x -> is_triu(),          '==', 0, '$x -> is_triu()');
cmp_ok($x -> is_striu(),         '==', 0, '$x -> is_striu()');
cmp_ok($x -> is_tril(),          '==', 0, '$x -> is_tril()');
cmp_ok($x -> is_stril(),         '==', 0, '$x -> is_stril()');
cmp_ok($x -> is_atriu(),         '==', 0, '$x -> is_atriu()');
cmp_ok($x -> is_satriu(),        '==', 0, '$x -> is_satriu()');
cmp_ok($x -> is_atril(),         '==', 0, '$x -> is_atril()');
cmp_ok($x -> is_satril(),        '==', 0, '$x -> is_satril()');

# identity

note(<<'EOF');
$x = Math::Matrix -> new([[1, 0, 0],
                          [0, 1, 0],
                          [0, 0, 1]]);
EOF

$x = Math::Matrix -> new([[1, 0, 0],
                          [0, 1, 0],
                          [0, 0, 1]]);

cmp_ok($x -> is_empty(),         '==', 0, '$x -> is_empty()');
cmp_ok($x -> is_scalar(),        '==', 0, '$x -> is_scalar()');
cmp_ok($x -> is_vector(),        '==', 0, '$x -> is_vector()');
cmp_ok($x -> is_row(),           '==', 0, '$x -> is_row()');
cmp_ok($x -> is_col(),           '==', 0, '$x -> is_col()');
cmp_ok($x -> is_square(),        '==', 1, '$x -> is_square()');
cmp_ok($x -> is_symmetric(),     '==', 1, '$x -> is_symmetric()');
cmp_ok($x -> is_antisymmetric(), '==', 0, '$x -> is_antisymmetric()');
cmp_ok($x -> is_persymmetric(),  '==', 1, '$x -> is_persymmetric()');
cmp_ok($x -> is_hankel(),        '==', 1, '$x -> is_hankel()');
cmp_ok($x -> is_zero(),          '==', 0, '$x -> is_zero()');
cmp_ok($x -> is_one(),           '==', 0, '$x -> is_one()');
cmp_ok($x -> is_constant(),      '==', 0, '$x -> is_constant()');
cmp_ok($x -> is_identity(),      '==', 1, '$x -> is_identity()');
cmp_ok($x -> is_exchg(),         '==', 0, '$x -> is_exchg()');
cmp_ok($x -> is_bool(),          '==', 1, '$x -> is_bool()');
cmp_ok($x -> is_perm(),          '==', 1, '$x -> is_perm()');
cmp_ok($x -> is_int(),           '==', 1, '$x -> is_int()');
cmp_ok($x -> is_diag(),          '==', 1, '$x -> is_diag()');
cmp_ok($x -> is_adiag(),         '==', 0, '$x -> is_adiag()');
cmp_ok($x -> is_tridiag(),       '==', 1, '$x -> is_tridiag()');
cmp_ok($x -> is_atridiag(),      '==', 0, '$x -> is_atridiag()');
cmp_ok($x -> is_pentadiag(),     '==', 1, '$x -> is_pentadiag()');
cmp_ok($x -> is_apentadiag(),    '==', 1, '$x -> is_apentadiag()');
cmp_ok($x -> is_heptadiag(),     '==', 0, '$x -> is_heptadiag()');
cmp_ok($x -> is_aheptadiag(),    '==', 0, '$x -> is_aheptadiag()');
cmp_ok($x -> is_band(0),         '==', 1, '$x -> is_band(0)');
cmp_ok($x -> is_aband(0),        '==', 0, '$x -> is_aband(0)');
cmp_ok($x -> is_band(1),         '==', 1, '$x -> is_band(1)');
cmp_ok($x -> is_aband(1),        '==', 0, '$x -> is_aband(1)');
cmp_ok($x -> is_band(2),         '==', 1, '$x -> is_band(2)');
cmp_ok($x -> is_aband(2),        '==', 1, '$x -> is_aband(2)');
cmp_ok($x -> is_band(3),         '==', 0, '$x -> is_band(3)');
cmp_ok($x -> is_aband(3),        '==', 0, '$x -> is_aband(3)');
cmp_ok($x -> is_band(4),         '==', 0, '$x -> is_band(4)');
cmp_ok($x -> is_aband(4),        '==', 0, '$x -> is_aband(4)');
cmp_ok($x -> is_triu(),          '==', 1, '$x -> is_triu()');
cmp_ok($x -> is_striu(),         '==', 0, '$x -> is_striu()');
cmp_ok($x -> is_tril(),          '==', 1, '$x -> is_tril()');
cmp_ok($x -> is_stril(),         '==', 0, '$x -> is_stril()');
cmp_ok($x -> is_atriu(),         '==', 0, '$x -> is_atriu()');
cmp_ok($x -> is_satriu(),        '==', 0, '$x -> is_satriu()');
cmp_ok($x -> is_atril(),         '==', 0, '$x -> is_atril()');
cmp_ok($x -> is_satril(),        '==', 0, '$x -> is_satril()');

# exchange

note(<<'EOF');
$x = Math::Matrix -> new([[0, 0, 1],
                          [0, 1, 0],
                          [1, 0, 0]]);
EOF

$x = Math::Matrix -> new([[0, 0, 1],
                          [0, 1, 0],
                          [1, 0, 0]]);

cmp_ok($x -> is_empty(),         '==', 0, '$x -> is_empty()');
cmp_ok($x -> is_scalar(),        '==', 0, '$x -> is_scalar()');
cmp_ok($x -> is_vector(),        '==', 0, '$x -> is_vector()');
cmp_ok($x -> is_row(),           '==', 0, '$x -> is_row()');
cmp_ok($x -> is_col(),           '==', 0, '$x -> is_col()');
cmp_ok($x -> is_square(),        '==', 1, '$x -> is_square()');
cmp_ok($x -> is_symmetric(),     '==', 1, '$x -> is_symmetric()');
cmp_ok($x -> is_antisymmetric(), '==', 0, '$x -> is_antisymmetric()');
cmp_ok($x -> is_persymmetric(),  '==', 1, '$x -> is_persymmetric()');
cmp_ok($x -> is_hankel(),        '==', 0, '$x -> is_hankel()');
cmp_ok($x -> is_zero(),          '==', 0, '$x -> is_zero()');
cmp_ok($x -> is_one(),           '==', 0, '$x -> is_one()');
cmp_ok($x -> is_constant(),      '==', 0, '$x -> is_constant()');
cmp_ok($x -> is_identity(),      '==', 0, '$x -> is_identity()');
cmp_ok($x -> is_exchg(),         '==', 1, '$x -> is_exchg()');
cmp_ok($x -> is_bool(),          '==', 1, '$x -> is_bool()');
cmp_ok($x -> is_perm(),          '==', 1, '$x -> is_perm()');
cmp_ok($x -> is_int(),           '==', 1, '$x -> is_int()');
cmp_ok($x -> is_diag(),          '==', 0, '$x -> is_diag()');
cmp_ok($x -> is_adiag(),         '==', 1, '$x -> is_adiag()');
cmp_ok($x -> is_tridiag(),       '==', 0, '$x -> is_tridiag()');
cmp_ok($x -> is_atridiag(),      '==', 1, '$x -> is_atridiag()');
cmp_ok($x -> is_pentadiag(),     '==', 1, '$x -> is_pentadiag()');
cmp_ok($x -> is_apentadiag(),    '==', 1, '$x -> is_apentadiag()');
cmp_ok($x -> is_heptadiag(),     '==', 0, '$x -> is_heptadiag()');
cmp_ok($x -> is_aheptadiag(),    '==', 0, '$x -> is_aheptadiag()');
cmp_ok($x -> is_band(0),         '==', 0, '$x -> is_band(0)');
cmp_ok($x -> is_aband(0),        '==', 1, '$x -> is_aband(0)');
cmp_ok($x -> is_band(1),         '==', 0, '$x -> is_band(1)');
cmp_ok($x -> is_aband(1),        '==', 1, '$x -> is_aband(1)');
cmp_ok($x -> is_band(2),         '==', 1, '$x -> is_band(2)');
cmp_ok($x -> is_aband(2),        '==', 1, '$x -> is_aband(2)');
cmp_ok($x -> is_band(3),         '==', 0, '$x -> is_band(3)');
cmp_ok($x -> is_aband(3),        '==', 0, '$x -> is_aband(3)');
cmp_ok($x -> is_band(4),         '==', 0, '$x -> is_band(4)');
cmp_ok($x -> is_aband(4),        '==', 0, '$x -> is_aband(4)');
cmp_ok($x -> is_triu(),          '==', 0, '$x -> is_triu()');
cmp_ok($x -> is_striu(),         '==', 0, '$x -> is_striu()');
cmp_ok($x -> is_tril(),          '==', 0, '$x -> is_tril()');
cmp_ok($x -> is_stril(),         '==', 0, '$x -> is_stril()');
cmp_ok($x -> is_atriu(),         '==', 1, '$x -> is_atriu()');
cmp_ok($x -> is_satriu(),        '==', 0, '$x -> is_satriu()');
cmp_ok($x -> is_atril(),         '==', 1, '$x -> is_atril()');
cmp_ok($x -> is_satril(),        '==', 0, '$x -> is_satril()');

# permutation

note(<<'EOF');
$x = Math::Matrix -> new([[0, 1, 0],
                          [0, 0, 1],
                          [1, 0, 0]]);
EOF

$x = Math::Matrix -> new([[0, 1, 0],
                          [0, 0, 1],
                          [1, 0, 0]]);

cmp_ok($x -> is_empty(),         '==', 0, '$x -> is_empty()');
cmp_ok($x -> is_scalar(),        '==', 0, '$x -> is_scalar()');
cmp_ok($x -> is_vector(),        '==', 0, '$x -> is_vector()');
cmp_ok($x -> is_row(),           '==', 0, '$x -> is_row()');
cmp_ok($x -> is_col(),           '==', 0, '$x -> is_col()');
cmp_ok($x -> is_square(),        '==', 1, '$x -> is_square()');
cmp_ok($x -> is_symmetric(),     '==', 0, '$x -> is_symmetric()');
cmp_ok($x -> is_antisymmetric(), '==', 0, '$x -> is_antisymmetric()');
cmp_ok($x -> is_persymmetric(),  '==', 1, '$x -> is_persymmetric()');
cmp_ok($x -> is_hankel(),        '==', 1, '$x -> is_hankel()');
cmp_ok($x -> is_zero(),          '==', 0, '$x -> is_zero()');
cmp_ok($x -> is_one(),           '==', 0, '$x -> is_one()');
cmp_ok($x -> is_constant(),      '==', 0, '$x -> is_constant()');
cmp_ok($x -> is_identity(),      '==', 0, '$x -> is_identity()');
cmp_ok($x -> is_exchg(),         '==', 0, '$x -> is_exchg()');
cmp_ok($x -> is_bool(),          '==', 1, '$x -> is_bool()');
cmp_ok($x -> is_perm(),          '==', 1, '$x -> is_perm()');
cmp_ok($x -> is_int(),           '==', 1, '$x -> is_int()');
cmp_ok($x -> is_diag(),          '==', 0, '$x -> is_diag()');
cmp_ok($x -> is_adiag(),         '==', 0, '$x -> is_adiag()');
cmp_ok($x -> is_tridiag(),       '==', 0, '$x -> is_tridiag()');
cmp_ok($x -> is_atridiag(),      '==', 1, '$x -> is_atridiag()');
cmp_ok($x -> is_pentadiag(),     '==', 1, '$x -> is_pentadiag()');
cmp_ok($x -> is_apentadiag(),    '==', 1, '$x -> is_apentadiag()');
cmp_ok($x -> is_heptadiag(),     '==', 0, '$x -> is_heptadiag()');
cmp_ok($x -> is_aheptadiag(),    '==', 0, '$x -> is_aheptadiag()');
cmp_ok($x -> is_band(0),         '==', 0, '$x -> is_band(0)');
cmp_ok($x -> is_aband(0),        '==', 0, '$x -> is_aband(0)');
cmp_ok($x -> is_band(1),         '==', 0, '$x -> is_band(1)');
cmp_ok($x -> is_aband(1),        '==', 1, '$x -> is_aband(1)');
cmp_ok($x -> is_band(2),         '==', 1, '$x -> is_band(2)');
cmp_ok($x -> is_aband(2),        '==', 1, '$x -> is_aband(2)');
cmp_ok($x -> is_band(3),         '==', 0, '$x -> is_band(3)');
cmp_ok($x -> is_aband(3),        '==', 0, '$x -> is_aband(3)');
cmp_ok($x -> is_band(4),         '==', 0, '$x -> is_band(4)');
cmp_ok($x -> is_aband(4),        '==', 0, '$x -> is_aband(4)');
cmp_ok($x -> is_triu(),          '==', 0, '$x -> is_triu()');
cmp_ok($x -> is_striu(),         '==', 0, '$x -> is_striu()');
cmp_ok($x -> is_tril(),          '==', 0, '$x -> is_tril()');
cmp_ok($x -> is_stril(),         '==', 0, '$x -> is_stril()');
cmp_ok($x -> is_atriu(),         '==', 0, '$x -> is_atriu()');
cmp_ok($x -> is_satriu(),        '==', 0, '$x -> is_satriu()');
cmp_ok($x -> is_atril(),         '==', 0, '$x -> is_atril()');
cmp_ok($x -> is_satril(),        '==', 0, '$x -> is_satril()');

# upper triangular

note(<<'EOF');
$x = Math::Matrix -> new([[1, 2, 3],
                          [0, 5, 6],
                          [0, 0, 9]]);
EOF

$x = Math::Matrix -> new([[1, 2, 3],
                          [0, 5, 6],
                          [0, 0, 9]]);

cmp_ok($x -> is_empty(),         '==', 0, '$x -> is_empty()');
cmp_ok($x -> is_scalar(),        '==', 0, '$x -> is_scalar()');
cmp_ok($x -> is_vector(),        '==', 0, '$x -> is_vector()');
cmp_ok($x -> is_row(),           '==', 0, '$x -> is_row()');
cmp_ok($x -> is_col(),           '==', 0, '$x -> is_col()');
cmp_ok($x -> is_square(),        '==', 1, '$x -> is_square()');
cmp_ok($x -> is_symmetric(),     '==', 0, '$x -> is_symmetric()');
cmp_ok($x -> is_antisymmetric(), '==', 0, '$x -> is_antisymmetric()');
cmp_ok($x -> is_persymmetric(),  '==', 0, '$x -> is_persymmetric()');
cmp_ok($x -> is_hankel(),        '==', 0, '$x -> is_hankel()');
cmp_ok($x -> is_zero(),          '==', 0, '$x -> is_zero()');
cmp_ok($x -> is_one(),           '==', 0, '$x -> is_one()');
cmp_ok($x -> is_constant(),      '==', 0, '$x -> is_constant()');
cmp_ok($x -> is_identity(),      '==', 0, '$x -> is_identity()');
cmp_ok($x -> is_exchg(),         '==', 0, '$x -> is_exchg()');
cmp_ok($x -> is_bool(),          '==', 0, '$x -> is_bool()');
cmp_ok($x -> is_perm(),          '==', 0, '$x -> is_perm()');
cmp_ok($x -> is_int(),           '==', 1, '$x -> is_int()');
cmp_ok($x -> is_diag(),          '==', 0, '$x -> is_diag()');
cmp_ok($x -> is_adiag(),         '==', 0, '$x -> is_adiag()');
cmp_ok($x -> is_tridiag(),       '==', 0, '$x -> is_tridiag()');
cmp_ok($x -> is_atridiag(),      '==', 0, '$x -> is_atridiag()');
cmp_ok($x -> is_pentadiag(),     '==', 1, '$x -> is_pentadiag()');
cmp_ok($x -> is_apentadiag(),    '==', 1, '$x -> is_apentadiag()');
cmp_ok($x -> is_heptadiag(),     '==', 0, '$x -> is_heptadiag()');
cmp_ok($x -> is_aheptadiag(),    '==', 0, '$x -> is_aheptadiag()');
cmp_ok($x -> is_band(0),         '==', 0, '$x -> is_band(0)');
cmp_ok($x -> is_aband(0),        '==', 0, '$x -> is_aband(0)');
cmp_ok($x -> is_band(1),         '==', 0, '$x -> is_band(1)');
cmp_ok($x -> is_aband(1),        '==', 0, '$x -> is_aband(1)');
cmp_ok($x -> is_band(2),         '==', 1, '$x -> is_band(2)');
cmp_ok($x -> is_aband(2),        '==', 1, '$x -> is_aband(2)');
cmp_ok($x -> is_band(3),         '==', 0, '$x -> is_band(3)');
cmp_ok($x -> is_aband(3),        '==', 0, '$x -> is_aband(3)');
cmp_ok($x -> is_band(4),         '==', 0, '$x -> is_band(4)');
cmp_ok($x -> is_aband(4),        '==', 0, '$x -> is_aband(4)');
cmp_ok($x -> is_triu(),          '==', 1, '$x -> is_triu()');
cmp_ok($x -> is_striu(),         '==', 0, '$x -> is_striu()');
cmp_ok($x -> is_tril(),          '==', 0, '$x -> is_tril()');
cmp_ok($x -> is_stril(),         '==', 0, '$x -> is_stril()');
cmp_ok($x -> is_atriu(),         '==', 0, '$x -> is_atriu()');
cmp_ok($x -> is_satriu(),        '==', 0, '$x -> is_satriu()');
cmp_ok($x -> is_atril(),         '==', 0, '$x -> is_atril()');
cmp_ok($x -> is_satril(),        '==', 0, '$x -> is_satril()');

# strictly upper triangular

note(<<'EOF');
$x = Math::Matrix -> new([[0, 2, 3],
                          [0, 0, 6],
                          [0, 0, 0]]);
EOF

$x = Math::Matrix -> new([[0, 2, 3],
                          [0, 0, 6],
                          [0, 0, 0]]);

cmp_ok($x -> is_empty(),         '==', 0, '$x -> is_empty()');
cmp_ok($x -> is_scalar(),        '==', 0, '$x -> is_scalar()');
cmp_ok($x -> is_vector(),        '==', 0, '$x -> is_vector()');
cmp_ok($x -> is_row(),           '==', 0, '$x -> is_row()');
cmp_ok($x -> is_col(),           '==', 0, '$x -> is_col()');
cmp_ok($x -> is_square(),        '==', 1, '$x -> is_square()');
cmp_ok($x -> is_symmetric(),     '==', 0, '$x -> is_symmetric()');
cmp_ok($x -> is_antisymmetric(), '==', 0, '$x -> is_antisymmetric()');
cmp_ok($x -> is_persymmetric(),  '==', 0, '$x -> is_persymmetric()');
cmp_ok($x -> is_hankel(),        '==', 0, '$x -> is_hankel()');
cmp_ok($x -> is_zero(),          '==', 0, '$x -> is_zero()');
cmp_ok($x -> is_one(),           '==', 0, '$x -> is_one()');
cmp_ok($x -> is_constant(),      '==', 0, '$x -> is_constant()');
cmp_ok($x -> is_identity(),      '==', 0, '$x -> is_identity()');
cmp_ok($x -> is_exchg(),         '==', 0, '$x -> is_exchg()');
cmp_ok($x -> is_bool(),          '==', 0, '$x -> is_bool()');
cmp_ok($x -> is_perm(),          '==', 0, '$x -> is_perm()');
cmp_ok($x -> is_int(),           '==', 1, '$x -> is_int()');
cmp_ok($x -> is_diag(),          '==', 0, '$x -> is_diag()');
cmp_ok($x -> is_adiag(),         '==', 0, '$x -> is_adiag()');
cmp_ok($x -> is_tridiag(),       '==', 0, '$x -> is_tridiag()');
cmp_ok($x -> is_atridiag(),      '==', 1, '$x -> is_atridiag()');
cmp_ok($x -> is_pentadiag(),     '==', 1, '$x -> is_pentadiag()');
cmp_ok($x -> is_apentadiag(),    '==', 1, '$x -> is_apentadiag()');
cmp_ok($x -> is_heptadiag(),     '==', 0, '$x -> is_heptadiag()');
cmp_ok($x -> is_aheptadiag(),    '==', 0, '$x -> is_aheptadiag()');
cmp_ok($x -> is_band(0),         '==', 0, '$x -> is_band(0)');
cmp_ok($x -> is_aband(0),        '==', 0, '$x -> is_aband(0)');
cmp_ok($x -> is_band(1),         '==', 0, '$x -> is_band(1)');
cmp_ok($x -> is_aband(1),        '==', 1, '$x -> is_aband(1)');
cmp_ok($x -> is_band(2),         '==', 1, '$x -> is_band(2)');
cmp_ok($x -> is_aband(2),        '==', 1, '$x -> is_aband(2)');
cmp_ok($x -> is_band(3),         '==', 0, '$x -> is_band(3)');
cmp_ok($x -> is_aband(3),        '==', 0, '$x -> is_aband(3)');
cmp_ok($x -> is_band(4),         '==', 0, '$x -> is_band(4)');
cmp_ok($x -> is_aband(4),        '==', 0, '$x -> is_aband(4)');
cmp_ok($x -> is_triu(),          '==', 1, '$x -> is_triu()');
cmp_ok($x -> is_striu(),         '==', 1, '$x -> is_striu()');
cmp_ok($x -> is_tril(),          '==', 0, '$x -> is_tril()');
cmp_ok($x -> is_stril(),         '==', 0, '$x -> is_stril()');
cmp_ok($x -> is_atriu(),         '==', 0, '$x -> is_atriu()');
cmp_ok($x -> is_satriu(),        '==', 0, '$x -> is_satriu()');
cmp_ok($x -> is_atril(),         '==', 0, '$x -> is_atril()');
cmp_ok($x -> is_satril(),        '==', 0, '$x -> is_satril()');

# lower triangular

note(<<'EOF');
$x = Math::Matrix -> new([[1, 0, 0],
                          [4, 5, 0],
                          [7, 8, 9]]);
EOF

$x = Math::Matrix -> new([[1, 0, 0],
                          [4, 5, 0],
                          [7, 8, 9]]);

cmp_ok($x -> is_empty(),         '==', 0, '$x -> is_empty()');
cmp_ok($x -> is_scalar(),        '==', 0, '$x -> is_scalar()');
cmp_ok($x -> is_vector(),        '==', 0, '$x -> is_vector()');
cmp_ok($x -> is_row(),           '==', 0, '$x -> is_row()');
cmp_ok($x -> is_col(),           '==', 0, '$x -> is_col()');
cmp_ok($x -> is_square(),        '==', 1, '$x -> is_square()');
cmp_ok($x -> is_symmetric(),     '==', 0, '$x -> is_symmetric()');
cmp_ok($x -> is_antisymmetric(), '==', 0, '$x -> is_antisymmetric()');
cmp_ok($x -> is_persymmetric(),  '==', 0, '$x -> is_persymmetric()');
cmp_ok($x -> is_hankel(),        '==', 0, '$x -> is_hankel()');
cmp_ok($x -> is_zero(),          '==', 0, '$x -> is_zero()');
cmp_ok($x -> is_one(),           '==', 0, '$x -> is_one()');
cmp_ok($x -> is_constant(),      '==', 0, '$x -> is_constant()');
cmp_ok($x -> is_identity(),      '==', 0, '$x -> is_identity()');
cmp_ok($x -> is_exchg(),         '==', 0, '$x -> is_exchg()');
cmp_ok($x -> is_bool(),          '==', 0, '$x -> is_bool()');
cmp_ok($x -> is_perm(),          '==', 0, '$x -> is_perm()');
cmp_ok($x -> is_int(),           '==', 1, '$x -> is_int()');
cmp_ok($x -> is_diag(),          '==', 0, '$x -> is_diag()');
cmp_ok($x -> is_adiag(),         '==', 0, '$x -> is_adiag()');
cmp_ok($x -> is_tridiag(),       '==', 0, '$x -> is_tridiag()');
cmp_ok($x -> is_atridiag(),      '==', 0, '$x -> is_atridiag()');
cmp_ok($x -> is_pentadiag(),     '==', 1, '$x -> is_pentadiag()');
cmp_ok($x -> is_apentadiag(),    '==', 1, '$x -> is_apentadiag()');
cmp_ok($x -> is_heptadiag(),     '==', 0, '$x -> is_heptadiag()');
cmp_ok($x -> is_aheptadiag(),    '==', 0, '$x -> is_aheptadiag()');
cmp_ok($x -> is_band(0),         '==', 0, '$x -> is_band(0)');
cmp_ok($x -> is_aband(0),        '==', 0, '$x -> is_aband(0)');
cmp_ok($x -> is_band(1),         '==', 0, '$x -> is_band(1)');
cmp_ok($x -> is_aband(1),        '==', 0, '$x -> is_aband(1)');
cmp_ok($x -> is_band(2),         '==', 1, '$x -> is_band(2)');
cmp_ok($x -> is_aband(2),        '==', 1, '$x -> is_aband(2)');
cmp_ok($x -> is_band(3),         '==', 0, '$x -> is_band(3)');
cmp_ok($x -> is_aband(3),        '==', 0, '$x -> is_aband(3)');
cmp_ok($x -> is_band(4),         '==', 0, '$x -> is_band(4)');
cmp_ok($x -> is_aband(4),        '==', 0, '$x -> is_aband(4)');
cmp_ok($x -> is_triu(),          '==', 0, '$x -> is_triu()');
cmp_ok($x -> is_striu(),         '==', 0, '$x -> is_striu()');
cmp_ok($x -> is_tril(),          '==', 1, '$x -> is_tril()');
cmp_ok($x -> is_stril(),         '==', 0, '$x -> is_stril()');
cmp_ok($x -> is_atriu(),         '==', 0, '$x -> is_atriu()');
cmp_ok($x -> is_satriu(),        '==', 0, '$x -> is_satriu()');
cmp_ok($x -> is_atril(),         '==', 0, '$x -> is_atril()');
cmp_ok($x -> is_satril(),        '==', 0, '$x -> is_satril()');

# strictly lower triangular

note(<<'EOF');
$x = Math::Matrix -> new([[0, 0, 0],
                          [4, 0, 0],
                          [7, 8, 0]]);
EOF

$x = Math::Matrix -> new([[0, 0, 0],
                          [4, 0, 0],
                          [7, 8, 0]]);

cmp_ok($x -> is_empty(),         '==', 0, '$x -> is_empty()');
cmp_ok($x -> is_scalar(),        '==', 0, '$x -> is_scalar()');
cmp_ok($x -> is_vector(),        '==', 0, '$x -> is_vector()');
cmp_ok($x -> is_row(),           '==', 0, '$x -> is_row()');
cmp_ok($x -> is_col(),           '==', 0, '$x -> is_col()');
cmp_ok($x -> is_square(),        '==', 1, '$x -> is_square()');
cmp_ok($x -> is_symmetric(),     '==', 0, '$x -> is_symmetric()');
cmp_ok($x -> is_antisymmetric(), '==', 0, '$x -> is_antisymmetric()');
cmp_ok($x -> is_persymmetric(),  '==', 0, '$x -> is_persymmetric()');
cmp_ok($x -> is_hankel(),        '==', 0, '$x -> is_hankel()');
cmp_ok($x -> is_zero(),          '==', 0, '$x -> is_zero()');
cmp_ok($x -> is_one(),           '==', 0, '$x -> is_one()');
cmp_ok($x -> is_constant(),      '==', 0, '$x -> is_constant()');
cmp_ok($x -> is_identity(),      '==', 0, '$x -> is_identity()');
cmp_ok($x -> is_exchg(),         '==', 0, '$x -> is_exchg()');
cmp_ok($x -> is_bool(),          '==', 0, '$x -> is_bool()');
cmp_ok($x -> is_perm(),          '==', 0, '$x -> is_perm()');
cmp_ok($x -> is_int(),           '==', 1, '$x -> is_int()');
cmp_ok($x -> is_diag(),          '==', 0, '$x -> is_diag()');
cmp_ok($x -> is_adiag(),         '==', 0, '$x -> is_adiag()');
cmp_ok($x -> is_tridiag(),       '==', 0, '$x -> is_tridiag()');
cmp_ok($x -> is_atridiag(),      '==', 1, '$x -> is_atridiag()');
cmp_ok($x -> is_pentadiag(),     '==', 1, '$x -> is_pentadiag()');
cmp_ok($x -> is_apentadiag(),    '==', 1, '$x -> is_apentadiag()');
cmp_ok($x -> is_heptadiag(),     '==', 0, '$x -> is_heptadiag()');
cmp_ok($x -> is_aheptadiag(),    '==', 0, '$x -> is_aheptadiag()');
cmp_ok($x -> is_band(0),         '==', 0, '$x -> is_band(0)');
cmp_ok($x -> is_aband(0),        '==', 0, '$x -> is_aband(0)');
cmp_ok($x -> is_band(1),         '==', 0, '$x -> is_band(1)');
cmp_ok($x -> is_aband(1),        '==', 1, '$x -> is_aband(1)');
cmp_ok($x -> is_band(2),         '==', 1, '$x -> is_band(2)');
cmp_ok($x -> is_aband(2),        '==', 1, '$x -> is_aband(2)');
cmp_ok($x -> is_band(3),         '==', 0, '$x -> is_band(3)');
cmp_ok($x -> is_aband(3),        '==', 0, '$x -> is_aband(3)');
cmp_ok($x -> is_band(4),         '==', 0, '$x -> is_band(4)');
cmp_ok($x -> is_aband(4),        '==', 0, '$x -> is_aband(4)');
cmp_ok($x -> is_triu(),          '==', 0, '$x -> is_triu()');
cmp_ok($x -> is_striu(),         '==', 0, '$x -> is_striu()');
cmp_ok($x -> is_tril(),          '==', 1, '$x -> is_tril()');
cmp_ok($x -> is_stril(),         '==', 1, '$x -> is_stril()');
cmp_ok($x -> is_atriu(),         '==', 0, '$x -> is_atriu()');
cmp_ok($x -> is_satriu(),        '==', 0, '$x -> is_satriu()');
cmp_ok($x -> is_atril(),         '==', 0, '$x -> is_atril()');
cmp_ok($x -> is_satril(),        '==', 0, '$x -> is_satril()');

# upper anti-triangular

note(<<'EOF');
$x = Math::Matrix -> new([[1, 2, 3],
                          [4, 5, 0],
                          [7, 0, 0]]);
EOF

$x = Math::Matrix -> new([[1, 2, 3],
                          [4, 5, 0],
                          [7, 0, 0]]);

cmp_ok($x -> is_empty(),         '==', 0, '$x -> is_empty()');
cmp_ok($x -> is_scalar(),        '==', 0, '$x -> is_scalar()');
cmp_ok($x -> is_vector(),        '==', 0, '$x -> is_vector()');
cmp_ok($x -> is_row(),           '==', 0, '$x -> is_row()');
cmp_ok($x -> is_col(),           '==', 0, '$x -> is_col()');
cmp_ok($x -> is_square(),        '==', 1, '$x -> is_square()');
cmp_ok($x -> is_symmetric(),     '==', 0, '$x -> is_symmetric()');
cmp_ok($x -> is_antisymmetric(), '==', 0, '$x -> is_antisymmetric()');
cmp_ok($x -> is_persymmetric(),  '==', 0, '$x -> is_persymmetric()');
cmp_ok($x -> is_hankel(),        '==', 0, '$x -> is_hankel()');
cmp_ok($x -> is_zero(),          '==', 0, '$x -> is_zero()');
cmp_ok($x -> is_one(),           '==', 0, '$x -> is_one()');
cmp_ok($x -> is_constant(),      '==', 0, '$x -> is_constant()');
cmp_ok($x -> is_identity(),      '==', 0, '$x -> is_identity()');
cmp_ok($x -> is_exchg(),         '==', 0, '$x -> is_exchg()');
cmp_ok($x -> is_bool(),          '==', 0, '$x -> is_bool()');
cmp_ok($x -> is_perm(),          '==', 0, '$x -> is_perm()');
cmp_ok($x -> is_int(),           '==', 1, '$x -> is_int()');
cmp_ok($x -> is_diag(),          '==', 0, '$x -> is_diag()');
cmp_ok($x -> is_adiag(),         '==', 0, '$x -> is_adiag()');
cmp_ok($x -> is_tridiag(),       '==', 0, '$x -> is_tridiag()');
cmp_ok($x -> is_atridiag(),      '==', 0, '$x -> is_atridiag()');
cmp_ok($x -> is_pentadiag(),     '==', 1, '$x -> is_pentadiag()');
cmp_ok($x -> is_apentadiag(),    '==', 1, '$x -> is_apentadiag()');
cmp_ok($x -> is_heptadiag(),     '==', 0, '$x -> is_heptadiag()');
cmp_ok($x -> is_aheptadiag(),    '==', 0, '$x -> is_aheptadiag()');
cmp_ok($x -> is_band(0),         '==', 0, '$x -> is_band(0)');
cmp_ok($x -> is_aband(0),        '==', 0, '$x -> is_aband(0)');
cmp_ok($x -> is_band(1),         '==', 0, '$x -> is_band(1)');
cmp_ok($x -> is_aband(1),        '==', 0, '$x -> is_aband(1)');
cmp_ok($x -> is_band(2),         '==', 1, '$x -> is_band(2)');
cmp_ok($x -> is_aband(2),        '==', 1, '$x -> is_aband(2)');
cmp_ok($x -> is_band(3),         '==', 0, '$x -> is_band(3)');
cmp_ok($x -> is_aband(3),        '==', 0, '$x -> is_aband(3)');
cmp_ok($x -> is_band(4),         '==', 0, '$x -> is_band(4)');
cmp_ok($x -> is_aband(4),        '==', 0, '$x -> is_aband(4)');
cmp_ok($x -> is_triu(),          '==', 0, '$x -> is_triu()');
cmp_ok($x -> is_striu(),         '==', 0, '$x -> is_striu()');
cmp_ok($x -> is_tril(),          '==', 0, '$x -> is_tril()');
cmp_ok($x -> is_stril(),         '==', 0, '$x -> is_stril()');
cmp_ok($x -> is_atriu(),         '==', 1, '$x -> is_atriu()');
cmp_ok($x -> is_satriu(),        '==', 0, '$x -> is_satriu()');
cmp_ok($x -> is_atril(),         '==', 0, '$x -> is_atril()');
cmp_ok($x -> is_satril(),        '==', 0, '$x -> is_satril()');

# strictly upper anti-triangular

note(<<'EOF');
$x = Math::Matrix -> new([[1, 2, 0],
                          [4, 0, 0],
                          [0, 0, 0]]);
EOF

$x = Math::Matrix -> new([[1, 2, 0],
                          [4, 0, 0],
                          [0, 0, 0]]);

cmp_ok($x -> is_empty(),         '==', 0, '$x -> is_empty()');
cmp_ok($x -> is_scalar(),        '==', 0, '$x -> is_scalar()');
cmp_ok($x -> is_vector(),        '==', 0, '$x -> is_vector()');
cmp_ok($x -> is_row(),           '==', 0, '$x -> is_row()');
cmp_ok($x -> is_col(),           '==', 0, '$x -> is_col()');
cmp_ok($x -> is_square(),        '==', 1, '$x -> is_square()');
cmp_ok($x -> is_symmetric(),     '==', 0, '$x -> is_symmetric()');
cmp_ok($x -> is_antisymmetric(), '==', 0, '$x -> is_antisymmetric()');
cmp_ok($x -> is_persymmetric(),  '==', 0, '$x -> is_persymmetric()');
cmp_ok($x -> is_hankel(),        '==', 0, '$x -> is_hankel()');
cmp_ok($x -> is_zero(),          '==', 0, '$x -> is_zero()');
cmp_ok($x -> is_one(),           '==', 0, '$x -> is_one()');
cmp_ok($x -> is_constant(),      '==', 0, '$x -> is_constant()');
cmp_ok($x -> is_identity(),      '==', 0, '$x -> is_identity()');
cmp_ok($x -> is_exchg(),         '==', 0, '$x -> is_exchg()');
cmp_ok($x -> is_bool(),          '==', 0, '$x -> is_bool()');
cmp_ok($x -> is_perm(),          '==', 0, '$x -> is_perm()');
cmp_ok($x -> is_int(),           '==', 1, '$x -> is_int()');
cmp_ok($x -> is_diag(),          '==', 0, '$x -> is_diag()');
cmp_ok($x -> is_adiag(),         '==', 0, '$x -> is_adiag()');
cmp_ok($x -> is_tridiag(),       '==', 1, '$x -> is_tridiag()');
cmp_ok($x -> is_atridiag(),      '==', 0, '$x -> is_atridiag()');
cmp_ok($x -> is_pentadiag(),     '==', 1, '$x -> is_pentadiag()');
cmp_ok($x -> is_apentadiag(),    '==', 1, '$x -> is_apentadiag()');
cmp_ok($x -> is_heptadiag(),     '==', 0, '$x -> is_heptadiag()');
cmp_ok($x -> is_aheptadiag(),    '==', 0, '$x -> is_aheptadiag()');
cmp_ok($x -> is_band(0),         '==', 0, '$x -> is_band(0)');
cmp_ok($x -> is_aband(0),        '==', 0, '$x -> is_aband(0)');
cmp_ok($x -> is_band(1),         '==', 1, '$x -> is_band(1)');
cmp_ok($x -> is_aband(1),        '==', 0, '$x -> is_aband(1)');
cmp_ok($x -> is_band(2),         '==', 1, '$x -> is_band(2)');
cmp_ok($x -> is_aband(2),        '==', 1, '$x -> is_aband(2)');
cmp_ok($x -> is_band(3),         '==', 0, '$x -> is_band(3)');
cmp_ok($x -> is_aband(3),        '==', 0, '$x -> is_aband(3)');
cmp_ok($x -> is_band(4),         '==', 0, '$x -> is_band(4)');
cmp_ok($x -> is_aband(4),        '==', 0, '$x -> is_aband(4)');
cmp_ok($x -> is_triu(),          '==', 0, '$x -> is_triu()');
cmp_ok($x -> is_striu(),         '==', 0, '$x -> is_striu()');
cmp_ok($x -> is_tril(),          '==', 0, '$x -> is_tril()');
cmp_ok($x -> is_stril(),         '==', 0, '$x -> is_stril()');
cmp_ok($x -> is_atriu(),         '==', 1, '$x -> is_atriu()');
cmp_ok($x -> is_satriu(),        '==', 1, '$x -> is_satriu()');
cmp_ok($x -> is_atril(),         '==', 0, '$x -> is_atril()');
cmp_ok($x -> is_satril(),        '==', 0, '$x -> is_satril()');

# lower anti-triangular

note(<<'EOF');
$x = Math::Matrix -> new([[0, 0, 3],
                          [0, 5, 6],
                          [7, 8, 9]]);
EOF

$x = Math::Matrix -> new([[0, 0, 3],
                          [0, 5, 6],
                          [7, 8, 9]]);

cmp_ok($x -> is_empty(),         '==', 0, '$x -> is_empty()');
cmp_ok($x -> is_scalar(),        '==', 0, '$x -> is_scalar()');
cmp_ok($x -> is_vector(),        '==', 0, '$x -> is_vector()');
cmp_ok($x -> is_row(),           '==', 0, '$x -> is_row()');
cmp_ok($x -> is_col(),           '==', 0, '$x -> is_col()');
cmp_ok($x -> is_square(),        '==', 1, '$x -> is_square()');
cmp_ok($x -> is_symmetric(),     '==', 0, '$x -> is_symmetric()');
cmp_ok($x -> is_antisymmetric(), '==', 0, '$x -> is_antisymmetric()');
cmp_ok($x -> is_persymmetric(),  '==', 0, '$x -> is_persymmetric()');
cmp_ok($x -> is_hankel(),        '==', 0, '$x -> is_hankel()');
cmp_ok($x -> is_zero(),          '==', 0, '$x -> is_zero()');
cmp_ok($x -> is_one(),           '==', 0, '$x -> is_one()');
cmp_ok($x -> is_constant(),      '==', 0, '$x -> is_constant()');
cmp_ok($x -> is_identity(),      '==', 0, '$x -> is_identity()');
cmp_ok($x -> is_exchg(),         '==', 0, '$x -> is_exchg()');
cmp_ok($x -> is_bool(),          '==', 0, '$x -> is_bool()');
cmp_ok($x -> is_perm(),          '==', 0, '$x -> is_perm()');
cmp_ok($x -> is_int(),           '==', 1, '$x -> is_int()');
cmp_ok($x -> is_diag(),          '==', 0, '$x -> is_diag()');
cmp_ok($x -> is_adiag(),         '==', 0, '$x -> is_adiag()');
cmp_ok($x -> is_tridiag(),       '==', 0, '$x -> is_tridiag()');
cmp_ok($x -> is_atridiag(),      '==', 0, '$x -> is_atridiag()');
cmp_ok($x -> is_pentadiag(),     '==', 1, '$x -> is_pentadiag()');
cmp_ok($x -> is_apentadiag(),    '==', 1, '$x -> is_apentadiag()');
cmp_ok($x -> is_heptadiag(),     '==', 0, '$x -> is_heptadiag()');
cmp_ok($x -> is_aheptadiag(),    '==', 0, '$x -> is_aheptadiag()');
cmp_ok($x -> is_band(0),         '==', 0, '$x -> is_band(0)');
cmp_ok($x -> is_aband(0),        '==', 0, '$x -> is_aband(0)');
cmp_ok($x -> is_band(1),         '==', 0, '$x -> is_band(1)');
cmp_ok($x -> is_aband(1),        '==', 0, '$x -> is_aband(1)');
cmp_ok($x -> is_band(2),         '==', 1, '$x -> is_band(2)');
cmp_ok($x -> is_aband(2),        '==', 1, '$x -> is_aband(2)');
cmp_ok($x -> is_band(3),         '==', 0, '$x -> is_band(3)');
cmp_ok($x -> is_aband(3),        '==', 0, '$x -> is_aband(3)');
cmp_ok($x -> is_band(4),         '==', 0, '$x -> is_band(4)');
cmp_ok($x -> is_aband(4),        '==', 0, '$x -> is_aband(4)');
cmp_ok($x -> is_triu(),          '==', 0, '$x -> is_triu()');
cmp_ok($x -> is_striu(),         '==', 0, '$x -> is_striu()');
cmp_ok($x -> is_tril(),          '==', 0, '$x -> is_tril()');
cmp_ok($x -> is_stril(),         '==', 0, '$x -> is_stril()');
cmp_ok($x -> is_atriu(),         '==', 0, '$x -> is_atriu()');
cmp_ok($x -> is_satriu(),        '==', 0, '$x -> is_satriu()');
cmp_ok($x -> is_atril(),         '==', 1, '$x -> is_atril()');
cmp_ok($x -> is_satril(),        '==', 0, '$x -> is_satril()');

# strictly lower anti-triangular

note(<<'EOF');
$x = Math::Matrix -> new([[0, 0, 0],
                          [0, 0, 6],
                          [0, 8, 9]]);
EOF

$x = Math::Matrix -> new([[0, 0, 0],
                          [0, 0, 6],
                          [0, 8, 9]]);

cmp_ok($x -> is_empty(),         '==', 0, '$x -> is_empty()');
cmp_ok($x -> is_scalar(),        '==', 0, '$x -> is_scalar()');
cmp_ok($x -> is_vector(),        '==', 0, '$x -> is_vector()');
cmp_ok($x -> is_row(),           '==', 0, '$x -> is_row()');
cmp_ok($x -> is_col(),           '==', 0, '$x -> is_col()');
cmp_ok($x -> is_square(),        '==', 1, '$x -> is_square()');
cmp_ok($x -> is_symmetric(),     '==', 0, '$x -> is_symmetric()');
cmp_ok($x -> is_antisymmetric(), '==', 0, '$x -> is_antisymmetric()');
cmp_ok($x -> is_persymmetric(),  '==', 0, '$x -> is_persymmetric()');
cmp_ok($x -> is_hankel(),        '==', 0, '$x -> is_hankel()');
cmp_ok($x -> is_zero(),          '==', 0, '$x -> is_zero()');
cmp_ok($x -> is_one(),           '==', 0, '$x -> is_one()');
cmp_ok($x -> is_constant(),      '==', 0, '$x -> is_constant()');
cmp_ok($x -> is_identity(),      '==', 0, '$x -> is_identity()');
cmp_ok($x -> is_exchg(),         '==', 0, '$x -> is_exchg()');
cmp_ok($x -> is_bool(),          '==', 0, '$x -> is_bool()');
cmp_ok($x -> is_perm(),          '==', 0, '$x -> is_perm()');
cmp_ok($x -> is_int(),           '==', 1, '$x -> is_int()');
cmp_ok($x -> is_diag(),          '==', 0, '$x -> is_diag()');
cmp_ok($x -> is_adiag(),         '==', 0, '$x -> is_adiag()');
cmp_ok($x -> is_tridiag(),       '==', 1, '$x -> is_tridiag()');
cmp_ok($x -> is_atridiag(),      '==', 0, '$x -> is_atridiag()');
cmp_ok($x -> is_pentadiag(),     '==', 1, '$x -> is_pentadiag()');
cmp_ok($x -> is_apentadiag(),    '==', 1, '$x -> is_apentadiag()');
cmp_ok($x -> is_heptadiag(),     '==', 0, '$x -> is_heptadiag()');
cmp_ok($x -> is_aheptadiag(),    '==', 0, '$x -> is_aheptadiag()');
cmp_ok($x -> is_band(0),         '==', 0, '$x -> is_band(0)');
cmp_ok($x -> is_aband(0),        '==', 0, '$x -> is_aband(0)');
cmp_ok($x -> is_band(1),         '==', 1, '$x -> is_band(1)');
cmp_ok($x -> is_aband(1),        '==', 0, '$x -> is_aband(1)');
cmp_ok($x -> is_band(2),         '==', 1, '$x -> is_band(2)');
cmp_ok($x -> is_aband(2),        '==', 1, '$x -> is_aband(2)');
cmp_ok($x -> is_band(3),         '==', 0, '$x -> is_band(3)');
cmp_ok($x -> is_aband(3),        '==', 0, '$x -> is_aband(3)');
cmp_ok($x -> is_band(4),         '==', 0, '$x -> is_band(4)');
cmp_ok($x -> is_aband(4),        '==', 0, '$x -> is_aband(4)');
cmp_ok($x -> is_triu(),          '==', 0, '$x -> is_triu()');
cmp_ok($x -> is_striu(),         '==', 0, '$x -> is_striu()');
cmp_ok($x -> is_tril(),          '==', 0, '$x -> is_tril()');
cmp_ok($x -> is_stril(),         '==', 0, '$x -> is_stril()');
cmp_ok($x -> is_atriu(),         '==', 0, '$x -> is_atriu()');
cmp_ok($x -> is_satriu(),        '==', 0, '$x -> is_satriu()');
cmp_ok($x -> is_atril(),         '==', 1, '$x -> is_atril()');
cmp_ok($x -> is_satril(),        '==', 1, '$x -> is_satril()');

# tridiagonal

note(<<'EOF');
$x = Math::Matrix -> new([[7, 7, 0, 0, 0, 0],
                          [7, 7, 7, 0, 0, 0],
                          [0, 7, 7, 7, 0, 0],
                          [0, 0, 7, 7, 7, 0],
                          [0, 0, 0, 7, 7, 7],
                          [0, 0, 0, 0, 7, 7]]);
EOF

$x = Math::Matrix -> new([[7, 7, 0, 0, 0, 0],
                          [7, 7, 7, 0, 0, 0],
                          [0, 7, 7, 7, 0, 0],
                          [0, 0, 7, 7, 7, 0],
                          [0, 0, 0, 7, 7, 7],
                          [0, 0, 0, 0, 7, 7]]);

cmp_ok($x -> is_empty(),         '==', 0, '$x -> is_empty()');
cmp_ok($x -> is_scalar(),        '==', 0, '$x -> is_scalar()');
cmp_ok($x -> is_vector(),        '==', 0, '$x -> is_vector()');
cmp_ok($x -> is_row(),           '==', 0, '$x -> is_row()');
cmp_ok($x -> is_col(),           '==', 0, '$x -> is_col()');
cmp_ok($x -> is_square(),        '==', 1, '$x -> is_square()');
cmp_ok($x -> is_symmetric(),     '==', 1, '$x -> is_symmetric()');
cmp_ok($x -> is_antisymmetric(), '==', 0, '$x -> is_antisymmetric()');
cmp_ok($x -> is_persymmetric(),  '==', 1, '$x -> is_persymmetric()');
cmp_ok($x -> is_hankel(),        '==', 1, '$x -> is_hankel()');
cmp_ok($x -> is_zero(),          '==', 0, '$x -> is_zero()');
cmp_ok($x -> is_one(),           '==', 0, '$x -> is_one()');
cmp_ok($x -> is_constant(),      '==', 0, '$x -> is_constant()');
cmp_ok($x -> is_identity(),      '==', 0, '$x -> is_identity()');
cmp_ok($x -> is_exchg(),         '==', 0, '$x -> is_exchg()');
cmp_ok($x -> is_bool(),          '==', 0, '$x -> is_bool()');
cmp_ok($x -> is_perm(),          '==', 0, '$x -> is_perm()');
cmp_ok($x -> is_int(),           '==', 1, '$x -> is_int()');
cmp_ok($x -> is_diag(),          '==', 0, '$x -> is_diag()');
cmp_ok($x -> is_adiag(),         '==', 0, '$x -> is_adiag()');
cmp_ok($x -> is_tridiag(),       '==', 1, '$x -> is_tridiag()');
cmp_ok($x -> is_atridiag(),      '==', 0, '$x -> is_atridiag()');
cmp_ok($x -> is_pentadiag(),     '==', 1, '$x -> is_pentadiag()');
cmp_ok($x -> is_apentadiag(),    '==', 0, '$x -> is_apentadiag()');
cmp_ok($x -> is_heptadiag(),     '==', 1, '$x -> is_heptadiag()');
cmp_ok($x -> is_aheptadiag(),    '==', 0, '$x -> is_aheptadiag()');
cmp_ok($x -> is_band(0),         '==', 0, '$x -> is_band(0)');
cmp_ok($x -> is_aband(0),        '==', 0, '$x -> is_aband(0)');
cmp_ok($x -> is_band(1),         '==', 1, '$x -> is_band(1)');
cmp_ok($x -> is_aband(1),        '==', 0, '$x -> is_aband(1)');
cmp_ok($x -> is_band(2),         '==', 1, '$x -> is_band(2)');
cmp_ok($x -> is_aband(2),        '==', 0, '$x -> is_aband(2)');
cmp_ok($x -> is_band(3),         '==', 1, '$x -> is_band(3)');
cmp_ok($x -> is_aband(3),        '==', 0, '$x -> is_aband(3)');
cmp_ok($x -> is_band(4),         '==', 1, '$x -> is_band(4)');
cmp_ok($x -> is_aband(4),        '==', 0, '$x -> is_aband(4)');
cmp_ok($x -> is_triu(),          '==', 0, '$x -> is_triu()');
cmp_ok($x -> is_striu(),         '==', 0, '$x -> is_striu()');
cmp_ok($x -> is_tril(),          '==', 0, '$x -> is_tril()');
cmp_ok($x -> is_stril(),         '==', 0, '$x -> is_stril()');
cmp_ok($x -> is_atriu(),         '==', 0, '$x -> is_atriu()');
cmp_ok($x -> is_satriu(),        '==', 0, '$x -> is_satriu()');
cmp_ok($x -> is_atril(),         '==', 0, '$x -> is_atril()');
cmp_ok($x -> is_satril(),        '==', 0, '$x -> is_satril()');

# anti-tridiagonal

note(<<'EOF');
$x = Math::Matrix -> new([[0, 0, 0, 0, 7, 7],
                          [0, 0, 0, 7, 7, 7],
                          [0, 0, 7, 7, 7, 0],
                          [0, 7, 7, 7, 0, 0],
                          [7, 7, 7, 0, 0, 0],
                          [7, 7, 0, 0, 0, 0]]);
EOF

$x = Math::Matrix -> new([[0, 0, 0, 0, 7, 7],
                          [0, 0, 0, 7, 7, 7],
                          [0, 0, 7, 7, 7, 0],
                          [0, 7, 7, 7, 0, 0],
                          [7, 7, 7, 0, 0, 0],
                          [7, 7, 0, 0, 0, 0]]);

cmp_ok($x -> is_empty(),         '==', 0, '$x -> is_empty()');
cmp_ok($x -> is_scalar(),        '==', 0, '$x -> is_scalar()');
cmp_ok($x -> is_vector(),        '==', 0, '$x -> is_vector()');
cmp_ok($x -> is_row(),           '==', 0, '$x -> is_row()');
cmp_ok($x -> is_col(),           '==', 0, '$x -> is_col()');
cmp_ok($x -> is_square(),        '==', 1, '$x -> is_square()');
cmp_ok($x -> is_symmetric(),     '==', 1, '$x -> is_symmetric()');
cmp_ok($x -> is_antisymmetric(), '==', 0, '$x -> is_antisymmetric()');
cmp_ok($x -> is_persymmetric(),  '==', 1, '$x -> is_persymmetric()');
cmp_ok($x -> is_hankel(),        '==', 0, '$x -> is_hankel()');
cmp_ok($x -> is_zero(),          '==', 0, '$x -> is_zero()');
cmp_ok($x -> is_one(),           '==', 0, '$x -> is_one()');
cmp_ok($x -> is_constant(),      '==', 0, '$x -> is_constant()');
cmp_ok($x -> is_identity(),      '==', 0, '$x -> is_identity()');
cmp_ok($x -> is_exchg(),         '==', 0, '$x -> is_exchg()');
cmp_ok($x -> is_bool(),          '==', 0, '$x -> is_bool()');
cmp_ok($x -> is_perm(),          '==', 0, '$x -> is_perm()');
cmp_ok($x -> is_int(),           '==', 1, '$x -> is_int()');
cmp_ok($x -> is_diag(),          '==', 0, '$x -> is_diag()');
cmp_ok($x -> is_adiag(),         '==', 0, '$x -> is_adiag()');
cmp_ok($x -> is_tridiag(),       '==', 0, '$x -> is_tridiag()');
cmp_ok($x -> is_atridiag(),      '==', 1, '$x -> is_atridiag()');
cmp_ok($x -> is_pentadiag(),     '==', 0, '$x -> is_pentadiag()');
cmp_ok($x -> is_apentadiag(),    '==', 1, '$x -> is_apentadiag()');
cmp_ok($x -> is_heptadiag(),     '==', 0, '$x -> is_heptadiag()');
cmp_ok($x -> is_aheptadiag(),    '==', 1, '$x -> is_aheptadiag()');
cmp_ok($x -> is_band(0),         '==', 0, '$x -> is_band(0)');
cmp_ok($x -> is_aband(0),        '==', 0, '$x -> is_aband(0)');
cmp_ok($x -> is_band(1),         '==', 0, '$x -> is_band(1)');
cmp_ok($x -> is_aband(1),        '==', 1, '$x -> is_aband(1)');
cmp_ok($x -> is_band(2),         '==', 0, '$x -> is_band(2)');
cmp_ok($x -> is_aband(2),        '==', 1, '$x -> is_aband(2)');
cmp_ok($x -> is_band(3),         '==', 0, '$x -> is_band(3)');
cmp_ok($x -> is_aband(3),        '==', 1, '$x -> is_aband(3)');
cmp_ok($x -> is_band(4),         '==', 0, '$x -> is_band(4)');
cmp_ok($x -> is_aband(4),        '==', 1, '$x -> is_aband(4)');
cmp_ok($x -> is_triu(),          '==', 0, '$x -> is_triu()');
cmp_ok($x -> is_striu(),         '==', 0, '$x -> is_striu()');
cmp_ok($x -> is_tril(),          '==', 0, '$x -> is_tril()');
cmp_ok($x -> is_stril(),         '==', 0, '$x -> is_stril()');
cmp_ok($x -> is_atriu(),         '==', 0, '$x -> is_atriu()');
cmp_ok($x -> is_satriu(),        '==', 0, '$x -> is_satriu()');
cmp_ok($x -> is_atril(),         '==', 0, '$x -> is_atril()');
cmp_ok($x -> is_satril(),        '==', 0, '$x -> is_satril()');

# pentadiagonal

note(<<'EOF');
$x = Math::Matrix -> new([[7, 7, 7, 0, 0, 0],
                          [7, 7, 7, 7, 0, 0],
                          [7, 7, 7, 7, 7, 0],
                          [0, 7, 7, 7, 7, 7],
                          [0, 0, 7, 7, 7, 7],
                          [0, 0, 0, 7, 7, 7]]);
EOF

$x = Math::Matrix -> new([[7, 7, 7, 0, 0, 0],
                          [7, 7, 7, 7, 0, 0],
                          [7, 7, 7, 7, 7, 0],
                          [0, 7, 7, 7, 7, 7],
                          [0, 0, 7, 7, 7, 7],
                          [0, 0, 0, 7, 7, 7]]);

cmp_ok($x -> is_empty(),         '==', 0, '$x -> is_empty()');
cmp_ok($x -> is_scalar(),        '==', 0, '$x -> is_scalar()');
cmp_ok($x -> is_vector(),        '==', 0, '$x -> is_vector()');
cmp_ok($x -> is_row(),           '==', 0, '$x -> is_row()');
cmp_ok($x -> is_col(),           '==', 0, '$x -> is_col()');
cmp_ok($x -> is_square(),        '==', 1, '$x -> is_square()');
cmp_ok($x -> is_symmetric(),     '==', 1, '$x -> is_symmetric()');
cmp_ok($x -> is_antisymmetric(), '==', 0, '$x -> is_antisymmetric()');
cmp_ok($x -> is_persymmetric(),  '==', 1, '$x -> is_persymmetric()');
cmp_ok($x -> is_hankel(),        '==', 1, '$x -> is_hankel()');
cmp_ok($x -> is_zero(),          '==', 0, '$x -> is_zero()');
cmp_ok($x -> is_one(),           '==', 0, '$x -> is_one()');
cmp_ok($x -> is_constant(),      '==', 0, '$x -> is_constant()');
cmp_ok($x -> is_identity(),      '==', 0, '$x -> is_identity()');
cmp_ok($x -> is_exchg(),         '==', 0, '$x -> is_exchg()');
cmp_ok($x -> is_bool(),          '==', 0, '$x -> is_bool()');
cmp_ok($x -> is_perm(),          '==', 0, '$x -> is_perm()');
cmp_ok($x -> is_int(),           '==', 1, '$x -> is_int()');
cmp_ok($x -> is_diag(),          '==', 0, '$x -> is_diag()');
cmp_ok($x -> is_adiag(),         '==', 0, '$x -> is_adiag()');
cmp_ok($x -> is_tridiag(),       '==', 0, '$x -> is_tridiag()');
cmp_ok($x -> is_atridiag(),      '==', 0, '$x -> is_atridiag()');
cmp_ok($x -> is_pentadiag(),     '==', 1, '$x -> is_pentadiag()');
cmp_ok($x -> is_apentadiag(),    '==', 0, '$x -> is_apentadiag()');
cmp_ok($x -> is_heptadiag(),     '==', 1, '$x -> is_heptadiag()');
cmp_ok($x -> is_aheptadiag(),    '==', 0, '$x -> is_aheptadiag()');
cmp_ok($x -> is_band(0),         '==', 0, '$x -> is_band(0)');
cmp_ok($x -> is_aband(0),        '==', 0, '$x -> is_aband(0)');
cmp_ok($x -> is_band(1),         '==', 0, '$x -> is_band(1)');
cmp_ok($x -> is_aband(1),        '==', 0, '$x -> is_aband(1)');
cmp_ok($x -> is_band(2),         '==', 1, '$x -> is_band(2)');
cmp_ok($x -> is_aband(2),        '==', 0, '$x -> is_aband(2)');
cmp_ok($x -> is_band(3),         '==', 1, '$x -> is_band(3)');
cmp_ok($x -> is_aband(3),        '==', 0, '$x -> is_aband(3)');
cmp_ok($x -> is_band(4),         '==', 1, '$x -> is_band(4)');
cmp_ok($x -> is_aband(4),        '==', 0, '$x -> is_aband(4)');
cmp_ok($x -> is_triu(),          '==', 0, '$x -> is_triu()');
cmp_ok($x -> is_striu(),         '==', 0, '$x -> is_striu()');
cmp_ok($x -> is_tril(),          '==', 0, '$x -> is_tril()');
cmp_ok($x -> is_stril(),         '==', 0, '$x -> is_stril()');
cmp_ok($x -> is_atriu(),         '==', 0, '$x -> is_atriu()');
cmp_ok($x -> is_satriu(),        '==', 0, '$x -> is_satriu()');
cmp_ok($x -> is_atril(),         '==', 0, '$x -> is_atril()');
cmp_ok($x -> is_satril(),        '==', 0, '$x -> is_satril()');

# anti-pentadiagonal

note(<<'EOF');
$x = Math::Matrix -> new([[0, 0, 0, 7, 7, 7],
                          [0, 0, 7, 7, 7, 7],
                          [0, 7, 7, 7, 7, 7],
                          [7, 7, 7, 7, 7, 0],
                          [7, 7, 7, 7, 0, 0],
                          [7, 7, 7, 0, 0, 0]]);
EOF

$x = Math::Matrix -> new([[0, 0, 0, 7, 7, 7],
                          [0, 0, 7, 7, 7, 7],
                          [0, 7, 7, 7, 7, 7],
                          [7, 7, 7, 7, 7, 0],
                          [7, 7, 7, 7, 0, 0],
                          [7, 7, 7, 0, 0, 0]]);

cmp_ok($x -> is_empty(),         '==', 0, '$x -> is_empty()');
cmp_ok($x -> is_scalar(),        '==', 0, '$x -> is_scalar()');
cmp_ok($x -> is_vector(),        '==', 0, '$x -> is_vector()');
cmp_ok($x -> is_row(),           '==', 0, '$x -> is_row()');
cmp_ok($x -> is_col(),           '==', 0, '$x -> is_col()');
cmp_ok($x -> is_square(),        '==', 1, '$x -> is_square()');
cmp_ok($x -> is_symmetric(),     '==', 1, '$x -> is_symmetric()');
cmp_ok($x -> is_antisymmetric(), '==', 0, '$x -> is_antisymmetric()');
cmp_ok($x -> is_persymmetric(),  '==', 1, '$x -> is_persymmetric()');
cmp_ok($x -> is_hankel(),        '==', 0, '$x -> is_hankel()');
cmp_ok($x -> is_zero(),          '==', 0, '$x -> is_zero()');
cmp_ok($x -> is_one(),           '==', 0, '$x -> is_one()');
cmp_ok($x -> is_constant(),      '==', 0, '$x -> is_constant()');
cmp_ok($x -> is_identity(),      '==', 0, '$x -> is_identity()');
cmp_ok($x -> is_exchg(),         '==', 0, '$x -> is_exchg()');
cmp_ok($x -> is_bool(),          '==', 0, '$x -> is_bool()');
cmp_ok($x -> is_perm(),          '==', 0, '$x -> is_perm()');
cmp_ok($x -> is_int(),           '==', 1, '$x -> is_int()');
cmp_ok($x -> is_diag(),          '==', 0, '$x -> is_diag()');
cmp_ok($x -> is_adiag(),         '==', 0, '$x -> is_adiag()');
cmp_ok($x -> is_tridiag(),       '==', 0, '$x -> is_tridiag()');
cmp_ok($x -> is_atridiag(),      '==', 0, '$x -> is_atridiag()');
cmp_ok($x -> is_pentadiag(),     '==', 0, '$x -> is_pentadiag()');
cmp_ok($x -> is_apentadiag(),    '==', 1, '$x -> is_apentadiag()');
cmp_ok($x -> is_heptadiag(),     '==', 0, '$x -> is_heptadiag()');
cmp_ok($x -> is_aheptadiag(),    '==', 1, '$x -> is_aheptadiag()');
cmp_ok($x -> is_band(0),         '==', 0, '$x -> is_band(0)');
cmp_ok($x -> is_aband(0),        '==', 0, '$x -> is_aband(0)');
cmp_ok($x -> is_band(1),         '==', 0, '$x -> is_band(1)');
cmp_ok($x -> is_aband(1),        '==', 0, '$x -> is_aband(1)');
cmp_ok($x -> is_band(2),         '==', 0, '$x -> is_band(2)');
cmp_ok($x -> is_aband(2),        '==', 1, '$x -> is_aband(2)');
cmp_ok($x -> is_band(3),         '==', 0, '$x -> is_band(3)');
cmp_ok($x -> is_aband(3),        '==', 1, '$x -> is_aband(3)');
cmp_ok($x -> is_band(4),         '==', 0, '$x -> is_band(4)');
cmp_ok($x -> is_aband(4),        '==', 1, '$x -> is_aband(4)');
cmp_ok($x -> is_triu(),          '==', 0, '$x -> is_triu()');
cmp_ok($x -> is_striu(),         '==', 0, '$x -> is_striu()');
cmp_ok($x -> is_tril(),          '==', 0, '$x -> is_tril()');
cmp_ok($x -> is_stril(),         '==', 0, '$x -> is_stril()');
cmp_ok($x -> is_atriu(),         '==', 0, '$x -> is_atriu()');
cmp_ok($x -> is_satriu(),        '==', 0, '$x -> is_satriu()');
cmp_ok($x -> is_atril(),         '==', 0, '$x -> is_atril()');
cmp_ok($x -> is_satril(),        '==', 0, '$x -> is_satril()');

# heptadiagonal

note(<<'EOF');
$x = Math::Matrix -> new([[7, 7, 7, 7, 0, 0],
                          [7, 7, 7, 7, 7, 0],
                          [7, 7, 7, 7, 7, 7],
                          [7, 7, 7, 7, 7, 7],
                          [0, 7, 7, 7, 7, 7],
                          [0, 0, 7, 7, 7, 7]]);
EOF

$x = Math::Matrix -> new([[7, 7, 7, 7, 0, 0],
                          [7, 7, 7, 7, 7, 0],
                          [7, 7, 7, 7, 7, 7],
                          [7, 7, 7, 7, 7, 7],
                          [0, 7, 7, 7, 7, 7],
                          [0, 0, 7, 7, 7, 7]]);

cmp_ok($x -> is_empty(),         '==', 0, '$x -> is_empty()');
cmp_ok($x -> is_scalar(),        '==', 0, '$x -> is_scalar()');
cmp_ok($x -> is_vector(),        '==', 0, '$x -> is_vector()');
cmp_ok($x -> is_row(),           '==', 0, '$x -> is_row()');
cmp_ok($x -> is_col(),           '==', 0, '$x -> is_col()');
cmp_ok($x -> is_square(),        '==', 1, '$x -> is_square()');
cmp_ok($x -> is_symmetric(),     '==', 1, '$x -> is_symmetric()');
cmp_ok($x -> is_antisymmetric(), '==', 0, '$x -> is_antisymmetric()');
cmp_ok($x -> is_persymmetric(),  '==', 1, '$x -> is_persymmetric()');
cmp_ok($x -> is_hankel(),        '==', 1, '$x -> is_hankel()');
cmp_ok($x -> is_zero(),          '==', 0, '$x -> is_zero()');
cmp_ok($x -> is_one(),           '==', 0, '$x -> is_one()');
cmp_ok($x -> is_constant(),      '==', 0, '$x -> is_constant()');
cmp_ok($x -> is_identity(),      '==', 0, '$x -> is_identity()');
cmp_ok($x -> is_exchg(),         '==', 0, '$x -> is_exchg()');
cmp_ok($x -> is_bool(),          '==', 0, '$x -> is_bool()');
cmp_ok($x -> is_perm(),          '==', 0, '$x -> is_perm()');
cmp_ok($x -> is_int(),           '==', 1, '$x -> is_int()');
cmp_ok($x -> is_diag(),          '==', 0, '$x -> is_diag()');
cmp_ok($x -> is_adiag(),         '==', 0, '$x -> is_adiag()');
cmp_ok($x -> is_tridiag(),       '==', 0, '$x -> is_tridiag()');
cmp_ok($x -> is_atridiag(),      '==', 0, '$x -> is_atridiag()');
cmp_ok($x -> is_pentadiag(),     '==', 0, '$x -> is_pentadiag()');
cmp_ok($x -> is_apentadiag(),    '==', 0, '$x -> is_apentadiag()');
cmp_ok($x -> is_heptadiag(),     '==', 1, '$x -> is_heptadiag()');
cmp_ok($x -> is_aheptadiag(),    '==', 0, '$x -> is_aheptadiag()');
cmp_ok($x -> is_band(0),         '==', 0, '$x -> is_band(0)');
cmp_ok($x -> is_aband(0),        '==', 0, '$x -> is_aband(0)');
cmp_ok($x -> is_band(1),         '==', 0, '$x -> is_band(1)');
cmp_ok($x -> is_aband(1),        '==', 0, '$x -> is_aband(1)');
cmp_ok($x -> is_band(2),         '==', 0, '$x -> is_band(2)');
cmp_ok($x -> is_aband(2),        '==', 0, '$x -> is_aband(2)');
cmp_ok($x -> is_band(3),         '==', 1, '$x -> is_band(3)');
cmp_ok($x -> is_aband(3),        '==', 0, '$x -> is_aband(3)');
cmp_ok($x -> is_band(4),         '==', 1, '$x -> is_band(4)');
cmp_ok($x -> is_aband(4),        '==', 0, '$x -> is_aband(4)');
cmp_ok($x -> is_triu(),          '==', 0, '$x -> is_triu()');
cmp_ok($x -> is_striu(),         '==', 0, '$x -> is_striu()');
cmp_ok($x -> is_tril(),          '==', 0, '$x -> is_tril()');
cmp_ok($x -> is_stril(),         '==', 0, '$x -> is_stril()');
cmp_ok($x -> is_atriu(),         '==', 0, '$x -> is_atriu()');
cmp_ok($x -> is_satriu(),        '==', 0, '$x -> is_satriu()');
cmp_ok($x -> is_atril(),         '==', 0, '$x -> is_atril()');
cmp_ok($x -> is_satril(),        '==', 0, '$x -> is_satril()');

# anti-heptadiagonal

note(<<'EOF');
$x = Math::Matrix -> new([[0, 0, 7, 7, 7, 7],
                          [0, 7, 7, 7, 7, 7],
                          [7, 7, 7, 7, 7, 7],
                          [7, 7, 7, 7, 7, 7],
                          [7, 7, 7, 7, 7, 0],
                          [7, 7, 7, 7, 0, 0]]);
EOF

$x = Math::Matrix -> new([[0, 0, 7, 7, 7, 7],
                          [0, 7, 7, 7, 7, 7],
                          [7, 7, 7, 7, 7, 7],
                          [7, 7, 7, 7, 7, 7],
                          [7, 7, 7, 7, 7, 0],
                          [7, 7, 7, 7, 0, 0]]);

cmp_ok($x -> is_empty(),         '==', 0, '$x -> is_empty()');
cmp_ok($x -> is_scalar(),        '==', 0, '$x -> is_scalar()');
cmp_ok($x -> is_vector(),        '==', 0, '$x -> is_vector()');
cmp_ok($x -> is_row(),           '==', 0, '$x -> is_row()');
cmp_ok($x -> is_col(),           '==', 0, '$x -> is_col()');
cmp_ok($x -> is_square(),        '==', 1, '$x -> is_square()');
cmp_ok($x -> is_symmetric(),     '==', 1, '$x -> is_symmetric()');
cmp_ok($x -> is_antisymmetric(), '==', 0, '$x -> is_antisymmetric()');
cmp_ok($x -> is_persymmetric(),  '==', 1, '$x -> is_persymmetric()');
cmp_ok($x -> is_hankel(),        '==', 0, '$x -> is_hankel()');
cmp_ok($x -> is_zero(),          '==', 0, '$x -> is_zero()');
cmp_ok($x -> is_one(),           '==', 0, '$x -> is_one()');
cmp_ok($x -> is_constant(),      '==', 0, '$x -> is_constant()');
cmp_ok($x -> is_identity(),      '==', 0, '$x -> is_identity()');
cmp_ok($x -> is_exchg(),         '==', 0, '$x -> is_exchg()');
cmp_ok($x -> is_bool(),          '==', 0, '$x -> is_bool()');
cmp_ok($x -> is_perm(),          '==', 0, '$x -> is_perm()');
cmp_ok($x -> is_int(),           '==', 1, '$x -> is_int()');
cmp_ok($x -> is_diag(),          '==', 0, '$x -> is_diag()');
cmp_ok($x -> is_adiag(),         '==', 0, '$x -> is_adiag()');
cmp_ok($x -> is_tridiag(),       '==', 0, '$x -> is_tridiag()');
cmp_ok($x -> is_atridiag(),      '==', 0, '$x -> is_atridiag()');
cmp_ok($x -> is_pentadiag(),     '==', 0, '$x -> is_pentadiag()');
cmp_ok($x -> is_apentadiag(),    '==', 0, '$x -> is_apentadiag()');
cmp_ok($x -> is_heptadiag(),     '==', 0, '$x -> is_heptadiag()');
cmp_ok($x -> is_aheptadiag(),    '==', 1, '$x -> is_aheptadiag()');
cmp_ok($x -> is_band(0),         '==', 0, '$x -> is_band(0)');
cmp_ok($x -> is_aband(0),        '==', 0, '$x -> is_aband(0)');
cmp_ok($x -> is_band(1),         '==', 0, '$x -> is_band(1)');
cmp_ok($x -> is_aband(1),        '==', 0, '$x -> is_aband(1)');
cmp_ok($x -> is_band(2),         '==', 0, '$x -> is_band(2)');
cmp_ok($x -> is_aband(2),        '==', 0, '$x -> is_aband(2)');
cmp_ok($x -> is_band(3),         '==', 0, '$x -> is_band(3)');
cmp_ok($x -> is_aband(3),        '==', 1, '$x -> is_aband(3)');
cmp_ok($x -> is_band(4),         '==', 0, '$x -> is_band(4)');
cmp_ok($x -> is_aband(4),        '==', 1, '$x -> is_aband(4)');
cmp_ok($x -> is_triu(),          '==', 0, '$x -> is_triu()');
cmp_ok($x -> is_striu(),         '==', 0, '$x -> is_striu()');
cmp_ok($x -> is_tril(),          '==', 0, '$x -> is_tril()');
cmp_ok($x -> is_stril(),         '==', 0, '$x -> is_stril()');
cmp_ok($x -> is_atriu(),         '==', 0, '$x -> is_atriu()');
cmp_ok($x -> is_satriu(),        '==', 0, '$x -> is_satriu()');
cmp_ok($x -> is_atril(),         '==', 0, '$x -> is_atril()');
cmp_ok($x -> is_satril(),        '==', 0, '$x -> is_satril()');
