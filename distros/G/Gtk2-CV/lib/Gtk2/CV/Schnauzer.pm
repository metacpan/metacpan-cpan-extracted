=head1 NAME

Gtk2::CV::Schnauzer - a widget for displaying image collections

=head1 SYNOPSIS

  use Gtk2::CV::Schnauzer;

=head1 DESCRIPTION

=head2 METHODS

=over 4

=cut

package Gtk2::CV::Schnauzer::DrawingArea;

use Glib::Object::Subclass Gtk2::DrawingArea,
   signals => { size_allocate => \&Gtk2::CV::Schnauzer::do_size_allocate_rounded };

package Gtk2::CV::Schnauzer;

use common::sense;
use integer;

our %EXCLUDE; # to be set from your .cvrc to exclude additional files
our $ICONSCALE; # to be set from your .cvrc to set icon scale
our $FONTSCALE; # to be set from your .cvrc to set icon font scale
our $DISPLAYSCALE; # to be set from your .cvrc to set display scale (for hidpi displays)

use Gtk2;
use Gtk2::Pango;
use Gtk2::Gdk::Keysyms;

use Gtk2::CV;

use Glib::Object::Subclass
   Gtk2::VBox::,
   signals => {
      activate          => { flags => [qw/run-first/], return_type => undef, param_types => [Glib::Scalar::] },
      popup             => { flags => [qw/run-first/], return_type => undef, param_types => [Gtk2::Menu::, Glib::Scalar::, Gtk2::Gdk::Event::] },
      popup_selected    => { flags => [qw/run-first/], return_type => undef, param_types => [Gtk2::Menu::, Glib::Scalar::] },
      selection_changed => { flags => [qw/run-first/], return_type => undef, param_types => [Glib::Scalar::] },
      chpaths           => { flags => [qw/run-first/], return_type => undef, param_types => [] },
      chdir             => { flags => [qw/run-first/], return_type => undef, param_types => [Glib::Scalar::] },
   };

use List::Util qw(min max);

use File::Spec;
use File::Copy;
use File::Temp ();
use Cwd ();

use POSIX qw(ceil ENOTDIR _exit strftime);

use Encode ();
use Errno ();
use Fcntl;
use IO::AIO;

use Gtk2::CV::Jobber;
use Gtk2::CV::ImageWindow (); # dir_is_movie

use base Gtk2::CV::Jobber::Client::;

my %dir;
my $dirid;
my %directory_visited;

our $UTF8_RE = qr{^
 ( ([\x00-\x7f])              # 1-byte pattern
 | ([\xc2-\xdf][\x80-\xbf])   # 2-byte pattern
 | ((([\xe0][\xa0-\xbf])|([\xed][\x80-\x9f])|([\xe1-\xec\xee-\xef][\x80-\xbf]))([\x80-\xbf])) # 3-byte pattern
 | ((([\xf0][\x90-\xbf])|([\xf1-\xf3][\x80-\xbf])|([\xf4][\x80-\x8f]))([\x80-\xbf]{2}))       # 4-byte pattern
 )*
$}x;

# this basiclaly provides an overridable hook for your .cvrc
sub filename_display_name;
*filename_display_name = \&Glib::filename_display_name;

# quote for shell, but assume it is being interactively pasted
# input is octet string, output is unicode string
sub shellquote_selection($) {
   local $_ = $_[0];

   if ($_ =~ $UTF8_RE) {
      utf8::decode $_;

      # it really is that complicated
      s/([\$`\\"])/\\$1/g;
      s/!/"\\!"/g;
      s/'/"\\'"/g;
      "\"$_\""

   } else {
      # we use bash's syntax
      s/([^\x20-\x26\x28-\x7e])/sprintf "\\x%02x", ord $1/ge;
      "\$\'$_\'"
   }
}

sub format_size($) {
   # perl doesn't support %'d
   scalar reverse join ",", unpack "(a3)*", scalar reverse "$_[0]"
}

sub regdir($) {
   $dir{$_[0]} ||= ++$dirid;
}

my $curdir = File::Spec->curdir;
my $updir  = File::Spec->updir;

sub parent_dir($) {
   my ($volume, $dirs, $file) = File::Spec->splitpath ($_[0], 1);
   my @dirs = File::Spec->splitdir ($dirs);
   pop @dirs; # oh my god
   $dirs = File::Spec->catdir (@dirs);
   File::Spec->catpath ($volume, $dirs, $file)
}

sub IW() { 80 } # must be the same as in CV.xs(!)
sub IH() { 60 } # must be the same as in CV.xs(!)

sub default_display_scale {
   init Gtk2::Gdk;

   my $screen = Gtk2::Gdk::Screen->get_default
      or return 1;

   my $rect = $screen->get_monitor_geometry (0)
      or return 1;

   no integer;

   my $dpi = $rect->width * 2.54 * 10 / $screen->get_monitor_width_mm (0);

   $dpi < 110 ? 1 : $dpi / 96
}

BEGIN {
   no integer;
   $ICONSCALE = $ENV{CV_THUMBNAIL_SCALE} || $ICONSCALE || 1;
   eval "sub IWG()    { " . (int IW * $ICONSCALE   ) . " }"; # "G"eneration
   eval "sub IHG()    { " . (int IH * $ICONSCALE   ) . " }"; # "G"eneration

   $DISPLAYSCALE = $ENV{CV_DISPLAY_SCALE} || $DISPLAYSCALE || default_display_scale;
   eval "sub IWD()    { " . (int IW * $DISPLAYSCALE) . " }"; # "D"isplay
   eval "sub IHD()    { " . (int IH * $DISPLAYSCALE) . " }"; # "D"isplay
   eval "sub IX()     { " . (int 20 * $DISPLAYSCALE) . " }"; # extra horizontal space

   my $fsize = int 12 * ($ENV{CV_SCHNAUZER_FONTSCALE} || $FONTSCALE || $ICONSCALE) * $DISPLAYSCALE;
   eval "sub FY()     { $fsize }";
   eval "sub IY()     { " . (ceil 1.25 * $fsize) . " }";
}

sub SCROLL_Y()    {  1 }
sub SCROLL_X()    { 10 }
sub SCROLL_TIME() { 500 }

sub FAST_RANGE()  { 10000 } # searching for this many entries * 2 is fast
sub SLOW_RANGE()  {    10 } # doing this many slow ops per idle callback is ok

sub F_CHECKED()  { 1 } # entry has been investigated
sub F_ISDIR()    { 2 } # entry is certainly a directory
sub F_HASXVPIC() { 4 } # entry (likely) has a thumbnail file
sub F_HASPM()    { 8 } # entry has a pixmap

# entries are arrays with these indices. the order
# is hardcoded in several places, such as chpaths.
sub E_DIR   () { 0 }
sub E_FILE  () { 1 }
sub E_FLAGS () { 2 }
sub E_PIXMAP() { 3 }

sub load_icon {
   my $pb = Gtk2::CV::require_image $_[0];

   $pb->scale_simple (IWD, IHD, "bilinear")
}

sub load_icon_pm {
   scalar +(load_icon $_[0])->render_pixmap_and_mask (0.5)
}

my %combine;

sub img_combine {
   my ($self, $base, $add) = @_;
   $combine{"$base,$add"} ||= do {
      my ($w, $h) = $base->get_size;
      my $pm = new Gtk2::Gdk::Pixmap $base, $w, $h, -1;
      $pm->draw_drawable ($self->style->white_gc, $base, 0, 0, 0, 0, $w, $h);
      $pm->draw_pixbuf   ($self->style->white_gc, $add , 0, 0, 0, 0, $w, $h, "max",  0, 0);

      $pm
   }
}

my %ext_logo = (
   jpeg => "jpeg",
   jfif => "jpeg",
   jp2  => "jpeg",
   jpc  => "jpeg",
   jpg  => "jpeg",
   jpe  => "jpeg",
   png  => "png",
   gif  => "gif",
   tif  => "tif",
   tiff => "tif",

   webp => "png",
   wep  => "png",
   wej  => "jpeg",

   mp2  => "mp2",
   mp3  => "mp3",
   m4a  => "audio",
   pcm  => "audio", # rare
   sun  => "audio", # rare
   au   => "audio",
   iff  => "audio", # rare
   aif  => "audio",
   aiff => "audio",
   wav  => "audio",

   mpeg => "mpeg",
   mpg  => "mpeg",
   mpv  => "mpeg",
   mpa  => "mpeg",
   mpe  => "mpeg",
   mp4  => "mpeg",
   m1v  => "mpeg",
   m2v  => "mpeg",
   m4v  => "mpeg",
   ts   => "mpeg",
   
   ogm  => "ogm",
   mkv  => "ogm", # sigh

   mov  => "mov",
   qt   => "mov",
   flv  => "mov", # todo

   divx => "avi",
   avi  => "avi",
   wmv  => "wmv",
   asf  => "asf",

   rm   => "rm",
   ram  => "rm",
   rmvb => "rm",

   txt  => "txt",
   csv  => "txt",
   crc  => "txt",

   mid  => "midi",
   midi => "midi",

   rar  => "rar",
   zip  => "zip",
   ace  => "ace",

   par  => "par",
   par2 => "par",
);

my $file_img;
my $diru_img;
my $dirv_img;

my $dirx_layer;
my $dire_layer;
my $dirs_layer;

my %file_img;

sub init {
   $file_img = load_icon_pm "file.png";
   $diru_img = load_icon_pm "dir-unvisited.png";
   $dirv_img = load_icon_pm "dir-visited.png";
  
   $dirx_layer = load_icon "dir-xvpics.png";
   $dire_layer = load_icon "dir-empty.png";
   $dirs_layer = load_icon "dir-symlink.png";
  
   %file_img = do {
      my %logo = reverse %ext_logo;

      map +($_ => load_icon_pm "file-$_.png"), keys %logo
   };
}

# get pathname of corresponding xvpics-dir
sub xvdir($) {
   $_[0] =~ m%^(.*/)?([^/]+)$%sm
      or Carp::croak "FATAL: unable to split <$_[0]> into dirname/basename";
   "$1.xvpics"
}

# get filename of corresponding xvpic-file
sub xvpic($) {
   $_[0] =~ m%^(.*/)?([^/]+)$%sm
      or Carp::croak "FATAL: unable to split <$_[0]> into dirname/basename";
   "$1.xvpics/$2"
}

sub dirname($) {
   $_[0] =~ m%^(.*)/([^/]+)%sm
      ? wantarray ? ($1     , $2   ) : $1
      : wantarray ? ($curdir, $_[0]) : $curdir
}

# filename => extension
sub extension {
   $_[0] =~ /\.([a-z0-9]{2,4})[\.\-_0-9~]*$/i
      ? lc $1 : ();
}

sub read_thumb($) {
   if (my $pb = eval { Gtk2::CV::load_jpeg $_[0] }) {
      return Gtk2::CV::dealpha $pb;
   } elsif (open my $p7, "<:raw", $_[0]) {
      if (<$p7> =~ /^P7 332/) {
         local $_;
         1 while ($_ = <$p7>) =~ /^#/;
         if (/^(\d+)\s+(\d+)\s+255/) {
            local $/;
            return p7_to_pb $1, $2, <$p7>;
         }
      }
   }

   ();
}

# rotate a file
Gtk2::CV::Jobber::define rotate =>
   pri   => -1000,
   read  => 1,
   fork  => 1,
sub {
   my ($job) = @_;
   my $path = $job->{path};
   my $rot = $job->{data};

   delete $job->{data};

   eval {
      die "can only rotate regular files"
         unless Fcntl::S_ISREG ($job->{stat}[2]);

      $rot = $rot eq "auto" ? "-a"
           : $rot ==   0    ? undef
           : $rot ==  90    ? -9
           : $rot == 180    ? -1
           : $rot == 270    ? -2
           : die "can only rotate by 0, 90, 180 and 270 degrees";

      if ($rot) {
         system "exiftran", "-ip", $rot, $path
            and die "exiftran failed: $?";
      }
   };

   $job->finish;
};

sub video_thumbnail_at {
   my ($path, $time, $w) = @_;

   utf8::downgrade $path; # work around bugs in Gtk2
   
   if (0) {
      # fucking ffmpeg can't be told to be quiet except on errors
      open my $fh, "exec ffmpeg -ss $time -i \Q$path\E -vframes 1 -an -f rawvideo -vcodec ppm -y /dev/fd/3 3>&1 1>&2 2>/dev/null |"
#   open my $fh, "exec totem-gstreamer-video-thumbnailer -t $time -s $w \Q$path\E /dev/fd/3 3>&1 1>&2 |"
         or die "ffmpeg: $!";

      my $pb = new_with_type Gtk2::Gdk::PixbufLoader "pnm";
      local $/; $pb->write ("" . scalar <$fh>);
      $pb->close;
      return $pb->get_pixbuf;
   } else {
      my $dir = File::Temp::tempdir DIR => $Gtk2::CV::FAST_TMP
         or return;

      #system "exec mpv -really-quiet -noautosub -nosound -input nodefault-bindings -noconfig all -ss $time -frames 2 -vf scale=" . IWG . ":-2::::::1 -vo pnm:outdir=\Q$dir\E \Q$path\E >/dev/null 2>&1 </dev/null";
      system "exec mpv"
           . " --really-quiet"
           . " --no-terminal --sid=no --ao=null --no-config"
           . " --access-references=no --autoload-files=no"
           . " --start=$time --frames=2 --vf=scale=" . IWG . ":-2::::::1"
           . " --vo=image -vo-image-format=png --vo-image-png-compression=0 -vo-image-outdir=\Q$dir\E \Q$path\E"
           . " >/dev/null 2>&1 </dev/null";

      my $pb = eval { new_from_file Gtk2::Gdk::Pixbuf "$dir/00000002.png" };

      # mplayer can write a large number of files when a single one is requested...
      if (opendir my $fh, $dir) {
         unlink map "$dir/$_", readdir $fh;
      }

      rmdir $dir;

      return $pb;
   }
}

sub video_thumbnail {
   my ($path) = @_;

   # do primitive filetype detection - gstreamer hates us otherwise
#   return unless $path =~ /\.(?: asf | wmv | avi | mpg | mpeg )$/xi;

   my $t1 =        video_thumbnail_at $path,   0, 512 or return;
   my $t2 = $t1 && video_thumbnail_at $path,   5, 512;
   my $t3 = $t2 && video_thumbnail_at $path,  30, 512;
   my $t4 = $t3 && video_thumbnail_at $path, 180, 512;

   # assume all four images to have the same size
   my $tw = $t1->get_width;
   my $th = $t1->get_height;

   my $pb = new Gtk2::Gdk::Pixbuf "rgb", 0, 8, $tw * 2, $th * 2;
   $pb->fill (0xff69b400); # pinku eiga *g*

   # make sure all frames have the right size
   $t2 = $t2->scale_simple ($tw, $th, "bilinear") if $t2;
   $t3 = $t3->scale_simple ($tw, $th, "bilinear") if $t3;
   $t4 = $t4->scale_simple ($tw, $th, "bilinear") if $t4;

   $t1->copy_area (0, 0, $tw, $th, $pb,   0,   0);
   $t2->copy_area (0, 0, $tw, $th, $pb, $tw,   0) if $t2;
   $t3->copy_area (0, 0, $tw, $th, $pb,   0, $th) if $t3;
   $t4->copy_area (0, 0, $tw, $th, $pb, $tw, $th) if $t4;

   $pb
}

# generate a thumbnail for a file
Gtk2::CV::Jobber::define gen_thumb =>
   pri   => -1000,
   read  => 1,
   fork  => 1,
sub {
   my ($job) = @_;
   my $path = $job->{path};

   delete $job->{data};

   eval {
      die "can only generate thumbnail for regular files"
         unless Fcntl::S_ISREG ($job->{stat}[2]);

      mkdir +(dirname $path) . "/.xvpics", 0777;

      my $pb;

      if (sysopen my $fh, $path, IO::AIO::O_RDONLY) {
         if (IO::AIO::mmap my $data, -s $fh, IO::AIO::PROT_READ, IO::AIO::MAP_SHARED, $fh) {
            my $type = Gtk2::CV::filetype $data;

            $pb = eval { $type eq "image/jpeg" && Gtk2::CV::decode_jpeg $data, 1, IWG, IHG }
                  || eval { $type eq "image/jxl" && Gtk2::CV::decode_jxl $data, 1, IWG, IHG }
                  || eval { $type eq "image/webp" && Gtk2::CV::decode_webp $data, 1, IWG, IHG }
                  || eval {
                        my $loader = new Gtk2::Gdk::PixbufLoader;

                        # should set size-prepared callback to scale down, but
                        # we only really care about this for jpeg files, which are handled above.
                        #$loader->set_size (IW, IH);

                        $loader->write ($data);

                        $loader->close;
                        $loader->get_pixbuf
                     }
                  || eval { video_thumbnail $path }
             ;
         }
      }

      $pb ||= Gtk2::CV::require_image "error.png";

      utf8::downgrade $path; # Gtk2::Gdk::Pixbuf upgrades :/

      my ($w, $h) = ($pb->get_width, $pb->get_height);

      if ($w * IHG > $h * IWG) {
         $h = (int $h * IWG / $w + 0.5) || 1;
         $w = IWG;
      } else {
         $w = (int $w * IHG / $h + 0.5) || 1;
         $h = IHG;
      }

      $pb = Gtk2::CV::dealpha $pb->scale_simple ($w, $h, 'tiles');

#      sysopen my $fh, xvpic $path, IO::AIO::O_CREAT | IO::AIO::O_TRUNC | IO::AIO::O_WRONLY, 0666
      open my $fh, ">:raw", xvpic $path
         or die "xvpic($path): $!";
      syswrite $fh, $pb->save_to_buffer ("jpeg", quality => 95);;
      close $fh;

      $job->{data} = $pb->get_pixels . pack "SSS", $w, $h, $pb->get_rowstride;

      utime $job->{stat}[9], $job->{stat}[9], xvpic $path;
   };

   warn "$@" if $@;#d#

   $job->finish;
};

Gtk2::CV::Jobber::define upd_thumb =>
   pri   => -2000,
   stat  => 1,
sub {
   my ($job) = @_;
   my $path = $job->{path};

   aioreq_pri -2;
   aio_stat xvpic $path, sub {
      Gtk2::CV::Jobber::submit gen_thumb => $path
         unless $job->{stat}[9] == (stat _)[9];

      $job->finish;
   };
};

# recursively delete a directory
Gtk2::CV::Jobber::define rm_rf =>
   pri   => 1000,
   fork  => 1,
   hide  => 1,
sub {
   my ($job) = @_;

   #$Gtk2::CV::Jobber::jobs{$job->{path}} = { }; # no further jobs make sense
   system "rm", "-rf", $job->{path};
   $job->finish;
};

# remove a file, or move it to the unlink directory
Gtk2::CV::Jobber::define unlink =>
   pri   => 1000,
   class => "stat",
   hide  => 1,
sub {
   my ($job) = @_;

   $Gtk2::CV::Jobber::jobs{$job->{path}} = { }; # no further jobs make sense

   aioreq_pri -2;
   aio_unlink $job->{path}, sub {
      my $status = shift;

      aio_unlink xvpic $job->{path}, sub {
         aioreq_pri -4;
         aio_rmdir xvdir $job->{path}, sub {
            $job->{data} = $status;
            $job->finish;
         };
      };
   };
};

Gtk2::CV::Jobber::define unlink_thumb =>
   pri   => 0,
   class => "stat",
sub {
   my ($job) = @_;

   aioreq_pri -2;
   aio_unlink xvpic $job->{path}, sub {
      aioreq_pri -4;
      aio_rmdir xvdir $job->{path}, sub {
         $job->finish;
      };
   };
};

sub do_cpmv {
   my ($move, $job) = @_;
   my $src = $job->{path};
   my $dst = $job->{data};
   
   #TODO: move directories, too

   aioreq_pri -4;
   aio_stat $dst, sub {
      $dst .= "/" . (dirname $src)[1] if -d _;

      my $basedst = $dst;
      my $idx = 0;

      1 while $basedst =~ s/-\d\d\d$//;

      my $try_open; $try_open = sub {
         aioreq_pri -2;
         aio_stat "$dst/.", sub {
            if ($_[0] >= 0 || $! != Errno::ENOENT) {
               $dst = sprintf "%s-%03d", $basedst, $idx++;
               return $try_open->();
            }

            aioreq_pri -2;
            aio_open $dst, O_WRONLY | O_CREAT | O_EXCL, 0200, sub {
               if (my $fh = $_[0]) {
                  close $_[0];

                  my $cpmv = $move ? \&aio_move : \&aio_copy;

                  undef $try_open;
                  aioreq_pri -2;
                  $cpmv->($src, $dst, sub {
                     if ($_[0]) {
                        print "$src => $dst [ERROR $!]\n";
                        aio_unlink $dst, sub {
                           $job->finish;
                        };
                     } else {
                        $job->event (unlink => $src) if $move;
                        $job->event (create => $dst);

                        aioreq_pri 1;
                        $cpmv->(xvpic $src, xvpic $dst, sub {
                           # we do not care about the xvpic being copied correctly
                           printf "%s %s to %s\n", $src, $move ? "moved " : "copied", $dst;
                           $job->finish;
                        });
                     }
                  });
               } elsif ($! == Errno::EEXIST) {
                  $dst = sprintf "%s-%03d", $basedst, $idx++;
                  $try_open->();
               } else {
                  undef $try_open;
                  print "$src => $dst [ERROR $!]\n";
                  $job->finish;
               }
            };
         };
      };

      $try_open->();
   };

#   # TODO: don't use /bin/mv and generate create events.
#   system "/bin/mv", "-v", "-b", $path, "$dest/.";
#   system "/bin/mv",       "-b", xvpic $path, "$dest/.xvpics/."
#      if -e xvpic $path;
#   $job->event (unlink => $src);
#   $job->event (create => $dest);
};

Gtk2::CV::Jobber::define cp =>
   pri   => -2500,
   class => "read",
sub {
   do_cpmv 0, @_;
};

Gtk2::CV::Jobber::define mv =>
   pri   => -3000,
   class => "read",
   hide  => 1,
sub {
   do_cpmv 1, @_;
};

sub jobber_update {
   my ($self, $job) = @_;

   # update path => index map for faster access
   unless (exists $self->{map}) {
      my %map;

      @map{ map "$_->[E_DIR]/$_->[E_FILE]", @{$self->{entry}} }
         = (0 .. $#{$self->{entry}});

      $self->{map} = \%map;
   }

   exists $self->{map}{$job->{path}}
      or return; # not for us

   my $idx = $self->{map}{$job->{path}};

   if ($job->{type} eq "unlink") {
      return if $job->{status};

      --$self->{cursor} if $self->{cursor} > $_;

      delete $self->{sel}{$idx};
      splice @{$self->{entry}}, $idx, 1;
      $self->entry_changed;
      $self->invalidate_all;

   } else {
      if ($job->{type} eq "gen_thumb" && exists $job->{data}) {
         my $data = Encode::encode "iso-8859-1", $job->{data};
         my ($w, $h, $rs) = unpack "SSS", substr $data, -6;

         for ($self->{entry}[$idx]) {
            $_->[E_FLAGS] &= ~F_HASPM;
            $_->[E_FLAGS] |= F_HASXVPIC;
            $_->[E_PIXMAP] = new_from_data Gtk2::Gdk::Pixbuf $data, 'rgb', 0, 8, $w, $h, $rs;
         }
      } elsif ($job->{type} eq "unlink_thumb") {
         for ($self->{entry}[$idx]) {
            $_->[E_FLAGS] &= ~(F_HASPM | F_HASXVPIC);
            $_->[E_PIXMAP] = undef;
         }
      } elsif ( $job->{type} eq "rotate" ) {
        Gtk2::CV::Jobber::submit gen_thumb => "$job->{path}"
           if $self->{entry}[$idx][E_FLAGS] & F_HASXVPIC;
      }

      $self->draw_entry ($idx);
   }
}

sub force_pixmap($$) {
   my ($self, $entry) = @_;

   return if $entry->[E_FLAGS] & F_HASPM;

   if ($entry->[E_PIXMAP]) {
      my $pb = ARRAY:: eq ref $entry->[E_PIXMAP]
               ? p7_to_pb @{$entry->[E_PIXMAP]}
               : $entry->[E_PIXMAP];

      my ($w, $h) = ($pb->get_width, $pb->get_height);

      if (($w != IWD and $h != IHD) or $w > IWD or $h > IHD) {
         ($w, $h) = ($w * IHD / $h, IHD);
         ($w, $h) = (IWD, $h * IWD / $w) if $w > IWD;

         $pb = $pb->scale_simple ($w, $h, "bilinear");
      }

      $entry->[E_PIXMAP] = new Gtk2::Gdk::Pixmap $self->{window}, $w, $h, -1;
      $entry->[E_PIXMAP]->draw_pixbuf ($self->style->white_gc, $pb, 0, 0, 0, 0, $w, $h, "max",  0, 0);
   } else {
      $entry->[E_PIXMAP] = $file_img{ $ext_logo{ extension $entry->[E_FILE] } } || $file_img;
   }

   $entry->[E_FLAGS] |= F_HASPM;
}

# prefetch a file after a timeout
sub prefetch {
   my ($self, $inc) = @_;

   return unless $self->cursor_valid;

   my $prefetch = $self->{cursor} + $inc;
   return if $prefetch < 0 || $prefetch > $#{$self->{entry}};

   my $e = $self->{entry}[$prefetch];
   $self->{prefetch} = "$e->[0]/$e->[1]";

   remove Glib::Source delete $self->{prefetch_source}
      if $self->{prefetch_source};

   $self->{prefetch_source} = add Glib::Timeout 100, sub {
      my $id = ++$self->{prefetch_aio};
      aioreq_pri -1;
      aio_open $self->{prefetch}, O_RDONLY, 0, sub {
         my $fh = $_[0]
            or return;

         my $ofs = 0;

         $self->{aio_reader} = sub {
            return unless $id == $self->{prefetch_aio};

            aioreq_pri -1;
            aio_read $fh, $ofs, 4096, my $buffer, 0, sub {
               return unless $id == $self->{prefetch_aio};
               return unless $self->{aio_reader};
               return delete $self->{aio_reader}
                  if $_[0] <= 0 || $ofs > 1024*1024;

               $ofs += 4096;
               $self->{aio_reader}->();
            };
         };

         $self->{aio_reader}->();
      };

      delete $self->{prefetch_source};
      0
   };
}

sub prefetch_cancel {
   my ($self) = @_;

   delete $self->{prefetch};
   delete $self->{prefetch_aio};
}

sub coord {
   my ($self, $event) = @_;

   my $x = $event->x / (IWD + IX);
   my $y = $event->y / (IHD + IY);

   (
      (max 0, min $self->{cols} - 1, $x),
      (max 0, min $self->{page} - 1, $y) + $self->{row},
   );
}

# newer gtk2 versions (maybe caused by xft bugs?) change the label width
# rather erratically even with the same font, which, when size hints are
# used, will resize the window when the label text changes. this tries to
# work around this, by allocating more vertical pixels for rounding
# issues and never reducing the height, ever.
sub fix_label_jumping {
   my ($label) = @_;

   my $max;

   $label->signal_connect_after (size_request => sub {
      my $h = $_[1]->height;
      $max = $h + 2 if $max < $h;
      $_[1]->height ($max);
   });
}

sub INIT_INSTANCE {
   my ($self) = @_;

   init unless %file_img;

   $self->{cols}  = 1; # just pretend, simplifies code a lot
   $self->{page}  = 1;
   $self->{offs}  = 0;
   $self->{entry} = [];

   $self->push_composite_child;

   $self->pack_start (my $hbox = new Gtk2::HBox, 1, 1, 0);
   $self->pack_start (new Gtk2::HSeparator, 0, 0, 0);
   $self->pack_end   (my $labelwindow = new Gtk2::EventBox, 0, 1, 0);
   $labelwindow->add ($self->{info} = new Gtk2::Label);
   fix_label_jumping $self->{info};
   # make sure the text clips to the window *sigh*
   $labelwindow->signal_connect_after (size_request => sub { $_[1]->width (0) });
   $self->{info}->set (selectable => 1, xalign => 0, justify => "left");

   $self->signal_connect (destroy => sub { %{$_[0]} = () });

   $hbox->pack_start ($self->{draw}   = new Gtk2::CV::Schnauzer::DrawingArea, 1, 1, 0);
   $hbox->pack_end   ($self->{scroll} = new Gtk2::VScrollbar , 0, 0, 0);

   $self->{adj} = $self->{scroll}->get ("adjustment");

   $self->{adj}->signal_connect (value_changed => sub {
      my $row = $_[0]->value;

      if (my $diff = $self->{row} - $row) {
         $self->{row}  = $row;
         $self->{offs} = $row * $self->{cols};

         if ($self->{window}) {
            if ($self->{page} > abs $diff) {
               if ($diff > 0) {
                  $self->{window}->scroll (0, $diff * (IHD + IY));
               } else {
                  $self->{window}->scroll (0, $diff * (IHD + IY));
               }
               $self->{window}->process_all_updates;
            } else {
               $self->invalidate_all;
            }
         }
      }

      0
   });

   #$self->{draw}->set_redraw_on_allocate (0); # nope
   $self->{draw}->double_buffered (1);

   $self->{draw}->signal_connect (size_request => sub {
      $_[1]->width  ((IWD + IX) * 4);
      $_[1]->height ((IHD + IY) * 3);

      1
   });

   $self->{draw}->signal_connect_after (realize => sub {
      $self->{window} = $_[0]->window;

      $self->setadj;
      $self->make_visible ($self->{cursor}) if $self->cursor_valid;

      0
   });

   $self->{draw}->signal_connect (configure_event => sub {
      $self->{width}  = $_[1]->width;
      $self->{height} = $_[1]->height;
      $self->{cols} = ($self->{width}  / (IWD + IX)) || 1;
      $self->{page} = ($self->{height} / (IHD + IY)) || 1;

      $self->{row} = ($self->{offs} + $self->{cols} / 2) / $self->{cols};
      $self->{offs} = $self->{row} * $self->{cols};

      $self->setadj;

      $self->{adj}->set_value ($self->{row});
      $self->invalidate_all;

      1
   });

   $self->{draw}->signal_connect (expose_event => sub {
      $self->expose ($_[1]);
   });

   $self->{draw}->signal_connect (scroll_event => sub {
      my $dir = $_[1]->direction;

      $self->prefetch_cancel;

      if ($dir eq "down") {
         my $value = $self->{adj}->value + $self->{page};
         $self->{adj}->set_value ($value <= $self->{maxrow} ? $value : $self->{maxrow});
         $self->clear_cursor;

      } elsif ($dir eq "up") {
         my $value = $self->{adj}->value;
         $self->{adj}->set_value ($value >= $self->{page} ? $value - $self->{page} : 0);
         $self->clear_cursor;
         
      } else {
         return 0;
      }

      return 1;
   });

   $self->{draw}->signal_connect (button_press_event => sub {
      my ($x, $y) = $self->coord ($_[1]);
      my $cursor = $x + $y * $self->{cols};

      $self->prefetch_cancel;

      if ($_[1]->type eq "button-press") {
         if ($_[1]->button == 1) {
            $_[0]->grab_focus;

            delete $self->{cursor};

            unless ($_[1]->state * "shift-mask") {
               $self->clear_selection;
               $self->invalidate_all;
               delete $self->{cursor_current};
               $self->{cursor} = $cursor if $cursor < @{$self->{entry}};
            }

            if ($cursor < @{$self->{entry}} && $self->{sel}{$cursor}) {
               delete $self->{sel}{$cursor};
               delete $self->{sel_x1};

               $self->emit_sel_changed ($_[1]->time);

               $self->invalidate (
                  (($cursor - $self->{offs}) % $self->{cols},
                   ($cursor - $self->{offs}) / $self->{cols}) x 2
               );
            } else {
               ($self->{sel_x1}, $self->{sel_y1}) =
               ($self->{sel_x2}, $self->{sel_y2}) = ($x, $y);
               $self->{oldsel} = $self->{sel};
               $self->selrect;
            }
         } elsif ($_[1]->button == 3) {
            $self->emit_popup ($_[1],
                               $cursor < @{$self->{entry}} ? $cursor : undef);
         }
      } elsif ($_[1]->type eq "2button-press") { 
         $self->emit_activate ($cursor) if $cursor < @{$self->{entry}};
      }

      1
   });

   my $scroll_diff; # for drag & scroll

   $self->{draw}->signal_connect (motion_notify_event => sub {
      return unless exists $self->{sel_x1};

      my ($x, $y) = $self->get_pointer;

      $self->{sel_mouse_scroll} ||= [$x, 0];
      my $dx = ($self->{sel_mouse_scroll}[0] - $x) / SCROLL_X;

      if ($y < - SCROLL_Y) {
         $self->sel_scroll ($self->{sel_mouse_scroll}[1] - $dx);
         $self->{sel_mouse_scroll}[1] = $dx;
         $scroll_diff = -1;
      } elsif ($y > $self->{page} * (IHD + IY) + SCROLL_Y) {
         $self->sel_scroll ($self->{sel_mouse_scroll}[1] - $dx);
         $self->{sel_mouse_scroll}[1] = $dx;
         $scroll_diff = +1;
      } else {
         $scroll_diff = 0;
         delete $self->{sel_mouse_scroll};
      }

      $self->{scroll_id} ||= add Glib::Timeout SCROLL_TIME, sub {
         $self->sel_scroll ($scroll_diff);

         1
      };

      my ($x, $y) = $self->coord ($_[1]);

      if ($x != $self->{sel_x2} || $y != $self->{sel_y2}) {
         ($self->{sel_x2}, $self->{sel_y2}) = ($x, $y);
         $self->selrect;
      }

      1;
   });

   $self->{draw}->signal_connect (button_release_event => sub {
      delete $self->{oldsel};
      
      remove Glib::Source delete $self->{scroll_id} if exists $self->{scroll_id};

      return unless exists $self->{sel_x1};

      # nop
      1
   });

   # selection

   $self->{sel_widget} = new Gtk2::Invisible;

   # we need to hardcode the internal target atom list, as there is no
   # other way to get at this info (for drag & drop, it's easy, so, again,
   # the normal selection comes as an afterthought at best).
   $self->{sel_widget}->selection_add_target (Gtk2::Gdk->SELECTION_PRIMARY, Gtk2::Gdk::Atom->new ($_), 1)
      for qw(STRING TEXT UTF8_STRING COMPOUND_TEXT text/plain text/plain;charset=utf-8);

   $self->{sel_widget}->signal_connect (selection_get => sub {
      my (undef, $data, $info, $time) = @_;

      $data->set_text (
         join " ",
            map shellquote_selection $_,
               sort
                  map "$_->[0]/$_->[1]",
                     values %{$self->{sel} || {}}
      );
   });

   # unnecessary redraws...
   $self->{draw}->signal_connect (focus_in_event  => sub { 1 });
   $self->{draw}->signal_connect (focus_out_event => sub { 1 });

   # gtk+ supports no motion compression, a major lacking feature. we have to pay for the
   # workaround with incorrect behaviour and extra server-turnarounds.
   $self->{draw}->add_events ([qw(button_press_mask button_release_mask button-motion-mask scroll_mask pointer-motion-hint-mask)]);
   $self->{draw}->can_focus (1);

   $self->signal_connect (key_press_event => sub { $self->handle_key ($_[1]->keyval, $_[1]->state) });
   $self->add_events ([qw(key_press_mask key_release_mask)]);

   $self->pop_composite_child;

   $self->jobber_register;
}

sub do_size_allocate_rounded {
   $_[1]->width  ($_[1]->width  / (IWD + IX) * (IWD + IX));
   $_[1]->height ($_[1]->height / (IHD + IY) * (IHD + IY));
   $_[0]->signal_chain_from_overridden ($_[1]);
}

sub set_geometry_hints {
   my ($self) = @_;

   my $window = $self->get_toplevel
      or return;

   my $hints = new Gtk2::Gdk::Geometry;
   $hints->base_width  (IWD + IX); $hints->base_height (IHD + IY);
   $hints->width_inc   (IWD + IX); $hints->height_inc  (IHD + IY);
   $window->set_geometry_hints ($self->{draw}, $hints, [qw(base-size resize-inc)]);
}

sub finish_info_update {
   my ($self) = @_;

   delete $self->{info_text};
   (delete $self->{info_updater_group})->cancel
      if exists $self->{info_updater_group};
   remove Glib::Source delete $self->{info_updater}
      if exists $self->{info_updater};
}

sub emit_sel_changed {
   my ($self, $time) = @_;

   $time ||= Gtk2->get_current_event_time;

   $self->finish_info_update;

   my $sel = $self->{sel};

   if (!$sel || !%$sel) {
      Gtk2::Selection->owner_set (undef, Gtk2::Gdk->SELECTION_PRIMARY, $time)
         if Gtk2::Gdk::Selection->owner_get (Gtk2::Gdk->SELECTION_PRIMARY) == $self->{sel_widget}->window;

      $self->{info}->set_text ("");
   } else {
      Gtk2::Selection->owner_set ($self->{sel_widget}, Gtk2::Gdk->SELECTION_PRIMARY, $time)
         if $time;

      if (1 < scalar keys %$sel) {
         $self->{info_text} = sprintf "%d entries selected", scalar keys %$sel;
         $self->{info}->set_text ("$self->{info_text} (...)");

         # start stat'ing all entries after a second
         $self->{info_updater} = add Glib::Timeout 300, sub {
            my $todo = [values %{ $self->{sel} }];
            $self->{info_size} = 0;
            $self->{info_disk} = 0;

            $self->{info_updater} = add Glib::Timeout 300, sub {
               no integer;
               $self->{info}->set_text (sprintf "%s (%.6g+%.3gMB, %d entries to stat)", $self->{info_text},
                                                $self->{info_size} / 1e6, $self->{info_disk} / 1e6, scalar @$todo);

               1
            };

            $self->{info_updater_group} = aio_group sub {
               no integer;
               $self->{info}->set_text (sprintf "%s (%.6g+%.3gMB)", $self->{info_text},
                                                $self->{info_size} / 1e6, $self->{info_disk} / 1e6);
               $self->finish_info_update;
            };
            $self->{info_updater_group}->feed (sub {
               my $entry = pop @$todo
                  or return;
               $_[0]->add (aio_stat "$entry->[E_DIR]/$entry->[E_FILE]", sub {
                  my ($size, $blocks) = (stat _)[7, 12];
                  $self->{info_size} += $size;
                  $self->{info_disk} += $blocks * 512 - $size;
               });
            });

            0
         };
      } else {
         my $entry = $self->{entry}[(keys %$sel)[0]];

         my $id = ++$self->{aio_sel_changed};

         aioreq_pri 3;
         aio_stat "$entry->[E_DIR]/$entry->[E_FILE]", sub {
            return unless $id == $self->{aio_sel_changed};
            $self->{info}->set_text (
               sprintf "%s: %s bytes, last modified %s (in %s)",
                       (filename_display_name $entry->[E_FILE]),
                       (format_size -s _),
                       (strftime "%Y-%m-%d %H:%M:%S", localtime +(stat _)[9]),
                       (filename_display_name $entry->[E_DIR]),
            );
         };
      }
   }

   $self->signal_emit (selection_changed => $self->{sel});
}

sub emit_popup {
   my ($self, $event, $cursor) = @_;

   my $idx   = $self->cursor_valid ? $self->{cursor} : $cursor;
   my $entry = $self->{entry}[$idx];

   my $menu = new Gtk2::Menu;

   if (exists $self->{dir}) {
      $menu->append (my $i_up = new Gtk2::MenuItem "Parent (^)");
      $i_up->signal_connect (activate => sub {
         $self->updir;
      });
   }

   my @sel = keys %{$self->{sel}};
   @sel = $cursor if !@sel && defined $cursor;

   if (@sel) {
      $menu->append (my $item = new Gtk2::MenuItem "Do");
      $item->set_submenu (my $sel = new Gtk2::Menu);

      $sel->append (my $item = new Gtk2::MenuItem @sel . " file(s)");
      $item->set_sensitive (0);

      $sel->append (my $item = new Gtk2::MenuItem "Generate Thumbnails (Ctrl-G)");
      $item->signal_connect (activate => sub { $self->generate_thumbnails (@sel) });

      $sel->append (my $item = new Gtk2::MenuItem "Update Thumbnails (Ctrl-U)");
      $item->signal_connect (activate => sub { $self->update_thumbnails (@sel) });

      $sel->append (my $item = new Gtk2::MenuItem "Remove Thumbnails");
      $item->signal_connect (activate => sub { $self->unlink_thumbnails (@sel) });

      $sel->append (my $item = new Gtk2::MenuItem "Delete");
      $item->set_submenu (my $del = new Gtk2::Menu);
      $del->append (my $item = new Gtk2::MenuItem "Physically (Ctrl-D)");
      $item->signal_connect (activate => sub { $self->unlink (0, @sel) });
      $del->append (my $item = new Gtk2::MenuItem "Physically & Recursive (Ctrl-Shift-D)");
      $item->signal_connect (activate => sub { $self->unlink (1, @sel) });

      $sel->append (my $item = new Gtk2::MenuItem "Rotate");
      $item->set_submenu (my $rotate = new Gtk2::Menu);
      $rotate->append (my $item = new Gtk2::MenuItem "90 clockwise");
      $item->signal_connect (activate => sub { $self->rotate (90, @sel) });
      $rotate->append (my $item = new Gtk2::MenuItem "90 counter-clockwise");
      $item->signal_connect (activate => sub { $self->rotate (270, @sel) });
      $rotate->append (my $item = new Gtk2::MenuItem "180");
      $item->signal_connect (activate => sub { $self->rotate (180, @sel) });
      $rotate->append (my $item = new Gtk2::MenuItem "automatic (exif orientation tag)");
      $item->signal_connect (activate => sub { $self->rotate ("auto", @sel) });
		
      $self->signal_emit (popup_selected => $menu, \@sel);
   }

   {
      $menu->append (my $item = new Gtk2::MenuItem "Select");
      $item->set_submenu (my $sel = new Gtk2::Menu);

      $sel->append (my $item = new Gtk2::MenuItem "By Adjacent Name");
      $item->set_submenu (my $by_pfx = new Gtk2::Menu);

      my $name = $entry->[E_FILE];
      my %cnt;

      $cnt{Gtk2::CV::common_prefix_length $name, $self->{entry}[$_][1]}++
         for (max 0, $idx - FAST_RANGE) .. min ($idx + FAST_RANGE, $#{$self->{entry}});

      my $sum = 0;
      for my $len (reverse 1 .. -2 + length $entry->[E_FILE]) {
         my $cnt = $cnt{$len}
            or next;
         $sum += $cnt;
         my $pfx = substr $entry->[E_FILE], 0, $len;
         my $label = "$pfx*\t($sum)";
         $label =~ s/_/__/g;
         $by_pfx->append (my $item = new Gtk2::MenuItem $label);
         $item->signal_connect (activate => sub {
            delete $self->{sel};

            for ((max 0, $idx - FAST_RANGE) .. min ($idx + FAST_RANGE, $#{$self->{entry}})) {
               next unless $len <= Gtk2::CV::common_prefix_length $name, $self->{entry}[$_][1];
               $self->{sel}{$_} = $self->{entry}[$_];
            }

            $self->invalidate_all;
         });
      }

      $sel->append (my $item = new Gtk2::MenuItem "By Adjacent Dir (Alt-A)");
      $item->signal_connect (activate => sub { $self->selection_adjacent_dir });

      $sel->append (my $item = new Gtk2::MenuItem "Unselect Thumbnailed (Ctrl -)");
      $item->signal_connect (activate => sub { $self->selection_remove_thumbnailed });

      $sel->append (my $item = new Gtk2::MenuItem "Keep only Thumbnailed (Ctrl +)");
      $item->signal_connect (activate => sub { $self->selection_keep_only_thumbnailed });
   }

   $self->signal_emit (popup => $menu, $cursor, $event);
   $_->show_all for $menu->get_children;
   $menu->popup (undef, undef, undef, undef, $event->button, $event->time);
}

sub emit_activate {
   my ($self, $cursor) = @_;

   $self->prefetch_cancel;

   my $entry = $self->{entry}[$cursor];
   my $path = "$entry->[E_DIR]/$entry->[E_FILE]";

   $self->{cursor_current} = $path;

   if (-d $path && !Gtk2::CV::ImageWindow::dir_is_movie $path) {
      $self->push_state;
      $self->set_dir ($path);
   } else {
      $self->signal_emit (activate => $path);
   }
}

sub make_visible {
   my ($self, $offs) = @_;

   my $row = $offs / $self->{cols};

   $self->{adj}->set_value ($row < $self->{maxrow} ? $row : $self->{maxrow})
      if $row < $self->{row} || $row >= $self->{row} + $self->{page};
}

sub draw_entry {
   my ($self, $offs) = @_;

   my $row = $offs / $self->{cols};

   if ($row >= $self->{row} and $row < $self->{row} + $self->{page}) {
      $offs -= $self->{offs};
      $self->invalidate (
         ($offs % $self->{cols}, $offs / $self->{cols}) x 2,
      );
   }
}

sub cursor_valid {
   my ($self) = @_;

   my $cursor = $self->{cursor};

   defined $cursor
        && $self->{sel}{$cursor}
        && $cursor < @{$self->{entry}}
        && $cursor >= $self->{offs}
        && $cursor < $self->{offs} + $self->{page} * $self->{cols};
}

sub cursor_move {
   my ($self, $inc, $time) = @_;

   my $cursor = $self->{cursor};
   my $cursor_prev = $cursor;

   if ($self->cursor_valid) {
      $self->clear_selection;

      my $oldcursor = $cursor;
      
      $cursor += $inc;
      $cursor -= $inc if $cursor < 0 || $cursor >= @{$self->{entry}};

      if ($cursor < $self->{offs}) {
         $self->{adj}->set_value ($self->{row} - 1);
      } elsif ($cursor >= $self->{offs} + $self->{page} * $self->{cols}) {
         $self->{adj}->set_value ($self->{row} + $self->{page});
      }

      $self->invalidate (
         (($oldcursor - $self->{offs}) % $self->{cols},
          ($oldcursor - $self->{offs}) / $self->{cols}) x 2
      );
   } else {
      $self->clear_selection;
      $cursor_prev = -1;

      unless (defined $cursor) {
         if ($inc < 0) {
            $cursor = $self->{offs} + $self->{page} * $self->{cols} - 1;
         } else {
            $cursor = $self->{offs};
            $cursor++ while $cursor < $#{$self->{entry}}
                            && -d "$self->{entry}[$cursor][0]/$self->{entry}[$cursor][1]/$curdir";

            $cursor = 0 if $cursor == $#{$self->{entry}};
         }
      } else {
         my $entry = $self->{entry}[$cursor];
         $cursor += $inc if $self->{cursor_current} eq "$entry->[E_DIR]/$entry->[E_FILE]";
         $cursor -= $inc if $cursor < 0 || $cursor >= @{$self->{entry}};
      }

      $self->make_visible ($cursor);
   }

   $self->{cursor} = $cursor;
   delete $self->{cursor_current};
   $self->{sel}{$cursor} = $self->{entry}[$cursor];

   $self->emit_sel_changed;

   $self->invalidate (
      (($cursor - $self->{offs}) % $self->{cols},
       ($cursor - $self->{offs}) / $self->{cols}) x 2
   );

   $cursor_prev != $cursor
}

sub clear_cursor {
   my ($self) = @_;

   if (
      defined (my $cursor = delete $self->{cursor})
      && 1 >= scalar keys %{ $self->{sel} }
   ) {
      delete $self->{sel}{$cursor};
      $self->emit_sel_changed;

      $self->draw_entry ($cursor);
   }
}

sub clear_selection {
   my ($self) = @_;

   delete $self->{cursor};

   $self->draw_entry ($_) for keys %{delete $self->{sel} || {}};

   $self->emit_sel_changed;
}

sub get_selection {
   my ($self) = @_;

   $self->{sel}
}

=item $schnauzer->rotate( degrees, idx[, idx...])

Rotate the raw images on the given entries.

=cut

sub rotate {
   my ($self, $degrees, @idx) = @_;

   Gtk2::CV::Jobber::inhibit {
      for (sort { $b <=> $a } @idx) {
         my $e = $self->{entry}[$_];
         Gtk2::CV::Jobber::submit rotate => "$e->[0]/$e->[1]", $degrees;
         delete $self->{sel}{$_};
      }

      $self->invalidate_all;
      $self->emit_sel_changed;
   };
}

=item $schnauzer->generate_thumbnails (idx[, idx...])

Generate (unconditionally) the thumbnails on the given entries.

=cut

sub generate_thumbnails {
   my ($self, @idx) = @_;

   Gtk2::CV::Jobber::inhibit {
      for (sort { $b <=> $a } @idx) {
         my $e = $self->{entry}[$_];
         Gtk2::CV::Jobber::submit gen_thumb => "$e->[0]/$e->[1]";
         delete $self->{sel}{$_};
      }

      $self->invalidate_all;
      $self->emit_sel_changed;
   };
}

=item $schnauzer->update_thumbnails (idx[, idx...])

Update (if needed) the thumbnails on the given entries.

=cut

sub update_thumbnails {
   my ($self, @idx) = @_;

   Gtk2::CV::Jobber::inhibit {
      for (sort { $b <=> $a } @idx) {
         my $e = $self->{entry}[$_];
         Gtk2::CV::Jobber::submit upd_thumb => "$e->[0]/$e->[1]";
         delete $self->{sel}{$_};
      }

      $self->invalidate_all;
      $self->emit_sel_changed;
   };
}

=item $schnauzer->unlink_thumbnails (idx[, idx...])

Physically remove the thumbnails on the given entries.

=cut

sub unlink_thumbnails {
   my ($self, @idx) = @_;

   Gtk2::CV::Jobber::inhibit {
      for (sort { $b <=> $a } @idx) {
         my $e = $self->{entry}[$_];
         Gtk2::CV::Jobber::submit unlink_thumb => "$e->[0]/$e->[1]";
         delete $self->{sel}{$_};
      }

      $self->invalidate_all;
      $self->emit_sel_changed;
   };
}

=item $schnauzer->selection_adjacent_dir

=cut

sub selection_adjacent_dir {
   my ($self) = @_;

   my $sel = $self->{sel} ||= {};
   my @keys = sort keys %$sel;
   my $entry = $self->{entry};

   my $same_prefix = sub {
      my ($idx, $pfx) = @_;

      $idx >= 0 && $idx <= $#$entry
         or return 0;

      $pfx eq substr "$entry->[$idx][E_DIR]/", 0, length $pfx
   };

   # frst arg may be out-of-range
   my $common_prefix = sub {
      my ($a, $b) = @_;

      $a >= 0 && $a <= $#$entry
         or return "";

      my $pfx = Gtk2::CV::common_prefix_length "$entry->[$a][E_DIR]/", "$entry->[$b][E_DIR]/";
      $pfx = substr "$entry->[$a][E_DIR]/", 0, $pfx;
      $pfx =~ s/[^\/]+$//;

      $pfx
   };

   # find consecutive ranges
   while (@keys) {
      my $end = pop @keys;
      my $beg = $end;

      $beg = pop @keys
         while @keys && $keys[-1] == $beg - 1;

      # detect common dir prefix
      my $pfx = $common_prefix->($beg, $end);

      if ($same_prefix->($beg - 1, $pfx) or $same_prefix->($end + 1, $pfx)) {
         # extend borders within same dir first
      } else {
         # extend borders to shallower directories

         # find longer common prefix
         my $pfxa = $common_prefix->($beg - 1, $beg);
         my $pfxb = $common_prefix->($end + 1, $end);

         $pfx = length $pfxa < length $pfxb ? $pfxb : $pfxa;
      }

      while ($same_prefix->($beg - 1, $pfx)) {
         --$beg;
         $sel->{$beg} = $entry->[$beg];
      };

      while ($same_prefix->($end + 1, $pfx)) {
         ++$self->{cursor}
            if $self->{cursor} == $end;

         ++$end;
         $sel->{$end} = $entry->[$end];
      }
   }

   $self->invalidate_all;
   $self->emit_sel_changed;
}

=item $schnauzer->selection_remove_thumbnailed

=item $schnauzer->selection_keep_only_thumbnailed

=cut

sub selection_remove_thumbnailed {
   my ($self) = @_;

   for (keys %{$self->{sel}}) {
      delete $self->{sel}{$_} if $self->{entry}[$_][2] & F_HASXVPIC;
   }

   $self->invalidate_all;
   $self->emit_sel_changed;
}

sub selection_keep_only_thumbnailed {
   my ($self) = @_;

   for (keys %{$self->{sel}}) {
      delete $self->{sel}{$_} unless $self->{entry}[$_][2] & F_HASXVPIC;
   }

   $self->invalidate_all;
   $self->emit_sel_changed;
}

=item $schnauzer->unlink (recursive, idx[, idx...])

Physically delete the given entries.

=cut

sub unlink {
   my ($self, $recursive, @idx) = @_;

   Gtk2::CV::Jobber::inhibit {
      for (sort { $b <=> $a } @idx) {
         my $e = $self->{entry}[$_];
         if (exists $ENV{CV_TRASHCAN} and !$recursive) {
            Gtk2::CV::Jobber::submit mv => "$e->[0]/$e->[1]", $ENV{CV_TRASHCAN};
         } elsif ($e->[2] & F_ISDIR) {
            Gtk2::CV::Jobber::submit rm_rf => "$e->[0]/$e->[1]"
               if $recursive;
         } else {
            Gtk2::CV::Jobber::submit unlink => "$e->[0]/$e->[1]";
         }

         --$self->{cursor} if $self->{cursor} > $_;
         delete $self->{sel}{$_};
         splice @{$self->{entry}}, $_, 1, ();
      }

      $self->entry_changed;
      $self->setadj;

      $self->emit_sel_changed;
      $self->invalidate_all;
   };
}

sub handle_key {
   my ($self, $key, $state) = @_;

   $self->prefetch_cancel;

   $state *= Gtk2::Accelerator->get_default_mod_mask;

   if ($state == ["control-mask"]) {
      if ($key == $Gtk2::Gdk::Keysyms{g}) {
         my @sel = keys %{$self->{sel}};
         $self->generate_thumbnails (@sel ? @sel : 0 .. $#{$self->{entry}});
      } elsif ($key == $Gtk2::Gdk::Keysyms{a}) {
         $self->select_all;
      } elsif ($key == $Gtk2::Gdk::Keysyms{s}) {
         $self->rescan;
      } elsif ($key == $Gtk2::Gdk::Keysyms{d}) {
         $self->unlink (0, keys %{$self->{sel}});
      } elsif ($key == $Gtk2::Gdk::Keysyms{u}) {
         my @sel = keys %{$self->{sel}};
         $self->update_thumbnails (@sel ? @sel : 0 .. $#{$self->{entry}});

      } elsif ($key == ord '-') {
         $self->selection_remove_thumbnailed;
      } elsif ($key == ord '+') {
         $self->selection_keep_only_thumbnailed;

      } elsif ($key == $Gtk2::Gdk::Keysyms{Return}) {
         $self->cursor_move (0) unless $self->cursor_valid;
         $self->emit_activate ($self->{cursor});
      } elsif ($key == $Gtk2::Gdk::Keysyms{space}) {
         $self->cursor_move (1) or return 1
            if $self->{cursor_current} || !$self->cursor_valid;
         $self->emit_activate ($self->{cursor}) if $self->cursor_valid;
         $self->prefetch (1);
      } elsif ($key == $Gtk2::Gdk::Keysyms{BackSpace}) {
         $self->cursor_move (-1) or return 1;
         $self->emit_activate ($self->{cursor}) if $self->cursor_valid;
         $self->prefetch (-1);

      } else {
         return 0;
      }
   } elsif ($state == ["mod1-mask"]) {
      if ($key == $Gtk2::Gdk::Keysyms{a}) {
         $self->selection_adjacent_dir;
      } else {
         return 0;
      }
   } elsif ($state == ["shift-mask", "control-mask"]) {
      if ($key == $Gtk2::Gdk::Keysyms{A}) {
         $self->select_range ($self->{offs}, $self->{offs} + $self->{cols} * $self->{page} - 1);
      } elsif ($key == $Gtk2::Gdk::Keysyms{D}) {
         $self->unlink (1, keys %{$self->{sel}});
      } elsif ($key == $Gtk2::Gdk::Keysyms{G}) {
         $self->unlink_thumbnails (keys %{$self->{sel}});
      } else {
         return 0;
      }
   } elsif ($state == []) {
      if ($key == $Gtk2::Gdk::Keysyms{Page_Up}) {
         my $value = $self->{adj}->value;
         $self->{adj}->set_value ($value >= $self->{page} ? $value - $self->{page} : 0);
         $self->clear_cursor;
      } elsif ($key == $Gtk2::Gdk::Keysyms{Page_Down}) {
         my $value = $self->{adj}->value + $self->{page};
         $self->{adj}->set_value ($value <= $self->{maxrow} ? $value : $self->{maxrow});
         $self->clear_cursor;

      } elsif ($key == $Gtk2::Gdk::Keysyms{Home}) {
         $self->{adj}->set_value (0);
         $self->clear_cursor;
      } elsif ($key == $Gtk2::Gdk::Keysyms{End}) {
         $self->{adj}->set_value ($self->{maxrow});
         $self->clear_cursor;

      } elsif ($key == $Gtk2::Gdk::Keysyms{Up}) {
         $self->cursor_move (-$self->{cols});
      } elsif ($key == $Gtk2::Gdk::Keysyms{Down}) {
         $self->cursor_move (+$self->{cols});
      } elsif ($key == $Gtk2::Gdk::Keysyms{Left}) {
         $self->cursor_move (-1);
      } elsif ($key == $Gtk2::Gdk::Keysyms{Right}) {
         $self->cursor_move (+1);

      } elsif ($key == $Gtk2::Gdk::Keysyms{Return}) {
         $self->cursor_move (0) unless $self->cursor_valid;
         $self->emit_activate ($self->{cursor});
      } elsif ($key == $Gtk2::Gdk::Keysyms{space}) {
         $self->cursor_move (1) or return 1
            if $self->{cursor_current} || !$self->cursor_valid;
         $self->emit_activate ($self->{cursor}) if $self->cursor_valid;
         $self->prefetch (1);
      } elsif ($key == $Gtk2::Gdk::Keysyms{BackSpace}) {
         $self->cursor_move (-1) or return 1;
         $self->emit_activate ($self->{cursor}) if $self->cursor_valid;
         $self->prefetch (-1);

      } elsif ($key == ord '^') {
         $self->updir if exists $self->{dir};

      } elsif (($key >= (ord '0') && $key <= (ord '9'))
               || ($key >= (ord 'a') && $key <= (ord 'z'))) {

         $key = chr $key;

         my ($idx, $cursor) = (0, 0);

         $self->clear_selection;

         for my $entry (@{$self->{entry}}) {
            $idx++;
            $cursor = $idx if $key gt lcfirst $entry->[E_FILE];
         }

         if ($cursor < @{$self->{entry}}) {
            delete $self->{cursor_current};
            $self->{sel}{$cursor} = $self->{entry}[$cursor];
            $self->{cursor} = $cursor;

            $self->{adj}->set_value (min $self->{maxrow}, $cursor / $self->{cols});
            $self->emit_sel_changed;
            $self->invalidate_all;
         }
      } else {
         return 0;
      }
   } else {
      return 0;
   }

   1
}

sub invalidate {
   my ($self, $x1, $y1, $x2, $y2) = @_;

   return unless $self->{window};

   $self->{draw}->queue_draw_area (
      $x1 * (IWD + IX), $y1 * (IHD + IY),
      ($x2 - $x1 + 1) * (IWD + IX), ($y2 - $y1 + 1) * (IHD + IY),
   );
}

sub invalidate_all {
   my ($self) = @_;

   $self->invalidate (0, 0, $self->{cols} - 1, $self->{page} - 1);
}

sub select_range {
   my ($self, $a, $b) = @_;

   for ($a .. $b) {
      next if 0 > $_ || $_ > $#{$self->{entry}};

      $self->{sel}{$_} = $self->{entry}[$_];
      $self->draw_entry ($_);
   }

   $self->emit_sel_changed;
}

sub select_all {
   my ($self) = @_;

   $self->select_range (0, $#{$self->{entry}});
}

=item $schnauer->entry_changed

This method needs to be called whenever the C<< $schnauzer->{entry} >>
member has been changed in any way.

=cut

sub entry_changed {
   my ($self) = @_;

   # remove entries for which a job exists that will eventually delete it (hide attr)
   {
      my %delete;

      @delete{ grep exists $Gtk2::CV::Jobber::hide{"$_->[0]/$_->[1]"}, @{ $self->{entry} } }
         = ();

      # a rare event
      $self->{entry} = [grep !exists $delete{$_}, @{ $self->{entry} }]
         if %delete;
   }

   delete $self->{map};
   delete $self->{idle_check_done};
   delete $self->{idle_check_idx};
   delete $self->{idle_check};
   $self->{generation}++;
   $self->start_idle_check;
}

sub selrect {
   my ($self) = @_;

   return unless $self->{oldsel};

   my ($x1, $y1) = ($self->{sel_x1}, $self->{sel_y1});
   my ($x2, $y2) = ($self->{sel_x2}, $self->{sel_y2});

   my $prev = $self->{sel};
   $self->{sel} = { %{$self->{oldsel}} };

   if (0) {
      # rectangular selection
      ($x1, $x2) = ($x2, $x1) if $x1 > $x2;
      ($y1, $y2) = ($y2, $y1) if $y1 > $y2;

      outer:
      for my $y ($y1 .. $y2) {
         my $idx = $y * $self->{cols};
         for my $x ($x1 .. $x2) {
            my $idx = $idx + $x;
            last outer if $idx > $#{$self->{entry}};

            $self->{sel}{$idx} = $self->{entry}[$idx];
         }
      }
   } else {
      # range selection
      my $a = $x1 + $y1 * $self->{cols};
      my $b = $x2 + $y2 * $self->{cols};

      ($a, $b) = ($b, $a) if $a > $b;

      for my $idx ($a .. $b) {
         last if $idx > $#{$self->{entry}};
         $self->{sel}{$idx} = $self->{entry}[$idx];
      }
   }

   $self->emit_sel_changed;
   for my $idx (keys %{$self->{sel}}) {
      $self->draw_entry ($idx) if !exists $prev->{$idx};
   }
   for my $idx (keys %$prev) {
      $self->draw_entry ($idx) if !exists $self->{sel}{$idx};
   }
}

sub sel_scroll {
   my ($self, $row_diff) = @_;

   my $row = $self->{row} + $row_diff;

   $row = max 0, min $row, $self->{maxrow};

   if ($self->{row} != $row) {
      $self->{sel_y2} += $row - $self->{row};
      $self->selrect;
      $self->{adj}->set_value ($row);
   }
}

sub setadj {
   my ($self) = @_;

   no integer;

   $self->{rows} = ceil @{$self->{entry}} / $self->{cols};
   $self->{maxrow} = $self->{rows} - $self->{page};

   $self->{adj}->step_increment (1);
   $self->{adj}->page_size      ($self->{page});
   $self->{adj}->page_increment ($self->{page});
   $self->{adj}->lower          (0);
   $self->{adj}->upper          ($self->{rows});
   $self->{adj}->changed;

   $self->{adj}->set_value ($self->{maxrow})
      if $self->{row} > $self->{maxrow};
}

sub expose {
   my ($self, $event) = @_;

   no integer;

   return unless @{$self->{entry}};

   my ($x1, $y1, $x2, $y2) = $event->area->values; # x y w h

   $self->{window}->clear_area ($x1, $y1, $x2, $y2);

   $x2 += $x1;
   $y2 += $y1;

   $x1 -= IWD + IX;
   $y1 -= IHD + IY;

   my @x = map $_ * (IWD + IX), 0 .. $self->{cols} - 1;
   my @y = map $_ * (IHD + IY), 0 .. $self->{page} - 1;

   # 'orrible, why do they deprecate _convenience_ functions? :(
   my $context = $self->get_pango_context;
   my $font = $context->get_font_description;

   $font->set_absolute_size (FY * Gtk2::Pango->scale);

   my $maxwidth = IWD + IX * 0.85;
   my $idx = $self->{offs} + 0;

   my $layout = new Gtk2::Pango::Layout $context;
   $layout->set_ellipsize ('end');
   $layout->set_width ($maxwidth * Gtk2::Pango->scale);

   my $first_unchecked;

   my @jobs;

   my $black_gc = $self->style->black_gc;
   my $white_gc = $self->style->white_gc;

outer:
   for my $y (@y) {
      for my $x (@x) {
         if ($y > $y1 && $y < $y2
             && $x > $x1 && $x < $x2) {
            my $entry = $self->{entry}[$idx];
            my $path = "$entry->[E_DIR]/$entry->[E_FILE]";
            my $text_gc;

            # selected?
            if (exists $self->{sel}{$idx}) {
               $self->{window}->draw_rectangle ($black_gc, 1,
                       $x, $y, IWD + IX, IHD + IY);
               $text_gc = $white_gc;
            } else {
               $text_gc = $black_gc;
            }

            if (exists $Gtk2::CV::Jobber::jobs{$path}) {
               push @jobs, $path;

               $self->{window}->draw_rectangle ($self->style->dark_gc ('normal'), 1,
                       $x + IX * 0.1, $y, IWD + IX * 0.8, IHD);
            }

            # pre-render thumb into pixmap
            $self->force_pixmap ($entry)
               unless $entry->[E_FLAGS] & F_HASPM;

            $first_unchecked = $idx
               unless $entry->[E_FLAGS] & F_CHECKED || defined $first_unchecked;

            my $pm = $entry->[E_PIXMAP];
            my ($pw, $ph) = $pm->get_size;

            $self->{window}->draw_drawable ($white_gc,
                     $pm,
                     0, 0,
                     $x + (IX + IWD - $pw) * 0.5,
                     $y + (     IHD - $ph) * 0.5,
                     $pw, $ph);

            utf8::downgrade $entry->[E_FILE];#d# ugly workaround for Glib-bug, costs performance like nothing :)

            $layout->set_text (filename_display_name $entry->[E_FILE]);

            my ($w, $h) = $layout->get_pixel_size;

            $self->{window}->draw_layout (
               $text_gc,
               $x + (IX + IWD - $w) * 0.5, $y + IHD,
               $layout
            );
         }

         last outer if ++$idx >= @{$self->{entry}};
      }
   }

   push @Gtk2::CV::Jobber::jobs, reverse @jobs;

   $self->{idle_check_idx} = $first_unchecked
      if defined $first_unchecked;

   1
}

sub do_activate {
   # nop
}

sub start_idle_check {
   my ($self) = @_;

   return if $self->{idle_check_done};
   $self->realize;
#   $self->{inhibit_guard} ||= Gtk2::CV::Jobber::inhibit_guard;
   $self->{idle_check_watcher} ||= add Glib::Idle sub { $self->idle_check }, undef, 500;
}

sub idle_check {
   my ($self) = @_;

   my $generation = $self->{generation};

   my $todo = FAST_RANGE;

   while (--$todo) {
      my $idx = $self->{idle_check_idx}++;

      if ($idx >= @{$self->{entry}}) {
         if ($self->{idle_check}) {
            # found a file, restart scan
            delete $self->{idle_check};
            delete $self->{idle_check_idx};
            return 1;
         }

         # finish
         $self->{idle_check_done}++;
         delete $self->{idle_check_watcher};
         return 0;
      }

      my $entry = $self->{entry}[$idx];

      unless ($entry->[E_FLAGS] & F_CHECKED) {
         $entry->[E_FLAGS] |= F_CHECKED;

         my $path = "$entry->[E_DIR]/$entry->[E_FILE]";
         $self->{idle_check}++;

         if ($entry->[E_FLAGS] & F_HASXVPIC) {
            my $xvpic = xvpic $path;
            aioreq_pri -1;
            aio_open $xvpic, O_RDONLY, 0, sub {
               return unless $generation == $self->{generation};

               my $fh = shift
                  or return $self->start_idle_check;

               aioreq_pri 0;
               aio_readahead $fh, 0, -s $fh, sub {
                  return unless $generation == $self->{generation};

                  $entry->[E_FLAGS] &= ~F_HASPM;
                  $entry->[E_PIXMAP] = read_thumb $xvpic;
                  $self->draw_entry ($idx);
                  $self->start_idle_check;
               };
            };

         } elsif ($entry->[E_FLAGS] & F_ISDIR) {
            aioreq_pri -1;
            aio_lstat $path, sub {
               return unless $generation == $self->{generation};
               my $is_symlink = -l _;

               aioreq_pri -1;
               aio_stat "$path/.xvpics", sub { # hopefully this pulls in part of the dir
                  return unless $generation == $self->{generation};
                  my $has_xvpics = -d _;

                  my $is_empty = 1;

                  opendir my $fh, $path #d# no clue how to do this sensibly with IO::AIO
                     or return;
                     local $_;
                     while (defined ($_ = readdir $fh)) {
                        next if $_ eq $updir;
                        next if $_ eq $curdir;
                        next if $_ eq ".xvpics";
                        $is_empty = 0;
                        last;
                     }
                  closedir $fh;

                  my $img = $directory_visited{$path} ? $dirv_img : $diru_img;

                  $img = $self->img_combine ($img, $dire_layer) if $is_empty;
                  $img = $self->img_combine ($img, $dirx_layer) if $has_xvpics;
                  $img = $self->img_combine ($img, $dirs_layer) if $is_symlink;

                  $entry->[E_FLAGS] |= F_HASPM;
                  $entry->[E_PIXMAP] = $img;
                  $self->draw_entry ($idx);
                  $self->start_idle_check;
               };
            };
         } else {
            aioreq_pri -1;
            aio_stat $path, sub {
               return unless $generation == $self->{generation};

               if (-d _) {
                  $entry->[E_FLAGS] |= F_ISDIR;
                  $entry->[E_FLAGS] &= ~F_CHECKED;
               }

               $self->start_idle_check;
            };
         }

         delete $self->{idle_check_watcher};
         return 0;
      }
   }

   return 1;
}

sub do_chpaths {
   # nop
}

sub chpaths {
   my ($self, $paths, $nosort, $cb) = @_;

   (delete $self->{chpaths_grp})->cancel if $self->{chpaths_grp};

   my $all_group = $self->{chpaths_grp} = aio_group $cb;

   # get_parent_widnow is a hack hack., but otherwise gtk mishandles events
   $self->get_toplevel->set_sensitive (0) if $self->get_toplevel;
   my $inhibit_guard = Gtk2::CV::Jobber::inhibit_guard;

   my $guard = Guard::guard {
      delete $self->{chpaths_grp};
      undef $inhibit_guard;
      $self->get_toplevel->set_sensitive (1) if $self->get_toplevel;
      $self->{draw}->grab_focus unless eval { $self->get_toplevel->get_focus };
   };

   $self->start_idle_check;
   $self->signal_emit ("chpaths");

   my $base = $self->{dir};

   delete $self->{cursor_current};
   delete $self->{cursor};
   delete $self->{sel};
   delete $self->{map};
   $self->{entry} = [];
   $self->entry_changed;

   $self->emit_sel_changed;

   my %exclude = ($curdir => 0, $updir => 0, ".xvpics" => 0, %EXCLUDE);

   my %xvpics;
   my $leaves = -1;

   my $order = $paths;

   ### phase 1, .xvpics scan, if applicable, and sort

   my $grp = add $all_group aio_group;

   if (defined $base) {
      $leaves = (stat $base)[3];
      $leaves -= 2; # . and ..

      add $grp aio_readdir "$base/.xvpics", sub {
         return unless $_[0];

         $leaves--; # .xvpics itself
         $xvpics{$_}++ for @{ $_[0] };
      };

      add $grp aio_nop sub {
         # try stat'ing entries that look like directories first
         my (@d, @f);
         for (@$paths) {
            $_->[1] =~ /.\./ ? push @f, $_ : push @d, $_
         }

         push @d, @f;
         $paths = \@d;
      };

   }

   cb $grp sub {
      my $grp = add $all_group aio_group;
      limit $grp 32;

      my $progress = new Gtk2::CV::Progress title => "scanning...", work => scalar @$paths;

      my (@d, @f);
      my $i = 0;

      feed $grp sub {
         while ($i < @$paths) {
            my ($dir, $file) = @{ $paths->[$i++] };

            # work around bugs in the Glib module early
            utf8::downgrade $dir;
            utf8::downgrade $file;

            if (exists $exclude{$file}) {
               # ignore
               $progress->increment;
            } elsif ($base eq $dir ? exists $xvpics{$file} : -r "$dir/.xvpics/$file") {
               delete $xvpics{$file};
               push @f, [$dir, $file, F_HASXVPIC];
               $progress->increment;
            } elsif ($leaves) {
               # this is faster than a normal stat on many modern filesystems
               add $grp aio_stat "$dir/$file/$curdir", sub {
                  if (!$_[0]) { # no error
                     add $grp aio_lstat "$dir/$file", sub {
                        if (-d _) {
                           $leaves--;
                           push @d, [$dir, $file, F_ISDIR | F_HASPM, $directory_visited{"$dir/$file"} ? $dirv_img : $diru_img];
                        } else {
                           push @f, [$dir, $file];
                        }
                        $progress->increment;
                     };
                  } elsif ($! == ENOTDIR) {
                     push @f, [$dir, $file];
                     $progress->increment;
                  } else {
                     # does not exist:
                     # ELOOP, ENAMETOOLONG => symlink pointing nowhere
                     # ENOENT => entry does not even exist
                     # EACCESS, EIO, EOVERFLOW => we have to give up
                     $progress->increment;
                  }
               };

               return;
            } else {
               push @f, [$dir, $file, undef, 0];
               $progress->increment;
            }
         }
      };

      cb $grp sub {
         $progress->set_title ("sorting...");

         if ($nosort) {
            for (\@d, \@f) {
               my %h = map +("$_->[E_DIR]/$_->[E_FILE]" => $_), @$_;
               @$_ = grep $_, map $h{"$_->[E_DIR]/$_->[E_FILE]"}, @$order;
            }
         } else {
            for (\@d, \@f) {
               @$_ = map $_->[1],
                          sort { $a->[E_DIR] cmp $b->[E_DIR] }
                             map [foldcase $_->[E_FILE], $_],
                                 @$_;
            }
         }

         $self->{entry} = [@d, @f];
         $self->entry_changed;

         $self->{adj}->set_value (0);
         $self->setadj;

         $self->{draw}->queue_draw;

         # remove extraneous .xvpics files (but only after an extra check)
         my @xvpics = keys %xvpics;
         $progress = new Gtk2::CV::Progress title => "clean thumbnails...", work => scalar @xvpics;

         my $grp = aio_group sub {
            # try to nuke .xvpics at the end, maybe it is empty
            rmdir "$base/.xvpics";
         };

         limit $grp 1;
         feed $grp sub {
            @xvpics or return;
            my $file = pop @xvpics;
            aioreq_pri -3;
            add $grp aio_stat "$base/$file", sub {
               if (!$_[0] || -d _) {
                  $progress->increment;
               } else {
                  aioreq_pri -3;
                  add $grp aio_unlink "$self->{dir}/.xvpics/$file", sub {
                     $progress->increment;
                  };
               }
            };
         };

         undef $guard;
      };
   };
}

sub set_paths {
   my ($self, $paths, $nosort, $cb) = @_;

   $paths = [
      map /^(.*)\/([^\/]*)$/s
             ? [$1, $2]
             : [$curdir, $_],
          @$paths
   ];
 
   delete $self->{dir};
   $self->chpaths ($paths, $nosort, sub {
      $self->window->property_delete (Gtk2::Gdk::Atom->intern ("_X_CWD", 0))
         if $self->window;

      $cb->() if $cb;
   });
}

sub do_chdir {
   # nop
}

sub chdir {
   my ($self, $dir, $cb) = @_;

   $dir = Cwd::abs_path $dir;

   $directory_visited{$dir}++;

   -d $dir
      or die "$dir: $!";

   $self->realize;
   $self->window->property_change (
      Gtk2::Gdk::Atom->intern ("_X_CWD", 0),
      Gtk2::Gdk::Atom->intern ("STRING", 0),
      Gtk2::Gdk::CHARS, 'replace',
      $dir,
   );

   aio_readdirx $dir, IO::AIO::READDIR_STAT_ORDER, sub {
      $self->{dir} = $dir;
      $self->chpaths ([map [$dir, $_], @{$_[0]}], 0, $cb);

      $self->signal_emit (chdir => $dir);
   };
}

=item $schnauzer->set_dir ($path[, $cb])

Replace the schnauzer contents by the files in the given directory.

=cut

sub set_dir {
   my ($self, $dir, $cb) = @_;

   $self->chdir ($dir, $cb);
}

=item $state = $schnauzer->get_state

=item $schnauzer->set_state ($state)

Saves/restores (some of) the current state, such as the current directory
or currently displayed files.

Can be used to switch temporarily to another directory.

=cut

sub get_state {
   my ($self) = @_;

   exists $self->{dir}
      ? [$self->{dir}, undef]
      : [undef, $self->get_paths]
}

sub set_state {
   my ($self, $state, $cb) = @_;

   my ($dir, $paths) = @$state;

   if ($paths) {
      $self->set_paths ($paths, $cb);
   } else {
      $self->set_dir ($dir, $cb);
   }
}

=item $schnauzer->push_state

=item $schnauzer->pop_state ([$cb])

Pushes/pops the state from the state stack. Is used internally to
implement recursing into subdirectories and returning.

=cut

sub push_state {
   my ($self) = @_;

   push @{ $self->{state_stack} ||= [] }, $self->get_state;
}

sub pop_state {
   my ($self, $cb) = @_;

   $self->set_state (pop @{ $self->{state_stack} }, $cb);
}

sub updir {
   my ($self) = @_;

   if (@{ $self->{state_stack} || [] }) {
      $self->pop_state;
   } elsif (exists $self->{dir}) {
      $self->set_dir (parent_dir $self->{dir});
   }
}

sub get_paths {
   my ($self) = @_;

   [ map "$_->[E_DIR]/$_->[E_FILE]", @{$self->{entry}} ]
}

sub rescan {
   my ($self) = @_;

   if ($self->{dir}) {
      $self->set_dir ($self->{dir});
   } else {
      $self->set_paths ($self->get_paths);
   }
}

=back

=head1 AUTHOR

Marc Lehmann <schmorp@schmorp.de>

=cut

1

