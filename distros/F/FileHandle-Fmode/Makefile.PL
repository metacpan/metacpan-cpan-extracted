use ExtUtils::MakeMaker;

my %options =
(
  NAME     => 'FileHandle::Fmode',
  VERSION_FROM => 'Fmode.pm',
  LICENSE  => 'perl',
  DEFINE   => $] < 5.008 ? $] < 5.006001 ? '-DOLDPERL' : '-DPERL561_OR_LATER' : '-DPERL580_OR_LATER -DPERL561_OR_LATER',
  clean   => { FILES => 'temp.txt temp2.txt' },
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

