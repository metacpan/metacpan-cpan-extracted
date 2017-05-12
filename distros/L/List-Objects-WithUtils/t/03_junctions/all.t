use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'array';

ok array()->all_items->does('List::Objects::WithUtils::Role::Array');

# ==
ok array(3, 3.0)->all_items == 3,     '==';
ok array(3, 3  )->all_items == 3,     '==';
ok array(3, 3.0, 3)->all_items == 3,  '==';
ok not( array(2, 3)->all_items == 3 ),    'negative ==';
ok not( array(2, 3, 3)->all_items == 3 ), 'negative ==';

# !=
ok array(3, 4, 5)->all_items != 2,    '!=';
ok array(3, 3, 5)->all_items != 2,    '!=';
ok array(3, 3, 3.0)->all_items != 2,  '!=';
ok not( array(3, 4, 5)->all_items != 3 ), 'negative !=';
ok not( array(3, 3.0)->all_items != 3 ),  'negative !=';

# >=
ok array(3, 4, 5)->all_items >= 2,  '>=';
ok array(3, 4, 5)->all_items >= 3,  '>=';
ok 6 >= array(3, 4, 5)->all_items,  '>= switched';
ok 5 >= array(3, 4, 5)->all_items,  '>= switched';
ok not( array(3, 4, 5)->all_items >= 5 ), 'negative >=';
ok not( 2 >= array(3, 4, 5)->all_items ), 'negative >= switched';

# >
ok array(3, 4, 5)->all_items > 2, '>';
ok 6 > array(3, 4, 5)->all_items, '> switched';
ok not( array(3, 4, 5)->all_items > 4 ), 'negative >';
ok not( 2 > array(3, 4, 5)->all_items ), 'negative > switched';

# <=
ok array(3, 4, 5)->all_items <= 5, '<=';
ok array(3, 4, 5)->all_items <= 6, '<=';
ok 2 <= array(3, 4, 5)->all_items, '<= switched';
ok 3 <= array(3, 4, 5)->all_items, '<= switched';
ok not( array(3, 4, 5)->all_items <= 2 ), 'negative <=';
ok not( 6 <= array(3, 4, 5)->all_items ), 'negative <= switched';

# <
ok array(3, 4, 5)->all_items < 6, '<';
ok 2 < array(3, 4, 5)->all_items, '< switched';
ok not( array(3, 4, 5)->all_items < 5 ), 'negative <';
ok not( array(3, 4, 5)->all_items < 2 ), 'negative <';
ok not( 5 < array(3, 4, 5)->all_items ), 'negative < switched';
ok not( 6 < array(3, 4, 5)->all_items ), 'negative < switched';

# eq
ok array('a', 'a')->all_items eq 'a', 'eq';
ok not( array('a', 'b')->all_items eq 'a' ), 'negative eq';

# ne
ok array('a', 'b')->all_items ne 'c', 'ne';
ok not( array('a', 'b')->all_items ne 'a' ), 'negative ne';

# ge
ok array('g', 'h')->all_items ge 'g', 'ge';
ok array('g', 'h')->all_items ge 'f', 'ge';
ok 'i' ge array('g', 'h')->all_items, 'ge switched';
ok 'h' ge array('g', 'h')->all_items, 'ge switched';
ok not( array('g', 'h')->all_items ge 'i' ), 'negative ge';
ok not( 'f' ge array('g', 'h')->all_items ), 'negative ge switched';

# gt
ok array('g', 'h')->all_items gt 'f', 'gt';
ok 'i' gt array('g', 'h')->all_items, 'gt switched';
ok not( array('a', 'h')->all_items gt 'e' ), 'negative gt';
ok not( array('g', 'h')->all_items gt 'g' ), 'negative gt';
ok not( 'f' gt array('g', 'h')->all_items ), 'negative gt switched';
ok not( 'g' gt array('g', 'h')->all_items ), 'negative gt switched';

# le
ok array('g', 'h')->all_items le 'i', 'le';
ok array('g', 'h')->all_items le 'h', 'le';
ok 'f' le array('g', 'h')->all_items, 'le switched';
ok 'g' le array('g', 'h')->all_items, 'le switched';
ok not( array('g', 'h')->all_items le 'f'), 'negative le';
ok not( 'i' le array('g', 'h')->all_items ), 'negative le switched';

# lt
ok array('g', 'h')->all_items lt 'i', 'lt';
ok 'f' lt array('g', 'h')->all_items, 'lt switched';
ok not( array('b', 'h')->all_items lt 'a' ), 'negative lt';
ok not( array('g', 'h')->all_items lt 'f' ), 'negative lt';
ok not( 'h' lt array('g', 'h')->all_items ), 'negative lt switched';
ok not( 'i' lt array('g', 'h')->all_items ), 'negative lt switched';

# regex
ok array(3, 10)->all_items == qr/\d+/, '== regex';
ok qr/^[ab]$/ == array('a', 'b')->all_items, '== regex switched';
ok not( array(2, 3, 'c')->all_items == qr/\d+/ ), 'negative == regex';
ok not( qr/\d/ == array('a', 'b', 1)->all_items ), 'negative == regex switched';

ok array(3, 4, 5)->all_items != qr/[a-z]/, '!= regex';
ok array('a', 'b', 'c')->all_items != qr/\d/, '!= regex';
ok not( array(3, 4, 5)->all_items != qr/4/ ), 'negative != regex';
ok not( qr/4/ != array(3, 4, 5)->all_items ), 'negative != regex switched';

# bool
ok array( 2, 2 )->all_items, 'bool';
ok !array( 2, 0 )->all_items, 'negative bool';
ok !array( '', 'a' )->all_items, 'negative bool';
ok !array( 'a', undef, 'b' )->all_items, 'negative bool';

done_testing;
