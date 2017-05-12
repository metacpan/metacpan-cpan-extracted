use 5.006001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'HTTP::CryptoCookie',
    'DISTNAME'		=> 'HTTP-CryptoCookie',
    'VERSION_FROM'	=> 'CryptoCookie.pm', # finds $VERSION
    'PREREQ_PM'		=> {'Test::More'  =>  0,
			'CGI::Cookie' => '1.26',
			'Crypt::CBC' => '2.17',
			'Crypt::Rijndael' => 0,
			'Convert::ASCII::Armour' => 0,
			'Compress::Zlib' => 0,
			'Digest::SHA2' => '1.1.0',
			'FreezeThaw' => 0,
			'Digest::SHA256' => 0 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (AUTHOR     => 'Dave Paris (a-mused) <amused@pobox.com>') : ()),
);

