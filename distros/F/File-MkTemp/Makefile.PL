############################################################################
#program: Makefile.PL
#purpose: Make the Makefile 
#by: Travis Gummels
#date: Mar 15 1999
############################################################################
print "\nChecking for File::Spec ......";
eval {
    require File::Spec;
};
if ($@) {
    print " FAILED! :(\n";
    print "Please read the errs file for errors.\n";

    open (F,">>errs");
    print F $@;
    close(F);

    print <<EOM;

The File::Spec module is needed to create a directory/file string
in the format understandable to the OS you are running.

The File::Spec module can be obtained from CPAN.  Visit
http://www.perl.com/CPAN/ to find a CPAN site near you.

EOM

    exit;
} else {
    print " PASSED! :)\n";
}


use ExtUtils::MakeMaker;
WriteMakefile(NAME => 'File',
	      VERSION_FROM => 'File/MkTemp.pm',
              clean => {FILES=>q[file* errs ./t/MkTemp_* ./t/MkTempO_*]});

package MY;
sub postamble {
	"\n\# Avoid make problems:\nstatic::\n\ndynamic::\n\n";
}

print "\n";
