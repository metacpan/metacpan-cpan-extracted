use 5.008005;
use ExtUtils::MakeMaker;

$CC = 'g++';
$freetype_cflags = `freetype-config --cflags`; chomp($freetype_cflags);
$freetype_libs = `freetype-config --libs`; chomp($freetype_libs);
WriteMakefile(
    NAME              => 'Image::PNGwriter',
    VERSION_FROM      => 'lib/Image/PNGwriter.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Image/PNGwriter.pm', # retrieve abstract from module
       AUTHOR         => 'Andres Kievsky <ank@cpan.org>') : ()),
    LIBS              => ['-lpngwriter -lpng '.$freetype_libs], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    CC		      => $CC,
    LD		      => '$(CC)',
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
    XSOPT             => '-C++',
    TYPEMAPS          => ['perlobject.map' ],
    CCFLAGS           => "-Wall -Wno-deprecated $freetype_cflags",
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);
if  (eval {require ExtUtils::Constant; 1}) {
  # If you edit these definitions to change the constants used by this module,
  # you will need to use the generated const-c.inc and const-xs.inc
  # files to replace their "fallback" counterparts before distributing your
  # changes.
  my @names = (qw(PNGWRITER_DEFAULT_COMPRESSION PNGWRITER_H PNGWRITER_VERSION
		 PNG_BYTES_TO_CHECK));
  ExtUtils::Constant::WriteConstants(
                                     NAME         => 'Image::PNGwriter',
                                     NAMES        => \@names,
                                     DEFAULT_TYPE => 'IV',
                                     C_FILE       => 'const-c.inc',
                                     XS_FILE      => 'const-xs.inc',
                                  );

}
else {
  use File::Copy;
  use File::Spec;
  foreach my $file ('const-c.inc', 'const-xs.inc') {
    my $fallback = File::Spec->catfile('fallback', $file);
    copy ($fallback, $file) or die "Can't copy $fallback to $file: $!";
  }
}
