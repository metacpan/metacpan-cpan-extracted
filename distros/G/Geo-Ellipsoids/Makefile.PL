use ExtUtils::MakeMaker;
WriteMakefile(
  NAME          => 'Geo::Ellipsoids',
  VERSION_FROM  => 'lib/Geo/Ellipsoids.pm',
  ABSTRACT_FROM => 'lib/Geo/Ellipsoids.pm',
  LICENSE       => 'perl',
  PREREQ_PM => {
                 'Geo::Functions' => 0.03,
                 'Geo::Constants' => 0.04,
               },
  'META_MERGE' => {
    'resources' => {
      'repository' => {
        'web' => 'https://github.com/mrdvt92/perl-Geo-Ellipsoids.git',
        'url' => 'git@github.com:mrdvt92/perl-Geo-Ellipsoids.git',
        'type' => 'git'
      },
      'homepage' => 'https://github.com/mrdvt92/perl-Geo-Ellipsoids',
      'bugtracker' => {
        'web' => 'https://github.com/mrdvt92/perl-Geo-Ellipsoids/issues'
      }
    },
    'meta-spec' => {
      'version' => 2
    }
  },
);
