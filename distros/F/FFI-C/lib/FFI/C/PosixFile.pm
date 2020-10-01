package FFI::C::PosixFile;

use strict;
use warnings;
use Carp qw( croak );
use base qw( FFI::C::File );

# ABSTRACT: Perl interface to C File pointer with POSIX extensions
our $VERSION = '0.10'; # VERSION


our $ffi = $FFI::C::File::ffi;

if($ffi->find_symbol('fdopen') && $ffi->find_symbol('fileno'))
{

  $ffi->attach( fdopen => [ 'int', 'string' ] => 'opaque' => sub {
    my($xsub, $class, $fd, $mode) = @_;
    if(my $ptr = $xsub->($fd, $mode))
    {
      return bless \$ptr, $class;
    }
    else
    {
      croak "Error opening fd $fd with mode $mode: $!";
    }
  });


  $ffi->attach( fileno => [ 'FILE' ] => 'int' );

}
else
{
  require Sub::Install;
  foreach my $ctor (qw( fopen freopen new fdopen tmpfile ))
  {
    Sub::Install::install_sub({
      code => sub { croak "FFI::C::PosixFile not supported on this platform"; },
      into => __PACKAGE__,
      as   => $ctor,
    });
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

FFI::C::PosixFile - Perl interface to C File pointer with POSIX extensions

=head1 VERSION

version 0.10

=head1 SYNOPSIS

 use FFI::C::PosixFile;

 my $stdout = FFI::C::PosixFile->fdopen(1, "w");
 say $stdout->fileno;  # prints 1

=head1 DESCRIPTION

This is a subclass of L<FFI::C::File> which adds a couple of useful POSIX extensions that
may not be available on non-POSIX systems.  Trying to create an instance of this class will
fail on platforms that do not support the extensions.

=head1 CONSTRUCTOR

=head2 fopen

 my $file = FFI::C::PosixFile->fopen($filename, $mode);

Opens the file with the given mode.  See your standard library C documentation for the
exact format of C<$mode>.

=head2 new

 my $file = FFI::C::PosixFile->new($ptr);

Create a new File instance object from the opaque pointer.  Note that it isn't possible
to do any error checking on the type, so make sure that the pointer you are providing
really is a C file pointer.

=head2 fdopen

 my $file = FFI::C::PosixFile->fdopen($fd, $mode);

Create a new File instance from a POSIX file descriptor.

=head1 METHODS

=head2 fileno

 my $fd = $file->fileno;

Returns the POSIX file descriptor for the file pointer.

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

This software is copyright (c) 2020 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
