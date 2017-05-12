use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Ipernity::API',
    VERSION_FROM      => 'lib/Ipernity/API.pm', # finds $VERSION
    PREREQ_PM         => {
	    'URI'		=> 1.55,
	    'HTTP::Request'	=> 5.827,
	    'XML::Simple'	=> 2.18,
	    'LWP::UserAgent'	=> 5.829,
	    'Digest::MD5'	=> 2.36,
    },
    PREREQ_FATAL      => 0,
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Ipernity/API.pm', # retrieve abstract from module
       AUTHOR         => 'Winfried Neessen <doomy@dokuleser.org>') : ()),
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);
