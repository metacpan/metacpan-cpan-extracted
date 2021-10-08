use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Geo::GoogleEarth::Pluggable',
    VERSION_FROM => 'lib/Geo/GoogleEarth/Pluggable.pm',
    AUTHOR       => 'Michael R. Davis (domain=>michaelrdavis,tld=>com,account=>perl)',
    ABSTRACT_FROM=> 'lib/Geo/GoogleEarth/Pluggable.pm',
    PREREQ_PM    => {
                     'Test::Simple'             => 0.44,
                     'Scalar::Util'             => 0,
                     'IO::Scalar'               => 0,
                     'XML::LibXML::LazyBuilder' => 0,
                     'Archive::Zip'             => 0,
                     'Method::Autoload'         => 0,
                     'Module::Pluggable'        => 0,
                     'Package::New'             => 0,
                    },
    LICENSE          => 'bsd',
    META_MERGE       => {
          'meta-spec' =>  { version => 2 },
          'resources' =>  {
                            homepage   => 'https://github.com/mrdvt92/perl-Geo-GoogleEarth-Pluggable',
                            bugtracker => {
                                web  => 'https://github.com/mrdvt92/perl-Geo-GoogleEarth-Pluggable/issues',
                            },
                            repository => {
                                type => 'git',
                                url  => 'git@github.com:mrdvt92/perl-Geo-GoogleEarth-Pluggable.git',
                                web  => 'https://github.com/mrdvt92/perl-Geo-GoogleEarth-Pluggable.git',
                            },
                          },
                        },

);
