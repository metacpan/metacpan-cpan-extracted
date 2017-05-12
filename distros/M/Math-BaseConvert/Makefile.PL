use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
#   the contents of the Makefile that is written.
WriteMakefile(
  'NAME'         => 'Math::BaseConvert',
  'VERSION'      => '1.8',
  'ABSTRACT'     => 'fast functions to CoNVert between number Bases',
  'AUTHOR'       => 'Pip Stuart <Pip@CPAN.Org>',
  'EXE_FILES'    => [
                      'bin/cnv',
                    ],
  'PREREQ_PM'    => {
    'Math::BigInt'                   => 0,
    'Memoize'                        => 0,
    'Test'                           => 0,
    'Test::Pod'                      => 0,
    'Test::Pod::Coverage'            => 0,
  }, # Module::Name => 1.1,
  'dist'         => { 'COMPRESS' => 'gzip', 'SUFFIX' => 'tgz' },
);
