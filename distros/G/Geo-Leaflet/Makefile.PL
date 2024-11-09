use ExtUtils::MakeMaker;
WriteMakefile(
    NAME          => 'Geo::Leaflet',
    VERSION_FROM  => 'lib/Geo/Leaflet.pm',
    PREREQ_PM     => {
                      'Package::New' => 0,
                      'CGI'          => 0,
                      'JSON::XS'     => 0,
                     },
    ABSTRACT_FROM => 'lib/Geo/Leaflet.pm',
    AUTHOR        => 'Michael R. Davis',
    LICENSE       => 'mit',

  'META_MERGE' => {
    'resources' => {
      'repository' => {
        'web' => 'https://github.com/mrdvt92/perl-Geo-Leaflet.git',
        'url' => 'git@github.com:mrdvt92/perl-Geo-Leaflet.git',
        'type' => 'git'
      },
      'homepage' => 'https://github.com/mrdvt92/perl-Geo-Leaflet',
      'bugtracker' => {
        'web' => 'https://github.com/mrdvt92/perl-Geo-Leaflet/issues'
      }
    },
    'meta-spec' => {
      'version' => 2
    }
  }

);
