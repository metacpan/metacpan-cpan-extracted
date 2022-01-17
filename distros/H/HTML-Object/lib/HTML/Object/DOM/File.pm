##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/File.pm
## Version v0.1.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/12/25
## Modified 2021/12/25
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::DOM::File;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic::File );
    use DateTime::Format::Strptime;
    use Module::Generic::Scalar;
    our $VERSION = 'v0.1.0';
};

sub arrayBuffer
{
    my $self = shift( @_ );
    my $data = $self->load({ binmode => 'raw' });
    return( Module::Generic::Scalar->new( \$data ) );
}

sub lastModified
{
    my $self = shift( @_ );
    my $dt = $self->mtime;
    my $fmt = DateTime::Format::Strptime->new( pattern => '%s' );
    $dt->set_formatter( $fmt );
    return( $dt );
}

sub lastModifiedDate { return( shift->mtime ); }

sub name { return( shift->basename ); }

# Note: sub size is inherited

sub slice
{
    my $self = shift( @_ );
    my( $start, $end ) = @_;
    return( $self->error( "start value provided is not an integer." ) ) if( !$self->_is_integer( $start ) );
    $end = $self->size if( !$self->_is_integer( $end ) );
    return( Module::Generic::Scalar->new ) if( $end <= $start );
    my $len = $end - $start;
    $self->message( 4, "Reading data from offset '$start' with end '$end' for length '$len'." );
    my $opened = $self->opened;
    my $io;
    my $pos;
    if( $opened )
    {
        $io = $opened;
        $pos = $io->seek(0,1);
    }
    else
    {
        $io = $self->open({ binmode => 'utf-8' }) || return( $self->pass_error );
    }
    $io->seek( $start, 0 ) || return( $self->pass_error );
    my $data;
    $self->read( $data, $len ) || return( $self->pass_error );
    if( $opened )
    {
        $io->seek( $pos, 0 ) if( defined( $pos ) );
    }
    else
    {
        $self->close;
    }
    $self->message( 4, "Returning '$data'" );
    return( Module::Generic::Scalar->new( \$data ) );
}

sub stream { return( shift->open( @_ ) ); }

sub text
{
    my $self = shift( @_ );
    my $data = $self->load_utf8;
    return( Module::Generic::Scalar->new( \$data ) );
}

sub type { return( shift->finfo->mime_type ); }

sub webkitRelativePath { return( shift->relative ); }

1;
# XXX POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::File - HTML Object DOM File Class

=head1 SYNOPSIS

    use HTML::Object::DOM::File;
    my $file = HTML::Object::DOM::File->new || 
        die( HTML::Object::DOM::File->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

The C<File> interface provides information about files and allows access to their content.

File objects are generally retrieved from a L<HTML::Object::DOM::FileList> object returned using the C<<input>> L<files|HTML::Object::DOM::Element::Input/files> method.

It inherits from L<Module::Generic::File>

=head1 PROPERTIES

=head2 lastModified

Read-only.

Returns the last modified time of the file, in second since the UNIX epoch (January 1st, 1970 at Midnight), as a L<Module::Generic::DateTime> object. The DateTime object stringifies to the seconds since epoch.

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/File/lastModified>

=head2 lastModifiedDate

Read-only.

Returns the last modified date and time of the file referenced by the file object, as a L<Module::Generic::DateTime> object.

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/File/lastModifiedDate>

=head2 name

Read-only.

Returns the name of the file referenced by the file object.

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/File/name>

=head2 webkitRelativePath

Read-only.

Returns the relative file path.

Normally under JavaScript, this works alongside the C<<input>> attribute C<webkitdirectory>:

    <input type="file" webkitdirectory />

allowing a user to select an entire directory instead of just files. So, C<webkitRelativePath> provide the relative file path to that directory uploaded.

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/File/webkitRelativePath>

=head2 size

Read-only.

Returns the size of the file in bytes.

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/File/size>

=head2 type

Read-only.

Returns the MIME type of the file, or C<undef> if it cannot find it.

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/File/type>

=head1 METHODS

=head2 arrayBuffer

Opens the file as C<raw> data and returns its content as a L<scalar object|Module::Generic::Scalar>.

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Blob/arrayBuffer>

=head2 slice

Provided with a C<start> and an C<end> as a range, and an optional encoding and this will return that range of data from the file, as a L<scalar object|Module::Generic::Scalar>. If no encoding is provided, this will default to C<utf-8>

If you specify a negative C<start>, it is treated as an offset from the end of the file's data toward the beginning. For example, C<-10> would be the C<10th> from last byte in the file data. The default value is C<0>. If you specify a value for C<start> that is larger than the size of the file, the returned L<scalar object|Module::Generic::Scalar> has size 0 and contains no data.

The C<end> specifies the offset (not the length) of the last byte, without including it, to include in the returned data. If you specify a negative C<end>, it is treated as an offset from the end of the data toward the beginning. For example, C<-10> would be the C<10th> from last byte in the file's data. The default value is the file C<size>, i.e. until the end of the file's data.

Returns a new L<scalar object|Module::Generic::Scalar> containing the data in the specified range of bytes of the file.

=head2 stream

This opens the file and returns its file handle to read the file's contents. You could also do:

    my $io = $file->open || die( $file->error );

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Blob/stream>

=head2 text

Opens the file in C<utf-8> and returns its content as a L<scalar object|Module::Generic::Scalar>.

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Blob/text>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/File>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
