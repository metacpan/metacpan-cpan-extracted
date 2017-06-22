use strict;
use warnings;

no if $] >= 5.018, warnings => 'experimental::smartmatch';

use Test::More;
use Test::Warn;
use Test::Exception;

use Dios;

plan tests => 3;


subtest 'where { block() }' => sub {
    plan tests => 3;

    func small_int (Int $n where { $n < 10 } //= 0) {
        ok defined $n, "small_int($n) has defined value";
        ok $n < 10, "small_int($n) has value in range";
        return 1;
    }

    subtest "small_int()" => sub {
        ok  eval{ small_int();  }, "small_int() called as expected"
            or note $@;
    };

    subtest "small_int(9)" => sub {
        ok  eval{ small_int(9); }, "small_int(9) called as expected"
            or note $@;
    };

    subtest "small_int(10)" => sub {
        ok !eval{ small_int(10);}, "small_int(10) not called (as expected)";
        note $@;
    };
};


subtest 'where [0..9]' => sub {
    plan tests => 4;

    func range_int (Int $n where {$n~~[0..9]} //= 0) {
        ok defined $n, "range_int($n) has defined value";
        ok 0 <= $n && $n <= 9, "range_int($n) has value in range";
        return 1;
    }

    subtest "range_int()" => sub {
        ok  eval{ range_int();  }, "range_int() called as expected"
            or note $@;
    };

    subtest "range_int(9)" => sub {
        ok  eval{ range_int(9); }, "range_int(9) called as expected"
            or note $@;
    };

    subtest "range_int(10)" => sub {
        ok !eval{ range_int(10);}, "range_int(10) not called (as expected)";
        note $@;
    };

    subtest "range_int(-1)" => sub {
        ok !eval{ range_int(-1);}, "range_int(10) not called (as expected)";
        note $@;
    };
};


subtest 'where { { cat => 1, dog => 2}->{$_} }' => sub {
    plan tests => 4;

    func hash_member (Str :$animal where { { cat => 1, dog => 2 }->{$_} } //= 'cat') {
        ok defined $animal, "hash_member($animal) has defined value";
        like $animal, qr{^(cat|dog)$} , "hash_member($animal) has value in range";
        return 1;
    }

    subtest "hash_member()" => sub {
        ok  eval{ hash_member();  }, "hash_member() called as expected"
            or note $@;
    };

    subtest "hash_member('cat')" => sub {
        ok  eval{ hash_member(animal=>'cat'); }, "hash_member('cat') called as expected"
            or note $@;
    };

    subtest "hash_member('dog')" => sub {
        ok  eval{ hash_member(animal=>'dog'); }, "hash_member('dog') called as expected"
            or note $@;
    };

    subtest "hash_member('fish')" => sub {
        ok !eval{ hash_member(animal=>'fish');}, "hash_member('fish') not called (as expected)";
        note $@;
    };
};

