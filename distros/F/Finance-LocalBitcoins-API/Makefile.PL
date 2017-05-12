use 5.014002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Finance::LocalBitcoins::API',
    VERSION_FROM      => 'lib/Finance/LocalBitcoins/API.pm', # finds $VERSION
    PREREQ_PM         => {
        JSON              => 0,
        'LWP::UserAgent'  => 6,
        URI               => 0,
        CGI               => 0,
        JSON              => 0,
        'MIME::Base64'    => 0,
        'Time::HiRes'     => 0,
        'Digest::SHA'     => 0,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Finance/LocalBitcoins/API.pm', # retrieve abstract from module
       AUTHOR         => 'Jeff Anderson <peawormsworth@gmail.com>') : ()),
);
