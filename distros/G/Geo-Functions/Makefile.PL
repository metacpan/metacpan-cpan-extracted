use ExtUtils::MakeMaker;
WriteMakefile(
  LICENSE       => 'mit',
  NAME          => q{Geo::Functions},
  VERSION_FROM  => q{lib/Geo/Functions.pm},
  ABSTRACT_FROM => 'lib/Geo/Functions.pm',
  PREREQ_PM     => {
                    'Exporter'       => 0,
                    'Geo::Constants' => 0.06,
                   },
  'META_MERGE'  => {
                    'resources' => {
                      'repository' => {
                        'web' => 'https://github.com/mrdvt92/perl-Geo-Functions.git',
                        'url' => 'git@github.com:mrdvt92/perl-Geo-Functions.git',
                        'type' => 'git'
                      },
                       'homepage' => 'https://github.com/mrdvt92/perl-Geo-Functions',
                      'bugtracker' => {
                        'web' => 'https://github.com/mrdvt92/perl-Geo-Functions/issues'
                      }
                    },
                    'meta-spec' => {'version' => 2},
                   },
);
