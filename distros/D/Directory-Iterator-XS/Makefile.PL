use 5.006002;
use ExtUtils::MakeMaker;
use File::Spec;

my $ds = File::Spec->join('x','x');
$ds =~ y/x//ds;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Directory::Iterator::XS',
    VERSION_FROM      => 'lib/Directory/Iterator/XS.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Directory/Iterator/XS.pm', # retrieve abstract from module
       AUTHOR         => 'Steve Sanbeg <sanbeg@cpan.org>') : ()),
    ($ExtUtils::MakeMaker::VERSION >= 6.3002 ?
	  (LICENSE		=> 'perl') : ()),
    ($ExtUtils::MakeMaker::VERSION >= 6.4600 ?
      (META_MERGE => { 
	resources => { 
	  repository => 'https://github.com/sanbeg/Directory-Iterator'
	 }
       }) : ()
   ),

    LIBS              => [''], # e.g., '-lm'
    DEFINE            => qq(-DDIRECTORY_SEPARATOR=$ds), 
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    OBJECT            => '$(O_FILES)', # link all the C files too
    CC => 'c++', LD => 'c++', XSOPT => '-C++',
    #CCFLAGS => '-pedantic',
);
