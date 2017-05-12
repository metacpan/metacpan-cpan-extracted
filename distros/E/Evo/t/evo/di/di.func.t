package main;
use Evo 'Test::More; Evo::Di; Evo::Internal::Exception';

{

  package My::Alien;
  use Evo -Loaded;
  sub new { bless {}, __PACKAGE__ }

  package My::C1;
  use Evo -Class, -Loaded;
  has c2           => inject 'My::C2';
  has c2alias      => inject 'My::C2';
  has not_required => optional, inject 'My::Missing';

  package My::C2;
  use Evo -Class, -Loaded;
  has 'c3'  => inject 'My::C3';
  has alien => inject 'My::Alien';

  package My::C3;
  use Evo -Class, -Loaded;
  has 'val';

  package My::Fail;
  use Evo -Class, -Loaded;
  has missing => inject 'My::Missing',;

  package My::Circ1;
  use Evo -Class, -Loaded;
  has circ2 => inject 'My::Circ2',;

  package My::Circ2;
  use Evo -Class, -Loaded;
  has circ3 => inject 'My::Circ3',;

  package My::Circ3;
  use Evo -Class, -Loaded;
  has circ1 => inject 'My::Circ1',;

  package My::Hash;
  use Evo -Class, -Loaded;
  has req => inject 'req@hash';
  has opt => optional, inject 'opt@hash';

  package My::Mortal;
  use Evo -Class, -Loaded;
  has c1      => inject 'My::C1';
  has c1alias => inject 'My::C1';
  has 'baz';

}

MORTAL: {
  my $di = Evo::Di->new();
  $di->provide('My::C3@defaults', {val => 'V'});
  my $c = $di->mortal('My::Mortal', baz => 44, c1 => 'bad');
  ok $c->c1;
  is $c->c1,      $di->single('My::C1');
  is $c->c1alias, $c->c1;
  isnt $c, $di->mortal('My::Mortal', baz => 44);
}

EXISTING: {
  my $di = Evo::Di->new();
  $di->provide('SOME_CONSTANT' => 33);
  is $di->single('SOME_CONSTANT'), 33;
}

PROVIDE: {
  my $di = Evo::Di->new;
  $di->provide(foo => 'FOO', bar => 'BAR');
  is $di->single('foo'), 'FOO';
  is $di->single('bar'), 'BAR';
  like exception { $di->provide('foo', 33) }, qr/"foo".+$0/;
}

OK: {
  my $di = Evo::Di->new;
  $di->provide('My::C3@defaults', {val => 'V'});
  my $c1 = $di->single('My::C1');
  is $c1, $di->single('My::C1');
  ok !exists $c1->{not_required};
  is $c1->c2,      $di->single('My::C2');
  is $c1->c2alias, $di->single('My::C2');
  is $c1->c2->alien, $di->single('My::Alien');
  is $c1->c2->c3,    $di->single('My::C3');
  is $c1->c2->c3->val, 'V';
  is_deeply $di->di_stash,
    {
    'My::C3@defaults', {val => 'V'},
    'My::C1'     => $c1,
    'My::C2'     => $c1->c2,
    'My::C3'     => $c1->c2->c3,
    'My::Alien', => $c1->c2->alien,
    };

}

FAIL: {
  my $di = Evo::Di->new;
  like exception { $di->single('My::Fail'); }, qr/My::Missing.+My::Fail.+$0/;
}

CIRC: {
  my $di = Evo::Di->new;
  like exception { $di->single('My::Circ1') }, qr/My::Circ2 -> My::Circ3 -> My::Circ1.+$0/;
}


done_testing;
