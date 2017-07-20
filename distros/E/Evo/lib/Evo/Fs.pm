package Evo::Fs;
use Evo '-Export *; -Class; ::Stat; -Path; Carp croak; -Path';
die "Win isn't supported yet. Pull requests are welcome!" if $^O eq 'MSWin32';

use Fcntl qw(:seek O_RDWR O_RDONLY O_WRONLY O_RDWR O_CREAT O_TRUNC O_APPEND O_EXCL :flock);
use Evo 'File::Spec; File::Path; Cwd() abs_path; File::Basename fileparse; Symbol()';
use Time::HiRes ();
use Evo 'List::Util first; File::Copy ()';
use Errno qw(EAGAIN EWOULDBLOCK);
use Scalar::Util;

sub SKIP_HIDDEN : Export : prototype() {
  sub($dir) {
    my @dirs = File::Spec->splitdir($dir);
    $dirs[-1] !~ /^\./;
  };
}


# ========= CLASS =========


has root =>
  check sub($v) { File::Spec->file_name_is_absolute($v) ? 1 : (0, "root should be absolute") };


sub cd ($self, $rel) {
  my $root = Evo::Path->from_string('', $self->root . '')->append_unsafe($rel)->to_string;
  ref($self)->new(root => $root);
}

sub path2real ($self, $rel) {
  Evo::Path->from_string($rel, $self->root . '')->to_string;
}

sub exists ($self, $path) {
  -e $self->path2real($path);
}


sub mkdir ($self, $path, $perm = undef) {
  my $real = $self->path2real($path);
  &CORE::mkdir($real, defined $perm ? $perm : ()) or croak "$real: $!";
}

sub make_tree ($self, $path, $perms = undef) {
  my $real = $self->path2real($path);
  my %opts = (error => \my $err);
  $opts{chmod} = $perms if defined $perms;
  File::Path::make_path($real, \%opts);
  croak join('; ', map { $_->%* } @$err) if @$err;    # TODO: test
}

sub symlink ($self, $to_path, $link_path) {
  CORE::symlink($self->path2real($to_path), $self->path2real($link_path))
    or croak "symlink $to_path $link_path: $!";
}

sub link ($self, $to_path, $link_path) {
  CORE::link($self->path2real($to_path), $self->path2real($link_path))
    or croak "hardlink $to_path $link_path: $!";
}

sub is_symlink ($self, $path) {
  -l $self->path2real($path);
}


sub utimes ($self, $path, $atime = undef, $mtime = undef) {
  my $real = $self->path2real($path);
  utime($atime // undef, $mtime // undef, $real) or croak "utimes $path: $!";
}

sub close ($self, $fh) {
  close $fh;
}

sub stat ($self, $path) {
  my %opts;
  my @stat = Time::HiRes::stat $self->path2real($path) or croak "stat $path: $!";
  @opts{qw(dev ino mode nlink uid gid rdev size atime mtime ctime blksize blocks)} = @stat;
  Evo::Fs::Stat->new(%opts, _data => \@stat);
}

sub rename ($self, $old, $new) {
  rename $self->path2real($old), $self->path2real($new) or croak "rename $!";
}


my %seek_map = (start => SEEK_SET, cur => SEEK_CUR, end => SEEK_END,);

my %open_map = (
  r    => O_RDONLY,
  'r+' => O_RDWR,

  w     => O_WRONLY | O_CREAT | O_TRUNC,
  wx    => O_WRONLY | O_CREAT | O_EXCL,
  'w+'  => O_RDWR | O_CREAT | O_TRUNC,
  'wx+' => O_RDWR | O_CREAT | O_EXCL,
  a     => O_WRONLY | O_CREAT | O_APPEND,
  ax    => O_WRONLY | O_CREAT | O_APPEND | O_EXCL,

  'a+'  => O_RDWR | O_CREAT | O_APPEND,
  'ax+' => O_RDWR | O_CREAT | O_APPEND | O_EXCL,
);

# self, fh, path, mode, perm?
sub sysopen ($, $, $, $, @) {
  croak "Bad mode $_[3]" unless exists $open_map{$_[3]};
  &CORE::sysopen($_[1], $_[0]->path2real($_[2]), $open_map{$_[3]}, (defined($_[4]) ? $_[4] : ()))
    or croak "sysopen: $!";
}


sub sysseek ($self, $fh, $pos, $whence = 'start') {
  croak "Bad whence $whence" unless exists $seek_map{$whence};
  &CORE::sysseek($fh, $pos, $seek_map{$whence}) // croak "Can't sysseek $!";
}

sub syswrite ($, $, $, @) {    # other lengh, scalar offset
  shift;
  &CORE::syswrite(@_) // croak "Can't write: $!";
}

sub sysread ($, $, $, $, @) {    # @other = string offset
  shift;
  &CORE::sysread(@_) // croak "Can't read: $!";
}

sub unlink ($self, $path) {
  unlink $self->path2real($path) or croak "$path $!";
}

sub remove_tree ($self, $path, $opts = {}) {
  my $real = $self->path2real($path);
  croak "remove_tree $real: Not a directory" unless $self->stat($path)->is_dir;
  File::Path::remove_tree($real, {%$opts, error => \my $err});
  croak join('; ', map { $_->%* } @$err) if @$err;    # TODO: test
}

sub ls ($self, $path) {
  my $real = $self->path2real($path);
  opendir(my $dh, $real) || croak "Can't opendir $real: $!";
  my @result = grep { $_ ne '.' && $_ ne '..' } readdir($dh);
  closedir $dh;
  @result;
}

my %flock_map = (
  ex    => LOCK_EX,
  ex_nb => LOCK_EX | LOCK_NB,
  sh    => LOCK_SH,
  sh_nb => LOCK_SH | LOCK_NB,
  un    => LOCK_UN
);


sub flock ($self, $fh, $flag) {
  croak "Bad flag $flag" unless exists $flock_map{$flag};
  my $res = flock($fh, $flock_map{$flag});
  croak "$!" unless $res || $! == EAGAIN || $! == EWOULDBLOCK;
  $res;
}

sub open ($self, $path, $mode, @rest) {
  $self->make_tree((fileparse($path))[1]) unless ($mode eq 'r' && $mode eq 'r+');
  $self->sysopen(my $fh, $path, $mode, @rest);
  $fh;
}


sub append ($self, $path, $) {
  my $fh = $self->open($path, 'a');
  $self->flock($fh, 'ex');
  $self->syswrite($fh, $_[2]);
  $self->flock($fh, 'un');
  CORE::close $fh;
  return;
}

# don't copy 3rd arg
sub write ($self, $path, $) {
  my $fh = $self->open($path, 'w');
  $self->flock($fh, 'ex');
  $self->syswrite($fh, $_[2]);
  $self->flock($fh, 'un');
  CORE::close $fh;
  return;
}

sub read_ref ($self, $path) {
  my $fh = $self->open($path, 'r');
  $self->flock($fh, 'sh');
  $self->sysread($fh, \my $buf, $self->stat($path)->size);
  $self->flock($fh, 'un');
  CORE::close $fh;
  \$buf;
}

sub read ($self, $path) {
  $self->read_ref($path)->$*;
}

sub write_many ($self, %map) {
  $self->write($_, $map{$_}) for keys %map;
  $self;
}

sub find_files ($self, $start, $fhs_fn, $pick = undef) {
  my %seen;
  my $fn = sub ($path) {
    my $stat = $self->stat($path);
    return unless $stat->is_file;
    $fhs_fn->($path);
  };
  $self->traverse($start, $fn, $pick);
}

# make faster?
sub traverse ($self, $start, $fn, $pick_d = undef) {

  $start = [$start] unless ref $start eq 'ARRAY';
  my %seen_dirs;        # don't go into the same dir twice
  my %seen_children;    # don't fire the same file twice

  my @stack = map { Evo::Path->new(base => $_); } map {
    my $path = $_;
    my $stat = $self->stat($path);
    $seen_dirs{($stat->dev, '-', $stat->ino)}++ ? () : ($path);
  } reverse $start->@*;

  while (@stack) {
    my $cur_dir = pop @stack;

    my (@dirs, @children);
    foreach my $cur_child (sort $self->ls($cur_dir)) {

      my $path = $cur_dir->append($cur_child);
      next unless $self->exists($path);    # broken link
      my $stat = $self->stat($path);


      my $bool
        = $stat->is_dir
        && $stat->can_exec
        && $stat->can_read
        && !$seen_dirs{$stat->dev, '-', $stat->ino}++
        && (!$pick_d || $pick_d->($path));

      unshift @dirs, $path if $bool;
      push @children, $path if !$seen_children{$stat->dev, '-', $stat->ino}++;

    }
    $fn->($_) for @children;
    push @stack, @dirs;
  }
}

my sub _copy_file ($self, $from, $to) {
  File::Copy::cp $self->path2real($from), $self->path2real($to) or die "Copy failed: $!";
}

sub copy_dir ($self, $from, $to) {
  $to = Evo::Path->new(base => $to);
  $self->make_tree($to);
  my @stack = ($from);
  while (@stack) {
    my $cur_dir = shift @stack;
    $self->traverse(
      $cur_dir,
      sub($path) {
        my $stat = $self->stat($path);
        my $dest = $to->append(join '/', $path->children->@*);
        if ($stat->is_dir) {
          $self->mkdir($dest) unless $self->exists($dest);
        }
        elsif ($stat->is_file) {
          _copy_file($self, $path, $dest);
        }

        #else { croak "Can't copy $path, not a dir neither a file"; }
      }
    );
  }
}

sub copy_file ($self, $from, $to) {
  $self->make_tree((fileparse($to))[1]);
  _copy_file($self, $from, $to);
}

# ========= MODULE =========

my $FSROOT = __PACKAGE__->new(root => '/');
sub FSROOT : Export {$FSROOT}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Evo::Fs

=head1 VERSION

version 0.0405

=head1 SYNOPSIS

  use Evo '-Fs; File::Basename fileparse';
  my $fs = Evo::Fs->new(root => '/tmp/testfs');

  say "/foo => ", $fs->path2real('/foo');
  say "foo => ",  $fs->path2real('/foo');    # the same

  my $fh = $fs->open('foo/bar.txt', 'w');    # open and create '/foo' if necessary
  $fs->close($fh);

  $fs->write('a/foo', 'one');                # /tmp/test/a/foo
  $fs->append('/a/foo', 'two');              # /tmp/test/a/foo
  say $fs->read('a/foo');                    # onetwo
  say $fs->read('/a/foo');                   # the same

  # bulk
  $fs->write_many('/a/foo' => 'afoo', '/b/foo' => 'bfoo');


  # copying
  $fs->write('/from/d/f' => 'OK');

  # copy file
  $fs->remove_tree('/to') if $fs->exists('/to');
  $fs->copy_file('/from/d/f' => '/to/d/f');
  say $fs->read('/to/d/f');    # OK

  # copy dir recursively
  $fs->remove_tree('/to') if $fs->exists('/to');
  $fs->copy_dir('/from' => '/to');
  say $fs->read('/to/d/f');    # OK

  $fs->sysopen($fh, '/c', 'w+');
  $fs->syswrite($fh, "123456");
  $fs->sysseek($fh, 0);
  $fs->sysread($fh, \my $buf, 3);
  say $buf;                                  # 123

  # traversing
  $fs->find_files(

    # where to start (/ => /tmp/testfs)
    '/',

    # do something with file
    sub ($path) {
      say $path;
    },

    # skip dirs like .git
    sub ($path) {
      scalar fileparse($path) !~ /^\./;
    }
  );

  $fs->find_files(
    ['/'],
    sub ($path) {
      say "FOUND: ", $path;
    }
  );

  # FSROOT
  use Evo::Fs 'FSROOT';
  say join ', ', FSROOT->ls('/');

=head1 DESCRIPTION

An abstraction url-like layer between file system and your application. Every path is relative to C<root>.

You wan't be able to do something like this:

  my $fs = Evo::Fs->new(root => '/tmp/fs');
  my $path = '../fs2/foo';
  $fs->write($path);

This is a security protection. But you can use L</cd> instead

  my $fs2 = $fs->cd('../fs2');
  $fs2->write('foo' => 'OK');

=head1 EXPORTS

=head2 FSROOT

Return a single instance of L<Evo::Fs> where root is C</>

=head1 ATTRIBUTES

=head2 root

  my $fs = Evo::Fs->new(root => '/tmp/test-root');

=head1 METHODS

=head2 cd

Create a new C<Evo::FS> instance. Also this is the only way to traverse up

  my $fs       = Evo::Fs->new(root => '/tmp/fs');
  my $fs2      = $fs->cd('../fs2');
  my $fs_child = $fs->cd('child');

=head2 copy_file($self, $from, $to)

Copy file, die if already exists

=head2 copy_dir($self, $from, $to)

Copy directory recursively, if directory C<$to>exists, replace it content, create it otherwise. And for the children do the same 

This functions kinda try to synchronize one path with another. Unlike C<cp -a>, 2 invocations of this functions will lead to the same result (C<cp> tries to check, if directory C<$to> exists and copies C<$from> to it in this case, this functions won't do this)

  my $fs = Evo::Fs->new(root => File::Temp->newdir);
  $fs->write('/base/child/file' => 'OK');
  $fs->make_tree('/copy/child'); # just to show that directory can exist
  $fs->copy_dir('/base', 'copy');
  say $fs->read('/copy/child/file'); # OK

In this example, directory C</copy/child> already exists, so a single file C</base/child/file> will be silenty copied to C</copy/child/file>

=head2 sysopen ($self, $path, $mode, $perm=...)

  my $fh = $fs->open('/foo/bar.txt', 'w');

Open a file and return a filehandle. Create parent directories if necessary.
 See L</sysopen> for list of modes

=head2 append, write, read, read_ref

  $fs->write('/tmp/my/file', 'foo');
  $fs->append('/tmp/my/file', 'bar');
  say $fs->read('/tmp/my/file');            # foobar
  say $fs->read_ref('/tmp/my/file')->$*;    # foobar

Read, write or append a content to the file. Dirs will be created if they don't exist.
Use lock 'ex' for append and write and lock 'sh' for read during each invocation

=head2 write_many

Write many files using L<write>

=head2 sysseek($self, $position, $whence='start')

Whence can be one of:

=for :list * start
* cur
* end

=head2 sysread ($self, $fh, $ref, $length[, $offset])

Call C<sysread> but accepts scalar reference for convinience

=head2 syswrite($self, $fh, $scalar, $length, $offset)

Call C<syswrite>

=head2 sysopen ($self, $fh, $path, $mode, $perm=...)

  $fs->sysopen(my $fh, '/tmp/foo', 'r');

Mode can be one of:

=for :list * r
Open file for reading. An exception occurs if the file does not exist.
* r+
Open file for reading and writing. An exception occurs if the file does not exist

* w
Open file for writing. The file is created (if it does not exist) or truncated (if it exists).
* wx
Like C<w> but fails if path exists.
* w+
Open file for reading and writing. The file is created (if it does not exist) or truncated (if it exists).
* wx+
Like C<w+> but fails if path exists.

* a
Open file for appending. The file is created if it does not exist.
* ax
Like C<a> but fails if path exists.
* a+
Open file for reading and appending. The file is created if it does not exist.
* ax+
Like C<a+> but fails if path exists.

=head2 rename($self, $oldpath, $newpath)

Rename a file.

=head2 stat($self, $path)

Return a L<Evo::Fs::Stat> object

=head2 path2real($virtual)

Convert a virtual path to the real one.

=head2 find_files($self, $dirs, $fn, $pick=undef)

  $fs->find_files('./tmp', sub ($fh) {...}, sub ($dir) {...});
  $fs->find_files(['/tmp'], sub ($fh) {...});

Find files in given directories. You can skip some directories by providing C<$pick-E<gt>($dir)> function.
This will work ok on circular links, hard links and so on. Every path will be passed to C<$fn-E<gt>($fh)>only once
even if it has many links.

So, in situations, when a file have several hard and symbolic links, only one of them will be passed to C<$fn>, and potentially
each time it can be different path for each C<find_files> invocation.

See L</traverse> for examining all nodes. This method just decorate it's arguments

=head3 SKIP_HIDDEN

You can also traverse all files, but ignore hidden directories, like ".git" this way:

  use Evo '-Fs FS SKIP_HIDDEN';
  FS->find_files('./', sub($path) { say $path; }, SKIP_HIDDEN)

=head2 traverse($self, $dirs, $fn, $pick=undef)

Traverse directories and invoke C<$fn-E<gt>$path> for each child node.

Each file is processed only once no matter how many links it has. So instead of a real filename you may be getting a link and never a real name depending on which one (file or link) was met first

You can provide C<$pick-E<gt>($dir)> to skip directories, for example, to skip hidden ones. By default all directories are processed

  $fs->traverse('/tmp', sub ($path) {...}, sub ($dir) {...});
  $fs->traverse(['/tmp'], sub ($path) {...},);

Also this method doesn't try to access directories without X and R permissions or pass them to C<$pick> (but such directories will be passed to C<fn> because are regular nodes)

In most cases you may want to use L</find_files> instead.

=head1 AUTHOR

alexbyk.com

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by alexbyk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
