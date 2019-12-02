use 5.010001;

use strict;
use warnings;
use ExtUtils::MakeMaker 6.64;

WriteMakefile(
    NAME             => 'Devel::Cover::Report::BitBucketServer',
    VERSION_FROM     => 'lib/Devel/Cover/Report/BitBucketServer.pm',
    ABSTRACT         => 'BitBucket Server backend for Devel::Cover',
    AUTHOR           => 'Thomas Kratz <tomk@cpan.org>',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => 5.010001,
    META_MERGE       => {
        resources => {
            license    => 'http://www.opensource.org/licenses/artistic-license-2.0',
            repository => 'https://github.com/tomk3003/devel-cover-report-bitbucket-server',
            bugtracker => 'https://github.com/tomk3003/devel-cover-report-bitbucket-server/issues'
        },
        no_index => { directory => ['t'] }
    },
    CONFIGURE_REQUIRES => { "ExtUtils::MakeMaker" => "6.64", },
    PREREQ_PM          => { "Devel::Cover"        => "1.25", "Path::Tiny" => "0.013", "JSON::MaybeXS" => 0, },
    TEST_REQUIRES      => { "JSON::MaybeXS"       => 0, },
    test               => { TESTS                 => 't/*.t' }
);
