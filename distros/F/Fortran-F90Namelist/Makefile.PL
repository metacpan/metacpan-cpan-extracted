# Makefile.PL
#
# Usage:
#   perl Makefile.PL
#   make
#   make test
#   make install
# To see details about tests (what exactly failed?), use
#   make test TEST_VERBOSE=1
#
# You can create the MANIFEST file with
#   perl -M'ExtUtils::Manifest qw(mkmanifest)' -e 'mkmanifest();'
# To update an existing MANIFEST file (which may contain comments after
# each file name), use
#   make manifest

use ExtUtils::MakeMaker;

WriteMakefile(
	      NAME         => 'Fortran::F90Namelist',
	      VERSION_FROM => 'lib/Fortran/F90Namelist.pm', # extract from .pm file
	      PL_FILES     => {}                 # leave Build.PL alone 
	     );

# Add this literally to the Makefile (see `man ExtUtils::MakeMaker'):
sub MY::postamble {
# For the time being, README will contain the documentation
return <<'MAKE_FRAG';
README: lib/Fortran/F90Namelist.pm
	pod2text lib/Fortran/F90Namelist.pm > README

pdf: lib/Fortran/F90Namelist.pm lib/Fortran/F90Namelist/Group.pm
	pod2latex -full -modify -prefile preamble.tex lib/Fortran/F90Namelist{,/Group}.pm -out F90Namelist.tex
	perl -i -0777 -pe 's/^(\\clearpage)/$$1\n\n\\emph{\\today}\n\n/m' F90Namelist.tex
	pdflatex F90Namelist && makeindex F90Namelist && pdflatex F90Namelist && pdflatex F90Namelist

cleantex:
	rm -f F90Namelist.{aux,dvi,idx,ilg,ind,log,out}

MAKE_FRAG
}


# End of file
