use Test::More;
use strict; use warnings FATAL => 'all';

{ package My::Array::Obj;
  use strict; use warnings FATAL => 'all';
  use parent 'List::Objects::WithUtils::Array';
  sub foo { 1 }
}
{ package My::Hash::Obj;
  use strict; use warnings FATAL => 'all';
  use parent 'List::Objects::WithUtils::Hash';
  sub bar { 1 }
}

{ package My::Autoboxen;
  use strict; use warnings FATAL => 'all';
  use List::Objects::WithUtils::Autobox
    HASH  => 'My::Hash::Obj',
    ARRAY => 'My::Array::Obj' ;

  use Test::More;

  ok []->foo, 'autoboxed array ok';
  ok {}->bar, 'autoboxed hash ok';
}

done_testing;
