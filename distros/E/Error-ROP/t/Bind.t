use Test::Spec;
use Error::ROP qw(rop);

describe "a code ref" => sub {
  my $fn = sub { my $x = shift; return $x / 2; };

  it "returns half" => sub {
    my $res = $fn->(10);
    is($res, 5);
  };

  it "can be bound with bind" => sub {
    my $res = rop { 40 / 2 };
    my $res2 = Error::ROP::bind($res, $fn);
    ok($res2->is_valid && $res2->value == 10);
  };

  it "can be bound with a failing rop" => sub {
    my $res = rop { 40 / 0 };
    my $res2 = Error::ROP::bind($res, $fn);
    ok(!$res2->is_valid);
  };

};

runtests unless caller;
1;
