use ExtUtils::MakeMaker;
WriteMakefile
(
  'PL_FILES' => {},
  'INSTALLDIRS' => 'site',
  'NAME' => 'List::Gen',
  'MIN_PERL_VERSION' => '5.010',
  'CONFIGURE_REQUIRES' => {
      'ExtUtils::MakeMaker' => '6.64',
  },
  'EXE_FILES' => [],
  'VERSION_FROM' => 'lib/List/Gen.pm',
  'PREREQ_PM' => {
      'Scalar::Util' => 0,
      'Filter::Simple' => 0,
      'Benchmark' => 0,
      'Symbol' => 0,
      'List::Util' => 0,
      'Tie::File' => 0,
  },
  'TEST_REQUIRES' => {
      'Test::More' => 0,
      'FindBin' => 0,
      'Cwd' => 0,
  },
  'META_MERGE' => {
      "meta-spec" => { version => 2 },
      resources => {
          repository => {
              type => 'git',
              url => 'git://github.com/jo-37/list-gen.git',
              web => 'https://github.com/jo-37/list-gen.git',
          },
      },
  },
)
;
