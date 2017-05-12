use Evo 'Test::More; -Lib *; Evo::Internal::Exception';

STRICT_OPTS: {

  {

    package My::Foo;    ## no critic
    use Evo::Lib 'strict_opts';

    sub foo(%opts) { strict_opts(\%opts, [qw(foo bar)]); }
    sub bar(%opts) { strict_opts(\%opts, qw(foo bar)); }
  };

  is_deeply [My::Foo::foo(foo => 33, bar => 44)], [33, 44];
  like exception { My::Foo::foo(bad => 33) }, qr/unknown options.+bad.+$0/i;
  like exception { My::Foo::bar(bad => 33) }, qr/unknown options.+bad.+$0/i;

  like exception { strict_opts({}, [], 1, 2) }, qr/Usage/;
  like exception { strict_opts({}) }, qr/Usage/;
}

UNIQ: {
  is_deeply [Evo::Lib::uniq(1, 2, 2, 3)], [1, 2, 3];
  is_deeply [uniq(1, 2, 2, 3)], [1, 2, 3];
}

done_testing;
