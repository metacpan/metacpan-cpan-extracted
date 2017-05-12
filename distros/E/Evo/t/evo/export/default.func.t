package main;
use Evo 'Test::More';
my ($meta, $meta_empty);

{

  package My::Empty;
  use Evo 'Evo::Export';

  $meta_empty = __PACKAGE__->EXPORT();
}

ok $meta_empty;
is $meta_empty, My::Empty->EXPORT();

{

  package My::Foo;
  use Evo -Loaded;
  use Evo::Export;
  $meta = __PACKAGE__->EXPORT();

  sub foo : Export {'FOO'}
}


ok $meta;
is $meta, My::Foo::->EXPORT();
My::Foo->import('foo');
is foo(), 'FOO';


done_testing;
