#######################################################################
#      $URL: svn+ssh://equilibrious@equilibrious.net/home/equilibrious/svnrepos/chrisdolan/Fuse-PDF/lib/Fuse/PDF/ContentFS.pm $
#     $Date: 2008-06-06 22:47:54 -0500 (Fri, 06 Jun 2008) $
#   $Author: equilibrious $
# $Revision: 767 $
########################################################################

package Fuse::PDF::ContentFS;

use warnings;
use strict;
use 5.008;

use Carp qw(carp);
use Readonly;
use POSIX qw(:errno_h);
use Fcntl qw(:mode);
use English qw(-no_match_vars);
use CAM::PDF;
use CAM::PDF::Node;
use CAM::PDF::Renderer::Images; # included so PAR picks it up
use CAM::PDF::Renderer::Text;   # included so PAR picks it up
use Fuse::PDF::ErrnoHacks;
use Fuse::PDF::FS;
use Fuse::PDF::ImageTemplate;

our $VERSION = '0.09';

Readonly::Scalar my $PATHLEN => 255;
Readonly::Scalar my $BLOCKSIZE => 4096;
Readonly::Scalar my $ELOOP_LIMIT => 100;
Readonly::Hash my %PERMS => (
   d => S_IFDIR() | oct 555,
   l => S_IFLNK() | oct 777,
   f => S_IFREG() | oct 444,
);

Readonly::Scalar my $USED_FILES => 1000;
Readonly::Scalar my $FREE_FILES => 1_000_000;
Readonly::Scalar my $MAX_BLOCKS => 1_000_000;
Readonly::Scalar my $FREE_BLOCKS => 500_000;

Readonly::Scalar my $FS_ROOT_KEY => 'FusePDF';  # track value from Fuse::PDF::FS

Readonly::Hash my %SCALARS => (map {$_ => 1} qw(string hexstring number boolean label));

Readonly::Scalar my $IMAGE_CACHE_TIMEOUT => 15; # seconds

# --------------------------------------------------

sub new {
   my ($pkg, $options) = @_;
   return if ! $options;
   return if ! $options->{pdf};

   my $self = bless { %{$options} }, $pkg;
   $self->{pdf_mtime} ||= $BASETIME;  # aka $^T

   return $self;
}

sub compact { ## no critic(ArgUnpacking)
   my ($self, $boolean) = @_;
   return $self->{compact} if @_ == 1;
   $self->{compact} = $boolean ? 1 : undef;
   return;
}

sub backup { ## no critic(ArgUnpacking)
   my ($self, $boolean) = @_;
   return $self->{backup} if @_ == 1;
   $self->{backup} = $boolean ? 1 : undef;
   return;
}

sub autosave_filename { ## no critic(ArgUnpacking)
   my ($self, $filename) = @_;
   return $self->{autosave_filename} if @_ == 1;
   $self->{autosave_filename} = $filename;
   return;
}

sub previous_revision {
   my ($self) = @_;

   my $prev_pdf = $self->{pdf}->previousRevision();
   return if !$prev_pdf;

   return __PACKAGE__->new({
      pdf => $prev_pdf,
      pdf_mtime => $self->{pdf_mtime},
   });
}

sub all_revisions {
   my ($self) = @_;
   my @revs;
   for (my $fs = $self; $fs; $fs = $fs->previous_revision) {  ## no critic(ProhibitCStyleForLoops)
      push @revs, $fs;
   }
   return @revs;
}

sub statistics {
   my ($self) = @_;
   my %stats;
   $stats{pages} = $self->{pdf}->numPages;
   return \%stats;
}

sub to_string {
   my ($self) = @_;
   my @stats = ($self->statistics);
   my $fs = $self;
   while ($fs = $fs->previous_revision) {
      push @stats, $fs->statistics;
   }
   my @rows = (
      'Name:       ' . $stats[0]->{name},
   );
   for my $i (0 .. $#stats) {
      my $s = $stats[$i];
      push @rows, 'Revision:   ' . (@stats - $i);
      push @rows, '  Pages:    ' . $s->{pages};
   }

   return join "\n", @rows, q{};
}

# --------------------------------------------------

sub fs_getattr {
   my ($self, $abspath) = @_;
   my ($f, $path) = $self->_file($abspath);
   if (defined $path) {
      return -EIO() if !$f->can('fs_getattr');
      return $f->fs_getattr($path);
   }
   return -$f if !ref $f;
   my $type = $f->{type};
   my $size = 'd' eq $type ? 0 : length $f->{content};
   my $blocks = 0 == $size ? 0 : (($size - 1) % $BLOCKSIZE) + 1;  # round up
   return
       0, # dev
       0, # inode
       $PERMS{$type},
       ('d' eq $type ? (2 + scalar keys %{$f->{content}}) : 1), # nlink
       $EFFECTIVE_USER_ID, # uid
       0+$EFFECTIVE_GROUP_ID, # gid
       0, # rdev
       $size,
       $self->{pdf_mtime},
       $self->{pdf_mtime},
       $self->{pdf_mtime},
       $BLOCKSIZE,
       $blocks;
}

sub fs_readlink {
   my ($self, $abspath) = @_;
   my ($f, $path) = $self->_file($abspath);
   if (defined $path) {
      return -EIO() if !$f->can('fs_readlink');
      return $f->fs_readlink($path);
   }
   return -$f if !ref $f;
   my $type = $f->{type};
   return -EINVAL() if 'l' ne $type;
   return $f->{content};
}

sub fs_getdir {
   my ($self, $abspath) = @_;
   my ($f, $path) = $self->_file($abspath);
   if (defined $path) {
      return -EIO() if !$f->can('fs_getdir');
      return $f->fs_getdir($path);
   }
   return -$f if !ref $f;
   return q{.}, q{..}, (keys %{$f->{content}}), 0;
}

sub fs_open {
   my ($self, $abspath, $flags) = @_;
   my ($f, $path) = $self->_file($abspath);
   if (defined $path) {
      return -EIO() if !$f->can('fs_open');
      return $f->fs_open($path);
   }
   return -$f if !ref $f;
   # check flags?
   return 0;
}

sub fs_read {
   my ($self, $abspath, $size, $offset) = @_;
   my ($f, $path) = $self->_file($abspath);
   if (defined $path) {
      return -EIO() if !$f->can('fs_read');
      return $f->fs_read($path);
   }
   return -$f if !ref $f;
   return substr $f->{content}, $offset, $size;
}

sub fs_statfs {
   my ($self) = @_;
   return $PATHLEN, $USED_FILES, $FREE_FILES, $MAX_BLOCKS, $FREE_BLOCKS, $BLOCKSIZE;
}

sub fs_mknod {
   my ($self, $abspath, $perms, $dev) = @_;
   my ($f, $path) = $self->_file($abspath);
   if (defined $path) {
      return -EIO() if !$f->can('fs_mknod');
      return $f->fs_mknod($path, $perms, $dev);
   }
   return -EIO();
}

sub fs_mkdir {
   my ($self, $abspath, $perm) = @_;
   my ($f, $path) = $self->_file($abspath);
   if (defined $path) {
      return -EIO() if !$f->can('fs_mkdir');
      return $f->fs_mkdir($path, $perm);
   }
   return -EIO();
}

sub fs_unlink {
   my ($self, $abspath) = @_;
   my ($f, $path) = $self->_file($abspath);
   if (defined $path) {
      return -EIO() if !$f->can('fs_unlink');
      return $f->fs_unlink($path);
   }
   return -EIO();
}

sub fs_rmdir {
   my ($self, $abspath) = @_;
   my ($f, $path) = $self->_file($abspath);
   if (defined $path) {
      return -EIO() if !$f->can('fs_rmdir');
      return $f->fs_rmdir($path);
   }
   return -EIO();
}

sub fs_symlink {
   my ($self, $link, $abspath) = @_;
   my ($f, $path) = $self->_file($abspath);
   if (defined $path) {
      return -EIO() if !$f->can('fs_symlink');
      return $f->fs_symlink($link, $path);
   }
   return -EIO();
}

sub fs_rename {
   my ($self, $srcpath, $destpath) = @_;
   my ($f_s, $src) = $self->_file($srcpath);
   if (defined $src) {
      return -EIO() if !$f_s->can('fs_rename');
      my ($f_d, $dest) = $self->_file($destpath);
      if (defined $dest) {
         return -EXDEV() if $f_s != $f_d;
         return $f_s->fs_rename($src, $dest);
      }
   }
   return -EIO();
}

sub fs_link {
   return -EIO();
}

sub fs_chmod {
   my ($self, $abspath, $perms) = @_;
   my ($f, $path) = $self->_file($abspath);
   if (defined $path) {
      return -EIO() if !$f->can('fs_chmod');
      return $f->fs_chmod($path, $perms);
   }
   return -EIO();
}

sub fs_chown {
   my ($self, $abspath, $uid, $gid) = @_;
   my ($f, $path) = $self->_file($abspath);
   if (defined $path) {
      return -EIO() if !$f->can('fs_chown');
      return $f->fs_chown($path, $uid, $gid);
   }
   return -EIO();
}

sub fs_truncate {
   my ($self, $abspath, $length) = @_;
   my ($f, $path) = $self->_file($abspath);
   if (defined $path) {
      return -EIO() if !$f->can('fs_truncate');
      return $f->fs_truncate($path, $length);
   }
   return -EIO();
}

sub fs_utime {
   my ($self, $abspath, $atime, $mtime) = @_;
   my ($f, $path) = $self->_file($abspath);
   if (defined $path) {
      return -EIO() if !$f->can('fs_utime');
      return $f->fs_utime($path, $atime, $mtime);
   }
   return -EIO();
}

sub fs_write {
   my ($self, $abspath, $str, $offset) = @_;
   my ($f, $path) = $self->_file($abspath);
   if (defined $path) {
      return -EIO() if !$f->can('fs_write');
      return $f->fs_write($path, $str, $offset);
   }
   return -EIO();
}

sub fs_flush {
   my ($self, $abspath) = @_;
   my ($f, $path) = $self->_file($abspath);
   if (defined $path) {
      return -EIO() if !$f->can('fs_flush');
      return $f->fs_flush($path);
   }
   return 0;
}

sub fs_release {
   my ($self, $abspath, $flags) = @_;
   my ($f, $path) = $self->_file($abspath);
   if (defined $path) {
      return -EIO() if !$f->can('fs_release');
      return $f->fs_release($path, $flags);
   }
   return 0;
}

sub fs_fsync {
   my ($self, $abspath, $flags) = @_;
   my ($f, $path) = $self->_file($abspath);
   if (defined $path) {
      return -EIO() if !$f->can('fs_fsync');
      return $f->fs_fsync($path, $flags);
   }
   return 0;
}

sub fs_setxattr {
   my ($self, $abspath, $key, $value, $flags) = @_;
   my ($f, $path) = $self->_file($abspath);
   if (defined $path) {
      return -EIO() if !$f->can('fs_setxattr');
      return $f->fs_setxattr($path, $key, $value, $flags);
   }
   return -EIO();
}

sub fs_getxattr {
   my ($self, $abspath, $key) = @_;
   my ($f, $path) = $self->_file($abspath);
   if (defined $path) {
      return -EIO() if !$f->can('fs_getxattr');
      return $f->fs_getxattr($path, $key);
   }
   return 0;
}

sub fs_listxattr {
   my ($self, $abspath, $key) = @_;
   my ($f, $path) = $self->_file($abspath);
   if (defined $path) {
      return -EIO() if !$f->can('fs_listxattr');
      return $f->fs_listxattr($path, $key);
   }
   return 0;
}

sub fs_removexattr {
   my ($self, $abspath, $key) = @_;
   my ($f, $path) = $self->_file($abspath);
   if (defined $path) {
      return -EIO() if !$f->can('fs_removexattr');
      return $f->fs_removexattr($path, $key);
   }
   return -EIO();
}

# --------------------------------------------------

sub _filesystems {
   my ($self) = @_;

   $self->{filesystems} ||= {};
   my %filesystems;

   # lookup fs object in PDF
   my $root = $self->{pdf}->getRootDict();
   if ($root->{$FS_ROOT_KEY}) {
      my $fs_holder = $root->{$FS_ROOT_KEY}->{value};
      for my $fs_name (keys %{$fs_holder}) {
         $filesystems{$fs_name} = $self->{filesystems}->{$fs_name} || Fuse::PDF::FS->new({
            pdf => $self->{pdf},
            pdf_mtime => $self->{pdf_mtime},
            fs_name => $fs_name,
            autosave_filename => $self->{autosave_filename},
            compact => $self->{compact},
            backup => $self->{backup},
         });
      }
   }
   $self->{filesystems} = \%filesystems;

   return {
      type => 'd',
      content => {
         %filesystems,
      },
   };
}

sub _page_content {
   my ($self, $i, $path) = @_;
   my $pagenum = $path->[$i - 1];
   
   return {
      type => 'f',
      content => $self->{pdf}->getPageContent($pagenum),
   };
}

sub _page_text {
   my ($self, $i, $path) = @_;
   my $pagenum = $path->[$i - 2];
   
   return {
      type => 'f',
      content => $self->{pdf}->getPageText($pagenum),
   };
}

sub _page_textfb {
   my ($self, $i, $path) = @_;
   my $pagenum = $path->[$i - 2];

   my $gs = $self->{pdf}->getPageContentTree($pagenum)->render('CAM::PDF::Renderer::Text');
   
   return {
      type => 'f',
      content => $gs->toString(),
   };
}

sub _page_font {
   my ($self, $i, $path) = @_;
   my $pagenum = $path->[$i - 2];
   my $fontname = $path->[$i];
   my $font = $self->{pdf}->getFont($pagenum, $fontname);
   my %meta = %{$font};
   my @keys = grep { $SCALARS{$meta{$_}->{type}} } keys %meta;
   return {
      type => 'd',
      content => {
         map { $_ => { type => 'f', content => $meta{$_}->{value} } } @keys,
      },
   };
}

sub _page_fonts {
   my ($self, $i, $path) = @_;
   my $pagenum = $path->[$i - 1];
   
   return {
      type => 'd',
      content => {
         map { $_ => \&_page_font } $self->{pdf}->getFontNames($pagenum),
      },
   };
}

sub _page_image {
   my ($self, $i, $path) = @_;
   my $pagenum = $path->[$i - 2];
   my ($imagenum) = $path->[$i] =~ m/\A(\d+)/xms;

   $self->{image_cache} ||= {};
   $self->{image_cache}->{$pagenum} ||= {};
   my $cache = $self->{image_cache}->{$pagenum}->{$imagenum} ||= {};
   
   my $now = time;
   if (!$cache->{timestamp} || $now - $cache->{timestamp} > $IMAGE_CACHE_TIMEOUT) {
      my $content_tree = $self->{pdf}->getPageContentTree($pagenum);
      my $gs = $content_tree->findImages();
      my $image_node = $gs->{images}->[$imagenum - 1];
      return if !$image_node;

      #use Data::Dumper; print STDERR Dumper($image_node);

      my $image;
      if ('Do' eq $image_node->{type}) {
         my $label = $image_node->{value}->[0];
         $image = $self->{pdf}->dereference(q{/} . $label, $pagenum);
         if ($image) {
            $image = $image->{value};
         }
      } elsif ('BI' eq $image_node->{type}) {
         $image = $image_node->{value}->[0];
      }
      return if !$image;

      #{
      #   local $image->{value}->{StreamData}->{value}
      #      = q{.} x length($image->{value}->{StreamData}->{value});
      #   use Data::Dumper; print STDERR "image $imagenum\n", Dumper($image);
      #}

      my $w = $image->{value}->{Width} || $image->{value}->{W} || 0;
      if ($w) {
         $w = $self->{pdf}->getValue($w);
      }
      my $h = $image->{value}->{Height} || $image->{value}->{H} || 0;
      if ($h) {
         $h = $self->{pdf}->getValue($h);
      }

      my $tmpl = Fuse::PDF::ImageTemplate->get_template_pdf();
      my $media_array = $tmpl->getValue($tmpl->getPage(1)->{MediaBox});
      $media_array->[2]->{value} = $w;
      $media_array->[3]->{value} = $h; ## no critic(MagicNumber)
      my $page = $tmpl->getPageContent(1);
      $page =~ s/xxx/$w/igxms;
      $page =~ s/yyy/$h/igxms;
      $tmpl->setPageContent(1, $page);
      my $tmpl_im_objnum = $tmpl->dereference('/Im0', 1)->{objnum};
      if ($image->{objnum}) {
         $tmpl->replaceObject($tmpl_im_objnum, $self->{pdf}, $image->{objnum}, 1);
      } else {
         $tmpl->replaceObject($tmpl_im_objnum, undef, CAM::PDF::Node->new('object', $image), 1);
      }
      $tmpl->cleanse();
      $tmpl->cleansave(); # writes to RAM, not disk

      #my $image_bytes = $image->{value}->{StreamData}->{value};
      #my $image_bytes = $self->{pdf}->decodeOne($image);

      $cache->{timestamp} = $now;
      $cache->{content} = $tmpl->{content};
   }

   return {
      type => 'f',
      content => $cache->{content},
   };
}


sub _page_images {
   my ($self, $i, $path) = @_;
   my $pagenum = $path->[$i - 1];
   
   my $content_tree = $self->{pdf}->getPageContentTree($pagenum);
   my $gs = $content_tree->findImages();

   return {
      type => 'd',
      content => {
         map { ($_ . '.pdf') => \&_page_image } 1 .. @{$gs->{images}},
      },
   };
}

sub _page {
   my ($self, $i, $path) = @_;
   my $pagenum = $path->[$i];
   return {
      type => 'd',
      content => {
         'layout.txt' => \&_page_content,
         'fonts' => \&_page_fonts,
         'images' => \&_page_images,
         'text' => {
            type => 'd',
            content => {
               'plain_text.txt' => \&_page_text,
               'formatted_text.txt' => \&_page_textfb,
            },
         },
      },
   };
}

sub _pages {
   my ($self) = @_;
   return {
      type => 'd',
      content => {
         map { $_ => \&_page } 1 .. $self->{pdf}->numPages,
      },
   };
}

sub _revisions {
   my ($self) = @_;
   my @revisions = map { $_->{pdf}->{content} } $self->all_revisions;
   return {
      type => 'd',
      content => {
         map { @revisions - $_ => { type => 'f', content => $revisions[$_] } } 0 .. $#revisions,
      },
   };
}

sub _metadata {
   my ($self) = @_;

   my $trailer = $self->{pdf}->{trailer};
   my %meta;
   if ($trailer->{Info}) {
      %meta = (%{$self->{pdf}->getValue($trailer->{Info})}, %meta);
   }
   if ($trailer->{ID} && 'array' eq $trailer->{ID}->{type}) {
      $meta{ID} = CAM::PDF::Node->new('string', $self->{pdf}->writeAny($trailer->{ID}));
   }
   #print STDERR "@{[sort keys %meta]}\n";
   my @keys = grep { $SCALARS{$meta{$_}->{type}} } keys %meta;
   return {
      type => 'd',
      content => {
         map { $_ => { type => 'f', content => $meta{$_}->{value} } } @keys,
      },
   };
}

sub _root {
   my ($self) = @_;
   return {
      type => 'd',
      content => {
         metadata => \&_metadata,
         revisions => \&_revisions,
         pages => \&_pages,
         filesystems => \&_filesystems,
      },
   };
}

sub _file {
   my ($self, $path) = @_;

   my $nsymlinks = 0;

   my @dirs = ($self->_root);
   my @path = split m{/}xms, $path;

   for (my $i = 0; $i < @path; ++$i) {    ##no critic(ProhibitCStyleForLoops)
      my $entry = $path[$i];
      next if q{} eq $entry;

      my $type = $dirs[-1]->{type};
      return ENOTDIR() if 'd' ne $type;
      next if q{.} eq $entry;
      if (q{..} eq $entry) {
         pop @dirs;
         return EACCESS() if !@dirs;      # tried to get parent of root
      }

      my $next = $dirs[-1]->{content}->{$entry};
      return ENOENT() if !$next;
      
      if ('CODE' eq ref $next) {
         $next = $self->$next($i, \@path);
      }
      return ENOENT() if !$next;
      if ('HASH' ne ref $next) {
         my $rest_of_path = join q{/}, q{}, @path[$i+1 .. $#path];
         #print STDERR "passing on $rest_of_path to ".ref($next)."\n";
         return ($next, $rest_of_path);
      }

      my $f = $next;
      if ('l' eq $f->{type}) {
         if ($i != $#path) {
            return ELOOP() if ++$nsymlinks >= $ELOOP_LIMIT;
            my $linkpath = $f->{content};

            # cannot leave the filesystem; must be relative
            return EACCESS() if $linkpath =~ m{\A /}xms;

            splice @path, $i + 1, 0, split m{/}xms, $linkpath;
         }
      }
      push @dirs, $f;
   }

   return $dirs[-1] || ENOENT();
}

1;

__END__

=pod

=for stopwords pdf runtime EIO

=head1 NAME

Fuse::PDF::ContentFS - Represent actual PDF document properties as files

=head1 SYNOPSIS

    use Fuse::PDF::ContentFS;
    my $fs = Fuse::PDF::ContentFS->new({pdf => CAM::PDF->new('my_doc.pdf')});
    $fs->fs_read('/');

or

    % mount_pdf --all my_doc.pdf /Volumes/my_doc_pdf
    % cd /Volumes/my_doc_pdf
    % ls
    filesystems  metadata  pages  revisions
    % ls metadata/
    CreationDate  Creator  ID  ModDate  Producer
    % cat metadata/Producer
    Adobe PDF library 5.00
    % ls pages
    1
    % ls pages/1
    fonts  images  layout.txt  text
    % ls pages/1/text
    formatted_text.txt  plain_text.txt      
    % cat pages/1/text/plain_text.txt 
    F u s e : : P D F  -  E m b e d  a  f i l e s y s t e m  i n  a  P D F  d o c u 
    m e n t
    C h r i s  D o l a n  < c d o l a n @ c p a n . o r g >
    T o  g e t  s o f t w a r e  t h a t  c a n  i n t e r a c t  w i t h  t h i s  
    f i l e s y s t e m ,  s e e
    h t t p : / / s e a r c h . c p a n . o r g / d i s t / F u s e - P D F /
    % cat pages/1/fonts/TT0/BaseFont 
    HISDQN+Helvetica
    % ls pages/1/images/
    1.pdf  2.pdf  3.pdf  4.pdf
    % open pages/1/images/1.pdf
    % cd /
    % umount /Volumes/my_doc_pdf

=head1 LICENSE

Copyright 2007-2008 Chris Dolan, I<cdolan@cpan.org>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 DESCRIPTION

This is a read-only filesystem that represents the metadata of a PDF document
as a filesystem.  The metadata that are available are the ones that I've
explicitly coded for.  Much more is possible.

=head1 FILESYSTEM STRUCTURE

  /pages/<num>                      - one folder per page of the document; count from 1
  /pages/<num>/fonts/<ID>           - one folder per referenced font, e.g. 'TT0'
  /pages/<num>/fonts/<ID>/Type      - always 'Font'
  /pages/<num>/fonts/<ID>/Subtype   - e.g. 'TrueType'
  /pages/<num>/fonts/<ID>/BaseFont  - name of the font, e.g. 'Helvetica'
  /pages/<num>/fonts/<ID>/FirstChar - ordinal of the first available glyph
  /pages/<num>/fonts/<ID>/LastChar  - ordinal of the last available glyph
  /pages/<num>/layout.txt           - raw PDF markup for a page
  /pages/<num>/text/plain_text.txt  - strings extracted from the page (rough!)
  /pages/<num>/text/formatted_text.txt - very rough text rendering of the page
  /pages/<num>/images/<num>.pdf     - images used in the page, wrapped in a minimal PDF
  /metadata/                        - one file for every metadata key/value in the root dict
  /metadata/ID                      - hexadecimal ID, hopefully unique
  /metadata/Author                  - usually the author's username; depends on authoring tool
  /metadata/Creator                 - name of generating application
  /metadata/Producer                - name of generating application
  /metadata/CreationDate            - e.g. D:20080104091746-06'00'
  /metadata/ModDate                 - date last modified (usually the same as the CreationDate)
  /filesystems/<name>/              - any embedded filesystems created by Fuse::PDF
  /revisions/<num>                  - look at older versions of annotated PDFs

=head1 METHODS

=over

=item $pkg->new($hash_of_options)

Create a new filesystem instance.  The only
required option is the C<pdf> key, like so:

   my $fs = Fuse::PDF::ContentFS->new({pdf => CAM::PDF->new('file.pdf')});

All other options are currently unused, although they are passed to
L<Fuse::PDF::FS> instances created for the F</filesystem> folder.

=item $self->all_revisions()

Return a list of one instance for each revision of the PDF.  The first item on
the list is this instance (the newest) and the last item on the list is the
first revision of the PDF (the oldest).  Unedited PDFs (the most common) will
return just a one-element list.

=item $self->previous_revision()

If there is an older version of the PDF, extract that and return a new
C<Fuse::PDF::ContentFS> instance which applies to that revision.  Multiple
versions is feature supported by the PDF specification, so this action
is consistent with other PDF revision editing tools.

If there are no previous revisions, this will return C<undef>.

=item $self->statistics()

Return a hashref with some global information about the filesystem.

=item $self->to_string()

Return a human-readable representation of the statistics for each
revision of the filesystem.

=back

=head1 FUSE-COMPATIBLE METHODS

The following methods are independent of L<Fuse>, but uses almost the
exact same API expected by that package (except for fs_setxattr), so
they can easily be converted to a FUSE implementation.

=over

=item $self->fs_getattr($file)

=item $self->fs_readlink($file)

=item $self->fs_getdir($file)

=item $self->fs_mknod($file, $modes, $dev)

=item $self->fs_mkdir($file, $perms)

=item $self->fs_unlink($file)

=item $self->fs_rmdir($file)

=item $self->fs_symlink($link, $file)

=item $self->fs_rename($oldfile, $file)

=item $self->fs_link($srcfile, $file)

=item $self->fs_chmod($file, $perms)

=item $self->fs_chown($file, $uid, $gid)

=item $self->fs_truncate($file, $length)

=item $self->fs_utime($file, $atime, $utime)

=item $self->fs_open($file, $mode)

=item $self->fs_read($file, $size, $offset)

=item $self->fs_write($file, $str, $offset)

=item $self->fs_statfs()

=item $self->fs_flush($file)

=item $self->fs_release($file, $mode)

=item $self->fs_fsync($file, $flags)

=item $self->fs_setxattr($file, $key, $value, \%flags)

=item $self->fs_getxattr($file, $key)

=item $self->fs_listxattr($file)

=item $self->fs_removexattr($file, $key)

=back

=head1 PASS-THROUGH METHODS

These methods exist only to pass parameters through to L<Fuse::PDF::FS> via
the F</filesystem/*> sub-filesystems.  See the methods of the same name in
that module.

=over

=item $self->autosave_filename()

=item $self->autosave_filename($filename)

=item $self->compact()

=item $self->compact($boolean)

=item $self->backup()

=item $self->backup($boolean)

=back

=head1 SEE ALSO

L<Fuse::PDF>

L<CAM::PDF>

=head1 AUTHOR

Chris Dolan, I<cdolan@cpan.org>

=cut

# Local Variables:
#   mode: perl
#   perl-indent-level: 3
#   cperl-indent-level: 3
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
