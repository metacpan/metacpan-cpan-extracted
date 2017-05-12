package main;
use Evo 'Test::More; -Attr; -Internal::Exception';

{

  package My::Dest;
  use FindBin;
  use lib "$FindBin::Bin";
  use Evo 'MyAttrFoo';

  sub foosub1 : Foo1         { }
  sub foosub2 : Foo2(a1, a2) { }

};

is_deeply $My::Dest::GOT_FOO1 , ['My::Dest', \&My::Dest::foosub1, 'foosub1'];
is_deeply $My::Dest::GOT_FOO2 , ['My::Dest', \&My::Dest::foosub2, 'foosub2', 'a1', 'a2'];

eval 'sub My::Dest::foobad : FooBad(abc) {}';    ## no critic
like $@, qr/invalid.+FooBad\(abc\)/i;

done_testing;
