use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'ExtUtils::configPL',
    'VERSION_FROM'	=> 'configPL.pm', # finds $VERSION
    'PREREQ_PM'		=> {'Filter::Util::Call' => 0,
			    'Config' => 0},
    'PL_FILES'		=> {
				't/def.PL'	=> 'def.t',
				't/opt.PL'	=> 'opt.t',
				't/mode.PL'	=> 'mode.t',
				't/no.PL'	=> 'no.t',
			   },
    depend		=> {
				't/def.PL'	=> 'configPL.pm',
				't/opt.PL'	=> 'configPL.pm',
				't/mode.PL'	=> 'configPL.pm',
				't/no.PL'	=> 'configPL.pm',
			   },
    realclean		=> { FILES => 't/*.t' },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'configPL.pm', # retrieve abstract from module
       AUTHOR     => 'Mark Pease <peasem@home.com>') : ()),
);
