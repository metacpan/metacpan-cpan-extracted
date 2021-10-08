use ExtUtils::MakeMaker;
WriteMakefile(
    NAME             => 'Geo::GoogleEarth::Pluggable::Plugin::AsGeoJSON',
    VERSION_FROM     => 'lib/Geo/GoogleEarth/Pluggable/Plugin/AsGeoJSON.pm',
    PREREQ_PM        => {
                         'Geo::GoogleEarth::Pluggable' => 0.16,
                         'JSON::XS'                    => 0,
                        },
    ABSTRACT_FROM    => 'lib/Geo/GoogleEarth/Pluggable/Plugin/AsGeoJSON.pm',
    AUTHOR           => 'Michael Davis <mrdvt@cpan.org>',
    LICENSE          => 'mit',
    META_MERGE       => {
          'meta-spec' =>  { version => 2 },
          'resources' =>  {
                            homepage   => 'https://github.com/mrdvt92/perl-Geo-GoogleEarth-Pluggable-Plugin-AsGeoJSON',
                            bugtracker => {
                                web  => 'https://github.com/mrdvt92/perl-Geo-GoogleEarth-Pluggable-Plugin-AsGeoJSON/issues',
                            },
                            repository => {
                                type => 'git',
                                url  => 'git@github.com:mrdvt92/perl-Geo-GoogleEarth-Pluggable-Plugin-AsGeoJSON.git',
                                web  => 'https://github.com/mrdvt92/perl-Geo-GoogleEarth-Pluggable-Plugin-AsGeoJSON.git',
                            },
                          },
                        },
);
