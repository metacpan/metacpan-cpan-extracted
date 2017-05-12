use strict;
use warnings;
 
use ExtUtils::MakeMaker;
WriteMakefile
(
  NAME         => 'IDCHECKIO',
  VERSION_FROM => 'lib/IDCHECKIO/Client.pm',
  AUTHOR   => 'Denis Jagoudel (denis.jagoudel@ariadnext.com)',
  ABSTRACT => 'Module to use the IDCHECKIO API easily',
  LICENSE  => 'perl',
  BUILD_REQUIRES => {
    'REST::Client'     => '273',
    'JSON::Parse'      => '0.39',
    'Cpanel::JSON::XS' => '3.0211'
  },
);
