use ExtUtils::MakeMaker;
WriteMakefile(
  'NAME'           => 'Math::BaseCnv',
# 'VERSION_FROM'   => 'lib/Math/BaseCnv.pm',
  'VERSION'        => '1.14',
# 'ABSTRACT_FROM'  => 'lib/Math/BaseCnv.pm',
  'ABSTRACT'       => 'basic functions to CoNVert between number Bases',
  'LICENSE'        => 'gpl_3',
  'AUTHOR'         => [ 'Pip Stuart <Pip@CPAN.Org>' ],
  'EXE_FILES'      => [ 'bin/cnv' ],
  'TEST_REQUIRES'  => {
    'Test'                           => 0,
    'Test::More'                     => 0,
    'Test::Pod'                      => 0,
    'Test::Pod::Coverage'            => 0,
  }, # Module::Name                  => 1.1,
  'PREREQ_PM'      => {
    'Math::BigInt'                   => 0,
    'Memoize'                        => 0,
    'Carp'                           => 0,
  },
  'dist'           => { 'COMPRESS'   => 'gzip',
                        'SUFFIX'     => '.tgz' },
);
