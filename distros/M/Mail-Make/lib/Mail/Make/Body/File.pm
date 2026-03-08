##----------------------------------------------------------------------------
## MIME Email Builder - ~/lib/Mail/Make/Body/File.pm
## Version v0.1.0
## Copyright(c) 2026 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2026/03/02
## Modified 2026/03/02
## All rights reserved.
##
## This program is free software; you can redistribute it and/or modify it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
# NOTE: Mail::Make::Body::File package
# Body stored on disk; only the file path is kept in memory.
package Mail::Make::Body::File;
BEGIN
{
    use strict;
    use warnings;
    warnings::register_categories( 'Mail::Make' );
    use parent qw( Mail::Make::Body );
    use vars qw( $VERSION $EXCEPTION_CLASS );
    our $EXCEPTION_CLASS = 'Mail::Make::Exception';
    our $VERSION         = 'v0.1.0';
}

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    my $path = shift( @_ ) ||
        return( $self->error( "Mail::Make::Body::File->new requires a file path" ) );
    $path = $self->new_file( $path );
    unless( $path->exists && $path->can_read )
    {
        return( $self->error( "File does not exist or is not readable: $path" ) );
    }
    # new_file() is inherited from Module::Generic and returns a new Module::Generic::File object
    $self->{_path} = $self->new_file( $path );
    $self->{_exception_class} = $EXCEPTION_CLASS;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    return( $self );
}

sub as_string
{
    my $self = shift( @_ );
    my $fh   = $self->open || return( $self->pass_error );
    # If we passed the 'open' statement, then we have a file, so we are safe.
    my $path = $self->{_path};
    my $data = '';
    my( $buf, $n );
    while( $n = $fh->read( $buf, 65536 ) )
    {
        $data .= $buf;
    }
    return( $self->error( "Error reading file '$path': $!" ) ) if( !defined( $n ) );
    $fh->close;
    return( \$data );
}

sub is_on_file { return(1); }

sub length
{
    my $self = shift( @_ );
    my $path = $self->{_path} ||
        return( $self->error( "No file path has been set yet." ) );
    return( $path->length );
}

# Returns a binary filehandle opened for reading
sub open
{
    my $self = shift( @_ );
    my $path = $self->{_path};
    return( $self->error( "No file path set." ) ) if( !defined( $path ) );
    my $fh = $path->open( '<' ) ||
        return( $self->error( "Cannot open file '$path' for reading: ", $path->error ) );
    $fh->binmode( ':raw' );
    return( $fh );
}

sub path
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $path = shift( @_ ) ||
            return( $self->error( "No file was provided." ) );
        $path = $self->new_file( $path ) || return( $self->pass_error );
        unless( $path->exists && $path->can_read )
        {
            return( $self->error( "File does not exist or is not readable: $path" ) );
        }
        $self->{_path} = $path;
        return( $self );
    }
    return( $self->{_path} );
}

sub purge
{
    my $self = shift( @_ );
    my $path = $self->{_path};
    if( defined( $path ) && -e $path )
    {
        $path->remove ||
            return( $self->error( "Cannot unlink '$path': ", $path->error ) );
    }
    $self->{_path} = undef;
    return( $self );
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Mail::Make::Body::File - On-Disk Body for Mail::Make

=head1 SYNOPSIS

    use Mail::Make::Body::File;
    my $body = Mail::Make::Body::File->new( '/path/to/logo.png' ) ||
        die( Mail::Make::Body::File->error );
    my $fh = $body->open || die( $body->error );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

Holds a reference to a file on disk. The file is read lazily when C<open()> or C<as_string()> is called.

=head1 CONSTRUCTOR

=head2 new( $filepath )

Accepts an absolute or relative file path. The file must exist and be readable at construction time or the constructor will fail with an explicit error.

=head1 METHODS

=head2 as_string

Slurps the entire file and returns a scalar reference. Use with caution on large files.

=head2 is_on_file

Returns true (1).

=head2 length

Returns the file size in bytes from C<stat()>.

=head2 open

Opens the file in raw binary mode and returns the filehandle.

=head2 path( [$newpath] )

Gets or sets the file path. When setting, validates that the new path exists and is readable.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mail::Make::Body::InCore>, L<Mail::Make::Body>, L<Mail::Make>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2026 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
