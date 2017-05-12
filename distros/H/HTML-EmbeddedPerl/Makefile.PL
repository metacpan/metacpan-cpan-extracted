use Config;
use ExtUtils::MakeMaker;
WriteMakefile(
  NAME          => 'HTML::EmbeddedPerl',
  ABSTRACT_FROM => 'lib/HTML/EmbeddedPerl.pm',
  AUTHOR        => 'TWINKLE COMPUTING <twinkle@cpan.org>',
  LICENSE       => 'perl',
  VERSION_FROM  => 'lib/HTML/EmbeddedPerl.pm',
  INST_SCRIPT   => 'blib/bin',
  INC           => '-I . -I mod_twepl',
  EXE_FILES     => ["bin/twepc$Config{_exe}", "bin/twepl$Config{_exe}"],
);

# xsubpp
print "ParseXS: processing to twepl_xsubs.\n";
chdir 'mod_twepl';
require 'XSUBTRIM.PL';
