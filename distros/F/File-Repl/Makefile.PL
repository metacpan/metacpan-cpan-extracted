# File::Repl
#
# Version
#      $Source: d:/src/perl/File/Repl/RCS/Makefile.PL $
#      $Revision: 1.4 $
#      $State: Exp $
#
# Start comments/code here - will not be processed into manual pages
#
#    Copyright © Dave Roberts  2000,2001
#
# Revision history:
#      $Log: Makefile.PL $
#      Revision 1.4  2011/11/25 07:29:24  Dave.Roberts
#      added COMPRESS arguments
#
#      Revision 1.3  2001/06/27 12:33:57  jj768
#      Changes to ignore the RCS directory
#
#
#******************************************************************************

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'File::Repl',
    'VERSION_FROM'	=> 'Repl.pm', # finds $VERSION
    'PREREQ_PM'		=> {
      File::Find         => 0,
      File::Copy         => 2.03,
      File::Basename     => 2.6,
      Win32::API         => 0,      # 0.2000.07.08,
  }, # e.g., Module::Name => 1.1
    'dist' => {
      ZIP      => 'wzzip.exe',
      ZIPFLAGS => "-P",
	  COMPRESS => 'gzip --best --force',
    },
    #HTMLLIBPODS => { 'Repl.pm'  => 'blib/html/site/lib/File/Repl.html'},
    MAN3PODS    => { 'Repl.pm'  => 'blib/man3/File::Repl.3' },
    PM => {
	    #'Repl.pm' => '$(INST_LIBDIR)/File/Repl.pm',  # installs File/File/Repl
      'Repl.pm' => '$(INST_LIBDIR)/Repl.pm',
      }
);

package MY;

sub postamble {
    <<"END_OF_POSTAMBLE";

pm_to_blib: README

README: Repl.pm
\tpod2text Repl.pm >README
\tpod2html Repl.pm >Repl.html
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

