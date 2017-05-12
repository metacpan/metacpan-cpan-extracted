package main;
use Evo 'Test::More; Symbol delete_package';
use Evo '-Class::Attrs *; -Class::Meta; -Internal::Exception; -Class::Syntax *';

no warnings 'once';        ## no critic
no warnings 'redefine';    ## no critic
my $loaded;
local *Module::Load::load = sub { $loaded = shift };


my $prev = Evo::Class::Attrs->can('gen_attr');
local *Evo::Class::Attrs::gen_attr = sub ($self, %opts) {
  $prev->($self, %opts);
  sub { uc "ATTR-$opts{name}" };
};

sub gen_meta($class = 'My::Class') {
  delete_package $class;
  Evo::Class::Meta->register($class);
}

REGISTER: {
  my ($meta) = Evo::Class::Meta->register('My::Class');
  is $My::Class::EVO_CLASS_META, $meta;
  ok $meta->attrs;
  is $meta, Evo::Class::Meta->register('My::Class');
}

BUILD_DEF: {
  ok gen_meta->package;
  ok gen_meta->reqs;
  ok gen_meta->attrs;
  ok gen_meta->methods;
}

FIND_OR_CROAK: {
  like exception { Evo::Class::Meta->find_or_croak('My::Bad'); }, qr/My::Bad.+$0/;
}


sub parse { Evo::Class::Meta->parse_attr(@_) }

MARK_OVERRIDEN: {
  my $meta = gen_meta;
  $meta->mark_as_overridden('mymeth');
  ok $meta->is_overridden('mymeth');
  ok !$meta->is_overridden('mymeth2');
}

MARK_PRIVATE: {
  my $meta = gen_meta;
  $meta->mark_as_private('private');
  ok $meta->is_private('private');
  ok !$meta->is_private('any');
}


IS_METHOD__REG_METHOD: {
  my $meta = gen_meta;

  eval 'package My::Class; sub own {}';    ## no critic
  ok $meta->is_method('own');

  eval 'package My::Class; *own2 = sub {}';    ## no critic
  ok $meta->is_method('own2');
  ok !$meta->is_method('not_exists');

  # external sub
  eval '*My::Class::external = sub { };';      ## no critic
  ok !$meta->is_method('external');
  $meta->reg_method('external');
  ok $meta->is_method('external');

  # skip xsubs
  eval 'package My::Class; use Fcntl "SEEK_CUR"';    ## no critic
  ok(My::Class->can('SEEK_CUR'));
  ok !$meta->is_method('SEEK_CUR');

  $meta->reg_attr('attr1');
  like exception { $meta->reg_method('not_existing'); }, qr/doesn't exist.+$0/;
  like exception { $meta->reg_method('attr1'); },        qr/already.+attribute.+attr1.+$0/;
  like exception { $meta->reg_method('own'); },          qr/already.+own".+$0/;
  like exception { $meta->reg_attr('4bad'); },           qr/4bad.+invalid.+$0/i;

}


REG_METHOD: {
  my $meta = gen_meta;
  eval 'package My::Class; sub own {}';      ## no critic
  eval '*My::Class::external = sub { };';    ## no critic

  $meta->attrs->gen_attr(parse('attr1'));
  like exception { $meta->reg_method('attr1'); },        qr/has attribute.+attr1.+$0/;
  like exception { $meta->reg_method('not_existing'); }, qr/doesn't exist.+$0/;
  like exception { $meta->reg_method('own'); },          qr/already.+own.+$0/;

  ok !$meta->is_method('external');
  $meta->reg_method('external');
  ok $meta->is_method('external');
}


PUBLIC_METHODS: {

  my $meta = gen_meta;
  eval '*My::Class::external = sub { };';    ## no critic
  eval 'package My::Class; sub own {}';      ## no critic


  # only own
  $meta->attrs->gen_attr(parse 'bad');
  is_deeply { $meta->_public_methods_map }, {own => My::Class->can('own')};
  is_deeply [$meta->public_methods], [qw(own)];

  # add external
  $meta->reg_method('external');
  is_deeply { $meta->_public_methods_map },
    {external => My::Class->can('external'), own => My::Class->can('own')};

  is_deeply [sort $meta->public_methods], [sort qw(external own)];

  # now mark as private
  $meta->mark_as_private('own');
  is_deeply { $meta->_public_methods_map }, {external => My::Class->can('external')};
  is_deeply [$meta->public_methods], [qw(external)];
}


EXTEND_METHODS: {

NORMAL: {
    my $parent = gen_meta;
    eval 'package My::Class; sub own {"OWN"}';    ## no critic
    my $child = gen_meta('My::Child');
    $child->extend_with('/::Class');
    is $loaded, 'My::Class';
    ok $child->is_method('own');
    is(My::Child->own, 'OWN');
  }

PRIVATE: {
    my $parent = gen_meta;
    eval 'package My::Class; sub own {}; sub priv {}';    ## no critic
    $parent->mark_as_private('priv');
    my $child = gen_meta('My::Child');
    $child->extend_with('My::Class');
    ok !$child->is_method('priv');
    ok(My::Child->can('own'));
    ok(!Evo::Internal::Util::names2code('My::Child', 'priv'));
  }

OVERRIDEN: {
    my $parent = gen_meta;
    my $child  = gen_meta('My::Child');
    eval 'package My::Class; sub own {"OWN"}';            ## no critic
    eval 'package My::Child; sub own {"OVER"}';           ## no critic
    $child->mark_as_overridden('own');
    $child->extend_with('My::Class');
    is(My::Child->own, 'OVER');
  }

CLASH_METHOD: {
    my $parent = gen_meta;
    my $child  = gen_meta('My::Child');
    eval 'package My::Class; sub own {"OWN"}';            ## no critic
    eval 'package My::Child; sub own {"CHILD"}';          ## no critic
    like exception { $child->extend_with('My::Class') }, qr/My::Child.+own.+$0/;
    is(My::Child->own, 'CHILD');
  }

  warn '-------------------', "\n";

CLASH_ATTR: {
    my $parent = gen_meta;
    eval 'package My::Class; sub own {"OWN"}';            ## no critic
    my $child = gen_meta('My::Child');
    $child->reg_attr('own');
    like exception { $child->extend_with('My::Class') }, qr/My::Child.+own.+$0/;
    is(My::Child->own, 'ATTR-OWN');
  }

CLASH_WITH_ALIEN_SUB: {
    my $parent = gen_meta;
    my $child  = gen_meta('My::Child');
    eval 'package My::Class; sub foo {"OVER"};';          ## no critic
    eval '*My::Child::foo = sub {"LIB"};';                ## no critic
    like exception { $child->extend_with('My::Class') }, qr/My::Child.+subroutine.+foo.+$0/;
    is(My::Child->foo, 'LIB');
    $child->mark_as_overridden('foo');
    $child->extend_with('My::Class');
    is(My::Child->foo, 'LIB');
  }

}


REG_ATTR: {
  my $meta = gen_meta;
  $meta->reg_attr('pub1', lazy, sub {'ATTR-PUB1'});

  ok $meta->is_attr('pub1');
  is(My::Class->pub1, 'ATTR-PUB1');

  eval 'package My::Class; sub own { }';    ## no critic
  eval '*My::Class::external = sub {}';     ## no critic
  eval '@My::Class::ISA = ("My::Isa")';     ## no critic

  # errors
  like exception { $meta->reg_attr('pub1') },     qr/My::Class.+already.+attribute.+pub1.+$0/;
  like exception { $meta->reg_attr('external') }, qr/My::Class.+already.+subroutine.+external.+$0/;
  like exception { $meta->reg_attr('own') },      qr/My::Class.+already.+method.+own.+$0/;
  like exception { $meta->reg_attr('4bad'); }, qr/4bad.+invalid.+$0/i;
  ok !$meta->is_attr($_) for qw(external own 4bad isa);
}

REG_ATTR_OVER: {
  my $meta = gen_meta;
  $meta->reg_attr('pub1', lazy, sub {'ATTR-PUB1'});

  ok $meta->is_attr('pub1');
  is(My::Class->pub1, 'ATTR-PUB1');

  eval '*My::Class::external = sub { }';       ## no critic
  eval 'package My::Class; sub own { }';       ## no critic
  eval 'package My::Isa; sub isa { "ISA"}';    ## no critic
  eval '@My::Class::ISA = ("My::Isa")';        ## no critic

  $meta->reg_attr_over('external', lazy, sub {'ATTR-EXTERNAL'});
  $meta->reg_attr_over('pub1');
  $meta->reg_attr_over('own', lazy, sub {'ATTR-OWN'});
  $meta->reg_attr_over('isa', lazy, sub {'ATTR-ISA'});
  ok $meta->is_overridden('pub1');
  ok $meta->is_overridden('isa');
  ok $meta->is_overridden('own');
  ok $meta->is_overridden('external');
  my $obj = bless {}, 'My::Class';
  is($obj->own,      'ATTR-OWN');
  is($obj->isa,      'ATTR-ISA');
  is($obj->external, 'ATTR-EXTERNAL');
}

PUBLIC_ATTRS: {
  my $meta = gen_meta;
  $meta->reg_attr('attr1');
  $meta->reg_attr('attr2');
  is(My::Class->attr1, 'ATTR-ATTR1');
  is(My::Class->attr2, 'ATTR-ATTR2');
  my @attrs = $meta->public_attrs;
  is_deeply \@attrs, [sort qw(attr1 attr2)];

  $meta->mark_as_private('attr1');
  @attrs = $meta->public_attrs;
  is_deeply \@attrs, [sort qw(attr2)];

}


EXTEND_ATTRS: {

NORMAL: {
    my $parent = gen_meta('My::Class');
    $parent->reg_attr('pub1');
    my $child = gen_meta('My::Child');
    $child->extend_with('My::Class');
    ok $child->is_attr('pub1');
    ok(My::Child->can('pub1'));
  }


PRIVATE: {
    my $parent = gen_meta('My::Class');
    $parent->reg_attr('priv');
    $parent->mark_as_private('priv');
    my $child = gen_meta('My::Child');
    $child->extend_with('My::Class');
    ok !$child->is_attr('priv');
  }

OVERRIDEN: {
    my $parent = gen_meta('My::Class');
    $parent->reg_attr('pub1');
    my $child = gen_meta('My::Child');
    eval '*My::Child::pub1 = sub {"OVER"}';    ## no critic
    $child->mark_as_overridden('pub1');
    $child->extend_with('My::Class');
    is(My::Child->pub1, 'OVER');
  }

CLASH_SUB: {
    my $parent = gen_meta('My::Class');
    $parent->reg_attr('pub1');
    my $child = gen_meta('My::Child');
    eval '*My::Child::pub1 = sub {"OVER"}';    ## no critic
    like exception { $child->extend_with('My::Class') }, qr/My::Child.+pub1.+$0/;
  }

CLASH_ATTR: {
    my $parent = gen_meta('My::Class');
    $parent->reg_attr('pub1');
    my $child = gen_meta('My::Child');
    $child->reg_attr('pub1');
    like exception { $child->extend_with('My::Class') }, qr/My::Child.+pub1.+$0/;
  }

CLASH_WITH_ALIEN_SUB: {
    my $parent = gen_meta;
    my $child  = gen_meta('My::Child');
    $parent->reg_attr('foo');
    eval '*My::Child::foo = sub {"LIB"};';    ## no critic
    like exception { $child->extend_with('My::Class') }, qr/My::Child.+subroutine.+foo.+$0/;
    is(My::Child->foo, 'LIB');
    $child->mark_as_overridden('foo');
    $child->extend_with('My::Class');
    is(My::Child->foo, 'LIB');
  }

}


REQUIREMENTS: {
  my $meta  = gen_meta;
  my $child = gen_meta('My::Child');
  eval '*My::Class::bad = sub {"FOO"}';      ## no critic
  eval '*My::Class::meth1 = sub {"FOO"}';    ## no critic
  eval 'package My::Class; sub own {}';      ## no critic
  $meta->reg_attr('attr1');
  $meta->reg_method('meth1');
  $meta->reg_requirement('req1');

  is_deeply [sort $meta->requirements], [sort qw(req1 attr1 meth1 own)];

  $meta->mark_as_private('attr1');
  $meta->mark_as_private('meth1');
  is_deeply [sort $meta->requirements], [sort qw(req1 own)];

}

EXTEND_REQUIREMENTS: {
  my $meta  = gen_meta;
  my $child = gen_meta('My::ChildR');
  eval '*My::Class::meth1 = sub {"FOO"}';       ## no critic
  eval '*My::Class::methpriv = sub {"FOO"}';    ## no critic
  eval 'package My::Class; sub own {}';         ## no critic
  $meta->reg_requirement('req1');
  $meta->reg_method('meth1');
  $meta->reg_attr('attr1');
  $child->extend_with('My::Class');

  is_deeply [sort $child->requirements], [sort qw(req1 meth1 own attr1)];
}


CHECK_IMPLEMENTATION: {
  my $inter = gen_meta('My::Inter');
  my $meta  = gen_meta();

  like exception { $meta->check_implementation('My::NotExists') },
    qr/NotExists isn't.+Evo::Class.+$0/;

  $inter->reg_requirement('myattr');
  $inter->reg_requirement('mymeth');
  $inter->reg_requirement('mysub');

  like exception { $meta->check_implementation('My::Inter'); }, qr/myattr;mymeth.+$0/;

  # method, attr, sub
  $meta->reg_attr('myattr');
  eval 'package My::Class; sub mymeth {"FOO"}';    ## no critic
  eval '*My::Class::mysub = sub {"FOO"}';          ## no critic

  $meta->check_implementation('/::Inter');
  is $loaded, 'My::Inter';
}

DUMPING: {

  my $meta = gen_meta();
  $meta->reg_attr('a');
  $meta->reg_requirement('r');
  eval '*My::Class::mymethod = sub {"FOO"}';       ## no critic
  $meta->reg_method('mymethod');
  $meta->mark_as_overridden('over');
  $meta->mark_as_private('priv');

  is_deeply $meta->info,
    {
    public     => {methods => ['mymethod'], attrs => ['a'], reqs => ['r'],},
    overridden => ['over'],
    private    => ['priv'],
    }

}

done_testing;
