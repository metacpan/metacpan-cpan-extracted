use strict;
use warnings;

use 5.006001;

use ExtUtils::MakeMaker;

WriteMakefile
  (
   'NAME'	        => 'Mail::POP3Client',
   'ABSTRACT'           => 'Perl 5 module to talk to a POP3 (RFC1939) server',
   'AUTHOR'             => 'Sean Dowd <pop3client@dowds.net>',
   'DISTNAME'           => "Mail-POP3Client",
   'VERSION_FROM'       => 'lib/Mail/POP3Client.pm',
   'LICENSE'            => 'perl',
   'MIN_PERL_VERSION'   => '5.6.1',
   'BUILD_REQUIRES'     => {},
   'CONFIGURE_REQUIRES' => {
     "ExtUtils::MakeMaker" => "6.30"
   },
   'LIBS'               => [''], # e.g., '-lm'
   'dist' => {
	      COMPRESS => "gzip -9f",
	      SUFFIX => "gz",
	     },
  "test" => {
    "TESTS" => "t/*.t"
  },
  META_MERGE => {
    resources => {
      repository => 'https://github.com/ssdowd/mail-pop3client',
    },
  },
  );
