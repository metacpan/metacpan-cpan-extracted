use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
use Config;

if (exists($Config{'usrinc'})) {
  $usrinc = $Config{'usrinc'};
} else {
  $usrinc = "/usr/include";
}

if (-r $usrinc . "/shadow.h") {
  $shadow = "-DHAVE_SHADOW_H";
} else {
  $shadow = '';
}

WriteMakefile('NAME'	=> 'File::LckPwdF',
	      'VERSION_FROM' => 'LckPwdF.pm', # finds $VERSION
	      'LIBS'	=> [''],
	      'DEFINE'	=> $shadow, 
	      'INC'	=> '',
	      'XSPROTOARG' => '-prototypes',
	      'dist' => {'COMPRESS'=>"gzip",
			 'SUFFIX'=>"gz",
			 'PREOP'=> "COLUMNS=76 pod2text \$(MAN1PODS)" .
			 " \$(MAN3PODS) > \$(DISTVNAME)/README"
			}
	     );
