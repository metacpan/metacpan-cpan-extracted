package main;
use Evo 'Test::More; Evo::Internal::Exception; Symbol delete_package; Module::Loaded';


{
  no warnings 'once';
  *My::Root::external_marked  = sub {'external_marked'};
  *My::Root::external_private = sub {'external_private'};

  package My::Alien;
  use Evo -Loaded;
  sub alien {'ok'}

  package My::Root;
  use Evo -Class, -Loaded;
  use parent 'My::Alien';

  # constants are skipped
  use Fcntl 'SEEK_CUR';
  use constant CONST => 3;

  has 'a1' => 'ok1';
  has 'a2' => 'bad';

  my sub priv1        {'HIDDEN'}
  sub priv2 : Private {'HIDDEN'}
  META->reg_method('external_marked');

  sub pmeth  {'ok'}
  sub ometh1 {'bad'}
  sub ometh2 {'bad'}

  package My::Parent;
  use Evo -Class, -Loaded, -Export;
  with 'My::Root';

  # exported functions are skipped
  sub func : Export {'FUNC'}

  package My::Class;
  use Evo -Class, -Loaded;
  has_over 'a2' => 'ok2';
  has_over 'a3' => 'ok3';    # parent doesn't has it, same as has
  has 'a4'      => 'ok4';    # parent doesn't has it, same as has
  META->mark_as_overridden('ometh2');
  with 'My::Parent';
  sub ometh2        {'ok2'}
  sub ometh1 : Over {'ok1'}

  package My::ClassCheckImpl;
  use Evo -Class, -Loaded;

  package My::ClassExtend;
  use Evo -Class;
  extends 'My::Class';
}

GENERAL: {
  my $meta;
  $meta = $My::Class::EVO_CLASS_META;
  isa_ok $meta, 'Evo::Class::Meta';
  ok $meta->is_attr('a1');
  is_deeply [sort $meta->requirements()],
    [sort qw(a1 a2 a3 a4 pmeth ometh1 ometh2 external_marked)];
  is(My::Class->pmeth,           'ok');
  is(My::Class->ometh1,          'ok1');
  is(My::Class->ometh2,          'ok2');
  is(My::Class->external_marked, 'external_marked');

  isa_ok 'My::Class', 'My::Parent';

  ok(My::Root->can('priv2'));
  ok(!Evo::Internal::Util::names2code('My::Class', 'priv2'));

  my $obj = My::Class->new;
  is $obj->a1, 'ok1';
  is $obj->a2, 'ok2';
  is $obj->a3, 'ok3';
  is $obj->a4, 'ok4';
  is $obj->new->a1, 'ok1';

  like exception { My::Class->can('has')->('a1') }, qr/already.+a1.+$0/i;
}

SKIP_EXTERNAL: {
  ok(My::Root->can('external_private'));
  ok(!Evo::Internal::Util::names2code('My::Class', 'external_private'));
}

SKIP_EXPORTED_SUBS: {
  ok(My::Parent->can('export'));
  ok(!Evo::Internal::Util::names2code('My::Class', 'func'));
}

SKIP_CONSTANTS: {
  ok(My::Root::->can('SEEK_CUR'));
  ok(!Evo::Internal::Util::names2code('My::Class', 'SEEK_CUR'));
  ok(My::Root->can('CONST'));
  ok(!Evo::Internal::Util::names2code('My::Class', 'CONST'));
}

ALIEN: {
  ok(My::Class->isa('My::Alien'));
  is(My::Class->alien, 'ok');
}

{

  package My::Interface;
  use Evo -Class, -Loaded;
  requires 'r1';
}

# implementation
like exception { My::ClassCheckImpl->can('implements')->('My::Interface') },
  qr/Bad implement.+$0/i;
like exception { My::ClassCheckImpl->can('with')->('My::Interface') }, qr/Bad implement.+$0/i;
Evo::Internal::Util::monkey_patch 'My::ClassCheckImpl', r1 => sub {'ok'};
My::ClassCheckImpl->can('implements')->('My::Interface');

eval q#package My::Bad; use Evo -Class; extends 'My::Alien'#;    ## no critic
like $@, qr/My::Alien isn't.+parent.+external/;

done_testing;
