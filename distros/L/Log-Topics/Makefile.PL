use ExtUtils::MakeMaker;
use Config;

$Version = '0.02';

WriteMakefile(
               'NAME'     => 'Log::Topics',
               linkext => {LINKTYPE => ''}, # not needed for MakeMakers >= 5
               'VERSION'  => $Version,
               'dist'     => { SUFFIX => 'gz', COMPRESS => 'gzip -f' },
               'clean' 	  => {'FILES' => '*~'},
);
