use strict;
use warnings;

use Locale::Nationality::en;

use Test::More;

# ------------------------

my($name) = Locale::Nationality::en -> new -> names;

is($$name[9], 'Australian', 'Australian is 10th in the list');
is($$name[$#$name - 14], 'Trinidadian or Tobagonian', "'Trinidadian or Tobagonian' (i.e. with spaces) is correctly handled");
is($$name[$#$name], 'Zimbabwean', 'Zimbabwean is last in the list');

done_testing();
