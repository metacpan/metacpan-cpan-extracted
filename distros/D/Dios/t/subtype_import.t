use warnings;
use strict;
use lib qw< ./tlib t/tlib >;

use Test::More;

plan tests => 4;

use Dios::Types 'validate';

use Types;
ok        validate(PosInt => +1);
ok !eval{ validate(PosInt => -1) };
ok        validate(ShortStr => 'short');
ok !eval{ validate(ShortStr => 'longstring') };

done_testing();

