use ExtUtils::MakeMaker;
WriteMakefile(
    NAME           => 'ExtUtils::MakeMaker::META_MERGE::GitHub',
    VERSION_FROM   => 'lib/ExtUtils/MakeMaker/META_MERGE/GitHub.pm',
    BUILD_REQUIRES => { 
                       'ExtUtils::MakeMaker' => 6.46,
                       'Test::Simple'        => 0,
                      },
    PREREQ_PM      => {
                      },
    ABSTRACT_FROM  => 'lib/ExtUtils/MakeMaker/META_MERGE/GitHub.pm',
    AUTHOR         => 'Michael R. Davis',
    LICENSE        => 'perl',
    META_MERGE     => {
                        'resources' => {
                                         'repository' => {
                                                           'web' => 'https://github.com/mrdvt92/perl-ExtUtils-MakeMaker-META_MERGE-GitHub.git',
                                                           'url' => 'git@github.com:mrdvt92/perl-ExtUtils-MakeMaker-META_MERGE-GitHub.git',
                                                           'type' => 'git'
                                                         },
                                         'homepage' => 'https://github.com/mrdvt92/perl-ExtUtils-MakeMaker-META_MERGE-GitHub',
                                         'bugtracker' => {
                                                           'web' => 'https://github.com/mrdvt92/perl-ExtUtils-MakeMaker-META_MERGE-GitHub/issues'
                                                         }
                                       },
                        'meta-spec' => {
                                         'version' => 2
                                       },
                      },
    EXE_FILES    => [
                    qw{
                       scripts/perl-ExtUtils-MakeMaker-META_MERGE-GitHub.pl
                      }
                    ],

);
