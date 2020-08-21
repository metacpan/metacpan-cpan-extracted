use strict;
use warnings;
 
use ExtUtils::MakeMaker;
 
my %params = (
  "VERSION" => "0.01",
  "NAME" => "GDB::bt",
  "ABSTRACT" => "Get perl backtraces from coredump files",
  "AUTHOR" => "- Ivan Baidakou",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "GDB-bt",
  "EXE_FILES" => ["bin/gdb-bt.pl", "bin/gdb-bt.py" ],
  "LICENSE" => "perl",
  "PREREQ_PM" => {},
  "META_MERGE" => { resources => {
      repository => 'https://github.com/basiliscos/p5-GDB-bt',
  }},
);

delete $params{CONFIGURE_REQUIRES} unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

delete $params{META_MERGE} unless eval { ExtUtils::MakeMaker->VERSION(6.46) };

WriteMakefile(%params);
