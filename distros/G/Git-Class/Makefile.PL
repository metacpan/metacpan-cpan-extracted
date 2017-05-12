use strict;
use warnings;
use ExtUtils::MakeMaker::CPANfile;

WriteMakefile(
  NAME          => 'Git::Class',
  AUTHOR        => 'Kenichi Ishigaki <ishigaki@cpan.org>',
  VERSION_FROM  => 'lib/Git/Class.pm',
  ABSTRACT_FROM => 'lib/Git/Class.pm',
  LICENSE       => 'perl',
  META_MERGE => {
    resources => {
      repository => 'http://github.com/charsbar/git-class',
    },
  },
);
