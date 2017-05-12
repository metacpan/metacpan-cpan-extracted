use Evo 'Test::More; -Test *; -Internal::Exception';

{

  package My::Foo;    ## no critic
  sub foo { shift; join '-', 'FOO', @_ }
}

SUB: {
  my $mock = mock('My::Foo::foo', sub { call_original(@_) });
  is(My::Foo->foo(), 'FOO');
  is(My::Foo->foo(1, 2), 'FOO-1-2');
  is $mock->get_call(0)->result, 'FOO';
  is_deeply $mock->calls->[0]->args, ['My::Foo'];
  is_deeply $mock->calls->[1]->args, ['My::Foo', 1, 2];
}

NOOP: {
  my $mock = mock('My::Foo::foo');
  ok(!My::Foo->foo(1, 2));
  ok !$mock->get_call(0)->result;
  is_deeply $mock->calls->[0]->args, ['My::Foo', 1, 2];
}

NOOP: {
  my $mock = mock('My::Foo::foo', 1);
  is(My::Foo->foo(1, 2), 'FOO-1-2');
  is $mock->get_call(0)->result, 'FOO-1-2';
  is_deeply $mock->calls->[0]->args, ['My::Foo', 1, 2];
}

RETHROW: {
  my $mock = mock('My::Foo::foo', rethrow => 1, patch => sub { die "Foo\n" });
  like exception { My::Foo->foo() }, qr/Foo/;

  undef $mock;
  $mock = mock('My::Foo::foo', sub { die "Foo\n" });
  ok !My::Foo->foo;
}

done_testing;
