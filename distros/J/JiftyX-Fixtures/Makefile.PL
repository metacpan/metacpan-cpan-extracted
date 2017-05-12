
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME  => 'JiftyX-Fixtures',
  NAME      => 'JiftyX::Fixtures',
  AUTHOR    => 'shelling\ \<shelling\@cpan\.org\>',
  ABSTRACT  => 'Insert fixtures into your Jifty application database',
  VERSION   => '0.07',
  EXE_FILES => [ qw(bin/jiftyx-fixtures) ],
  (eval { ExtUtils::MakeMaker->VERSION(6.21) } ? (LICENSE => 'mit') : ()),
  PREREQ_PM    => {
    "Text::Greeking" => '0',
    "YAML" => '0',
    "Jifty" => '0',
    "UNIVERSAL::dump" => '0',
    "App::CLI" => '0',
  },
);
