use strict;
use warnings;
use utf8;

use Hash::Util qw/lock_keys/;

use Test::More;
use Test::Deep;

use Hash::Util::Pick qw/pick/;

subtest basic => sub {
    subtest 'empty hash' => sub {
        cmp_deeply pick({}, qw//), {};
        cmp_deeply pick({}, qw/foo/), {};
        cmp_deeply pick({}, qw/foo bar/), {};
    };

    subtest 'single value' => sub {
        my $hash = { foo => 0 };
        cmp_deeply pick($hash, qw//), {};
        cmp_deeply pick($hash, qw/foo/), { foo => 0 };
        cmp_deeply pick($hash, qw/foo bar/), { foo => 0 };
    };

    subtest 'multi values' => sub {
        my $hash = { foo => 0, bar => 1 };
        cmp_deeply pick($hash, qw//), {};
        cmp_deeply pick($hash, qw/foo/), { foo => 0 };
        cmp_deeply pick($hash, qw/foo bar/), { foo => 0, bar => 1 };
    };

    subtest 'restricted hash' => sub {
        my %hash = ( foo => 0 );
        lock_keys(%hash);

        cmp_deeply pick(\%hash, qw//), {};
        cmp_deeply pick(\%hash, qw/foo/), { foo => 0 };
        cmp_deeply pick(\%hash, qw/foo bar/), { foo => 0 };
    };

    subtest 'undef value' => sub {
        cmp_deeply pick(undef, qw//), {};
        cmp_deeply pick(undef, qw/foo/), {};
        cmp_deeply pick(undef, qw/foo bar/), {};
    };
};

done_testing;

