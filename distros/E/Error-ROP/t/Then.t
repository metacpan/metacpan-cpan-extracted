use Test::Spec;
use Error::ROP qw(rop);

describe "then" => sub {

    it "can be execute after success" => sub {
        my $res = rop { 40 / 2 };
        my $res2 = $res->then("Can't divide" => sub { $_ / 2 });
        ok($res2->is_valid && $res2->value == 10);
    };

    it "shortcuts a failing rop" => sub {
        my $res = rop { 40 / 0 };
        my $res2 = $res->then("Can't divide" => sub { $_ / 2 });
        ok(!$res2->is_valid);
    };

    it "can be chained" => sub {
        my $res = rop { 40 / 2 };
        my $res2 = $res->then(
            "Can't divide" => sub { $_ / 2 },
            "Can't multiply" => sub { $_ * 4 },
            "Can't sum" => sub { $_ + 2 });
        ok($res2->is_valid && $res2->value == 42);
    };

    it "can be chained individually" => sub {
        my $res = rop { 40 / 2 };
        my $res2 = $res
            ->then("Can't divide" => sub { $_ / 2 })
            ->then("Can't multiply" => sub { $_ * 4 })
            ->then("Can't sum" => sub { $_ + 2 });
        is($res2->value, 42);
    };

    it "can be chained even when fails" => sub {
        my $res = rop { 40 / 2 };
        my $res2 = $res->then(
            "Can't divide" => sub { $_ / 0 },
            "Can't multiply" => sub { $_ * 4 },
            "Can't sum" => sub { $_ + 2 });
        ok(!$res2->is_valid && $res2->failure eq "Can't divide");
    };

    it "default to exceptions when not given failure text" => sub {
      my $res = rop { 40 / 2 };
      my $res2 = $res->then(
          undef => sub { $_ / 0 },
          "Can't multiply" => sub { $_ * 4 },
          "Can't sum" => sub { $_ + 2 });
      ok(index($res2->failure, "Illegal division by zero at") != -1);
    };

    it "default to exceptions when given empty failure text" => sub {
      my $res = rop { 40 / 2 };
      my $res2 = $res->then(
          "" => sub { $_ / 0 },
          "Can't multiply" => sub { $_ * 4 },
          "Can't sum" => sub { $_ + 2 });
      ok(index($res2->failure, "Illegal division by zero at") != -1);
    };
 	
    it "accepts also lists" => sub {
      my $res = rop { 40 / 2 };
      my $res2 = $res->then(
          sub { $_ / 0 },
          sub { $_ * 4 },
          sub { $_ + 2 });
      ok(index($res2->failure, "Illegal division by zero at") != -1);
    };

    it "accepts also coderefs" => sub {
      my $res = rop { 40 / 2 };
      my $res2 = $res
        ->then(sub { $_ / 0 })
        ->then(sub { $_ * 4 })
        ->then(sub { $_ + 2 });
      ok(index($res2->failure, "Illegal division by zero at") != -1);
    };

    xit "patata" => sub {
        my $res = rop { 40 / 2 };
        my $res2 = $res->patata(sub { $_ / 2 });
        is($res2->value, 10);
    };

};

runtests unless caller;
1;
