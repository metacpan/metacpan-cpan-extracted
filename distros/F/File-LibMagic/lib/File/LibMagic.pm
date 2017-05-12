package File::LibMagic;

use 5.008;

use strict;
use warnings;

use Carp;
use Exporter;
use Scalar::Util qw( reftype );
use XSLoader;

our $VERSION = '1.15';

XSLoader::load( __PACKAGE__, $VERSION );

use base 'Exporter';

my @Constants = qw(
    MAGIC_CHECK
    MAGIC_COMPRESS
    MAGIC_CONTINUE
    MAGIC_DEBUG
    MAGIC_DEVICES
    MAGIC_ERROR
    MAGIC_MIME
    MAGIC_NONE
    MAGIC_PRESERVE_ATIME
    MAGIC_RAW
    MAGIC_SYMLINK
);

for my $name (@Constants) {
    my ( $error, $value ) = constant($name);

    croak "WTF defining $name - $error"
        if defined $error;

    my $sub = sub {$value};

    ## no critic (TestingAndDebugging::ProhibitNoStrict)
    no strict 'refs';
    *{$name} = $sub;
    ## use critic
}

our %EXPORT_TAGS = (
    'easy'     => [qw( MagicBuffer MagicFile )],
    'complete' => [
        @Constants,
        qw(
            magic_buffer
            magic_buffer_offset
            magic_close
            magic_file
            magic_load
            magic_open
            )
    ]
);

$EXPORT_TAGS{all} = [ @{ $EXPORT_TAGS{easy} }, @{ $EXPORT_TAGS{complete} } ];

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

sub new {
    my $class = shift;

    my $flags = MAGIC_NONE();
    my $magic_file;
    if ( @_ == 1 ) {
        $magic_file = shift;
    }
    else {
        my %p = @_;
        $magic_file = $p{magic_file};
        $flags |= MAGIC_SYMLINK()
            if $p{follow_symlinks};
        $flags |= MAGIC_COMPRESS()
            if $p{uncompress};
    }

    my $m = magic_open($flags);

    my $magic_paths
        = ref $magic_file && reftype($magic_file) eq 'ARRAY'
        ? join ':', @{$magic_file}
        : $magic_file;

    # We need to call this even if $magic_paths is undef
    magic_load( $m, $magic_paths );

    return bless {
        magic      => $m,
        magic_file => $magic_file,
        flags      => $flags,
    }, $class;
}

sub info_from_string {
    my $self = shift;
    return $self->_info_hash( $self->_info_from_string(@_) );
}

sub info_from_filename {
    my $self = shift;
    return $self->_info_hash( $self->_info_from_filename(@_) );
}

sub info_from_handle {
    my $self = shift;
    return $self->_info_hash( $self->_info_from_handle(@_) );
}

sub _info_hash {
    return {
        description        => $_[1],
        mime_type          => $_[2],
        encoding           => $_[3],
        mime_with_encoding => $_[0]->_mime_with_encoding( @_[ 2, 3 ] ),
    };
}

sub _mime_with_encoding {
    return $_[1] unless $_[2];
    return "$_[1]; charset=$_[2]";
}

sub DESTROY {
    my ($self) = @_;

    magic_close( $self->{magic} ) if defined $self->{magic};
}

# Old OO API
sub checktype_contents {
    my ( $self, $data ) = @_;
    return magic_buffer( $self->_mime_handle(), $data );
}

sub checktype_filename {
    my ( $self, $filename ) = @_;
    return magic_file( $self->_mime_handle(), $filename );
}

sub describe_contents {
    my ( $self, $data ) = @_;
    return magic_buffer( $self->_describe_handle(), $data );
}

sub describe_filename {
    my ( $self, $filename ) = @_;
    return magic_file( $self->_describe_handle(), $filename );
}

sub _describe_handle {
    my $self = shift;
    _magic_setflags( $self->{magic}, MAGIC_NONE() );
    return $self->{magic};
}

sub _mime_handle {
    my $self = shift;
    _magic_setflags( $self->{magic}, MAGIC_MIME() );
    return $self->{magic};
}

1;

# ABSTRACT: Determine MIME types of data or files using libmagic

__END__

=pod

=head1 NAME

File::LibMagic - Determine MIME types of data or files using libmagic

=head1 VERSION

version 1.15

=head1 SYNOPSIS

  use File::LibMagic;

  my $magic = File::LibMagic->new();

  my $info = $magic->info_from_filename('path/to/file');
  # Prints a description like "ASCII text"
  print $info->{description};
  # Prints a MIME type like "text/plain"
  print $info->{mime_type};
  # Prints a character encoding like "us-ascii"
  print $info->{encoding};
  # Prints a MIME type with encoding like "text/plain; charset=us-ascii"
  print $info->{mime_with_encoding};

  my $file_content = read_file('path/to/file');
  $info = $magic->info_from_string($file_content);

  open my $fh, '<', 'path/to/file' or die $!;
  $info = $magic->info_from_handle($fh);

=head1 DESCRIPTION

The C<File::LibMagic> is a simple perl interface to libmagic from the file
package (version 4.x or 5.x). You will need both the library (F<libmagic.so>)
and the header file (F<magic.h>) to build this Perl module.

=head2 Installing libmagic

On Debian/Ubuntu run:

    sudo apt-get install libmagic-dev

On Mac you can use homebrew (http://brew.sh/):

    brew install libmagic

=head2 Specifying lib and/or include directories

On some systems, you may need to pass additional lib and include directories
to the Makefile.PL. You can do this with the `--lib` and `--include`
parameters:

    perl Makefile.PL --lib /usr/local/lib --include /usr/local/include

You can pass these parameters multiple times to specify more than one
location.

=head1 API

This module provides an object-oriented API with the following methods:

=head2 File::LibMagic->new()

Creates a new File::LibMagic object.

Using the object oriented interface only opens the magic database once, which
is probably most efficient for repeated uses.

Each C<File::LibMagic> object loads the magic database independently of other
C<File::LibMagic> objects, so you may want to share a single object across
many modules.

This method takes the following named parameters:

=over 4

=item * magic_file

This should be a string or an arrayref containing one or more magic files.

If a file you provide doesn't exist the constructor will throw an exception,
but only with libmagic 4.17+.

If you don't set this parameter, the constructor will throw an exception if it
can't find any magic files at all.

Note that even if you're using a custom file, you probably I<also> want to use
the standard file (F</usr/share/misc/magic> on my system, yours may vary).

=item * follow_symlinks

If this is true, then calls to C<< $magic->info_from_filename >> will follow
symlinks to the real file.

=item * uncompress

If this is true, then compressed files (such as gzip files) will be
uncompressed, and the various C<< info_from_* >> methods will return info
about the uncompressed file.

=back

=head2 $magic->info_from_filename('path/to/file')

This method returns info about the given file. The return value is a hash
reference with four keys:

=over 4

=item * description

A textual description of the file content like "ASCII C program text".

=item * mime_type

The MIME type without a character encoding, like "text/x-c".

=item * encoding

Just the character encoding, like "us-ascii".

=item * mime_with_encoding

The MIME type with a character encoding, like "text/x-c;
charset=us-ascii". Note that if no encoding was found, this will be the same
as the C<mime_type> key.

=back

=head2 $magic->info_from_string($string)

This method returns info about the given string. The string can be passed as a
reference to save memory.

The return value is the same as that of C<< $mime->info_from_filename() >>.

=head2 $magic->info_from_handle($fh)

This method returns info about the given filehandle. It will read data
starting from the handle's current position, and leave the handle at that same
position after reading.

=head1 DISCOURAGED APIS

This module offers two different procedural APIs based on optional exports,
the "easy" and "complete" interfaces. There is also an older OO API still
available. All of these APIs are discouraged, but will not be removed in the
near future, nor will using them cause any warnings.

I strongly recommend you use the new OO API. It's simpler than the complete
interface, more efficient than the easy interface, and more featureful than
the old OO API.

=head2 The Old OO API

This API uses the same constructor as the current API.

=over 4

=item * $magic->checktype_contents($data)

Returns the MIME type of the data given as the first argument. The data can be
passed as a plain scalar or as a reference to a scalar.

This is the same value as would be returned by the C<file> command with the
C<-i> switch.

=item * $magic->checktype_filename($filename)

Returns the MIME type of the given file.

This is the same value as would be returned by the C<file> command with the
C<-i> switch.

=item * $magic->describe_contents($data)

Returns a description (as a string) of the data given as the first argument.
The data can be passed as a plain scalar or as a reference to a scalar.

This is the same value as would be returned by the C<file> command with no
switches.

=item * $magic->describe_filename($filename)

Returns a description (as a string) of the given file.

This is the same value as would be returned by the C<file> command with no
switches.

=back

=head2 The "easy" interface

This interface is exported by:

  use File::LibMagic ':easy';

This interface exports two subroutines:

=over 4

=item * MagicBuffer($data)

Returns the description of a chunk of data, just like the C<describe_contents>
method.

=item * MagicFile($filename)

Returns the description of a file, just like the C<describe_filename> method.

=back

=head2 The "complete" interface

This interface is exported by:

  use File::LibMagic ':complete';

This interface exports several subroutines:

=over 4

=item * magic_open($flags)

This subroutine opens creates a magic handle. See the libmagic man page for a
description of all the flags. These are exported by the C<:complete> import.

  my $handle = magic_open(MAGIC_MIME);

=item * magic_load($handle, $filename)

This subroutine actually loads the magic file. The C<$filename> argument is
optional. There should be a sane default compiled into your C<libmagic>
library.

=item * magic_buffer($handle, $data)

This returns information about a chunk of data as a string. What it returns
depends on the flags you passed to C<magic_open>, a description, a MIME type,
etc.

=item * magic_file($handle, $filename)

This returns information about a file as a string. What it returns depends on
the flags you passed to C<magic_open>, a description, a MIME type, etc.

=item * magic_close($handle)

Closes the magic handle.

=back

=head1 EXCEPTIONS

This module can throw an exception if your system runs out of memory when
trying to call C<magic_open> internally.

=head1 SUPPORT

Please submit bugs to the CPAN RT system at
http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-LibMagic or via email at
bug-file-libmagic@rt.cpan.org.

=head1 BUGS

This module is totally dependent on the version of file on your system. It's
possible that the tests will fail because of this. Please report these
failures so I can make the tests smarter. Please make sure to report the
version of file on your system as well!

=head1 DEPENDENCIES/PREREQUISITES

This module requires file 4.x or file 5x and the associated libmagic library
and headers (http://darwinsys.com/file/).

=head1 RELATED MODULES

Andreas created File::LibMagic because he wanted to use libmagic (from
file 4.x) L<File::MMagic> only worked with file 3.x.

L<File::MimeInfo::Magic> uses the magic file from freedesktop.org which is
encoded in XML, and is thus not the fastest approach. See
L<http://mail.gnome.org/archives/nautilus-list/2003-December/msg00260.html>
for a discussion of this issue.

File::Type uses a relatively small magic file, which is directly hacked into
the module code. It is quite fast but the database is quite small relative to
the file package.

=head1 AUTHORS

=over 4

=item *

Andreas Fitzner

=item *

Michael Hendricks <michael@ndrix.org>

=item *

Dave Rolsky <autarch@urth.org>

=back

=head1 CONTRIBUTORS

=for stopwords E. Choroba Mithun Ayachit Olaf Alders

=over 4

=item *

E. Choroba <choroba@matfyz.cz>

=item *

Mithun Ayachit <mayachit@amfam.com>

=item *

Olaf Alders <olaf@wundersolutions.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Andreas Fitzner, Michael Hendricks, and Dave Rolsky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
