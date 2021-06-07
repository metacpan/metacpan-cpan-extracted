package FFI::C::Stat;

use strict;
use warnings;
use 5.008004;
use Ref::Util qw( is_ref is_globref is_blessed_ref );
use Carp ();
use FFI::Platypus 1.00;

# ABSTRACT: Object-oriented FFI interface to native stat and lstat
our $VERSION = '0.02'; # VERSION


my $ffi = FFI::Platypus->new( api => 1 );
$ffi->bundle;      # for accessors / constructor / destructor

$ffi->type('object(FFI::C::Stat)', 'stat');
if($^O eq 'MSWin32')
{
  $ffi->type('uint' => $_) for qw( uid_t gid_t nlink_t blksize_t blkcnt_t );
}

$ffi->mangler(sub { "stat__$_[0]" });

$ffi->attach( '_stat'  => ['string'] => 'opaque' );
$ffi->attach( '_fstat' => ['int',  ] => 'opaque' );
$ffi->attach( '_lstat' => ['string'] => 'opaque' );


sub new
{
  my($class, $file, %options) = @_;

  my $ptr;
  if(is_globref $file)
  { $ptr = _fstat(fileno($file)) }
  elsif(!is_ref($file) && defined $file)
  { $ptr = $options{symlink} ? _lstat($file) : _stat($file) }
  else
  { Carp::croak("Tried to stat something whch is neither a glob reference nor a plain string") }

  bless \$ptr, $class;
}


$ffi->attach( clone => ['opaque'] => 'opaque' => sub {
  my($xsub, $class, $other) = @_;

  my $ptr;
  if(is_blessed_ref $other)
  {
    if($other->isa('FFI::C::Stat'))
    {
      $ptr = $xsub->($$other);
    }
    else
    {
      Carp::croak("Not a FFI::C::Struct instance");
    }
  }
  elsif(!is_ref $other)
  {
    $ptr = $xsub->($other);
  }
  else
  {
    Carp::croak("Not an FFI::C::Struct structure or opaque pointer");
  }

  bless \$ptr, $class;
});

$ffi->attach( DESTROY => ['stat'] );


$ffi->attach( dev     => ['stat'] => 'dev_t'     );
$ffi->attach( ino     => ['stat'] => 'ino_t'     );
$ffi->attach( mode    => ['stat'] => 'mode_t'    );
$ffi->attach( nlink   => ['stat'] => 'nlink_t'   );
$ffi->attach( uid     => ['stat'] => 'uid_t'     );
$ffi->attach( gid     => ['stat'] => 'gid_t'     );
$ffi->attach( rdev    => ['stat'] => 'dev_t'     );
$ffi->attach( size    => ['stat'] => 'off_t'     );
$ffi->attach( atime   => ['stat'] => 'time_t'    );
$ffi->attach( mtime   => ['stat'] => 'time_t'    );
$ffi->attach( ctime   => ['stat'] => 'time_t'    );

if($^O ne 'MSWin32')
{
  $ffi->attach( blksize => ['stat'] => 'blksize_t' );
  $ffi->attach( blocks  => ['stat'] => 'blkcnt_t'  );
}
else
{
  *blksize = sub { '' };
  *blocks  = sub { '' };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

FFI::C::Stat - Object-oriented FFI interface to native stat and lstat

=head1 VERSION

version 0.02

=head1 SYNOPSIS

 use FFI::C::Stat;
 
 my $stat = FFI::C::Stat->new("foo.txt");
 print "size = ", $stat->size;

=head1 DESCRIPTION

Perl comes with perfectly good C<stat>, C<lstat> functions, however if you are writing
FFI bindings for a library that use the C C<stat> structure, you are out of luck there.
This module provides an FFI friendly interface to the C C<stat> function, which uses
an object similar to L<File::stat>, except the internals are a real C C<struct> that
you can pass into C APIs that need it.

Supposing you have a C function:

 void
 my_cfunction(struct stat *s)
 {
   ...
 }

You can bind C<my_cfunction> like this:

 use FFI::Platypus 1.00;
 
 my $ffi = FFI::Platypus->new( api => 1 );
 $ffi->type('object(FFI::C::Stat)' => 'stat');
 $ffi->attach( my_cfunction => ['stat'] => 'void' );

=head1 CONSTRUCTORS

=head2 new

 my $stat = FFI::C::Stat->new(*HANDLE,   %options);
 my $stat = FFI::C::Stat->new($filename, %options);

You can create a new instance of this class by calling the new method and passing in
either a file or directory handle, or by passing in the filename path.

Options:

=over 4

=item symlink

Use C<lstat> instead of C<stat>, that is if the filename is a symlink, C<stat> the
symlink instead of the target.

=back

=head2 clone

 my $stat = FFI::C::Stat->clone($other_stat);

Creates a clone of C<$stat>.  The argument C<$stat> can be either a L<FFI::C::Stat> instance,
or an opaque pointer to a C<stat> structure.  The latter case is helpful when writing bindings
to a method that returns a C<stat> structure, since you won't be wanting to free the pointer
that belongs to the callee.

C:

 struct stat *
 my_cfunction()
 {
   static struct stat stat;  /* definitely do not want to free static memory */
   ...
   return stat;
 }

Perl:

 $ffi->attach( my_cfunction => [] => 'opaque' => sub {
   my $xsub = shift;
   my $ptr = $xsub->();
   return FFI::C::Stat->clone($ptr);
 });

=head1 PROPERTIES

=head2 dev

 my $id = $stat->dev;

The ID of device containing file.

=head2 ino

 my $inode = $stat->ino;

The inode number.

=head2 mode

 my $mode = $stat->mode;

The file type and mode.

=head2 nlink

 my $n = $stat->nlink;

The number of hard links.

=head2 uid

 my $uid = $stat->uid;

The User ID owner.

=head2 gid

 my $gid = $stat->gid;

The Group ID owner.

=head2 rdev

 my $id = $stat->rdev;

The ID of device (if special file)

=head2 size

 my $size = $stat->size;

Returns the size of the file in bytes.

=head2 atime

 my $time = $stat->atime;

The time of last access.

=head2 mtime

 my $time = $stat->mtime;

The time of last modification.

=head2 ctime

 my $time = $stat->ctime;

The time of last status change.

=head2 blksize

 my $size = $stat->blksize;

The filesystem-specific  preferred I/O block size.

=head2 blocks

 my $count = $stat->blocks;

Number of blocks allocated.

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
