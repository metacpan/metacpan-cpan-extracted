use ExtUtils::MakeMaker;
WriteMakefile(
  NAME          => 'Geo::Constants',
  VERSION_FROM  => 'lib/Geo/Constants.pm',
  ABSTRACT_FROM => 'lib/Geo/Constants.pm',
  LICENSE       => 'perl',
  PREREQ_PM     => {
                    'Exporter'     => 0,
                    'Test::Simple' => 0.44, #Tests
                   },
  'META_MERGE' => {
    'resources' => {
      'repository' => {
        'web' => 'https://github.com/mrdvt92/perl-Geo-Constants.git',
        'url' => 'git@github.com:mrdvt92/perl-Geo-Constants.git',
        'type' => 'git'
      },
      'homepage' => 'https://github.com/mrdvt92/perl-Geo-Constants',
      'bugtracker' => {
        'web' => 'https://github.com/mrdvt92/perl-Geo-Constants/issues'
      }
    },
    'meta-spec' => {
      'version' => 2
    }
  },
);
