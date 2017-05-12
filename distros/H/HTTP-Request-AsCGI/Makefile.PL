
use strict;
use warnings;



use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME  => 'HTTP-Request-AsCGI',
  NAME      => 'HTTP::Request::AsCGI',
  AUTHOR    => "Christian\ Hansen\ \<ch\@ngmedia\.com\>\,\ Hans\ Dieter\ Pearcey\ \<hdp\@cpan\.org\>",
  ABSTRACT  => "Set\ up\ a\ CGI\ environment\ from\ an\ HTTP\:\:Request",
  VERSION   => '1.2',
  EXE_FILES => [ qw() ],
  (eval { ExtUtils::MakeMaker->VERSION(6.31) } ? (LICENSE => 'perl') : ()),
  PREREQ_PM    => {
    "Test::More" => '0',
    "IO::File" => '0',
    "HTTP::Response" => '1.53',
    "URI::Escape" => '0',
    "Class::Accessor" => '0',
    "HTTP::Request" => '0',
    "Carp" => '0',
  },
  test => {TESTS => 't/*.t'}
);

