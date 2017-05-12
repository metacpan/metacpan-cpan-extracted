package File::Fu::File;
$VERSION = v0.0.8;

use warnings;
use strict;
use Carp;

use IO::File ();

=head1 NAME

File::Fu::File - a filename object

=head1 SYNOPSIS

  use File::Fu;

  my $file = File::Fu->file("path/to/file");
  $file %= '.extension';
  $file->e and warn "$file exists";

  $file->l and warn "$file is a link to ", $file->readlink;

=cut

use base 'File::Fu::Base';

use Class::Accessor::Classy;
lv 'file';
ro 'dir';  aka dir  => 'dirname', 'parent';
no  Class::Accessor::Classy;

#use overload ();

=head1 Constructor

=head2 new

  my $file = File::Fu::File->new($path);

  my $file = File::Fu::File->new(@path);

=cut

sub new {
  my $package = shift;
  my $class = ref($package) || $package;
  my $self = {$class->_init(@_)};
  bless($self, $class);
  return($self);
} # end subroutine new definition
########################################################################

=head2 new_direct

  my $file = File::Fu::File->new_direct(
    dir => $dir_obj,
    file => $name
  );

=cut

sub new_direct {
  my $package = shift;
  my $class = ref($package) || $package;
  my $self = {@_};
  bless($self, $class);
  return($self);
} # end subroutine new_direct definition
########################################################################

=head1 Class Constants

=head2 dir_class

Return the corresponding dir class for this file object.  Default:
L<File::Fu::Dir>.

  my $dc = $class->dir_class;

=head2 is_dir

Always false for a file.

=head2 is_file

Always true for a file.

=cut

use constant dir_class => 'File::Fu::Dir';
use constant is_dir => 0;
use constant is_file => 1;

########################################################################

=for internal head2 _init
  my %fields = $class->_init(@_);

=cut

sub _init {
  my $class = shift;
  my @dirs = @_ or croak("file must have a name");
  my $file = pop(@dirs);
  if($file =~ m#/#) {
    croak("strange mix: ", join(',', @_, $file)) if(@dirs);
    my %p = $class->dir_class->_init($file);
    @dirs = @{$p{dirs}};
    $file = pop(@dirs);
  }

  return(dir => $class->dir_class->new(@dirs), file => $file);
} # end subroutine _init definition
########################################################################

=head1 Parts

=head2 basename

Returns a new object representing only the file part of the name.

  my $obj = $file->basename;

=cut

sub basename {
  my $self = shift;
  $self->new($self->file);
} # end subroutine basename definition
########################################################################

=head1 Methods

=head2 stringify

  my $string = $file->stringify;

=cut

sub stringify {
  my $self = shift;
  my $dir = $self->dir;
  #warn "stringify(..., $_[1], $_[2])";
  #Carp::carp("stringify ", overload::StrVal($self), " ($self->{file})");
  $dir = $dir->is_cwd ? '' : $dir->stringify;
  return($dir . $self->file);
} # end subroutine stringify definition
########################################################################

=head2 append

Append a string only to the filename part.

  $file->append('.gz');

  $file %= '.gz';

(Yeah... I tried to use .=, but overloading hates me.)

=cut

sub append {
  my $self = shift;
  my ($tail) = @_;
  $self->file .= $tail;
  $self;
} # end subroutine append definition
########################################################################

=head2 map

  $file->map(sub {...});

  $file &= sub {...};

=cut

sub map :method {
  my $self = shift;
  my ($sub) = shift;
  local $_ = $self->file;
  $sub->();
  $self->file = $_;
  $self;
} # end subroutine map definition
########################################################################

=head2 absolute

Get an absolute name (without checking the filesystem.)

  my $abs = $file->absolute;

=cut

sub absolute {
  my ($self) = shift;
  return($self->dir->absolute->file($self->file));
} # end subroutine absolutely definition
########################################################################

=head2 absolutely

Get an absolute name (resolved on the filesytem.)

  my $abs = $file->absolutely;

=cut

sub absolutely {
  my $self = shift;
  return($self->dir->absolutely->file($self->file));
} # end subroutine absolutely definition
########################################################################

=head1 Doing stuff

=head2 open

Open the file with $mode ('<', 'r', '>', 'w', etc) -- see L<IO::File>.

  my $fh = $file->open($mode, $permissions);

Throws an error if anything goes wrong or if the resulting filehandle
happens to be a directory.

=cut

# TODO should probably have our own filehandle so we can close in the
# destructor and croak there too?

sub open :method {
  my $self = shift;
  my $fh = IO::File->new($self, @_) or croak("cannot open '$self' $!");
  -d $fh and croak("$self is a directory");
  return($fh);
} # end subroutine open definition
########################################################################


=head2 sysopen

Interface to the sysopen() builtin.  The value of $mode is a text string
joined by '|' characters which must be valid O_* constants from Fcntl.

  my $fh = $file->sysopen($mode, $perms);

=cut

sub sysopen :method {
  my $self = shift;
  my ($mode, $perms) = @_;
  my $m = 0;
  foreach my $w (split /\|/, $mode) {
    my $word = 'O_' . uc($w);
    my $x = Fcntl->can($word) or croak("'$word' not found in Fcntl");
    $m |= $x->();
  }

  my $fh = IO::Handle->new;
  sysopen($fh, "$self", $m, $perms || 0666)
    or croak("error on sysopen '$self' - $!");

  return($fh);
} # sysopen ############################################################

=head2 piped_open

Opens a read pipe.  The file is appended to @command.

  my $fh = $file->piped_open(@command);

Example: useless use of cat.

  my $fh = $file->piped_open('cat');

This interface is deprecated (maybe) because it is limited to commands
which take the $file as the last argument.  See run() for the way of the
future.

=cut

sub piped_open {
  my $self = shift;
  my (@command) = @_;

  # TODO some way to decide where self goes in @command
  push(@command, $self);

  # TODO closing STDIN and such before the fork?

  # TODO here is where we need our own filehandle object again
  my $pid = open(my $fh, '-|', @command) or
    croak("cannot exec '@command' $!");
  return($fh);
} # end subroutine piped_open definition
########################################################################

=head2 run

Treat C<$file> as a program and execute a pipe open.

  my $fh = $file->run(@args);

If called in void context, runs C<system()> with autodie semantics and
multi-arg form (suppresses shell interpolation.)

  $file->run(@args);

No special treatment is made for whether $file is relative or not (the
underlying C<system()>/C<exec()> will search your path.)  Use
File::Fu->which() to get an absolute path beforehand.

  File::Fu->which('ls')->run('-l');

=cut

sub run {
  my $self = shift;
  my (@args) = @_;

  if(defined wantarray) {
    # TODO use IPC::Run
    my $fh = IO::Handle->new;
    my @command = ($self, @args);
    my $pid = open($fh, '-|', @command) or
      croak("cannot exec '@command' $!");
    return($fh);
  }
  else {
    my $ret = system {$self} $self, @args;
    croak("error executing '$self'", $ret < 0 ? " $!" : '') if($ret);
  }
} # run ################################################################

=head2 touch

Update the timestamp of a file (or create it.)

  $file->touch;

=cut

sub touch {
  my $self = shift;
  if(-e $self) {
    $self->utime(time);
  }
  else {
    $self->open('>');
  }
  return($self);
} # end subroutine touch definition
########################################################################

=head2 mkfifo

  my $file = $file->mkfifo($mode);

=cut

sub mkfifo :method {
  my $self = shift;
  my ($mode) = @_;

  $mode ||= 0700;
  require POSIX;
  POSIX::mkfifo("$self", $mode) or croak("mkfifo '$self' failed $!");

  return $self;
} # mkfifo #############################################################

=head2 link

  my $link = $file->link($name);

=cut

sub link :method {
  my $self = shift;
  my ($name) = @_;
  link($self, $name) or croak("link '$self' to '$name' failed $!");
  return($self->new($name));
} # end subroutine link definition
########################################################################

=head2 symlink

  my $link = $file->symlink($linkname);

Note that symlinks are relative to where they live.

  my $dir = File::Fu->dir("foo");
  my $file = $dir+'file';
  # $file->symlink($dir+'link'); is a broken link
  my $link = $file->basename->symlink($dir+'link');

=head2 relative_symlink

See L<File::Fu::Base/relative_symlink>.

=cut

sub symlink :method {
  my $self = shift;
  my ($name) = @_;
  symlink($self, $name) or
    croak("symlink '$self' to '$name' failed $!");
  return($self->new($name));
} # end subroutine symlink definition
########################################################################

# TODO
# my $link = $file->dwimlink(absolute|relative|samedir => $linkname);

=head2 unlink

  $file->unlink;

=cut

sub unlink :method {
  my $self = shift;
  unlink("$self") or croak("unlink '$self' failed $!");
} # end subroutine unlink definition
########################################################################

=head2 remove

A forced unlink (chmod the file if it is not writable.)

  $file->remove;

=cut

sub remove {
  my $self = shift;

  $self->chmod(0200)  unless($self->w);
  $self->unlink;
} # remove #############################################################

=head2 readlink

  my $to = $file->readlink;

=cut

sub readlink :method {
  my $self = shift;
  my $name = readlink($self);
  defined($name) or croak("cannot readlink '$self' $!");
  return($self->new($name));
} # end subroutine readlink definition
########################################################################

########################################################################
{ # a closure for this variable
my $has_slurp;

=head2 read

Read the entire file into memory (or swap!)

  my @lines = $file->read;

  my $file = $file->read;

If File::Slurp is available, options to read_file will be passed along.
See L<File::Slurp/read_file>.

=cut

sub read :method {
  my $self = shift;
  my @args = @_;

  $has_slurp ||= eval {require File::Slurp; 1} || -1;

  if($has_slurp > 0) {
    local $Carp::CarpLevel = 1;
    return(File::Slurp::read_file("$self", @args, err_mode => 'croak'));
  }
  else {
    croak("must have File::Slurp for fancy reads") if(@args);

    my $fh = $self->open;
    local $/ = wantarray ? $/ : undef;
    return(<$fh>);
  }
} # end subroutine read definition
########################################################################

=head2 write

Write the file's contents.  Returns the $file object for chaining.

  $file = $file->write($content);

If File::Slurp is available, $content may be either a scalar, scalar
ref, or array ref.

  $file->write($content, %args);

=cut

sub write {
  my $self = shift;
  my ($content, @args) = @_;

  $has_slurp ||= eval {require File::Slurp; 1} || -1;

  if($has_slurp > 0) {
    local $Carp::CarpLevel = 1;
    File::Slurp::write_file("$self",
      {@args, err_mode => 'croak'},
      $content
    );
  }
  else {
    croak("must have File::Slurp for fancy writes")
      if(@args or ref($content));
    my $fh = $self->open('>');
    print $fh $content;
    close($fh) or croak("write '$self' failed: $!");
  }

  return $self;
} # end subroutine write definition
########################################################################
} # File::Slurp closure
########################################################################

=head2 copy

Copies $file to $dest (which can be a file or directory) and returns the
name of the new file as an object.

  my $new = $file->copy($dest);

Note that if $dest is already a File object, that existing object will
be returned.

=cut

sub copy {
  my $self = shift;
  my ($dest) = shift;
  my (%opts) = @_;

  # decide if this is file-to-dir or file-to-file
  if(-d $dest) {
    $dest = $self->dir_class->new($dest)->file($self->basename);
  }
  else {
    $dest = $self->new($dest) unless(ref($dest));
  }
  if($dest->e) {
    croak("'$dest' and '$self' are the same file")
      if($self->is_same($dest));
  }

  # TODO here's another good reason to have our own filehandle object:
  # This fh-copy should be in there.
  my $ifh = $self->open;
  my $ofh = $dest->open('>');
  binmode($_) for($ifh, $ofh);
  while(1) {
    my $buf;
    defined(my $r = sysread($ifh, $buf, 1024)) or
      croak("sysread failed $!");
    $r or last;
    # why did File::Copy::copy do it like this?
    for(my $t = my $w = 0; $w < $r; $w += $t) {
      $t = syswrite($ofh, $buf, $r - $w, $w) or
        croak("syswrite failed $!");
    }
  }
  close($ofh) or croak("write '$dest' failed: $!");
  # TODO some form of rollback?

  # TODO handle opts
  #if($opts{preserve}) {
  #  # TODO chmod/chown and such
  #  $dest->utime($self->stat->mtime);
  #}

  return($dest);
} # copy ###############################################################

=head2 move

  my $new = $file->move($dest);

=cut

sub move {
  my $self = shift;
  my $new = $self->copy(@_); # TODO can use rename?
  $self->unlink;
  return($new);
} # move ###############################################################

########################################################################

=head1 AUTHOR

Eric Wilhelm @ <ewilhelm at cpan dot org>

http://scratchcomputing.com/

=head1 BUGS

If you found this module on CPAN, please report any bugs or feature
requests through the web interface at L<http://rt.cpan.org>.  I will be
notified, and then you'll automatically be notified of progress on your
bug as I make changes.

If you pulled this development version from my /svn/, please contact me
directly.

=head1 COPYRIGHT

Copyright (C) 2008 Eric L. Wilhelm, All Rights Reserved.

=head1 NO WARRANTY

Absolutely, positively NO WARRANTY, neither express or implied, is
offered with this software.  You use this software at your own risk.  In
case of loss, no person or entity owes you anything whatsoever.  You
have been warned.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

require File::Fu;
# vi:ts=2:sw=2:et:sta
1;
