##----------------------------------------------------------------------------
## MIME Email Builder - ~/lib/Mail/Make/Headers/MessageID.pm
## Version v0.2.0
## Copyright(c) 2026 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2026/03/02
## Modified 2026/03/03
## All rights reserved.
##
## This program is free software; you can redistribute it and/or modify it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Mail::Make::Headers::MessageID;
BEGIN
{
    use strict;
    use warnings;
    warnings::register_categories( 'Mail::Make' );
    use parent qw( Module::Generic );
    use vars qw( $VERSION $EXCEPTION_CLASS );
    use Data::UUID;
    use Mail::Make::Exception;
    use overload
    (
        '""'  => 'as_string',
        bool  => sub { 1 },
    );
    our $EXCEPTION_CLASS = 'Mail::Make::Exception';
    our $VERSION         = 'v0.2.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{_id}              = undef;
    $self->{_exception_class} = $EXCEPTION_CLASS;
    my $id = shift( @_ );
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    if( defined( $id ) && length( $id ) )
    {
        $self->id( $id ) || return( $self->pass_error );
    }
    else
    {
        $self->{_id} = $self->_generate;
    }
    return( $self );
}

sub as_string
{
    my $self = shift( @_ );
    return( $self->{_id} // '' );
}

# generate()
# Generates a new unique Message-ID string and sets it.
sub generate
{
    my $self = shift( @_ );
    $self->{_id} = $self->_generate;
    return( $self );
}

# id( [$value] )
# Gets or sets the Message-ID string. Must be in angle-bracket format
# <local-part@domain> per RFC 2822.
sub id
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $val = shift( @_ );
        unless( $val =~ /\A<[^>]+\@[^>]+>\z/ )
        {
            return( $self->error( "Message-ID must be in <local\@domain> format, got: '$val'" ) );
        }
        $self->{_id} = $val;
        return( $self );
    }
    return( $self->{_id} );
}

# value() — alias for as_string
sub value { return( shift->as_string ); }

# _generate()
# Produces a unique <uuid@generated> string.
sub _generate
{
    my $self = shift( @_ );
    my $uuid = lc( Data::UUID->new->create_str );
    $uuid =~ tr/-//d;
    return( "<${uuid}\@mail.make.generated>" );
}

# NOTE: STORABLE support
sub STORABLE_freeze { CORE::return( CORE::shift->FREEZE( @_ ) ); }

sub STORABLE_thaw   { CORE::return( CORE::shift->THAW( @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Mail::Make::Headers::MessageID - Typed Message-ID Header for Mail::Make

=head1 SYNOPSIS

    use Mail::Make::Headers::MessageID;

    # Auto-generated ID
    my $mid = Mail::Make::Headers::MessageID->new;
    print $mid->as_string;
    # <3f2504e04f8911d39a0c030648acfd0c@mail.make.generated>

    # Supplied ID
    my $mid2 = Mail::Make::Headers::MessageID->new( '<abc@example.com>' );

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

A typed object for the C<Message-ID> header field. Validates that any supplied value is in angle-bracket format, and auto-generates a UUID-based ID when none is supplied.

=head1 CONSTRUCTOR

=head2 new( [$id_string] )

If C<$id_string> is omitted, a unique ID is auto-generated. If supplied, it must be in C<< <local-part@domain> >> format.

=head1 METHODS

=head2 as_string

Returns the Message-ID string.

=head2 generate

Generates a fresh unique ID and replaces the current one.

=head2 id( [$value] )

Gets or sets the ID. Validates the angle-bracket format.

=head2 value

Alias for C<as_string>.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

RFC 2822 section 3.6.4

L<Mail::Make::Headers>, L<Mail::Make>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2026 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
