use lib qw(inc);
use Devel::CheckLib;
use Cwd;
use Config;
#for (keys %Config::Config) {
#	warn "$_: $Config::Config{$_}\n" if /cc|inc|lib/;
#}

check_lib_or_exit(
    debug   => 1,
    lib     => 'jpeg',
    libpath => [ grep length, split /\s+/,$Config::Config{libsdirs} ],
    incpath => [ Cwd::cwd(), grep length, split /\s+/,$Config::Config{locincpth} ],
    header  => [['"jinclude.h"','<jpeglib.h>']],
    define0 => "#define JPEG_INTERNALS\n",
    define  => "#if JPEG_LIB_VERSION < 80\n#error jpeglib version >= 80 required\n#endif",
);

#perl -Muni::perl=:dumper -MConfig -E 'say dumper \%Config::Config'                

use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	NAME              => 'Image::JpegTran',
	VERSION_FROM      => 'lib/Image/JpegTran.pm', # finds $VERSION
	PREREQ_PM         => {}, # e.g., Module::Name => 1.1
	ABSTRACT_FROM     => 'lib/Image/JpegTran.pm', # retrieve abstract from module
	AUTHOR            => 'Mons Anderson <mons@cpan.org>',
	LIBS              => ['-ljpeg'], # e.g., '-lm'
	DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
	INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	#CCFLAGS           => '-std=gnu99',
	#CCFLAGS           => '-Wunused -std=c99',
	OBJECT            => 'JpegTran.o transupp.o', # link all the C files too
);
