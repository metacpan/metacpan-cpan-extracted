use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'         => 'Kwiki::IRCMode',
	'VERSION_FROM' => 'lib/Kwiki/IRCMode.pm',
  (eval { ExtUtils::MakeMaker->VERSION(6.21) } ? (LICENSE => 'perl') : ()),
	'PREREQ_PM'    => {
    'Kwiki'         => 0.33 ,
    'Parse::IRCLog' => 1.101,
  },
	'PREREQ_PRINT' => 1
);
