use strict;
use warnings;
use utf8;

use Test::More;
use Test::Exception;
use Test::Deep;

use Hash::Util::Pick qw/omit_by/;

subtest success => sub {
    subtest 'empty hash' => sub {
        cmp_deeply omit_by({}, sub { }), {};
        cmp_deeply omit_by({}, sub { 0 }), {};
        cmp_deeply omit_by({}, sub { 1 }), {};
    };

    subtest 'single value' => sub {
        my $hash = { foo => 0 };
        cmp_deeply omit_by($hash, sub { }), { foo => 0 };
        cmp_deeply omit_by($hash, sub { 0 }), { foo => 0 };
        cmp_deeply omit_by($hash, sub { 1 }), {};
        cmp_deeply omit_by($hash, sub { $_ == 0 }), {};
        cmp_deeply omit_by($hash, sub { $_ == 1 }), { foo => 0 };
    };

    subtest 'multi values' => sub {
        my $hash = { foo => 0, bar => 1 };
        cmp_deeply omit_by($hash, sub { }), { foo => 0, bar => 1 };
        cmp_deeply omit_by($hash, sub { 0 }), { foo => 0, bar => 1 };
        cmp_deeply omit_by($hash, sub { 1 }), {};
        cmp_deeply omit_by($hash, sub { $_ == 0 }), { bar => 1 };
        cmp_deeply omit_by($hash, sub { $_ == 1 }), { foo => 0 };
    };

    subtest 'undef value' => sub {
        cmp_deeply omit_by(undef, sub { }), {};
        cmp_deeply omit_by(undef, sub { 0 }), {};
        cmp_deeply omit_by(undef, sub { 1 }), {};
    };

    subtest 'non coderef' => sub {
        cmp_deeply omit_by({}, undef), {};
        cmp_deeply omit_by({ foo => 1 }, undef), { foo => 1 };
    };
};

done_testing;

