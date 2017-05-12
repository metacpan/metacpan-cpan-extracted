use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME          => 'Email::MIME::XPath',
  AUTHOR        => 'Hans Dieter Pearcey <hdp@cpan.org>',
  VERSION_FROM  => 'lib/Email/MIME/XPath.pm',
  ABSTRACT_FROM => 'lib/Email/MIME/XPath.pm',
  PL_FILES      => {},
  PREREQ_PM     => {
    'Test::More'        => 0,
    'Scalar::Util'      => 0,
    'Tree::XPathEngine' => '0.05',
    'Test::use::ok'     => 0,
    'Email::MIME'       => '1.851',
    'Sub::Exporter'     => '0.972',
  },
  dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
  clean => { FILES    => 'Email-MIME-XPath-*' },
);
