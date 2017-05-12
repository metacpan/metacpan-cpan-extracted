use ExtUtils::MakeMaker;
use Config;

##------------------------------------------------------------------------
## We should use a function that allows us to check the return value of 
## compile stage.
##------------------------------------------------------------------------
print "Compiling libmpeg3 wrapper....";

## Suggestions on cross-platform optimization flags are welcome!
# `gcc -c libmpeg3.c -I$Config{archlibexp}/CORE -O3 -march=i686 -funroll-all-loops -fomit-frame-pointer -malign-loops=2 -malign-jumps=2 -malign-functions=2`;
`gcc -c libmpeg3.c -I$Config{archlibexp}/CORE -O3`;
print "OK\n";

##------------------------------------------------------------------------
## See lib/ExtUtils/MakeMaker.pm for details of how to influence
## the contents of the Makefile that is written.
##------------------------------------------------------------------------
WriteMakefile(
	      'NAME'		=> 'MPEG::LibMPEG3',
	      'VERSION_FROM'	=> 'LibMPEG3.pm', # finds $VERSION
	      'PREREQ_PM'       => {}, # e.g., Module::Name => 1.1
              'LIBS'            => ['-lm -lpthread -lmpeg3'],
              'OBJECT'          => 'libmpeg3.o',
	      'PERL_MALLOC_OK'  => 1,
	      
#   ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
#     (ABSTRACT_FROM => 'LibMPEG3.pm', # retrieve abstract from module
#      AUTHOR     => 'A. U. Thor <a.u.thor@a.galaxy.far.far.away>') : ()),
);
