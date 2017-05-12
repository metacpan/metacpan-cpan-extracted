#
# Created:  05 Dec 2001
# $Id: Makefile.PL,v 1.9 2003/11/13 18:50:01 rob Exp $

use ExtUtils::MakeMaker;
WriteMakefile
  NAME          => 'File::DirSync',
  VERSION_FROM  => 'lib/File/DirSync.pm', # finds $VERSION
  EXE_FILES     => [ 'dirsync' ],
  PREREQ_PM	  => {
    "File::Path" => 1,
    "File::Copy" => 1,
  },
  dist => {
    COMPRESS => "gzip -9 -vf",
  },
  AUTHOR => 'Rob Brown <bbb@cpan.org>',
  ;

package MY;

sub libscan {
  my $self = shift;
  my $path = shift;
  ($path =~ / \bCVS\b | \~$ /x) ? undef : $path;
}

sub postamble {
  return qq^

pm_to_blib: README

README: \$(VERSION_FROM)
	pod2text \$(VERSION_FROM) > README
^;
}
