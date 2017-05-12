use lib qw(inc);
use ExtUtils::PkgConfig;

my $libexif = 'libexif';

ExtUtils::PkgConfig->atleast_version($libexif,'0.6.18') or die "N/A: Need libexif >= 0.6.18\n";
my $include = ExtUtils::PkgConfig->cflags_only_I($libexif);
my $cflags  = ExtUtils::PkgConfig->cflags_only_other($libexif);
my $libs    = ExtUtils::PkgConfig->libs($libexif);

use 5.006002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	NAME              => 'Image::LibExif',
	VERSION_FROM      => 'lib/Image/LibExif.pm', # finds $VERSION
	PREREQ_PM         => {}, # e.g., Module::Name => 1.1
	ABSTRACT_FROM     => 'lib/Image/LibExif.pm', # retrieve abstract from module
	AUTHOR            => 'Mons Anderson <mons@cpan.org>',
	LIBS              => [$libs], # e.g., '-lm'
	DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
	INC               => '-I. '.$include, # e.g., '-I. -I/usr/include/other'
	CCFLAGS           => $cflags,
	META_ADD          => { license => 'perl' },
);
