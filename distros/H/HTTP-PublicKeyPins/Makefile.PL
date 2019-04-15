use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'HTTP::PublicKeyPins',
    AUTHOR           => q{David Dick <ddick@cpan.org>},
    VERSION_FROM     => 'lib/HTTP/PublicKeyPins.pm',
    ABSTRACT_FROM    => 'lib/HTTP/PublicKeyPins.pm',
    LICENSE          => 'Perl_5',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'File::Spec' => 0,
    },
    PREREQ_PM => {
	'Convert::ASN1' => 0,
	'Crypt::OpenSSL::X509' => 1.803,
	'Crypt::PKCS10' => 1.5,
	'Crypt::OpenSSL::RSA' => 0,
	'CryptX' => 0, # undeclared dep for Crypt::PKCS10
	'Carp' => 0,
	'Digest' => 0,
	'English' => 0,
	'FileHandle' => 0,
	'Getopt::Long' => 0,
	'Pod::Usage' => 0,
	'MIME::Base64' => 0,
	'Exporter' => 0,
	'strict' => 0,
	'warnings' => 0,
    },
    EXE_FILES => [
	'bin/hpkp_pin_sha256',
    ],
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'HTTP-PublicKeyPins-*' },
);
