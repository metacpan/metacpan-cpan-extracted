use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	      => 'File::RsyncP',
    'VERSION_FROM'    => 'lib/File/RsyncP.pm', # finds $VERSION
    'PREREQ_PM'       => {
                            Getopt::Long => 2.24,	# need OO interface
                         },
    'PMLIBDIRS'       => ['lib'],
    'DIR'             => ['Digest', 'FileList'],
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/File/RsyncP.pm', # retrieve abstract from module
       AUTHOR         => 'Craig Barratt <cbarratt@users.sourceforge.net>')
                          : ()),
);
