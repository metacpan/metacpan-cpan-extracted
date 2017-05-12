use Evo 'Test::More; -Internal::Exception; -Class::Meta; -Class::Attrs *; -Class::Syntax *';

sub parse { Evo::Class::Meta->parse_attr(@_) }

sub run_tests {

  diag "TESTING $Evo::Class::Attrs::IMPL";

SLOTS: {
    my $noop   = sub {1};
    my $attrs  = Evo::Class::Attrs->new();
    my $inject = {foo => 2};

    $attrs->gen_attr(parse 'foo', 'DEF', ro, inject $inject, check $noop);
    $attrs->gen_attr(parse bar => optional);
    $attrs->gen_attr(parse baz => lazy, $noop, no_method);

    is_deeply [$attrs->slots],
      [
      {
        name   => 'foo',
        inject => {foo => 2},
        value  => 'DEF',
        check  => $noop,
        ro     => 1,
        type   => ECA_DEFAULT,
        method => 1
      },
      {
        name   => 'bar',
        inject => undef,
        value  => undef,
        check  => undef,
        ro     => '',
        type   => ECA_OPTIONAL,
        method => 1
      },
      {
        name   => 'baz',
        inject => undef,
        value  => $noop,
        check  => undef,
        ro     => '',
        type   => ECA_LAZY,
        method => ''
      }
      ];


    ok $attrs->exists('foo');
    ok $attrs->exists('bar');
    ok $attrs->exists('baz');
    ok !$attrs->exists('bar404');
  }

OVERWRITE: {
    my $attrs = Evo::Class::Attrs->new();
    $attrs->gen_attr(parse('foo'));
    $attrs->gen_attr(parse('bar'));
    $attrs->gen_attr(parse('baz'));
    $attrs->gen_attr(parse('bar', 'DV'));
    is [$attrs->slots]->[1]->{type}, ECA_DEFAULT;
    is [$attrs->slots]->[1]->{name}, 'bar';

  }

}

run_tests();

do "t/test_memory.pl";
die $@ if $@;

done_testing;
