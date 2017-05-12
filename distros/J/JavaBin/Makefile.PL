use ExtUtils::MakeMaker;

WriteMakefile(
      'BUILD_REQUIRES' => {
    'Test::Fatal' => '0'
  },
    MIN_PERL_VERSION => 5.018,
    CCFLAGS      => '-fno-stack-protector -Wall -Werror -Wextra',
    NAME         => 'JavaBin',
    VERSION_FROM => 'lib/JavaBin.pm',
);
