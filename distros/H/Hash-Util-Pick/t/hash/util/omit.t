use strict;
use warnings;
use utf8;

use Hash::Util qw/lock_keys/;

use Test::More;
use Test::Deep;

use Hash::Util::Pick qw/omit/;

subtest basic => sub {
    subtest 'empty hash' => sub {
        cmp_deeply omit({}, qw//), {};
        cmp_deeply omit({}, qw/foo/), {};
        cmp_deeply omit({}, qw/foo bar/), {};
    };

    subtest 'single value' => sub {
        my $hash = { foo => 0 };
        cmp_deeply omit($hash, qw//), { foo => 0 };
        cmp_deeply omit($hash, qw/foo/), {};
        cmp_deeply omit($hash, qw/foo bar/), {};
    };

    subtest 'multi values' => sub {
        my $hash = { foo => 0, bar => 1 };
        cmp_deeply omit($hash, qw//), { foo => 0, bar => 1 };
        cmp_deeply omit($hash, qw/foo/), { bar => 1 };
        cmp_deeply omit($hash, qw/foo bar/), {};
    };

    subtest 'restricted hash' => sub {
        my %hash = ( foo => 0 );
        lock_keys(%hash);

        cmp_deeply omit(\%hash, qw//), { foo => 0 };
        cmp_deeply omit(\%hash, qw/foo/), {};
        cmp_deeply omit(\%hash, qw/foo bar/), {};
    };

    subtest 'undef value' => sub {
        cmp_deeply omit(undef, qw//), {};
        cmp_deeply omit(undef, qw/foo/), {};
        cmp_deeply omit(undef, qw/foo bar/), {};
    };
};

done_testing;

