# @(#)Makefile.PL	1.1    03/07/09

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'MVS::JESFTP',
    'VERSION_FROM' => 'JESFTP.pm', # finds $VERSION
    ($] ge '5.005') ? (
    	'AUTHOR' => 'Mike Owens (mike.owens@state.nm.us)',
    	'ABSTRACT' => 'Submit JCL jobstreams to MVS via FTP',
    ) : (),
);
