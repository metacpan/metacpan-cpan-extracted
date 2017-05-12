use Evo 'Test::More; -Test::Mock *; -Internal::Exception';

{

  package My::Foo;    ## no critic
  sub foo {"FOO"}
  sub bar { die "BAR" }
}

my $FOO = My::Foo->can('foo');
my $BAR = My::Foo->can('bar');

TWICE: {
  my $mock = Evo::Test::Mock->create_mock('My::Foo::foo', 1);
  like exception { Evo::Test::Mock->create_mock('My::Foo::foo', 1) }, qr/My::Foo::foo.+mocked.+$0/;
}

CALL_TROUGH: {
  my $mock = Evo::Test::Mock->create_mock('My::Foo::foo', 1);
  is $mock->sub->(), 'FOO';
  is $mock->get_call(0)->result, 'FOO';
  is $mock->calls->@*, 1;

  undef $mock;
  $mock = Evo::Test::Mock->create_mock('My::Foo::foo', 0);
  is $mock->sub->(), undef;
  is $mock->get_call(0)->result, undef;
  is $mock->calls->@*, 1;
}

SPY: {
  my (@args, $orig);
  my $sub = sub { push @args, \@_; $orig = get_original; qw(one two) };
  like exception { Evo::Test::Mock->create_mock('My::Foo::empty', $sub) }, qr/No sub/;

  my $mock = Evo::Test::Mock->create_mock('My::Foo::foo', $sub);

  is $mock->sub,   My::Foo->can('foo');
  isnt $mock->sub, $FOO;
  isnt(My::Foo->can('foo'), $FOO);

  # make a call
  is_deeply [$mock->sub->('a1', 'a2')], [qw(one two)];
  is_deeply [$mock->calls->[0]->result], [qw(one two)];
  ok !$mock->calls->[0]->exception;
  is_deeply \@args, [[qw(a1 a2)]];
  is $orig, $FOO;
}

SPY_EXCEPTION: {
  my $mock = Evo::Test::Mock->create_mock('My::Foo::bar', sub { call_original() });
  My::Foo->bar();
  like $mock->get_call(0)->exception, qr/BAR/;
  ok !$mock->get_call(0)->result;
}


# should be restored
is(My::Foo->can('foo'), $FOO);
is(My::Foo->can('bar'), $BAR);

done_testing;
