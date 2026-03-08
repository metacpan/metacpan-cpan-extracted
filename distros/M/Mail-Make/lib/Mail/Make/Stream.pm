##----------------------------------------------------------------------------
## MIME Email Builder - ~/lib/Mail/Make/Stream.pm
## Version v0.1.0
## Copyright(c) 2026 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2026/03/05
## Modified 2026/03/05
## All rights reserved.
##
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Mail::Make::Stream;
BEGIN
{
    use strict;
    use warnings;
    warnings::register_categories( 'Mail::Make' );
    use parent qw( Module::Generic );
    use vars qw( $VERSION $EXCEPTION_CLASS );
    use Mail::Make::Exception;
    our $EXCEPTION_CLASS = 'Mail::Make::Exception';
    our $VERSION         = 'v0.1.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{_exception_class}     = $EXCEPTION_CLASS;
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    return( $self );
}

# NOTE: STORABLE support

# NOTE: FREEZE is inherited

sub STORABLE_freeze { CORE::return( CORE::shift->FREEZE( @_ ) ); }

sub STORABLE_thaw   { CORE::return( CORE::shift->THAW( @_ ) ); }

# NOTE: THAW is inherited

1;

# NOTE: Mail::Make::Stream::Generic inline class
{
    package
        Mail::Make::Stream::Generic;
    BEGIN
    {
        use strict;
        use warnings;
        use parent qw( Module::Generic );
        use vars qw( $VERSION $EXCEPTION_CLASS );
        use Mail::Make::Exception;
        use Module::Generic::File::IO;
        use Module::Generic::Scalar::IO;
        our $EXCEPTION_CLASS = 'Mail::Make::Exception';
        our $VERSION = $Mail::Make::Stream::VERSION;
    };

    use strict;
    use warnings;

    sub init
    {
        my $self = shift( @_ );
        my $class = ( ref( $self ) || $self );
        $self->{_init_strict_use_sub} = 1;
        no strict 'refs';
        $self->{_exception_class} = defined( ${"${class}::EXCEPTION_CLASS"} )
            ? ${"${class}::EXCEPTION_CLASS"}
            : $EXCEPTION_CLASS;
        $self->SUPER::init( @_ ) || return( $self->pass_error );
        return( $self );
    }

    # _get_glob_from_arg( $source_or_dest [, write => 1] )
    #
    # Normalises any of the following into a ( $fh, $op ) pair:
    #
    #   - A native Perl glob / IO object    → used directly
    #   - A scalar reference (\$scalar)     → Module::Generic::Scalar::IO
    #   - A plain string (file path)        → Module::Generic::File opened via new_file()
    #
    # $op is a closure that:
    #   Read  mode: $op->( $buf, $len )  — returns bytes read (0 at EOF, undef on error)
    #   Write mode: $op->( $data )       — returns true on success, undef on error
    sub _get_glob_from_arg
    {
        my $self = shift( @_ );
        my $this = shift( @_ );
        if( !defined( $this ) || ( !ref( $this ) && !length( $this ) ) )
        {
            return( $self->error( "No argument was provided." ) );
        }
        my $opts = $self->_get_args_as_hash( @_ );
        $opts->{write} = 0 if( !exists( $opts->{write} ) );
        my $mode = $opts->{write} ? '+>' : '<';
        my $fh;
        my $is_native_glob = 0;

        if( $self->_is_glob( $this ) )
        {
            $fh = $this;
            # Even if this is an in-memory scalar handle, fileno() returns -1, which is true
            $is_native_glob++ if( fileno( $this ) );
        }
        elsif( $self->_is_scalar( $this ) )
        {
            $fh = Module::Generic::Scalar::IO->new( $this, $mode ) ||
                return( $self->pass_error( Module::Generic::Scalar::IO->error ) );
            $is_native_glob++;
        }
        else
        {
            my $f = $self->new_file( "$this" ) || return( $self->pass_error );
            if( !$f->exists && !$opts->{write} )
            {
                return( $self->error( "File '$this' does not exist." ) );
            }
            $fh = $f->open( $mode, { binmode => 'raw', ( $opts->{write} ? ( autoflush => 1 ) : () ) } ) ||
                return( $self->pass_error( $f->error ) );
            $is_native_glob++;
        }

        my $flags;
        if( $self->_can( $fh => 'fcntl' ) )
        {
            $flags = $fh->fcntl( F_GETFL, 0 );
        }
        else
        {
            $flags = fcntl( $fh, F_GETFL, 0 );
        }

        if( defined( $flags ) )
        {
            if( $opts->{write} )
            {
                unless( $flags & ( O_RDWR | O_WRONLY | O_APPEND ) )
                {
                    return( $self->error( "Filehandle provided does not have write permission enabled." ) );
                }
            }
            else
            {
                unless( ( ( $flags & O_RDONLY ) == O_RDONLY ) || ( $flags & O_RDWR ) )
                {
                    return( $self->error( "Filehandle provided does not have read permission enabled. File handle flags value is '$flags'" ) );
                }
            }
        }

        # We check if the file handle is an object, because calling core read() or print()
        # on it would not work unless the glob has implemented a tie. See perltie.
        my $op;
        my $meth;
        if( $opts->{write} )
        {
            if( $is_native_glob )
            {
                $op = sub
                {
                    my $rv = print( $fh @_ );
                    return( $self->error( "Error writing ", CORE::length( $_[0] ), " bytes of data to output: $!" ) )
                        if( !defined( $rv ) );
                    return( $rv );
                };
            }
            elsif( ( $meth = ( $self->_can( $fh => 'print' ) || $self->_can( $fh => 'write' ) ) ) )
            {
                $op = sub
                {
                    local $@;
                    my $rv = eval{ $fh->$meth( @_ ) };
                    if( $@ )
                    {
                        return( $self->error( "Error writing ", CORE::length( $_[0] ), " bytes of data to output: $@" ) );
                    }
                    if( !defined( $rv ) )
                    {
                        my $err;
                        if( defined( $! ) )
                        {
                            $err = $!;
                        }
                        elsif( $self->_can( $fh => 'error' ) )
                        {
                            $err = $fh->error;
                        }
                        elsif( $self->_can( $fh => 'errstr' ) )
                        {
                            $err = $fh->errstr;
                        }
                        return( $self->error( "Error writing ", CORE::length( $_[0] ), " bytes of data to output: $err" ) );
                    }
                    return( $rv );
                };
            }
            else
            {
                return( $self->error( "The file handle provided is not a native opened one and does not support the print() or write() methods." ) );
            }
        }
        else
        {
            if( $is_native_glob )
            {
                $op = sub
                {
                    my $n = read( $fh, $_[0], $_[1] );
                    if( !defined( $n ) )
                    {
                        return( $self->error( "Error reading ", $_[1], " bytes of data from input: $!" ) );
                    }
                    return( $n );
                };
            }
            elsif( $self->_can( $fh => 'read' ) )
            {
                $op = sub
                {
                    local $@;
                    my $n = eval{ $fh->read( @_ ) };
                    if( $@ )
                    {
                        return( $self->error( "Error reading ", $_[1], " bytes of data from input: $@" ) );
                    }
                    if( !defined( $n ) )
                    {
                        my $err;
                        if( defined( $! ) )
                        {
                            $err = $!;
                        }
                        elsif( $self->_can( $fh => 'error' ) )
                        {
                            $err = $fh->error;
                        }
                        elsif( $self->_can( $fh => 'errstr' ) )
                        {
                            $err = $fh->errstr;
                        }
                        return( $self->error( "Error reading ", $_[1], " bytes of data from input: $err" ) );
                    }
                    return( $n );
                };
            }
            else
            {
                return( $self->error( "The file handle provided is not a native opened one and does not support the read() method." ) );
            }
        }
        return( $fh, $op );
    }

    # NOTE: sub FREEZE is inherited

    sub STORABLE_freeze { CORE::return( CORE::shift->FREEZE( @_ ) ); }

    sub STORABLE_thaw { CORE::return( CORE::shift->THAW( @_ ) ); }

    # NOTE: sub THAW is inherited
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Mail::Make::Stream - Stream Infrastructure for Mail::Make Encoders

=head1 SYNOPSIS

    # Used internally by Mail::Make::Stream::Base64 and
    # Mail::Make::Stream::QuotedPrint. Not normally instantiated directly.

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

C<Mail::Make::Stream> is the namespace root for stream-oriented encode/decode helpers. It also defines the inline class C<Mail::Make::Stream::Generic>, which is the parent of all concrete stream encoders.

Its primary method is L</_get_glob_from_arg>, which normalises any of the following argument types into a C<( $fh, $op )> pair:

=over 4

=item * A native Perl glob or IO object

=item * A scalar reference — opened via L<Module::Generic::Scalar::IO>

=item * A plain string — treated as a file path and opened via C<new_file()>

=back

The returned C<$op> closure abstracts over the underlying handle type:

=over 4

=item * Read mode: C<$op-E<gt>( $buf, $len )> — bytes read (0 at EOF, undef on error)

=item * Write mode: C<$op-E<gt>( $data )> — true on success, undef on error

=back

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mail::Make::Stream::Base64>, L<Mail::Make::Stream::QuotedPrint>, L<Mail::Make>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2026 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
