package DC::OpenGL;

use common::sense;

use Carp ();
use DC;

our %GL_EXT;
our $GL_VERSION;

our $GL_NPOT;
our $GL_COMPRESS;
our $GL_BFSEP; # blendfuncseparate
our $GL_MULTITEX;
our $APPLE_NVIDIA_BUG;

our $DEBUG = 1;
our %INIT_HOOK;
our %SHUTDOWN_HOOK;

sub import {
   my $caller = caller;

   my $symtab = *{"main::DC::OpenGL::"}{HASH};

   for (keys %$symtab) {
      *{"$caller\::$_"} = *$_
         if /^(?:gl[A-Z_]|GL_)/;
   }
}

sub init {
   $GL_VERSION = gl_version * 1;
   %GL_EXT = map +($_ => 1), split /\s+/, gl_extensions;

   unless (defined $::CFG->{force_opengl11}) {
      # try to find a suitable default
      if (
         $GL_VERSION >= 2.0
         && (!$GL_EXT{GL_ARB_texture_non_power_of_two}
             || !$GL_EXT{GL_EXT_blend_func_separate})
      ) {
         $::CFG->{force_opengl11} = 1;
      } else {
         $::CFG->{force_opengl11} = 0;
      }
   }

   if ($::CFG->{force_opengl11}) {
      $GL_VERSION = 1.1;
      %GL_EXT = ();
   }

   $GL_BFSEP    = $GL_EXT{GL_EXT_blend_func_separate}      || $GL_VERSION >= 2.0;
   $GL_NPOT     = $GL_EXT{GL_ARB_texture_non_power_of_two} || $GL_VERSION >= 2.0;
   $GL_COMPRESS = $GL_EXT{GL_ARB_texture_compression}      || $GL_VERSION >= 1.3;
   $GL_MULTITEX = $GL_EXT{GL_ARB_multitexture}             || $GL_VERSION >= 1.3;
   $GL_MULTITEX &&= 2 <= glGetInteger GL_MAX_TEXTURE_UNITS;

   $GL_COMPRESS = 0 if DC::OpenGL::gl_vendor eq "Apple Computer, Inc."; # there is no end to their suckage

   $APPLE_NVIDIA_BUG = DC::OpenGL::gl_vendor eq "NVIDIA Corporation" && $^O eq "darwin";
   apple_nvidia_bug $APPLE_NVIDIA_BUG;

   disable_GL_EXT_blend_func_separate
      unless $GL_BFSEP;

   glDisable GL_COLOR_MATERIAL;
   glShadeModel GL_FLAT;
   glDisable GL_DITHER;
   glDisable GL_DEPTH_TEST;
   glDepthMask 0;

   my $hint = $::FAST ? GL_FASTEST : GL_NICEST;
   glHint GL_PERSPECTIVE_CORRECTION_HINT, $hint;
   glHint GL_POINT_SMOOTH_HINT          , $hint;
   glHint GL_LINE_SMOOTH_HINT           , $hint;
   glHint GL_POLYGON_SMOOTH_HINT        , $hint;
   glHint GL_GENERATE_MIPMAP_HINT       , $hint;
   glHint GL_TEXTURE_COMPRESSION_HINT   , $hint;
   #glDrawBuffer GL_BACK;
   #glReadBuffer GL_BACK;

   c_init;
   $_->() for values %INIT_HOOK;
}

sub quit {
   undef $GL_VERSION;
   undef %GL_EXT;
}

sub shutdown {
   $_->() for values %SHUTDOWN_HOOK;

   quit;
}

sub gl_check {
   return unless $DEBUG;

   if (my $error = glGetError) {
      my ($format, @args) = @_;
      Carp::cluck sprintf "opengl error %x while $format", $error, @args;
   }
}

1;

