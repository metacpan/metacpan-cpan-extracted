use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'DirDB::FTP',
    'VERSION_FROM'	=> 'FTP.pm', # finds $VERSION
    'PREREQ_PM'		=> {Net::FTP::blat => 0.02}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'FTP.pm', # retrieve abstract from module
       AUTHOR     => 'David Nicol <davidnico@cpan.org>') : ()),
);
