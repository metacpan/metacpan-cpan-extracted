use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Mail::POPRelay',
    'VERSION_FROM'	=> 'POPRelay.pm', # finds $VERSION
    'ABSTRACT_FROM'     => 'POPRelay.pm',
    'AUTHOR'            => 'POPRelay.pm',
    'EXE_FILES'		=> [ qw(bin/poprelay_cleanup bin/poprelay_ipop3d bin/poprelay_vpopd) ],
    'PREREQ_PM'		=> {
        'POSIX'        => 0,
	'Carp'         => 0,
	'Data::Dumper' => 0,
	'File::Tail'   => 0,
    }, # e.g., Module::Name => 1.1
    'dist'		=> {
        'COMPRESS'	=> 'gzip -9v',
        'SUFFIX'	=> '.gz',
    },
);


# ---------
sub MY::postamble {
'
readme : README.poprelay_cleanup README.poprelay_ipop3d README.poprelay_qpopper README.poprelay_vpopd README

README : POPRelay.pm
	pod2text POPRelay.pm > README

README.poprelay_cleanup : bin/poprelay_cleanup
	pod2text bin/poprelay_cleanup > README.poprelay_cleanup

README.poprelay_ipop3d : bin/poprelay_ipop3d
	pod2text bin/poprelay_ipop3d > README.poprelay_ipop3d

README.poprelay_qpopper : bin/poprelay_qpopper
	pod2text bin/poprelay_qpopper > README.poprelay_qpopper

README.poprelay_vpopd : bin/poprelay_vpopd
	pod2text bin/poprelay_vpopd > README.poprelay_vpopd


';
}

# $Id: Makefile.PL,v 1.2 2002/08/20 01:25:37 keith Exp $
