
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'LWP::Authen::Negotiate',
    VERSION_FROM      => 'lib/LWP/Authen/Negotiate.pm', # finds $VERSION
    PREREQ_PM         => {
                             'GSSAPI'       => '0.18',
                             'MIME::Base64' => 2.12,
                             'LWP::Debug'   => 0,    # currently used for writing out information in debug-mode.
                                                     # If there is a better way how to handle Debug-Logging
                                                     # with LWP please let me know! Achim
                         },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/LWP/Authen/Negotiate.pm', # retrieve abstract from module
       AUTHOR         => 'Achim Grolms <perl@grolmsnet.de>') : ()),
);
