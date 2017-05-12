use ExtUtils::MakeMaker;
WriteMakefile(
	      NAME => 'FakeHash',
	      VERSION_FROM => 'FakeHash.pm',
#	      'linkext' => {LINKTYPE => ''},
	      'dist' => {COMPRESS => 'gzip', SUFFIX => 'gz'},
#              depend => {'.SUFFIXES' => '.ps .gif .pic',
#                         '.ps.gif' = 
);
