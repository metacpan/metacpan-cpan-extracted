use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Filter::NumberLines',
    'VERSION_FROM'	=> 'NumberLines.pm', # finds $VERSION
    'PREREQ_PM' => {
         'Filter::Util::Call' => '1.05',
         'Filter::Simple'     => '0.78',
     },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
     (AUTHOR     => 'Hendrik Van Belleghem') : ()),
);
