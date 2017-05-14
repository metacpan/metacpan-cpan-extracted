use ExtUtils::MakeMaker;
WriteMakefile(
	      NAME => 'HTML::QuickCheck',
	      VERSION => '1.0b1',
	      'linkext' => {LINKTYPE => ''},
	      'dist' => {COMPRESS => 'gzip', SUFFIX => 'gz'},
);
