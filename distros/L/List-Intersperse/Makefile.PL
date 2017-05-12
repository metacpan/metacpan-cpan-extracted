use ExtUtils::MakeMaker;
WriteMakefile
  (NAME            => 'List::Intersperse',
   VERSION_FROM    => 'Intersperse.pm',
   dist =>
   {COMPRESS       => 'gzip',
    SUFFIX         => 'gz',
   },

   clean           => {FILES => ".test*"},
  );
