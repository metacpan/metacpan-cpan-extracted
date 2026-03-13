##----------------------------------------------------------------------------
## MIME Email Builder - ~/lib/Mail/Make/Body.pm
## Version v0.1.0
## Copyright(c) 2026 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2026/03/02
## Modified 2026/03/02
## All rights reserved.
##
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Mail::Make::Body;
BEGIN
{
    use strict;
    use warnings;
    warnings::register_categories( 'Mail::Make' );
    use parent qw( Module::Generic );
    use vars qw( $VERSION $EXCEPTION_CLASS );
    use Mail::Make::Exception;
    our $EXCEPTION_CLASS = 'Mail::Make::Exception';
    our $VERSION = 'v0.1.0';
};

use strict;
use warnings;

# Returns the body content as a scalar ref.
# Must be overridden by subclasses.
sub as_string
{
    my $self = shift( @_ );
    return( $self->error( ref( $self ) . "::as_string() is not implemented." ) );
}

sub data { return( shift->as_string( @_ ) ); }

# Returns the byte length of the body content.
sub length
{
    my $self   = shift( @_ );
    my $string = $self->as_string || return( $self->pass_error );
    return( CORE::length( $$string ) );
}

# Returns true if the body is stored on disk (Body::File), false otherwise.
sub is_on_file  { return(0); }

# Returns true if the body is stored in memory (Body::InCore), false otherwise.
sub is_in_core  { return(0); }

# path() - only meaningful for Body::File; returns undef here.
sub path { return; }

# Empties / releases the body content. Subclasses override.
sub purge { return( shift ); }

# NOTE: STORABLE support
sub STORABLE_freeze { CORE::return( CORE::shift->FREEZE( @_ ) ); }

sub STORABLE_thaw   { CORE::return( CORE::shift->THAW( @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Mail::Make::Body - MIME Body Base Class for Mail::Make

=head1 SYNOPSIS

    use Mail::Make::Body;

    # In-memory body
    my $b = Mail::Make::Body::InCore->new( "Hello, world!" ) ||
        die( Mail::Make::Body::InCore->error );
    my $ref = $b->as_string;   # scalar ref
    print $$ref;

    # File-backed body
    my $f = Mail::Make::Body::File->new( '/path/to/logo.png' ) ||
        die( Mail::Make::Body::File->error );
    my $ref = $f->as_string;   # reads entire file into memory

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

C<Mail::Make::Body> is the abstract base class for MIME body objects used by L<Mail::Make::Entity>. Two concrete subclasses are provided in the same file:

=over 4

=item L</Mail::Make::Body::InCore>

Holds the body content in memory as a scalar. Suitable for text parts and small attachments assembled at runtime.

=item L</Mail::Make::Body::File>

Holds a path to a file on disk. Content is read on demand by L</as_string>. The file is validated for existence and readability at construction time.

=back

=head1 METHODS (Mail::Make::Body)

=head2 as_string

Returns a scalar reference to the body content. Must be overridden by subclasses.

=head2 data

Alias for L</as_string>.

=head2 is_in_core

Returns 1 if this is a L<Mail::Make::Body::InCore> object, 0 otherwise.

=head2 is_on_file

Returns 1 if this is a L<Mail::Make::Body::File> object, 0 otherwise.

=head2 length

Returns the byte length of the body content.

=head2 path

Returns C<undef> for the base class. Overridden by L<Mail::Make::Body::File>.

=head2 purge

Releases the body content. Subclasses override.

=head1 METHODS (Mail::Make::Body::InCore)

=head2 new( [ $data ] )

Creates a new in-memory body. C<$data> may be a plain scalar or a scalar reference.

=head2 set( $data )

Replaces the stored data after construction.

=head1 METHODS (Mail::Make::Body::File)

=head2 new( [ $path ] )

Creates a new file-backed body. Validates that C<$path> exists and is readable.

=head2 path( [ $path ] )

Sets or gets the file path. Validates existence and readability on assignment.

=head2 purge

Deletes the file from disk and clears the path.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mail::Make>, L<Mail::Make::Entity>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2026 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
