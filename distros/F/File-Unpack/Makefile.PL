use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'File::Unpack',
    AUTHOR              => q{Juergen Weigert <jnw@cpan.org>},
    VERSION_FROM        => 'Unpack.pm',
    ABSTRACT_FROM       => 'Unpack.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    BUILD_REQUIRES => {
        'Test::More' => 0,
	'Test::CheckManifest' => '0.9',
	'FindBin' => 0,
	'Test::Pod' => '1.22',
	'Test::Pod::Coverage' => '1.08',
	'Pod::Coverage' => '0.18',
    },
    PL_FILES            => {},
    # Lzma, Bzip2, Zlib are not strictly required. 
    # we need them only for multi-level mimetype recognition.
    PREREQ_PM => {
	'File::LibMagic' => 0,
	'File::MimeInfo::Magic' => 0,
	'Compress::Raw::Lzma' => 0,
	'Compress::Raw::Bzip2' => 0,
	'Compress::Raw::Zlib' => '2.024',
	'BSD::Resource' => 0,
	'Filesys::Statvfs' => 0,

	'Cwd'	=> 0,
	'Carp'	=> 0,
	'File::Path' => 0,
	'File::Temp' => 0,
	'File::Copy' => 0,
	'File::Compare' => 0,
	'JSON' => 0,
	'String::ShellQuote' => 0,
	'IPC::Run' => 0, 
	'Text::Sprintf::Named' => 0,

	'Getopt::Long' => 0,
	'Pod::Usage' => 0,
    },
    # don't use bzip2 for cpan uploads, win32 smoke testers cannot unpack bz2.
    # dist                => { COMPRESS => 'bzip2 -9f', SUFFIX => 'bz2', },
    clean               => { FILES => ['file_unpack', 'File-Unpack-*' ] },
    EXE_FILES => [ 'file_unpack' ],
);

sub MY::postamble
{
  return q{
file_unpack: file_unpack.pl Makefile
	$(CP) file_unpack.pl $@
	## wait, so that -M < -M succeeds in ExtUtils/Command/MM.pm
	(sleep 1; echo .nf; $(PERL) $@ --help) > $(INST_MAN1DIR)/$@.1 || true
};
}

