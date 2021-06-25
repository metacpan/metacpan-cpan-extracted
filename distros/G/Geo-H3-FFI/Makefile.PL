use ExtUtils::MakeMaker;
WriteMakefile(
    NAME             => 'Geo::H3::FFI',
    VERSION_FROM     => 'lib/Geo/H3/FFI.pm',
    MIN_PERL_VERSION => '5.008',
    BUILD_REQUIRES   => {
                         'Test::More'          => 0,
                         'Test::Number::Delta' => 0,
                        },
    PREREQ_PM        => {
                         'Package::New'  => 0, 
                         'FFI::CheckLib' => 0, 
                         'FFI::Platypus' => 0, 
                         'FFI::C'        => 0, 
                        },
    ABSTRACT_FROM    => 'lib/Geo/H3/FFI.pm',
    AUTHOR           => 'Michael R. Davis (mrdvt@cpan.org)',
    LICENSE          => 'mit',
    META_MERGE       => {
          'meta-spec' =>  { version => 2 },
          'resources' =>  {
                            homepage   => 'https://github.com/mrdvt92/perl-Geo-H3-FFI',
                            bugtracker => {
                                web  => 'https://github.com/mrdvt92/perl-Geo-H3-FFI/issues',
                            },
                            repository => {
                                type => 'git',
                                url  => 'git@github.com:mrdvt92/perl-Geo-H3-FFI.git',
                                web  => 'https://github.com/mrdvt92/perl-Geo-H3-FFI.git',
                            },
                          },
                        },
);
