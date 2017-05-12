=head1 NAME

DC::Texture - tetxure class for Deliantra-Client

=head1 SYNOPSIS

 use DC::Texture;

=head1 DESCRIPTION

=over 4

=cut

package DC::Texture;

use common::sense;

use List::Util qw(max min);
use DC::OpenGL;

my %TEXTURES;
my ($MAX_W, $MAX_H) = (4096, 4096); # maximum texture size attempted by this module

sub new {
   my ($class, %data) = @_;

   my $self = bless {
      internalformat => GL_RGBA,
      format         => GL_RGBA,
      type           => GL_UNSIGNED_BYTE,
      %data,
   }, $class;

   DC::weaken ($TEXTURES{$self+0} = $self);

   $self->upload
      unless delete $self->{delay};

   $self
}

sub new_from_image {
   my ($class, $image, %arg) = @_;

   Carp::confess "tried to create texture from undefined image"
      unless defined $image;

   $class->new (image => $image, internalformat => undef, %arg)
}

sub new_from_resource {
   my ($class, $path, %arg) = @_;

   $class->new (resource_path => $path, internalformat => undef, %arg)
}

#sub new_from_surface {
#   my ($class, $surface) = @_;
#
#   $surface->rgba;
#
#   $class->new (
#      data   => $surface->pixels,
#      w      => $surface->width,
#      h      => $surface->height,
#   )
#}

#sub new_from_layout {
#   my ($class, $layout, %arg) = @_;
#
#   my ($w, $h, $data, $format, $internalformat) = $layout->render;
#
#   $class->new (
#      w              => $w,
#      h              => $h,
#      data           => $data,
#      format         => $format,
#      internalformat => $format,
#      type           => GL_UNSIGNED_BYTE,
#      %arg,
#   )
#}

sub new_from_opengl {
   my ($class, $w, $h, $cb) = @_;

   $class->new (w => $w || 1, h => $h || 1, render_cb => $cb, nearest => 1)
}

sub loading_done($$) {
   my ($self, $data) = @_;

   delete $self->{loading};
   ++$self->{delete_image};
   $self->{image} = $data;
   $self->upload;
}

sub upload {
   my ($self, $cb) = @_;

   push @{ $self->{upload_done} }, $cb
      if $cb;

   return if $self->{loading};

   unless ($GL_VERSION) {
      $self->{want_upload} = -1;
      return;
   }

   unless ($self->{name}) {
      # $tw,$th texture
      # $rw,$rh rendered/used size
      # $dw,$dh $data

      my ($data, $dw, $dh);

      if (exists $self->{resource_path}) {
         open my $fh, "<:raw", DC::find_rcfile $self->{resource_path};
         local $/;
         delete $self->{internalformat};
         $self->{image} = <$fh>;
         $self->{delete_image} = 1;
      }

      if (defined $self->{data}) {
         $data = $self->{data};
         ($dw, $dh) = @$self{qw(w h)};

      } elsif ($self->{render_cb}) {
         ($dw, $dh) = @$self{qw(w h)};

      } elsif (defined $self->{image}) {
         ($self->{w}, $self->{h}, $data, my $internalformat, $self->{format}, $self->{type})
            = DC::load_image_inline $self->{image};
        
         $self->{internalformat} ||= $internalformat;
         ($dw, $dh) = @$self{qw(w h)};
         
         delete $self->{image} if delete $self->{delete_image};

      } elsif (defined $self->{tile}) {
         ++$self->{loading};
         return DC::DB::get tilecache => $self->{tile}, sub {
            $self->loading_done ($_[0]);
         };

      } elsif (defined $self->{path}) {
         ++$self->{loading};
         return DC::DB::read_file $self->{path}, sub {
            $self->loading_done ($_[0]);
         };

      } else {
         Carp::confess "tried to create texture that is not data, render or image";
      }

      my ($tw, $th) = ($dw, $dh);

      defined $data or $self->{render_cb} or die; # some sanity check

      $self->{minified} ||= [DC::average $dw, $dh, $data]
         if $self->{minify};

      # against rather broken cards we enforce a maximum texture size
      $tw = min $MAX_W, $tw;
      $th = min $MAX_H, $th;

      # if only pot-textures are allowed, pot'ify tw/th
      unless ($GL_NPOT) {
         $tw = DC::minpot $tw;
         $th = DC::minpot $th;
      }

      # now further decrease texture size until the
      # card does accept it
      while (!texture_valid_2d $self->{internalformat}, $tw, $th, $self->{format}, $self->{type}) {
         # quarter the texture size
         $tw >>= 1;
         $th >>= 1;
      }

      # decide the amount of space used in the texture
      my ($rw, $rh);
      my ($ox, $oy); # area shift to lessen effect of buggy opengl implementations (nvida, ati)
      my $render;

      if ($self->{render_cb}) {
         # use only part of the texture
         #$rw >>= 1 while $rw > $tw;
         #$rh >>= 1 while $rh > $th;
         $rw = min $dw, $tw;
         $rh = min $dh, $th;
         ++$render;
      } else {
         if ($self->{wrap} || $tw < $dw || $th < $dh) {
            # scale to the full texture size
            ($rw, $rh) = ($tw, $th);
            ++$render;
         } else {
            # pad
            pad $data, $dw, $dh, $tw, $th;
            ($rw, $rh) = ($dw, $dh);
            ($dw, $dh) = ($tw, $th);
         }
      }

      if ($render) {
         $ox = int .5 * ($::WIDTH  - $rw);
         $oy = int .5 * ($::HEIGHT - $rh);

         glViewport $ox, $oy, $tw, $th;
         #glScissor 0, 0, $tw, $th;
         #glEnable GL_SCISSOR_TEST;
         glMatrixMode GL_PROJECTION;
         glLoadIdentity;
         glOrtho 0, $tw, 0, $th, -10000, 10000;
         glMatrixMode GL_MODELVIEW;
         glLoadIdentity;

         if ($self->{render_cb}) {
            glScale $rw / $dw, $rh / $dh;
            $self->{render_cb}->($self, $rw, $rh);
         } else {
            glClearColor 0, 0, 0, 0;
            glClear GL_COLOR_BUFFER_BIT;
            glPixelZoom $tw / $dw, $th / $dh;
            glRasterPos 0, 0;
            glDrawPixels $dw, $dh,
                         $self->{format},
                         $self->{type},
                         $data;
            glPixelZoom 1, 1;
         }
      }

      if ((my $name = delete $self->{want_upload}) > 0) {
         $self->{name} = $name;
      }

      glBindTexture GL_TEXTURE_2D, $self->{name} ||= glGenTexture;

      if ($self->{wrap}) {
         glTexParameter GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT;
         glTexParameter GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT;
      } else {
         glTexParameter GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, $GL_VERSION >= 1.2 ? GL_CLAMP_TO_EDGE : GL_CLAMP;
         glTexParameter GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, $GL_VERSION >= 1.2 ? GL_CLAMP_TO_EDGE : GL_CLAMP;
      }

      if ($::FAST || $self->{nearest}) {
         glTexParameter GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST;
         glTexParameter GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST;
      } elsif ($self->{mipmap} && $GL_VERSION >= 1.4) {
         glTexParameter GL_TEXTURE_2D, GL_GENERATE_MIPMAP, 1;
         glTexParameter GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR;
         glTexParameter GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR;
      } else {
         glTexParameter GL_TEXTURE_2D, GL_GENERATE_MIPMAP, $self->{mipmap};
         glTexParameter GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR;
         glTexParameter GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR;
      }
      
      glGetError;

      if ($render) {
         glCopyTexImage2D GL_TEXTURE_2D, 0,
                      $self->{internalformat},
                      $ox, $oy,
                      $tw, $th,
                      0;
         gl_check "copying to texture %dx%d if=%x",
                  $tw, $th, $self->{internalformat};

         #glDisable GL_SCISSOR_TEST;
      } else {
         my $if = $self->{internalformat};

         if ($GL_COMPRESS && $::CFG->{texture_compression}) {
            if ($if == GL_RGB) {
               $if = GL_COMPRESSED_RGB_ARB;
            } elsif ($if == GL_RGBA) {
               $if = GL_COMPRESSED_RGBA_ARB;
            }
         }

         glTexImage2D GL_TEXTURE_2D, 0,
                      $if,
                      $dw, $dh,
                      0,
                      $self->{format},
                      $self->{type},
                      $data;
         gl_check "uploading texture %dx%d if=%x f=%x t=%x",
                  $tw, $th, $self->{internalformat},  $self->{format}, $self->{type};
      }

      $self->{s} = $rw / $tw;
      $self->{t} = $rh / $th;

      if ($self->{tile}) {
         $::MAP->set_texture ($self->{tile}, @$self{qw(name w h s t)}, @{$self->{minified}})
            if $::MAP;
         $::MAPWIDGET->update
            if $::MAPWIDGET;
      }
   }

   $_->($self)
      for @{ (delete $self->{upload_done}) || [] };
}

sub unload {
   my ($self) = @_;

   glDeleteTexture delete $self->{name}
      if $self->{name};
} 

sub DESTROY {
   my ($self) = @_;

   delete $TEXTURES{$self+0};

   $self->unload;
}

$DC::OpenGL::INIT_HOOK{"DC::Texture"} = sub {
   for my $tex (values %TEXTURES) {
      if (my $name = $tex->{want_upload}) {
         $tex->upload;

         if ($tex->{loading} && $name > 0) {
            # if loading is delayed we still have to allocate the texture name
            glBindTexture GL_TEXTURE_2D, $name;
            glTexImage2D GL_TEXTURE_2D, 0, GL_ALPHA, 0, 0, 0, GL_ALPHA, GL_UNSIGNED_BYTE;
         }
      }
   }
};

$DC::OpenGL::SHUTDOWN_HOOK{"DC::Texture"} = sub {
   for (values %TEXTURES) {
      next unless $_->{name};
      $_->{want_upload} = $_->{name};
      $_->unload;
   }
};

1;

=back

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

