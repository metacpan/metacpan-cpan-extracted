use 5.008007;
use ExtUtils::MakeMaker;
use FindBin;
use File::Copy 'copy';

# Clenup files
my @cleanup_files;

# libpng soruce and header(libpng-1.6.17)
# script/libconf.h.prebuilt -> pnglibconf.h
my @libpng_sources = qw(
  pngconf.h
  pngdebug.h
  png.h
  pnginfo.h
  pngpriv.h
  pngstruct.h
  png.c
  pngerror.c
  pngget.c
  pngmem.c
  pngpread.c
  pngread.c
  pngrio.c
  pngrtran.c
  pngrutil.c
  pngset.c
  pngtest.c
  pngtrans.c
  pngwio.c
  pngwrite.c
  pngwtran.c
  pngwutil.c
);
my $libpng_libconf_soruce_from = 'scripts/pnglibconf.h.prebuilt';
my $libpng_libconf_soruce_to = 'pnglibconf.h';

# Copy libpng source
my $libpng_dir = "$FindBin::Bin/libpng-1.6.17";
for my $libpng_source (@libpng_sources) {
  copy "$libpng_dir/$libpng_source", "$FindBin::Bin/$libpng_source"
    or die "Can't copy $libpng_source: $!";
  push @cleanup_files, $libpng_source;
}
copy "$libpng_dir/$libpng_libconf_soruce_from", "$FindBin::Bin/$libpng_libconf_soruce_to"
  or die "Can't copy $libpng_libconf_soruce_from to $libpng_libconf_soruce_to: $!";
  
push @cleanup_files, $libpng_libconf_soruce_to;

# zlib source and header (zlib-1.2.8)
my @zlib_sources = qw(
  crc32.h
  deflate.h
  gzguts.h
  inffast.h
  inffixed.h
  inflate.h
  inftrees.h
  trees.h
  zconf.h
  zlib.h
  zutil.h
  adler32.c
  compress.c
  crc32.c
  deflate.c
  gzclose.c
  gzlib.c
  gzread.c
  gzwrite.c
  infback.c
  inffast.c
  inflate.c
  inftrees.c
  trees.c
  uncompr.c
  zutil.c
);

# Copy zlib source
my $zlib_dir = "$FindBin::Bin/zlib-1.2.8";
for my $zlib_source (@zlib_sources) {
  copy "$zlib_dir/$zlib_source", "$FindBin::Bin/$zlib_source"
    or die "Can't copy $zlib_source: $!";
  push @cleanup_files, $zlib_source;
}

push @cleanup_files, 'Image-PNG-Simple-*';

WriteMakefile(
    NAME              => 'Image::PNG::Simple',
    VERSION_FROM      => 'lib/Image/PNG/Simple.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Image/PNG/Simple.pm', # retrieve abstract from module
       AUTHOR         => 'A. U. Thor <kimoto@sakura.ne.jp>') : ()),
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
    OBJECT            => '$(O_FILES)', # link all the C files too.
    clean             =>  {FILES => join(' ', @cleanup_files)}
);
