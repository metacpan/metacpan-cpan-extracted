use 5.00800;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

eval { require forks };

WriteMakefile(
    NAME              => 'Email::Blaster',
    VERSION_FROM      => 'lib/Email/Blaster.pm', # finds $VERSION
    dist => {
      PREOP => 'pod2text lib/Email/Blaster.pm > $(DISTVNAME)/README',
    },
    EXE_FILES         => [qw(
      sbin/email-blaster-clustered.pl
      sbin/email-blaster-standalone.pl
      sbin/throttled-blaster.pl
    )],
    PREREQ_PM         => {
      forks             => 0.27,
      XML::Simple       => 2.18,
      Cwd               => 3.2701,
      Mail::Sendmail    => 0.79,
      Class::DBI::Lite  => 0.017,
      Digest::MD5       => 2.3601,
      MIME::Base64      => 3.07
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Email/Blaster.pm', # retrieve abstract from module
       AUTHOR         => 'John Drago <jdrago_999@yahoo.com>') : ()),
);
