use ExtUtils::MakeMaker;
WriteMakefile(
    NAME       => 'Devel::Deprecations::Environmental',
    META_MERGE => {
        license   => 'open_source',
        resources => {
            repository => 'https://github.com/DrHyde/perl-modules-Devel-Deprecations',
            bugtracker => 'https://github.com/DrHyde/perl-modules-Devel-Deprecations/issues',
        }
    },
  VERSION_FROM => 'lib/Devel/Deprecations/Environmental.pm',
  PREREQ_PM    => {
    'Test::More'                => 0.96, # done_testing and subtests
    'Test::Exception'           => 0.43,
    'Test::Time'                => 0.092,
    'Module::Load'              => 0,
    'DateTime'                  => 0,
    'DateTime::Format::ISO8601' => 0,
    'Devel::CheckOS'            => 1.95, # HWCapabilities::Int{32,64}
    'Scalar::Util'              => 0,
  },
);
