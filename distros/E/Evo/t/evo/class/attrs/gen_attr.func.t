package main;
use Evo;
use Test::More;
use Evo::Internal::Exception;

{

  package My::Empty;
  use Evo '-Class *';

  package My::Foo;
  use Evo -Class, -Loaded;

  has 'foo', optional, ro;
  has 'gt10', optional, ro, check sub { $_[0] > 10 };
  has 'gt10rw', optional, check sub { $_[0] > 10 };
  has 'req';

  has lazyfn => lazy, sub { 'LFN' . rand() };
  has lazyfnch => lazy, check sub {1}, sub { 'LFNCH' . rand() };
  has with_dv => 'DV';
  has with_dfn => sub {'DFN'};

  package My::Bar;
  use Evo -Class, -Loaded;
  has adef => 1;
  has 'alazy', lazy, sub {'L'};
  has 'asimple', optional;

};

ok $My::Foo::EVO_CLASS_META;
ok $My::Foo::EVO_CLASS_META->attrs;

ok(My::Empty->new());

my $obj = {};

like exception { My::Foo->new() }, qr/req.+required.+$0/;
like exception { My::Foo->new(gt10   => 9, req     => 1); }, qr/gt10.+$0/;
like exception { My::Foo->new(gt10rw => 9, req     => 1); }, qr/gt10.+$0/;
like exception { My::Foo->new(req    => 1, unknown => 1); }, qr/unknown.+$0/;

$obj = My::Foo->new(gt10 => 10 + 1, foo => 'FOO', req => 1);
like exception { $obj->gt10(11); },  qr/gt10.+readonly.+$0/;
like exception { $obj->gt10rw(9); }, qr/9.+gt10.+$0/;
like exception { $obj->foo('Bad') }, qr/foo.+readonly.+$0/;

# must be called once
like $obj->lazyfn,   qr/LFN/;
is $obj->lazyfn,     $obj->lazyfn;
like $obj->lazyfnch, qr/LFNCH/;
is $obj->lazyfnch,   $obj->lazyfnch;

is $obj->gt10, 11;
is $obj->gt10rw(12)->gt10rw, 12;

is $obj->with_dv,  'DV';
is $obj->with_dfn, 'DFN';

$obj = My::Foo::->new(req => 1, foo => 'foo');
is $obj->foo, 'foo';

$obj = My::Bar::->new();
is_deeply $obj, {adef => 1};
ok $obj->alazy;
is_deeply $obj, {adef => 1, alazy => 'L'};
ok $obj->asimple('S');
is_deeply $obj, {adef => 1, alazy => 'L', asimple => 'S'};

done_testing;
