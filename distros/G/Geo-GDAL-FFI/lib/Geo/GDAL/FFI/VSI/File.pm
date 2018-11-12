package Geo::GDAL::FFI::VSI::File;
use v5.10;
use strict;
use warnings;
use Encode qw(decode encode);
use Carp;
use FFI::Platypus::Buffer;
use FFI::Platypus::Declare;

our $VERSION = 0.0601;

sub Open {
    my ($class, $path, $access) = @_;
    $access //= 'r';
    my $self = {};
    $self->{handle} = Geo::GDAL::FFI::VSIFOpenExL(encode(utf8 => $path), $access, 1);
    unless ($self->{handle}) {
        confess Geo::GDAL::FFI::error_msg() // "Failed to open '$path' with access '$access'.";
    }
    return bless $self, $class;
}

sub DESTROY {
    my ($self) = @_;
    $self->Close;
}

sub Close {
    my ($self) = @_;
    return unless $self->{handle};
    my $e = Geo::GDAL::FFI::VSIFCloseL($self->{handle});
    confess Geo::GDAL::FFI::error_msg() // "Failed to close a VSIFILE." if $e == -1;
    delete $self->{handle};
}

sub Read {
    my ($self, $len) = @_;
    $len //= 1;
    my $buf = ' ' x $len;
    my ($pointer, $size) = scalar_to_buffer $buf;
    my $n = Geo::GDAL::FFI::VSIFReadL($pointer, 1, $len, $self->{handle});
    return substr $buf, 0, $n;
}

sub Write {
    my ($self, $buf) = @_;
    my $len = do {use bytes; length($buf)};
    my $address = cast 'string' => 'opaque', $buf;
    return Geo::GDAL::FFI::VSIFWriteL($address, 1, $len, $self->{handle});
}

sub Ingest {
    my ($self) = @_;
    my $s;
    my $e = Geo::GDAL::FFI::VSIIngestFile($self->{handle}, '', \$s, 0, -1);
    return $s;
}

1;

=pod

=encoding UTF-8

=head1 NAME

Geo::GDAL::FFI::VSI::File - A GDAL virtual file

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 Open

 my $vsifile = Geo::GDAL::FFI::VSI::File->Open($name, $access);

Open a virtual file. $name is the name of the file to open. $access is
'r', 'r+', 'a', or 'w'. 'r' is the default.

Returns a Geo::GDAL::FFI::VSI::File object.

=head2 Close

Closes the file handle. Is done automatically when the object is
destroyed.

=head2 Read($len)

Read $len bytes from the file. Returns the bytes in a Perl
string. $len is optional and by default 1.

=head2 Write($buf)

Write the Perl string $buf into the file. Returns the number of
succesfully written bytes.

=head1 LICENSE

This software is released under the Artistic License. See
L<perlartistic>.

=head1 AUTHOR

Ari Jolma - Ari.Jolma at gmail.com

=head1 SEE ALSO

L<Geo::GDAL::FFI>

L<Alien::gdal>, L<FFI::Platypus>, L<http://www.gdal.org>

=cut

__END__;
