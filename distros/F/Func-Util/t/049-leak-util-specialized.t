#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

BEGIN {
    eval { require Test::LeakTrace };
    plan skip_all => 'Test::LeakTrace required' if $@;
}
use Test::LeakTrace;

use Func::Util qw(
    first_gt first_lt first_ge first_le first_eq first_ne
    final final_gt final_lt final_ge final_le final_eq final_ne
    any_gt any_lt any_ge any_le any_eq any_ne
    all_gt all_lt all_ge all_le all_eq all_ne
    none_gt none_lt none_ge none_le none_eq none_ne
);

# Test data - create outside of leak tests
my @numbers = (1, 5, 10, 15, 20, 25, 30);
my @users = (
    { name => 'alice', age => 25 },
    { name => 'bob', age => 30 },
    { name => 'charlie', age => 17 },
    { name => 'david', age => 45 },
);

# Warmup
for (1..10) {
    first_gt(\@numbers, 10);
    any_lt(\@numbers, 5);
    all_ge(\@numbers, 1);
}

# ==== first_* functions ====

subtest 'first_gt' => sub {
    no_leaks_ok {
        for (1..500) {
            my $r1 = first_gt(\@numbers, 10);
            my $r2 = first_gt(\@numbers, 100);  # no match
            my $r3 = first_gt(\@users, 'age', 25);
        }
    } 'first_gt does not leak';
};

subtest 'first_lt' => sub {
    no_leaks_ok {
        for (1..500) {
            my $r1 = first_lt(\@numbers, 10);
            my $r2 = first_lt(\@numbers, 0);  # no match
            my $r3 = first_lt(\@users, 'age', 30);
        }
    } 'first_lt does not leak';
};

subtest 'first_ge' => sub {
    no_leaks_ok {
        for (1..500) {
            my $r1 = first_ge(\@numbers, 10);
            my $r2 = first_ge(\@numbers, 100);  # no match
            my $r3 = first_ge(\@users, 'age', 18);
        }
    } 'first_ge does not leak';
};

subtest 'first_le' => sub {
    no_leaks_ok {
        for (1..500) {
            my $r1 = first_le(\@numbers, 10);
            my $r2 = first_le(\@numbers, 0);  # no match
            my $r3 = first_le(\@users, 'age', 25);
        }
    } 'first_le does not leak';
};

subtest 'first_eq' => sub {
    no_leaks_ok {
        for (1..500) {
            my $r1 = first_eq(\@numbers, 10);
            my $r2 = first_eq(\@numbers, 999);  # no match
            my $r3 = first_eq(\@users, 'age', 30);
        }
    } 'first_eq does not leak';
};

subtest 'first_ne' => sub {
    no_leaks_ok {
        for (1..500) {
            my $r1 = first_ne(\@numbers, 1);
            my $r2 = first_ne(\@users, 'age', 25);
        }
    } 'first_ne does not leak';
};

# ==== final_* functions ====

subtest 'final with callback' => sub {
    no_leaks_ok {
        for (1..500) {
            my $r1 = final(sub { $_ > 10 }, \@numbers);
            my $r2 = final(sub { $_ > 100 }, \@numbers);  # no match
        }
    } 'final does not leak';
};

subtest 'final_gt' => sub {
    no_leaks_ok {
        for (1..500) {
            my $r1 = final_gt(\@numbers, 10);
            my $r2 = final_gt(\@numbers, 100);  # no match
            my $r3 = final_gt(\@users, 'age', 25);
        }
    } 'final_gt does not leak';
};

subtest 'final_lt' => sub {
    no_leaks_ok {
        for (1..500) {
            my $r1 = final_lt(\@numbers, 20);
            my $r2 = final_lt(\@numbers, 0);  # no match
            my $r3 = final_lt(\@users, 'age', 40);
        }
    } 'final_lt does not leak';
};

subtest 'final_ge' => sub {
    no_leaks_ok {
        for (1..500) {
            my $r1 = final_ge(\@numbers, 20);
            my $r2 = final_ge(\@users, 'age', 18);
        }
    } 'final_ge does not leak';
};

subtest 'final_le' => sub {
    no_leaks_ok {
        for (1..500) {
            my $r1 = final_le(\@numbers, 20);
            my $r2 = final_le(\@users, 'age', 30);
        }
    } 'final_le does not leak';
};

subtest 'final_eq' => sub {
    no_leaks_ok {
        for (1..500) {
            my $r1 = final_eq(\@numbers, 20);
            my $r2 = final_eq(\@users, 'age', 30);
        }
    } 'final_eq does not leak';
};

subtest 'final_ne' => sub {
    no_leaks_ok {
        for (1..500) {
            my $r1 = final_ne(\@numbers, 30);
            my $r2 = final_ne(\@users, 'age', 45);
        }
    } 'final_ne does not leak';
};

# ==== any_* functions ====

subtest 'any_gt' => sub {
    no_leaks_ok {
        for (1..500) {
            my $r1 = any_gt(\@numbers, 25);
            my $r2 = any_gt(\@numbers, 100);  # false
            my $r3 = any_gt(\@users, 'age', 40);
        }
    } 'any_gt does not leak';
};

subtest 'any_lt' => sub {
    no_leaks_ok {
        for (1..500) {
            my $r1 = any_lt(\@numbers, 5);
            my $r2 = any_lt(\@numbers, 0);  # false
            my $r3 = any_lt(\@users, 'age', 18);
        }
    } 'any_lt does not leak';
};

subtest 'any_ge' => sub {
    no_leaks_ok {
        for (1..500) {
            my $r1 = any_ge(\@numbers, 30);
            my $r2 = any_ge(\@users, 'age', 45);
        }
    } 'any_ge does not leak';
};

subtest 'any_le' => sub {
    no_leaks_ok {
        for (1..500) {
            my $r1 = any_le(\@numbers, 1);
            my $r2 = any_le(\@users, 'age', 17);
        }
    } 'any_le does not leak';
};

subtest 'any_eq' => sub {
    no_leaks_ok {
        for (1..500) {
            my $r1 = any_eq(\@numbers, 15);
            my $r2 = any_eq(\@numbers, 999);  # false
            my $r3 = any_eq(\@users, 'age', 25);
        }
    } 'any_eq does not leak';
};

subtest 'any_ne' => sub {
    no_leaks_ok {
        for (1..500) {
            my $r1 = any_ne(\@numbers, 1);
            my $r2 = any_ne(\@users, 'age', 25);
        }
    } 'any_ne does not leak';
};

# ==== all_* functions ====

subtest 'all_gt' => sub {
    no_leaks_ok {
        for (1..500) {
            my $r1 = all_gt(\@numbers, 0);   # true
            my $r2 = all_gt(\@numbers, 10);  # false
            my $r3 = all_gt(\@users, 'age', 16);
        }
    } 'all_gt does not leak';
};

subtest 'all_lt' => sub {
    no_leaks_ok {
        for (1..500) {
            my $r1 = all_lt(\@numbers, 100);  # true
            my $r2 = all_lt(\@numbers, 10);   # false
            my $r3 = all_lt(\@users, 'age', 50);
        }
    } 'all_lt does not leak';
};

subtest 'all_ge' => sub {
    no_leaks_ok {
        for (1..500) {
            my $r1 = all_ge(\@numbers, 1);   # true
            my $r2 = all_ge(\@numbers, 10);  # false
            my $r3 = all_ge(\@users, 'age', 17);
        }
    } 'all_ge does not leak';
};

subtest 'all_le' => sub {
    no_leaks_ok {
        for (1..500) {
            my $r1 = all_le(\@numbers, 30);  # true
            my $r2 = all_le(\@numbers, 10);  # false
            my $r3 = all_le(\@users, 'age', 45);
        }
    } 'all_le does not leak';
};

subtest 'all_eq' => sub {
    my @same = (5, 5, 5, 5);
    no_leaks_ok {
        for (1..500) {
            my $r1 = all_eq(\@same, 5);      # true
            my $r2 = all_eq(\@numbers, 10);  # false
        }
    } 'all_eq does not leak';
};

subtest 'all_ne' => sub {
    no_leaks_ok {
        for (1..500) {
            my $r1 = all_ne(\@numbers, 999);  # true
            my $r2 = all_ne(\@numbers, 10);   # false
        }
    } 'all_ne does not leak';
};

# ==== none_* functions ====

subtest 'none_gt' => sub {
    no_leaks_ok {
        for (1..500) {
            my $r1 = none_gt(\@numbers, 100);  # true
            my $r2 = none_gt(\@numbers, 10);   # false
            my $r3 = none_gt(\@users, 'age', 50);
        }
    } 'none_gt does not leak';
};

subtest 'none_lt' => sub {
    no_leaks_ok {
        for (1..500) {
            my $r1 = none_lt(\@numbers, 0);   # true
            my $r2 = none_lt(\@numbers, 10);  # false
            my $r3 = none_lt(\@users, 'age', 17);
        }
    } 'none_lt does not leak';
};

subtest 'none_ge' => sub {
    no_leaks_ok {
        for (1..500) {
            my $r1 = none_ge(\@numbers, 100);  # true
            my $r2 = none_ge(\@numbers, 1);    # false
        }
    } 'none_ge does not leak';
};

subtest 'none_le' => sub {
    no_leaks_ok {
        for (1..500) {
            my $r1 = none_le(\@numbers, 0);   # true
            my $r2 = none_le(\@numbers, 30);  # false
        }
    } 'none_le does not leak';
};

subtest 'none_eq' => sub {
    no_leaks_ok {
        for (1..500) {
            my $r1 = none_eq(\@numbers, 999);  # true
            my $r2 = none_eq(\@numbers, 10);   # false
        }
    } 'none_eq does not leak';
};

subtest 'none_ne' => sub {
    my @same = (5, 5, 5, 5);
    no_leaks_ok {
        for (1..500) {
            my $r1 = none_ne(\@same, 5);      # true (all equal)
            my $r2 = none_ne(\@numbers, 10);  # false
        }
    } 'none_ne does not leak';
};

done_testing();
