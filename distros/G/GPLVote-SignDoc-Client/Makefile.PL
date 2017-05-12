use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'GPLVote::SignDoc::Client',
    VERSION_FROM      => 'lib/GPLVote/SignDoc/Client.pm', # finds $VERSION
    PREREQ_PM         => { Crypt::OpenSSL::RSA => 0, Crypt::OpenSSL::AES => 0, Bytes::Random::Secure => 0, Crypt::CBC => 0, MIME::Base64 => 0, LWP::UserAgent => 0, JSON => 0, Digest::SHA => 0 },
    ($] >= 5.005 ?     
      (ABSTRACT_FROM  => 'lib/GPLVote/SignDoc/Client.pm', # retrieve abstract from module
       AUTHOR         => 'Andrey Velikoredchanin <andy@andyhost.ru>') : ()),
);
