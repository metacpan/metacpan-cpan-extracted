use ExtUtils::MakeMaker;

WriteMakefile
  (
   NAME		=> 'Games::Chess',
   VERSION_FROM	=> 'lib/Games/Chess.pm',
   PREREQ_PM    => { 'GD' => 0 },
   dist         => { COMPRESS => 'gzip', SUFFIX => 'gz' }
  );
