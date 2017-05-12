use 5.006001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'HTTP::Parser',
    'VERSION_FROM'	=> 'Parser.pm', # finds $VERSION
    'PREREQ_PM'		=> {
                         'URI'            => 0,
                         'HTTP::Request'  => 0,
                         'HTTP::Response' => 0,
                         'Test::More'     => 0,
                       },
    'LICENSE'   => 'perl',
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Parser.pm', # retrieve abstract from module
       AUTHOR     => 'David. B. Robins <dbrobins@davidrobins.net>') : ()),
);
