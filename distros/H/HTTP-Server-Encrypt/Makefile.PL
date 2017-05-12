use 5.008008;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'HTTP::Server::Encrypt',
    VERSION_FROM      => 'lib/HTTP/Server/Encrypt.pm', 
    PREREQ_PM         => {  
                            'Log::Lite' => 0.03,
                            'Sys::Sendfile' => 0,
                            'Data::Dump' => 0,
                            'HTTP::Status' => 0,
                            'HTTP::Date' => 0,
                            'Sys::Sendfile' => 0,
                            'Crypt::CBC' => 0,
                            'Digest::MD5' => 0,
                            'MIME::Base64' => 0,
                            'LWP::UserAgent' => 0,
                            'LWP::MediaTypes' => 0,
                        }, 
    ($] >= 5.005 ?     
      (ABSTRACT_FROM  => 'lib/HTTP/Server/Encrypt.pm', 
       AUTHOR         => 'Chen Gang <yikuyiku.com@gmail.com>') : ()),
);
