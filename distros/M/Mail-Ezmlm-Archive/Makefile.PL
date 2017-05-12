# $Id: Makefile.PL,v 1.0 2005/08/10 16:05 $

use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
	'AUTHOR'	   => 'Alessandro Ranellucci <aar@cpan.org>',
    'NAME'         => 'Mail::Ezmlm::Archive',
    'ABSTRACT'		=> 'Object methods for ezmlm-idx archives',
    'VERSION_FROM' => 'Archive.pm', # finds $VERSION
    'dist'         => { COMPRESS => 'gzip', SUFFIX => 'gz' }
);
