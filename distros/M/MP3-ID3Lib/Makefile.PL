use strict;
use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'	=> 'MP3::ID3Lib',
    'VERSION_FROM' => 'ID3Lib.pm',
    'LIBS'	=> ['-lid3 -lz'],
    'DEFINE'	=> '',
    'INC'	=> '',
    'OBJECT'    => 'ID3Lib.o',
    'CC'        => 'g++',
    'LD'        => 'g++',
    'PREREQ_PM' => {
      'Test::More' => 0,
      'File::Copy' => 0,
    },
    'dist' => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);

sub MY::libscan {
  my $path = $_[1];
  return '' if $path =~ /\B\.svn\b/;
  return $path;
}

