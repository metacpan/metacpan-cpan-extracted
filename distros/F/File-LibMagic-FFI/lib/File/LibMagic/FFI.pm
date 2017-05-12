package File::LibMagic::FFI;

use strict;
use warnings;
use 5.008001;
use FFI::Platypus;
use FFI::Platypus::Buffer ();
use FFI::CheckLib 0.06 ();
use constant {
  _MAGIC_NONE => 0x000000,
  _MAGIC_MIME => 0x000410, #MIME_TYPE | MIME_ENCODING,
};

# ABSTRACT: Determine MIME types of data or files using libmagic
our $VERSION = '0.04'; # VERSION


our $ffi = FFI::Platypus->new;
$ffi->lib(FFI::CheckLib::find_lib_or_die( lib => "magic" ));
$ffi->type(opaque => 'magic_t');

$ffi->attach( [magic_open   => '_open']   => ['int']                       => 'magic_t' );
$ffi->attach( [magic_load   => '_load']   => ['magic_t','string']          => 'int'     );
$ffi->attach( [magic_file   => '_file']   => ['magic_t','string']          => 'string'  );
$ffi->attach( [magic_buffer => '_buffer'] => ['magic_t','opaque','size_t'] => 'string'  );
$ffi->attach( [magic_close  => '_close']  => ['magic_t']                   => 'void'    );


sub new
{
  my($class, $magic_file) = @_;
  return bless { magic_file => $magic_file }, $class;
}

sub _mime_handle
{
  my($self) = @_;
  return $self->{mime_handle} ||= do {
    my $handle = _open(_MAGIC_MIME);
    _load($handle, $self->{magic_file});
    $handle;
  };
}

sub _describe_handle
{
  my($self) = @_;
  return $self->{describe_handle} ||= do {
    my $handle = _open(_MAGIC_NONE);
    _load($handle, $self->{magic_file});
    $handle;
  };
}

sub DESTROY
{
  my($self) = @_;
  _close($self->{magic_handle}) if defined $self->{magic_handle};
  _close($self->{mime_handle}) if defined $self->{mime_handle};
}


sub checktype_contents
{
  _buffer($_[0]->_mime_handle, FFI::Platypus::Buffer::scalar_to_buffer(ref $_[1] ? ${$_[1]} : $_[1]));
}


sub checktype_filename
{
  _file($_[0]->_mime_handle, $_[1]);
}


sub describe_contents
{
  _buffer($_[0]->_describe_handle, FFI::Platypus::Buffer::scalar_to_buffer(ref $_[1] ? ${$_[1]} : $_[1]));
}


sub describe_filename
{
  _file($_[0]->_describe_handle, $_[1]);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::LibMagic::FFI - Determine MIME types of data or files using libmagic

=head1 VERSION

version 0.04

=head1 SYNOPSIS

 use File::LibMagic;
 
 my $magic = File::LibMagic->new;
 
 # prints a description like "ASCII text"
 print $magic->describe_filename('path/to/file'), "\n";
 print $magic->describe_contents('this is some data'), "\n";
 
 # Prints a MIME type like "text/plain; charset=us-ascii"
 print $magic->checktype_filename('path/to/file'), "\n";
 print $magic->checktype_contents('this is some data'), "\n";

=head1 DESCRIPTION

This module is a simple Perl interface to C<libmagic>.  It provides the same full undeprecated interface as L<File::LibMagic>, but it uses L<FFI::Platypus> instead of C<XS> for
its implementation, and thus can be installed without a compiler.

=head1 API

This module provides an object-oriented API with the following methods:

=head2 new

 my $magic = File::LibMagic->new;
 my $magic = File::LibMagic->new('/etc/magic');

Creates a new File::LibMagic::FFI object.

Using the object oriented interface provides an efficient way to repeatedly determine the magic of a file.

This method takes an optional argument containing a path to the magic file.  If the file doesn't exist, this will throw an exception.

If you don't pass an argument, it will throw an exception if it can't find any magic files at all.

=head2 checktype_contents

 my $mime_type = $magic->checktype_contents($data);

Returns the MIME type of the data given as the first argument.  The data can be passed as a plain scalar or as a reference to a scalar.

This is the same value as would be returned by the C<file> command with the C<-i> option.

=head2 checktype_filename

 my $mime_type = $magic->checktype_filename($filename);

Returns the MIME type of the given file.

This is the same value as would be returned by the C<file> command with the C<-i> option.

=head2 describe_contents

 my $description = $magic->describe_contents($data);

Returns a description (as a string) of the data given as the first argument. The data can be passed as a plain scalar or as a reference to a scalar.

This is the same value as would be returned by the C<file> command with no options.

=head2 describe_filename

 my $description = $magic->describe_filename($filename);

Returns a description (as a string) of the given file.

This is the same value as would be returned by the C<file> command with no options.

=head1 DEPRECATED APIS

The FFI version does not support the deprecated APIs that L<File::LibMagic> does.

=head2 SEE ALSO

=over 4

=item L<File::LibMagic>

=item L<FFI::Platypus>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
