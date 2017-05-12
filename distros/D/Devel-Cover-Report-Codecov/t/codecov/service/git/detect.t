use strict;
use warnings FATAL => 'all';
use utf8;

our $SYSTEM;
BEGIN {
    $SYSTEM = sub { CORE::system(@_) };
    *CORE::GLOBAL::system = sub { goto $SYSTEM };
}

use File::Temp qw/tempdir/;
use File::Which qw/which/;

use t::Util;
use Devel::Cover::Report::Codecov::Service::Git;
sub detect { Devel::Cover::Report::Codecov::Service::Git->detect(@_) }

if (which 'git') {
    subtest integrated => sub {
        subtest 'is inside worktree'  => sub {
            my $dir = tempdir;
            extract_tar('t/data/git.tar.bz2', $dir);
            my $guard = cwd_guard("$dir/git");

            ok detect;
        };

        subtest 'is not inside worktree'  => sub {
            my $dir = tempdir;
            my $guard = cwd_guard($dir);

            ok not detect;
        };
    };
}

subtest mock => sub {
    subtest 'is inside worktree'  => sub {
        local $SYSTEM = sub { 0 };
        ok detect;
    };

    subtest 'is not inside worktree' => sub {
        local $SYSTEM = sub { 1 };
        ok not detect;
    };
};

done_testing;
