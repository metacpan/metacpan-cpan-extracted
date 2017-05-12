use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                 => 'MVC::Neaf',
    AUTHOR               => q{Konstantin S. Uvarin <khedin@gmail.com>},
    VERSION_FROM         => 'lib/MVC/Neaf.pm',
    ABSTRACT_FROM        => 'lib/MVC/Neaf.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    MIN_PERL_VERSION     => 5.008,
    PL_FILES             => {},
    PREREQ_PM => {
        'Carp'           => 0,
        'CGI'            => 0,
        'Data::Dumper'   => 0,
        'Digest::MD5'    => 0,
        'Digest::SHA'    => 0,
        'Encode'         => 0,
        'Fcntl'          => 0,
        'File::Basename' => 0,
        'Getopt::Long'   => 0,
        'HTTP::Headers'  => 0,
        'JSON'           => 0,
        'MIME::Base64'   => 0,
        'Module::Load'   => 0,
        'overload'       => 0,
        'parent'         => 0,
        'Plack::Request' => 0,
        'Scalar::Util'   => 0,
        'Sys::Hostname'  => 0,
        'Template'       => 0,
        'Time::HiRes'    => 0,
        'URI::Escape'    => 0,
    },
    TEST_REQUIRES => {
        'Test::More'     => 0.87, # done_testing
        'IO::Handle'     => 0,
        'File::Temp'     => 0,
    },
    META_MERGE => {
        "meta-spec" => { version => 2 },
        prereqs => {
            develop => {
                requires => {
                    'DBD::SQLite' => 0, # sql-based session
                    'DBI'         => 0,
                    'GD::Simple'  => 0, # for png example
                    (($] < 5.010) ? () : ('Validator::LIVR' => 0)),
                }
            }
        },
    },
    dist                 => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean                => { FILES => 'MVC-Neaf-*' },
);
