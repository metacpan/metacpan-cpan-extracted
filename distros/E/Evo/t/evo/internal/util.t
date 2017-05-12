package main;
use Evo -Internal::Util, -Internal::Exception;
use Test::More;

CHECK_SUBNAME: {
  ok Evo::Internal::Util::check_subname("Fo_3oad");
  ok Evo::Internal::Util::check_subname("f");
  ok !Evo::Internal::Util::check_subname(" Foo");
  ok !Evo::Internal::Util::check_subname("3Foo");
  ok !Evo::Internal::Util::check_subname("foo-Foo");
  ok !Evo::Internal::Util::check_subname("foo:Foo");
}

CODE2NAMES: {
  {

    package My::Foo;
    use Fcntl 'O_CREAT';
    sub foo { }
  }

  *bar = *My::Foo::foo;
  my ($pkg, $name, $const);

  ($pkg, $name) = Evo::Internal::Util::code2names(\&bar);
  is $pkg,  'My::Foo';
  is $name, 'foo';


  ($pkg, $name, $const) = Evo::Internal::Util::code2names(\&My::Foo::foo);
  is $pkg,  'My::Foo';
  is $name, 'foo';
  ok !$const;

  # CONST
  ($pkg, $name, $const) = Evo::Internal::Util::code2names(\&My::Foo::O_CREAT);
  ok $const;

  ($pkg, $name) = Evo::Internal::Util::code2names(sub { });
  is $pkg,  'main';
  is $name, '__ANON__';

  # names2code
  is Evo::Internal::Util::names2code('My::Foo', 'foo'), \&My::Foo::foo;
  ok !Evo::Internal::Util::names2code('My::Foo', 'foo2');
}

INJECT_CALL: {
  my $fn = Evo::Internal::Util::inject(
    package  => 'My::Module',
    line     => 33,
    filename => 'my.pl',
    code     => sub { caller(); }
  );

  is_deeply [$fn->()], ['My::Module', 'my.pl', 33];
}

LIST_SYMBOLS: {
  sub undef_symbols { Evo::Internal::Util::undef_symbols(@_) }

  {

    package My::Src;
    sub foo {'ok'}
    our $foo = 'ok';

    package My::Src::Child;
  }

  ok grep  { $_ eq 'Child::' } keys %My::Src::;
  ok !grep { $_ eq 'Child::' } Evo::Internal::Util::list_symbols('My::Src');
}

MONKEY_PATCH: {

  {

    package Foo;

    package Bar;
    sub foo {'foo'}

  }

  my %hash = (foo => sub {'pfoo'}, bar => sub {'pbar'});

  Evo::Internal::Util::monkey_patch('Foo', %hash);
  is Foo::foo(), 'pfoo';
  is Foo::bar(), 'pbar';

  my $restore
    = Evo::Internal::Util::monkey_patch_silent('Bar', foo => sub {'pfoo'}, bar => sub {'pbar'});
  is Bar::foo(), 'pfoo';
  is Bar::bar(), 'pbar';

  is $restore->{foo}->(), 'foo';
  ok exists $restore->{bar};
  ok !$restore->{bar};

  delete $restore->{bar};
  Evo::Internal::Util::monkey_patch_silent('Bar', %$restore);
  is Bar::foo(), 'foo';
}

RESOLVE_PACKAGE: {
  sub resolve { Evo::Internal::Util::resolve_package('My::Caller', @_) }

  # full
  is resolve('Foo'),      'Foo';
  is resolve('Foo::Bar'), 'Foo::Bar';

  # -
  is resolve('-Foo'),      'Evo::Foo';
  is resolve('-Foo::Bar'), 'Evo::Foo::Bar';

  # /
  is resolve('/'),           'My';
  is resolve('/::Foo'),      'My::Foo';
  is resolve('/::Foo::Bar'), 'My::Foo::Bar';

  # ::
  is resolve('::Foo'),      'My::Caller::Foo';
  is resolve('::Foo::Bar'), 'My::Caller::Foo::Bar';


  like exception { resolve('!Foo') },   qr/Can't resolve.+\!Foo/i;
  like exception { resolve('Foo!') },   qr/Can't resolve.+Foo\!/i;
  like exception { resolve('--Foo') },  qr/Can't resolve.+--Foo/i;
  like exception { resolve(':::Foo') }, qr/Can't resolve.+:::Foo/i;

  # package can't start with 3, so Main, ::3 isn't good idea
  like exception { Evo::Internal::Util::resolve_package('My', '/::3') },
    qr/Can't resolve.+::3.+My/i;
}


SUPPRESS_CARP: {
  local @My::Dst::CARP_NOT = ('My::Pkg');

## no critic;
  eval(<<'HERE');
    package My::Src;
#line 10 lib/My/Src.pm
    sub sboom { Carp::croak "Died" }
HERE

  eval(<<'HERE');
    package My::Dst;
#line 22 lib/My/Dst.pm
    *sboom = \&My::Src::sboom;
    sub dboom($class) { $class->sboom; };
HERE


  eval { My::Dst->dboom };
  like $@,   qr#My/Dst\.pm#;
  unlike $@, qr/$0/;

  Evo::Internal::Util::suppress_carp('My::Dst', 'My::Src');
  eval { My::Dst->dboom };
  like $@,   qr/$0/;
  unlike $@, qr#My/Dst\.pm#;


  Evo::Internal::Util::suppress_carp("My::Src", "My::Dst") for 1 .. 2;
  is_deeply \@My::Dst::CARP_NOT, [qw(My::Pkg My::Src)];
}


done_testing;
