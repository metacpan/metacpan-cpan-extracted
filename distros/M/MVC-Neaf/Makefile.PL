use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my $maker = ExtUtils::MakeMaker->VERSION;

my %test_req = (
        'Test::More'          => 0.87, # done_testing
        'Test::Warn'          => 0,
        'File::Temp'          => 0,
);

WriteMakefile(
    NAME                 => 'MVC::Neaf',
    AUTHOR               => q{Konstantin S. Uvarin <khedin@gmail.com>},
    VERSION_FROM         => 'lib/MVC/Neaf.pm',
    ABSTRACT_FROM        => 'lib/MVC/Neaf.pm',
    ($maker >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    MIN_PERL_VERSION     => 5.008,
    PL_FILES             => {},
    PREREQ_PM => {
        $] >= 5.01 ? () : (
            'Digest::SHA'     => 0,    # TODO use SHA3 instead
            'parent'          => 0,    # not present in 5.8
        ),
        'ExtUtils::MakeMaker' => 6.64, # for TEST_REQUIRES
        'HTTP::Headers::Fast' => 0.21, # psgi_flatten_without_sort
        'JSON::MaybeXS'       => 0,    # also by Plack via HTTP::Entity::Parser
        'Plack::Request'      => 0,
        'Template'            => 0,
        'URI::Escape'         => 0,
        $maker >= 7.12 ? () : (        # buggy test_requires, so emulate
            %test_req,
        ),
    },
    TEST_REQUIRES => {
        %test_req,
    },
    META_MERGE => {
        "meta-spec" => { version => 2 },
        prereqs => {
            develop => {
                requires => {
                    'DBD::SQLite'    => 0, # sql-based session
                    'DBI'            => 0,
                    'GD::Simple'     => 0, # for png example
                    'LWP::UserAgent' => 0, # it/*.t depends on it
                    'Test::Pod::Spelling' => 0,
                    'Lingua::Ispell' => 0,
                    (($] < 5.010) ? () : ('Validator::LIVR' => 0)),
                }
            },
            runtime => {
                recommends => {
                    'JSON::XS' => 0,
                    'Validator::LIVR' => 0,
                },
            },
        },
    },
    dist                 => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean                => { FILES => 'MVC-Neaf-*' },
);
