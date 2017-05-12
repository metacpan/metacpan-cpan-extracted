use strict;
use warnings;

use Test::More;
use Dios::Types 'validate';

subtype SmallInt of Int where { $_ < 10 };

ok        validate( SmallInt => 1  );
ok !eval{ validate( SmallInt => 10 ); };
like $@, qr{Value (.*) is not of type \QSmallInt\E}s;

done_testing();

