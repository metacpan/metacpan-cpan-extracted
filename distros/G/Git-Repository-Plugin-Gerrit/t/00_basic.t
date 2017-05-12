use strict;
use warnings;

use Test::More;
use Test::Fatal qw(exception);
use Test::Requires::Git;

test_requires_git();
plan tests => 2;

my $package = 'Git::Repository::Plugin::Gerrit';
use_ok($package);

subtest '_normalize_change_id' => sub {
    plan tests => 4;

    my $f = $package->can('_normalize_change_id');
    my $expected = 'Id2807d66540f3c1cf16ecabf0fbf83671a74a714';

    my @inputs = (
        'Change-Id: Id2807d66540f3c1cf16ecabf0fbf83671a74a714',
        'Id2807d66540f3c1cf16ecabf0fbf83671a74a714',
        'd2807d66540f3c1cf16ecabf0fbf83671a74a714'
    );
    for my $input (@inputs) {
        is($f->($package, $input), $expected, "normalized '$input'");
    }

    my @bad_inputs = (
        'Id: Id2807d66540f3c1cf16ecabf0fbf83671a74a714',
    );
    for my $input (@bad_inputs) {
        my $exception = exception { $f->($package, $input) };
        ok($exception, "threw exception '$input'");
    }
};
