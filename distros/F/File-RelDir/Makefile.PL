# File::RelDir
#
#    Maekfile.PL for File::RelDir
#    Copyright © Dave Roberts  2012
#
#******************************************************************************

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'File::RelDir',
    'VERSION_FROM'	=> 'RelDir.pm', # finds $VERSION
		'AUTHOR'   => 'Dave Roberts (droberts@cpan.org)',
		'ABSTRACT' => 'This module provides a mechanism to determine the relative path between two directory names.',
		'PREREQ_PM'		=> {
                  }, # e.g., Module::Name => 1.1

);

package MY;

sub postamble {
    <<"END_OF_POSTAMBLE";

pm_to_blib: README

README: RelDir.pm
\tpod2text RelDir.pm >README
\tpod2html RelDir.pm >RelDir.html
END_OF_POSTAMBLE
}

# Just to make it ignore editor backup files.
sub libscan {
 	$_ = $_[1];
	if ( m/(RCS|CVS|SCCS)/i || m/[~%]$/ || m/\.(orig|rej)$/ ) {
	  print " Ignoring $_\n";
	  return '';
  }
  return $_;
}

