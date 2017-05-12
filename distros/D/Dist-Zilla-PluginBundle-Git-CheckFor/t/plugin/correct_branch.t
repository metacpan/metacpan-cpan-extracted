use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Moose::More 0.004;
use Path::Tiny;

require 't/funcs.pm' unless eval { require funcs };

use Dist::Zilla::Plugin::Git::CheckFor::CorrectBranch;

my $THING = 'Dist::Zilla::Plugin::Git::CheckFor::CorrectBranch';

validate_class $THING => (
    does => [
        'Dist::Zilla::Role::Git::Repo::More',
        'Dist::Zilla::Role::BeforeRelease',
    ],
    attributes => [ qw{ release_branch } ],
    methods    => [ qw{ current_branch } ],
);

subtest 'simple repo, on wrong, divergent branch' => sub {
    our_test(
        'Git::CheckFor::CorrectBranch',
        qr/Your current branch \(other_branch\) is not the release branch \(master\)/,
    );
};

subtest 'simple repo, on wrong, divergent branch' => sub {
    our_test(
        [ 'Git::CheckFor::CorrectBranch' => { release_branch => ['barf'] } ],
        qr/Your current branch \(other_branch\) is not the release branch \(barf\)/,
    );
};

subtest 'simple repo, on correct branch' => sub {
    our_test(
        [ 'Git::CheckFor::CorrectBranch' => { release_branch => ['other_branch'] } ],
        undef,
        sub { ok !$_[0], 'passed!' },
    );
};

subtest 'simple repo, on correct branch, multiple release branches' => sub {
    our_test(
        [ 'Git::CheckFor::CorrectBranch' => { release_branch => ['other_branch','another_branch'] } ],
        undef,
        sub { ok !$_[0], 'passed!' },
    );
};

# our_test() below is... erm, a little awkward.  But it does the job, and can
# be refactored when a need/reason arises.

done_testing; # <=======

sub our_test {
    my ($plugin_cfg, $test_regex, $test) = @_;

    my $test_sub
        = ref $test && ref $test eq 'CODE'
        ? $test
        : sub { like($_[0], $test_regex, 'Correctly barfed on incorrect branch') }
        ;

    my ($tzil, $repo_root) = prep_for_testing(
        repo_init => [
            sub { path(qw{ lib DZT })->mkpath },
            _ack('lib/DZT/Sample.pm' => 'package DZT::Sample; use Something; 1;'),
            _ack(foo => 'bap'),
            _ack(bap => 'bink'),
            'git checkout -b other_branch',
            _ack(foo  => 'bink'),
            _ack(bink => 'bink'),
        ],
        plugin_list => [ 'GatherDir', $plugin_cfg, 'FakeRelease' ],
    );

    my $thrown = exception { $tzil->release };
    diag_log($tzil, $test_sub->($thrown));
}

