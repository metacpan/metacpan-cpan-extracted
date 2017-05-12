package main;
use Evo 'Test::More; -Internal::Exception';

{

  package My::Class;
  use Evo -Class;
  has 'attr1';
  has_over 'attr2';


  package My::Class2;
  use Evo '-Class META:META2';

  sub new ($me, @rest) {
    $me->SUPER::new(@rest);
  }
}

ok(My::Class->can($_), "$_ exists") for qw(attr1 attr2 new);

ok $My::Class::EVO_CLASS_META;
is(My::Class->META,   $My::Class::EVO_CLASS_META);
is(My::Class2->META2, $My::Class2::EVO_CLASS_META);

my $obj = My::Class->new(attr1 => 1, attr2 => 2);
is $obj->attr1, 1;
is $obj->attr2, 2;
is ref $obj, 'My::Class';

is ref(My::Class2->new), 'My::Class2';

done_testing;
