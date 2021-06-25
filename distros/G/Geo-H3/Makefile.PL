use ExtUtils::MakeMaker;
WriteMakefile(
    NAME             => 'Geo::H3',
    VERSION_FROM     => 'lib/Geo/H3.pm',
    MIN_PERL_VERSION => 5.008,
    BUILD_REQUIRES   => {
                         'Test::More'          => 0, 
                         'Test::Number::Delta' => 0,
                        },
    PREREQ_PM        => {
                         'Geo::H3::FFI'  => 0.05,
                         'FFI::CheckLib' => 0,
                        },
    ABSTRACT_FROM    => 'lib/Geo/H3.pm',
    AUTHOR           => 'Michael R. Davis <mrdvt@cpan.org>',
    LICENSE          => 'mit',
    META_MERGE       => {
          'meta-spec' =>  { version => 2 },
          'resources' =>  {
                            homepage   => 'https://github.com/mrdvt92/perl-Geo-H3',
                            bugtracker => {
                                web  => 'https://github.com/mrdvt92/perl-Geo-H3/issues',
                            },
                            repository => {
                                type => 'git',
                                url  => 'git@github.com:mrdvt92/perl-Geo-H3.git',
                                web  => 'https://github.com/mrdvt92/perl-Geo-H3.git',
                            },
                          },
                        },
    EXE_FILES        => [
                         qw{
                            scripts/perl-Geo-H3-geo-to-googleearth.pl
                           }
                        ],
);
