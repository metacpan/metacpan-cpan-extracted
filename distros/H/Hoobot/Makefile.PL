use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Hoobot',
    'VERSION_FROM'	=> 'lib/Hoobot.pm', # finds $VERSION
    'PREREQ_PM'		=> {
      LWP::UserAgent => 2.003,
      XML::LibXML => 1.54,
      URI => 1.23,
      HTTP::Request::Common => 1.19,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Hoobot.pm', # retrieve abstract from module
       AUTHOR     => 'Benjamin Smith <bsmith@cpan.org>') : ()),
);
