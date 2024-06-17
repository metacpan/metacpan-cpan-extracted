use strict;
use warnings;
use ExtUtils::MakeMaker;

my $defines = $] < 5.008 ? $] < 5.006001 ? '-DOLDPERL' : '-DPERL561_OR_LATER' : '-DPERL580_OR_LATER -DPERL561_OR_LATER';
$defines .= ' -DLIBC_IS_UCRT' if $Config::Config{libc} =~ /\-lucrt$|ucrt\.lib$/i;

my %options =
(
  NAME     => 'FileHandle::Fmode',
  VERSION_FROM => 'Fmode.pm',
  LICENSE  => 'perl',
  clean    => { FILES => 'temp.txt temp2.txt' },
  LICENSE  => 'perl',
  DEFINE   => $defines,
  META_MERGE => {
   'meta-spec' => { version => 2 },
    resources => {
      repository => {
        type => 'git',
        url => 'https://github.com/sisyphus/filehandle-fmode.git',
        web => 'https://github.com/sisyphus/filehandle-fmode',
      },
    },
  },
);

WriteMakefile(%options);

