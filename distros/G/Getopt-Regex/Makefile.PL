use ExtUtils::MakeMaker;
use Config;

$Version = '0.03';

WriteMakefile(
	      'NAME'     => 'Getopt::Regex',
	      linkext => {LINKTYPE => ''}, # not needed for MakeMakers >= 5
	      'VERSION'  => $Version,
	      'dist'     => { SUFFIX => 'gz', COMPRESS => 'gzip -f' },
	      'clean' 	  => {'FILES' => '*~'},
	      );
