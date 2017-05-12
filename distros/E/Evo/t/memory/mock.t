use Evo 'Test::More; -Test::Mock; Test::Evo::Helpers *';
plan skip_all => 'set TEST_MEMORY env to enable this test' unless $ENV{TEST_MEMORY};

{

  package My::Foo;
  sub foo { }
}

my $consumed = test_memory 10_000, 1_000_000, sub {
  my $mock = Evo::Test::Mock->create_mock('My::Foo::foo', sub { });
  $mock->sub->();
};

ok 1;

done_testing;
