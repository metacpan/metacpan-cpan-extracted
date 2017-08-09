use Test::Spec;
use Error::ROP qw(rop);

describe "a block" => sub {
    it "can succeed" => sub {
        my $res = rop { 42 / 2 };
        ok($res->is_valid);
    };
    it "can succeed and have a value" => sub {
        my $res = rop { 42 / 2 };
        ok($res->is_valid && $res->value == 21);
    };
    it "can fail" => sub {
        my $res = rop { 42 / 0 };
        ok(!$res->is_valid);
    };
};

runtests unless caller;
1;
