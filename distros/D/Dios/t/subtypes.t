use strict;
use warnings;

use Test::More;
use Dios::Types 'validate';

subtype SmallInt of Int where { $_ < 10 };

ok        validate( SmallInt => 1  );
ok !eval{ validate( SmallInt => 10 ); };
like $@, qr{Value (.*) is not of type \QSmallInt\E}s;


subtype Thing of Dict[foo, bar, ...];

subtype OtherThing of Thing & Dict[baz, bat, ...] | Tuple[Int,Str];

ok        validate( OtherThing => { foo=>1, bar=>1, baz=>1, bat=>1 });
ok        validate( OtherThing => [1,'foo']);
ok !eval{ validate( OtherThing => { boo=>1, bar=>1, baz=>1, bat=>1 }) };

done_testing();

