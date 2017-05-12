use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

use strict;
my $module = 'Mail::Query';
my ($name, $dir);
($name = $module) =~ s/.*::(\w+)/$1.pm/;
($dir  = $module) =~ s/::/-/g;

WriteMakefile(
    'NAME'		=> $module,
    'VERSION_FROM'	=> $name,
    'PREREQ_PM'		=> {
			    'Mail::Audit' => 0,
			    'Parse::RecDescent' => 0,
			   },
    'dist'              => { PREOP=>('rm -f README; '.
				     "pod2text -80 < $name > README; ".
				     "cp -f README $dir-\$(VERSION); "
				    ),
			   },

);
