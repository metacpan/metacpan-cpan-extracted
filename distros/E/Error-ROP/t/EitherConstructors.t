use Test::Spec;
use Error::ROP qw/success failure/;

sub always_succeeds {
    return success(shift);
}

sub always_fails {
    return failure("You don't have permissions.");
}

sub divide_or_not {
    my $number = shift;
    my $res;
    eval {
        $res = 42 / $number;
    };
    if ($@) {
        return failure($@);
    }
    return success($res);
}

sub other_calc {
    my $number = shift;
    my $first_step = divide_or_not($number - 1);
    if ($first_step->is_valid) {
        return success($first_step->value + 2);
    }
    return $first_step;
}

describe "Error::ROP class" => sub {
    it "wraps valid stuff" => sub {
        my $res = always_succeeds(42);
        ok($res->is_valid);
    };
    it "can get valid stuff" => sub {
        my $res = always_succeeds(42);
        is(42, $res->value);
    };
    it "can have an failure" => sub {
        my $res = always_fails(42);
        ok(!$res->is_valid);
    };
};

describe "An operation" => sub {
    it "can succeed" => sub {
        my $res = divide_or_not(3);
        ok($res->is_valid);
    };
    it "can fail" => sub {
        my $res = divide_or_not(0);
        ok(!$res->is_valid);
    };
    it "can succeed with multiple applications" => sub {
        my $res = other_calc(43);
        ok($res->is_valid);
    };
    it "can fail with multiple applications" => sub {
        my $res = other_calc(1);
        ok(!$res->is_valid);
    };
};


runtests unless caller;
1;
