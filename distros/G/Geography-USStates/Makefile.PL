use ExtUtils::MakeMaker;

WriteMakefile(NAME => 'Geography::USStates',
              dist => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
              VERSION_FROM => 'USStates.pm');
