package FFI::C::File;

use strict;
use warnings;
use Carp qw( croak );
use FFI::Platypus 1.00;
use base qw( Exporter );

our @EXPORT_OK = qw( SEEK_SET SEEK_CUR SEEK_END );

# ABSTRACT: Perl interface to C File pointer
our $VERSION = '0.12'; # VERSION


our $ffi = FFI::Platypus->new( api => 1, lib => [undef] );
$ffi->type( 'object(FFI::C::File)' => 'FILE' );
$ffi->load_custom_type('::Enum', 'whence',
  { package => 'FFI::C::File', prefix => 'SEEK_', type => 'int' },
  'set',
  'cur',
  'end',
);


$ffi->attach( fopen => [ 'string', 'string' ] => 'opaque' => sub {
  my($xsub, $class, $filename, $mode) = @_;
  my $ptr = $xsub->($filename, $mode);
  unless(defined $ptr)
  {
    croak "Error opening $filename with mode $mode: $!";
  }
  bless \$ptr, $class;
});


$ffi->attach( tmpfile => [] => 'opaque' => sub {
  my($xsub, $class) = @_;
  if(my $ptr = $xsub->())
  {
    return bless \$ptr, $class;
  }
  else
  {
    croak "Error opening temp file: $!"
  }
});


sub new
{
  my($class, $ptr) = @_;
  bless \$ptr, $class;
}


$ffi->attach( freopen => ['string','string','FILE'] => 'opaque' => sub {
  my($xsub, $self, $filename, $mode) = @_;
  if(my $ptr = $xsub->($filename, $mode, $self))
  {
    $$self = $ptr;
  }
  else
  {
    $$self = undef;
    $filename = 'undef' unless defined $filename;
    croak "Error opening $filename with mode $mode: $!";
  }
});


sub _read_write_wrapper
{
  my($xsub, $self, $buffer, $size) = @_;
  $self->clearerr;
  my $ret = $xsub->($$buffer, 1, $size, $self);
  if($ret != $size)
  {
    if(my $error = $self->ferror)
    {
      croak "File error: $!";
    }
  }
  return $ret;
}

$ffi->attach( fread => ['string', 'size_t', 'size_t', 'FILE'] => 'size_t' => \&_read_write_wrapper );


$ffi->attach( fwrite => ['string', 'size_t', 'size_t', 'FILE'] => 'size_t' => \&_read_write_wrapper );


$ffi->attach( fseek => ['FILE', 'long', 'whence'] => 'int', sub {
  my $xsub = shift;
  $xsub->(@_) and croak "Error seeking file: $!";
});


$ffi->attach( ftell => ['FILE'] => 'long' );


$ffi->attach( rewind => ['FILE'] );


$ffi->attach( fflush => ['FILE'] => 'int' => sub {
  my($xsub, $self) = @_;
  my $ret = $xsub->($self);
  die 'fixme' unless $ret == 0;
  return;
});


$ffi->attach( clearerr => ['FILE'] );


$ffi->attach( feof => ['FILE'] => 'int' );


$ffi->attach( ferror => ['FILE'] => 'int' );


sub take
{
  my($self) = @_;
  my $ptr = $$self;
  $$self = undef;
  $ptr;
}


$ffi->attach( fclose => [ 'FILE' ] => 'int' => sub {
  my($xsub, $self) = @_;
  my $ret = $xsub->($self);
  if($ret != 0)
  {
    croak "Error closing file: $!";
  }
  $$self = undef;
});

sub DESTROY
{
  my($self) = @_;
  $self->fclose if defined $$self;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

FFI::C::File - Perl interface to C File pointer

=head1 VERSION

version 0.12

=head1 SYNOPSIS

 use FFI::C::File;
 
 my $file1 = FFI::C::File->fopen("foo.txt", "w");
 my $content1 = "hello world!\n";
 $file1->fwrite(\$content1, length $content);
 $file1->fclose;
 
 my $file2 = FFI::C::File->fopen("foo.txt", "r");
 # take gets the file pointer, $file2 is no longer
 # usable.
 my $ptr = $file2->take;
 
 # reconstitute the File object using the same file
 # pointer
 my $file3 = FFI::C::File->new($ptr);
 my $content3 = "\0" x length $content;
 $file3->fread(\$content3, length $content);
 print $content3;  # "hello world!\n";

=head1 DESCRIPTION

This class provides an interface to the standard C library file pointers.  Normally from Perl
you want to use the native Perl file interfaces, but sometimes you might be working with a
C library that uses C library file pointers (anytime you see the C<FILE*> type this is the case),
and having C native interface can be useful.

For example, if you have a C function that takes a file pointer:

 void foo(FILE *fp);

You can use it from your Perl code like so:

 use FFI::Platypus 1.00;
 use FFI::C::File;
 
 my $ffi = FFI::Platypus->new( api => 1 );
 $ffi->attach( foo => ['object(FFI::C::File)'] );
 
 my $file = FFI::C::File->fopen("foo.txt", "r");
 foo($file);

As long as this class "owns" the file pointer it will close it automatically when it falls
out of scope.  If the C API you are calling is taking ownership of the file pointer and is
expected to close the file itself, then you can use the take method to take the file pointer.
Once this method is called, the file object is no longer usable (though it can be
later reconstituted using the C<new> constructor).

 use FFI::Platypus 1.00;
 use FFI::C::File;
 
 my $ffi = FFI::Platypus->new( api => 1 );
 $ffi->attach( foo => ['opaque'] );
 
 my $file = FFI::C::File->fopen("foo.txt", "r");
 my $ptr = $file->ptr;
 foo($ptr);

Likewise, if a C API returns a file pointer that you are expected to close you can create
a new File object from the opaque pointer using the C<new> constructor.  C:

 FILE *bar();

Perl:

 use FFI::Platypus 1.00;
 use FFI::C::File;
 
 my $ffi = FFI::Platypus->new( api => 1 );
 $ffi->attach( bar => [] => 'opaque' );
 
 my $ptr = bar();
 my $file = FFI::C::File->new($ptr);
 # can now read/write etc to/from $file

Constructors and methods will throw an exception on errors.  End-of-File (EOF) is not considered
an error.

The subclass L<FFI::C::PosixFile> extends this class by adding some POSIX extensions for
platforms that support them.

=head1 CONSTRUCTOR

=head2 fopen

 my $file = FFI::C::File->fopen($filename, $mode);

Opens the file with the given mode.  See your standard library C documentation for the
exact format of C<$mode>.

=head2 tmpfile

 my $file = FFI::C::File->tmpfile;

Creates and opens a temporary file.  The file is opened as binary file for update.  On
Windows this may require administrator privileges.

=head2 new

 my $file = FFI::C::File->new($ptr);

Create a new File instance object from the opaque pointer.  Note that it isn't possible
to do any error checking on the type, so make sure that the pointer you are providing
really is a C file pointer.

=head1 METHODS

=head2 freopen

 $file->freopen($filename, $mode);

Re-open the file stream.  If C<$filename> is C<undef>, then the same file is reopened.
This can be useful for reopening a file in a different mode.  Note that the mode
changes that are allowed are platform dependent.

=head2 fread

 my $bytes = $file->fread(\$buffer, $size);

Read up to C<$size> bytes into C<$buffer>.  C<$buffer> must be preallocated, otherwise
memory corruption will happen.  Returns the number of bytes actually read, which may
be fewer than the number of bytes requested if the end of file is reached.

=head2 fwrite

 my $bytes = $file->fwrite(\$buffer, $size);

Write up to C<$size> bytes from C<$buffer>.  Returns the number of bytes actually written.

=head2 fseek

 $file->fseek($offset, $whence);

Seek to the specified location in the file.  C<$whence> should be one of the following
(either strings, or constants can be used, the constants can be imported from this module):

=over 4

=item C<'set'> | SEEK_SET

Relative to the start of the file

=item C<'cur'> | SEEK_CUR

Relative to the current location of the file pointer.

=item C<'end'> | SEEK_END

Relative to the end of the file.

=back

=head2 ftell

 my $offset = $file->ftell;

Returns the file position indicator for the file pointer.

=head2 rewind

 $file->rewind;

Moves the file position indicator to the beginning of the file.

=head2 fflush

 $file->fflush;

Flush the file stream.

=head2 clearerr

 $file->clearerr;

Clear the error flag for the file stream.

=head2 feof

 my $bool = $file->feof;

Returns true if the end of file has been reached.  False otherwise.

=head2 ferror

 my $error = $file->ferror;

Returns the file error code.

=head2 take

 my $ptr = $file->take;

Takes ownership of the file from the object and returns the opaque file pointer.

=head2 fclose

 $file->close;

Close the file.

=head1 SEE ALSO

=over 4

=item L<FFI::C>

=item L<FFI::C::Array>

=item L<FFI::C::ArrayDef>

=item L<FFI::C::Def>

=item L<FFI::C::File>

=item L<FFI::C::PosixFile>

=item L<FFI::C::Struct>

=item L<FFI::C::StructDef>

=item L<FFI::C::Union>

=item L<FFI::C::UnionDef>

=item L<FFI::C::Util>

=item L<FFI::Platypus::Record>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020-2022 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
