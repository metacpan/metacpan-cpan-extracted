use Evo -Export::Meta;
use Test::More;
use Evo::Internal::Exception;
use Evo::Internal::Util;

my $loaded;
no warnings 'redefine';    ## no critic
local *Evo::Export::Meta::load = sub { $loaded = shift };

FIND_SLOT_INIT_SLOT: {
  local %My::Foo::;

  my $obj = Evo::Export::Meta->new("My::Foo");
  $obj->init_slot("name", "val");
  like exception { $obj->init_slot("name", "val") }, qr/already.+name.+$0/i;
  is $obj->find_slot("name"), "val";
  like exception { $obj->find_slot("not_exists") }, qr/My::Foo.+not_exists.+$0/;
}
KEY: {
  local $My::Foo::EVO_EXPORT_META;
  my $obj = Evo::Export::Meta->find_or_bind_to('My::Foo');
  is $obj,                      Evo::Export::Meta->find_or_bind_to('My::Foo');
  is $My::Foo::EVO_EXPORT_META, $obj;
}

SUB: {
  my $obj = Evo::Export::Meta->new('My::Foo');
  like exception { $obj->export('name') },     qr/My::Foo::name.+$0/;    # not exists
  like exception { $obj->export('name:fee') }, qr/My::Foo::name.+$0/;    # bad name

  no warnings 'once';
  local *My::Foo::name = my $sub = sub { };


  $obj->export('name');
  $obj->export('name:alias');
  is $obj->request('name', 'My::Dest'), $sub for 1 .. 2;
  is $obj->request('alias', 'My::Dest'),  $sub;
  is $obj->request('alias', 'My::Other'), $sub;
}

FN: {
  my $obj = Evo::Export::Meta->new('My::Foo');

  $obj->export_code('name', my $sub = sub {44});
  is $obj->request('name', 'My::Dest'), $sub for 1 .. 2;
  is $obj->request('name', 'My::Other'), $sub;
}

GEN: {
  local $My::Foo::EVO_EXPORT_META;
  my $obj = Evo::Export::Meta->new('My::Foo');

  my @got;
  $obj->export_gen(
    'name',
    my $sub = sub ($me, $dest) {
      push @got, $dest;
      sub {"$me-$dest"}
    }
  );

  # once for each dest
  is $obj->request('name', 'My::Dest')->(), 'My::Foo-My::Dest' for 1 .. 2;
  is $obj->request('name', 'My::Dest'), $obj->request('name', 'My::Dest');    # same fn
  is $obj->request('name', 'My::Other')->(), 'My::Foo-My::Other' for 1 .. 2;
  is_deeply \@got, [qw(My::Dest My::Other)];                                  # only 2 invocations

  no warnings 'once';
  is $My::Dest::EVO_EXPORT_CACHE->{'My::Foo'}{'name'}, $obj->request('name', 'My::Dest');
}

EXPAND_WILDCARDS: {
  my $obj = Evo::Export::Meta->new('My::Foo');
  like exception { $obj->expand_wildcards('*') }, qr/My::Foo.+nothing.+$0/;
  $obj->export_code('name1', sub { });
  $obj->export_code('name2', sub { });
  $obj->export_code('name3', sub { });
  is_deeply [$obj->expand_wildcards('name1', 'name1', '*', '-name3', 'name3:r3')],
    [qw(name1 name2 name3:r3)];
}


PROXY: {
  local $My::Orig::EVO_EXPORT_META;
  my $obj  = Evo::Export::Meta->new('My::Foo');
  my $orig = Evo::Export::Meta->find_or_bind_to('My::Orig');
  ok $My::Orig::EVO_EXPORT_META;

  like exception { $obj->export_from('ename', 'My::Orig', 'origname') },
    qr/My::Orig.+origname.+$0/;

  $orig->export_code(origname => my $sub = sub {'HELLO'});

  $obj->export_from('name', 'My::Orig', 'origname');

  is $obj->request('name', 'My::Dest')->('HELLO'), 'HELLO';

}


REEXPORT_ALL: {
  local $My::Orig::EVO_EXPORT_META;
  my $obj  = Evo::Export::Meta->new('My::Foo');
  my $orig = Evo::Export::Meta->find_or_bind_to('My::Orig');
  ok $My::Orig::EVO_EXPORT_META;

  $orig->export_code(origname1 => sub {'HELLO1'});
  $orig->export_code(origname2 => sub {'HELLO2'});

  $obj->export_proxy('/::Orig', '*', 'origname2:alias2');
  is_deeply [sort keys $obj->symbols->%*], [sort qw/origname1 origname2 alias2/];

  is $loaded, 'My::Orig';
}

INFO: {
  local $My::Foo::EVO_EXPORT_META;
  my $obj = Evo::Export::Meta->new('My::Foo');
  ok $obj->info();
}


done_testing;
