use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Mail::Simple::DKIM::Signer',
    VERSION_FROM      => 'lib/Mail/Simple/DKIM/Signer.pm', # finds $VERSION
    PREREQ_PM         => {
        
        Digest::SHA => 0,
        MIME::Base64 => 0,
        Crypt::OpenSSL::RSA => 0
        
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Mail/Simple/DKIM/Signer.pm', # retrieve abstract from module
       AUTHOR         => 'Mahmoud A. Mehyar <mamod.mehyar@gmail.com>') : ()),
);
