
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME  => 'Log-Statistics',
  NAME      => 'Log::Statistics',
  AUTHOR    => 'Alex\ White\ \<VVu\@geekfarm\.org\>',
  ABSTRACT  => 'near\-real\-time\ statistics\ from\ log\ files',
  VERSION   => '0.051',
  EXE_FILES => [ qw(bin/log_tail_mirror.pl bin/logstatsd bin/rrdgraph.sh) ],
  (eval { ExtUtils::MakeMaker->VERSION(6.31) } ? (LICENSE => 'bsd') : ()),
  PREREQ_PM    => {
    "IO::File" => '0',
    "YAML" => '0',
    "Benchmark" => '0',
    "Data::Dumper" => '0',
    "Test::More" => '0',
    "Config::IniFiles" => '0',
    "Class::Std::Utils" => '0',
    "File::Tail" => '0',
    "XML::Writer" => '0',
    "File::Temp" => '0',
    "Date::Manip" => '0',
    "Log::Log4perl" => '0',
  },
  test => {TESTS => 't/*.t'}
);

