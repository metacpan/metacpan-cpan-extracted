use ExtUtils::MakeMaker;
WriteMakefile(
  NAME          => 'Geo::Spline',
  VERSION_FROM  => 'lib/Geo/Spline.pm',
  ABSTRACT_FROM => 'lib/Geo/Spline.pm',
  LICENSE       => 'perl',
  PREREQ_PM     => {
                    'Geo::Constants'  => 0.04,
                    'Geo::Functions'  => 0.03,
                    'Geo::Ellipsoids' => 0.09,
                    'Test::Simple'    => 0.44, #Tests
                   },
  'META_MERGE' => {
    'resources' => {
      'repository' => {
        'web' => 'https://github.com/mrdvt92/perl-Geo-Spline.git',
        'url' => 'git@github.com:mrdvt92/perl-Geo-Spline.git',
        'type' => 'git'
      },
      'homepage' => 'https://github.com/mrdvt92/perl-Geo-Spline',
      'bugtracker' => {
        'web' => 'https://github.com/mrdvt92/perl-Geo-Spline/issues'
      }
    },
    'meta-spec' => {
      'version' => 2
    }
  },
);
