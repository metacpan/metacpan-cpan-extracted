use Evo 'Test::More; -Internal::Exception;-Class::Meta; -Class::Attrs, -Class::Syntax *';

sub parse {
  Evo::Class::Meta->parse_attr(@_);
}

my $positive = sub($v) { $v > 0 ? 1 : (0, 'OOPS') };

my ($attrs, $new, $_new);

sub before() {
  $attrs = Evo::Class::Attrs->new();
  no warnings 'once';
  $My::Class::EVO_CLASS_ATTRS = $attrs;
  $_new                       = $attrs->gen_new;
  $new                        = sub { $_new->('My::Class', @_) };
}

SKIP: {
  skip "no threads support", 1 unless eval "use threads; 1";    ## no critic
  before();
  $attrs->gen_attr(parse 'simple');
  $new->(simple => 'foo');

  threads->create(
    sub {
      $new->(simple => 'foo');
    }
  )->join();
}

sub run_tests {

SIMPLE: {
    before();
    $attrs->gen_attr(parse 'simple');
    my $val = 333;
    my $obj = $new->(simple => 'BAD', simple => $val);
    $val = 'bad';
    is_deeply $obj, {'simple', 333};
    isa_ok $obj, 'My::Class';
  }

REQUIRED: {
    before();
    $attrs->gen_attr(parse 'req');
    like exception { $new->() }, qr#"req" is required.+$0#;
  }

UNKNOWN: {
    before();
    like exception { $new->(bad => 1) }, qr#Unknown.+bad.+$0#;
  }


DEFAULT_CODE: {
    before();
    my $def = sub($class) { is $class, 'My::Class'; 'DEF' };
    $attrs->gen_attr(parse foo => $def);
    is_deeply $new->(foo => 222), {foo => 222};
    is_deeply $new->(), {foo => 'DEF'};
    is_deeply $new->(foo => undef), {foo => undef};
  }

DEFAULT_VALUE: {
    before();
    my $val = 'DEF';
    $attrs->gen_attr(parse foo => $val);
    $val = 'bad';
    is_deeply $new->(foo => 222), {foo => 222};
    is_deeply $new->(), {foo => 'DEF'};
    is_deeply $new->(foo => undef), {foo => undef};
  }


CHECK: {
    before();

    # check if passed but bypass checking of default value, even if it's negative
    $attrs->gen_attr(parse foo => 0, check $positive);
    like exception { $new->(foo => 0) }, qr#Bad value.+"0".+"foo".+OOPS.+$0#i;
    is_deeply $new->(), {foo => 0};
    is_deeply $new->(foo => 1), {foo => 1};
  }

CHECK_CHANGE: {
    before();
    $attrs->gen_attr(parse foo => check sub { $_[0] .= "BAD"; 1 });
    my $val = "VAL";
    is_deeply $new->(foo => $val), {foo => "VAL"};
    is $val, "VAL";
  }

PASS_OBJECT: {
    my $obj = $new->(foo => 2);
    my $obj2 = $_new->($obj, foo => 3);
    is $obj2->{foo}, 3;
  }
}


run_tests();

do "t/test_memory.pl";
die $@ if $@;

done_testing;
