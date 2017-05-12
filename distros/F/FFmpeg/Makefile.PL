use ExtUtils::MakeMaker;
use Config;

$FFMPEG_ROOT = $ENV{FFMPEG_ROOT} || '/usr/include/ffmpeg';
$FFMPEG_INC  = $ENV{FFMPEG_INC}  || $FFMPEG_ROOT || '/usr/include/ffmpeg';
$FFMPEG_LIB  = $ENV{FFMPEG_LIB}  || $FFMPEG_ROOT || '/usr/lib';

#
# ... now we're ready to start the module build & install process
#

$LDDLFLAGS = '';
$LDDLFLAGS = '-all_load' if $^O eq 'darwin';
$LDDLFLAGS = '-L/usr/pkg/lib' if $^O eq 'netbsd';

#open(FFMPEGH, ">ffmpeg.h") or die $!;
#print FFMPEGH "#include \"$FFMPEG_ROOT/config.h\"\n";
#print FFMPEGH "#include \"$FFMPEG_ROOT/ffmpeg.c\"\n";
#close(FFMPEGH);

WriteMakefile(
      'NAME'          => 'FFmpeg',
      'VERSION_FROM'  => 'FFmpeg.pm',
      'DEFINE'        => '-O',
      'LDDLFLAGS'     => "$Config{'lddlflags'} $LDDLFLAGS",

      'PREREQ_PM'     => {
              File::Temp => 0,
              HTTP::Request => 0,
              Image::Magick::Iterator   => 0.01,
              Image::PBMlib => 1.05, #1.06?
              LWP::UserAgent => 0,
      },

      ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
          (ABSTRACT_FROM  => 'FFmpeg.pm', # retrieve abstract from module
           AUTHOR         => 'Allen Day <allenday@ucla.edu>') : ()),

      'PERL_MALLOC_OK'  => 1,
      'LIBS'            => ["-L$FFMPEG_LIB -lavcodec -lavformat -lm -lz -ldl -lmp3lame -logg -lvorbis -lvorbisenc"],
      'INC'             => "-I. -I$FFMPEG_INC -I$FFMPEG_INC/libavutil -I$FFMPEG_INC/libavcodec -I$FFMPEG_INC/libavformat",
);
