package main;
use Evo 'Test::More';
use Evo '-Internal::Util';

{

  package My::Root;
  use Evo '-Export *', -Loaded;
  export_gen rootgen => sub ($me, $dest) {
    sub {"rootgen-$me-$dest"};
  };

  package My::Foo;
  use Evo '-Export *', -Loaded;

  use constant MYCONST => 'CONST';
  sub mysub                         {'sub'}
  sub mysuba : Export               {'suba'}
  sub mysubar_old : Export(mysubar) {'subar'}
  sub mybad : Export                { }

  sub mygena ($me, $dest) : ExportGen {
    sub {"mygena-$me-$dest"};
  }

  export 'mysub', 'MYCONST';
  export 'mysub:mysubalias';

  export_code mycode => sub {'mycode'};
  export_gen mygen => sub ($me, $dest) {
    sub {"mygen-$me-$dest"};
  };
  export_proxy 'My::Root', '*', 'rootgen:rootgenalias';

  package My::Forced;
  use Evo '-Export import_all:import';
  sub forced : Export {'forced'}

  package My::Custom;
  use Evo '-Export -import; -Loaded';

  sub import ($me, @list) {
    @list = ('*') if !@list;
    Evo::Export->install_in(scalar caller, $me, @list);
  }

  package My::Custom::Child;
  use parent 'My::Custom';
  sub custom : Export {'custom'}

}

My::Foo->import('*', '-mybad') for 1 .. 2;
My::Foo->import('mysub:mysubalias2') for 1 .. 2;

our $EVO_EXPORT_META;
ok !$EVO_EXPORT_META;
ok $My::Foo::EVO_EXPORT_META;
is [Evo::Internal::Util::code2names(\&mysuba)]->[0], 'My::Foo';

ok !main::->can('mybad');
is mysuba(),       'suba';
is MYCONST(),      'CONST';
is mysubar(),      'subar';
is mysub(),        'sub';
is mysubalias(),   'sub';
is mysubalias2(),  'sub';
is mycode(),       'mycode';
is mygen(),        'mygen-My::Foo-main';
is mygena(),       'mygena-My::Foo-main';
is rootgen(),      'rootgen-My::Foo-main';
is rootgenalias(), 'rootgen-My::Foo-main';

# import all by default
My::Forced->import();
ok forced(), 'forced';

# custom import
My::Custom::Child->import();
ok custom(), 'custom';

done_testing;
