use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'array';

ok array()->any_items->isa('List::Objects::WithUtils::Array'), 'subclass ok';

# ==
ok array(2, 3.0)->any_items == 2, '==';
ok array(2, 3.0)->any_items == 3, '==';
ok not( array(2, 3.0)->any_items == 4 ), 'negative ==';


# !=
ok array(3, 4.0)->any_items != 4, '!=';
ok array(4, 5.0)->any_items != 4, '!=';
ok not( array(3, 3.0)->any_items != 3 ), 'negative !=';


# >=
ok array(3, 4, 5)->any_items >= 5, '>=';
ok array(3, 4, 5)->any_items >= 2, '>=';
ok 6 >= array(3, 4, 5)->any_items, '>= switched';
ok 3 >= array(3, 4, 5)->any_items, '>= switched';
ok not( array(3, 4, 5)->any_items >= 6 ), 'negative >=';
ok not( 2 >= array(3, 4, 5)->any_items ), 'negative >= switched';


# >
ok array(3, 4, 5)->any_items > 2, '>';
ok array(3, 4, 5)->any_items > 3, '>';
ok 6 > array(3, 4, 5)->any_items, '> switched';
ok 4 > array(3, 4, 5)->any_items, '> switched';
ok not( array(3, 4, 5)->any_items > 6 ), 'negative >';
ok not( 2 > array(3, 4, 5)->any_items ), 'negative > switched';

# <=
ok array(3, 4, 5)->any_items <= 5, '<=';
ok array(3, 4, 5)->any_items <= 6, '<=';
ok 5 <= array(3, 4, 5)->any_items, '<= switched';
ok 2 <= array(3, 4, 5)->any_items, '<= switched';
ok not( array(3, 4, 5)->any_items <= 2 ), 'negative <=';
ok not( 6 <= array(3, 4, 5)->any_items ), 'negative <= switched';

# <
ok array(3, 4, 5)->any_items < 6, '<';
ok array(3, 4, 5)->any_items < 4, '<';
ok 2 < array(3, 4, 5)->any_items, '< switched';
ok 4 < array(3, 4, 5)->any_items, '< switched';
ok not( array(3, 4, 5)->any_items < 2 ), 'negative <';
ok not( 6 < array(3, 4, 5)->any_items ), 'negative < switched';

# eq
ok array(qw/ g h /)->any_items eq 'g', 'eq';
ok not( array(qw/ g h /)->any_items eq 'z' ), 'negative eq';

# ne
ok array( qw/ g h /)->any_items ne 'g', 'ne';
ok not( array(qw/ a a /)->any_items ne 'a' ), 'negative ne';

# ge
ok array(qw/ g h /)->any_items ge 'f', 'ge';
ok array(qw/ g h /)->any_items ge 'g', 'ge';
ok 'i' ge array(qw/ g h /)->any_items, 'ge switched';
ok 'g' ge array(qw/ g f /)->any_items, 'ge switched';
ok not( array(qw/ g h/)->any_items ge 'i' ), 'negative ge';
ok not( 'f' ge array(qw/ g h /)->any_items ), 'negative ge switched';

# gt
ok array(qw/ g h /)->any_items gt 'f', 'gt';
ok array(qw/ g h /)->any_items gt 'g', 'gt';
ok 'i' gt array(qw/ h g /)->any_items, 'gt switched';
ok 'h' gt array(qw/ h g /)->any_items, 'gt switched';
ok not( array(qw/ g h /)->any_items gt 'i' ), 'negative gt';
ok not( 'g' gt array(qw/ g h /)->any_items ), 'negative gt switched';
ok not( 'f' gt array(qw/ g h /)->any_items ), 'negative gt switched';

# le
ok array(qw/ g h /)->any_items le 'i', 'le';
ok array(qw/ g f /)->any_items le 'g', 'le';
ok 'f' le array(qw/ g h /)->any_items, 'le switched';
ok 'g' le array(qw/ h g /)->any_items, 'le switched';
ok not( array(qw/ g h /)->any_items le 'f' ), 'negative le';
ok not( 'i' le array(qw/ g h /)->any_items ), 'negative le switched';

# lt
ok array(qw/ g h /)->any_items lt 'i', 'lt';
ok array(qw/ h g /)->any_items lt 'h', 'lt';
ok 'f' lt array(qw/ g h /)->any_items, 'lt switched';
ok 'g' lt array(qw/ h g /)->any_items, 'lt switched';
ok not( array(qw/ g h /)->any_items lt 'f' ), 'negative lt';
ok not( 'i' lt array(qw/ g h /)->any_items ), 'negative lt switched';

# regex
ok array(3, 'b')->any_items == qr/\d+/, '== regex';
ok array(3, 4, 'a')->any_items != qr/\d/, '!= regex';
ok not(array(3,4,'a')->any_items == qr/b/), 'negated regex';

# bool
ok array(2, 0)->any_items, 'bool with zero';
ok array('', 'a')->any_items, 'bool with empty str';
ok !array(undef, 0)->any_items, 'negative bool';


done_testing;
