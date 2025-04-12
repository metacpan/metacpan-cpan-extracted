use ExtUtils::MakeMaker;
WriteMakefile(
    NAME          => 'Geo::WebService::OpenCellID',
    VERSION_FROM  => 'lib/Geo/WebService/OpenCellID.pm',
    AUTHOR        => 'Michael R. Davis',
    ABSTRACT_FROM => 'lib/Geo/WebService/OpenCellID.pm',
    PREREQ_PM     => {
                      'Test::Simple' => 0.44,
                      'URI'          => 0,
                      'XML::Simple'  => 0,
                      'LWP::Simple'  => 0,
                     },
  'META_MERGE' => {
    'meta-spec' => {
      'version' => 2
    },
    'resources' => {
      'bugtracker' => {
        'web' => 'https://github.com/perl-Geo-WebService-OpenCellID/perl-Geo-WebService-OpenCellID/issues'
      },
      'homepage' => 'https://github.com/perl-Geo-WebService-OpenCellID/perl-Geo-WebService-OpenCellID',
      'repository' => {
        'url' => 'git@github.com:perl-Geo-WebService-OpenCellID/perl-Geo-WebService-OpenCellID.git',
        'type' => 'git',
        'web' => 'https://github.com/perl-Geo-WebService-OpenCellID/perl-Geo-WebService-OpenCellID.git'
      }
    }
  },
);
