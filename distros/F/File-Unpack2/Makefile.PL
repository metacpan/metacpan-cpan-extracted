use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME          => 'File::Unpack2',
  VERSION_FROM  => 'lib/File/Unpack2.pm',
  ABSTRACT_FROM => 'lib/File/Unpack2.pm',
  AUTHOR        => 'Sebastian Riedel <sriedel@suse.com>',
  LICENSE       => 'perl',

  MIN_PERL_VERSION => '5.016',

  CONFIGURE_REQUIRES => {'ExtUtils::MakeMaker' => '7.12'},

  # Lzma, Bzip2, Zlib are not strictly required; they are only used for
  # multi-level mime-type recognition. BSD::Resource and Filesys::Statvfs are
  # likewise optional safeguards. They are listed as recommends, not requires.
  PREREQ_PM => {
    'File::LibMagic'        => 0,
    'File::MimeInfo::Magic' => 0,
    'Cwd'                   => 0,
    'Carp'                  => 0,
    'File::Path'            => 0,
    'File::Temp'            => 0,
    'File::Copy'            => 0,
    'File::Compare'         => 0,
    'JSON'                  => 0,
    'String::ShellQuote'    => 0,
    'IPC::Run'              => 0,
    'Text::Sprintf::Named'  => 0,
    'Getopt::Long'          => 0,
    'Pod::Usage'            => 0,
  },

  TEST_REQUIRES => {'Test::More' => '0.98'},

  META_MERGE => {
    'meta-spec'    => {version => 2},
    dynamic_config => 0,
    no_index       => {directory => ['t']},
    prereqs        => {
      runtime => {
        recommends => {
          'Compress::Raw::Lzma'  => 0,
          'Compress::Raw::Bzip2' => 0,
          'Compress::Raw::Zlib'  => '2.024',
          'BSD::Resource'        => 0,
          'Filesys::Statvfs'     => 0,
        },
      },
    },
    resources => {
      repository => {
        type => 'git',
        url  => 'https://github.com/openSUSE/perl-File-Unpack2.git',
        web  => 'https://github.com/openSUSE/perl-File-Unpack2',
      },
      bugtracker => {web => 'https://github.com/openSUSE/perl-File-Unpack2/issues'},
      homepage   => 'https://github.com/openSUSE/cavil',
      license    => ['https://dev.perl.org/licenses/'],
    },
  },

  EXE_FILES => ['script/file_unpack2'],

  clean => {FILES => 'File-Unpack2-*'},
);
