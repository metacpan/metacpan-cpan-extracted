use strict;
use warnings FATAL => 'all';
use utf8;

use Config;
use Cwd qw/abs_path/;
use File::Temp qw/tempdir/;
use File::Which qw/which/;
use Cwd::Guard qw/cwd_guard/;

use t::Util;
use Devel::Cover::Report::Codecov::Service::Mercurial;

sub configuration {
    Devel::Cover::Report::Codecov::Service::Mercurial->configuration(@_);
}

if (which 'hg') {
    subtest hg => sub {
        my $dir = tempdir;
        extract_tar('t/data/hg.tar.bz2', $dir);
        my $guard = cwd_guard("$dir/hg");

        cmp_deeply
            configuration,
            {
                branch => 'default',
                commit => 'a42207909e7bdfc81dde25f307e9076ba71e04bf',
            };
    };
}

subtest mock => sub {
    local $ENV{PATH} =
        abs_path('t/data/libexec') . $Config::Config{path_sep} . $ENV{PATH};

    cmp_deeply
        configuration,
        {
            branch => 'default',
            commit => 'a42207909e7bdfc81dde25f307e9076ba71e04bf',
        };
};

done_testing;
