##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Element/Meta.pm
## Version v0.2.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/12/23
## Modified 2022/09/18
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::DOM::Element::Meta;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::DOM::Element );
    use vars qw( $VERSION );
    our $VERSION = 'v0.2.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{tag} = 'meta' if( !CORE::length( "$self->{tag}" ) );
    return( $self );
}

sub content : lvalue { return( shift->_set_get_property( 'content', @_ ) ); }

sub httpEquiv : lvalue { return( shift->_set_get_property( 'httpequiv', @_ ) ); }

sub name : lvalue { return( shift->_set_get_property( 'name', @_ ) ); }

sub scheme : lvalue { return( shift->_set_get_property( 'scheme', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Element::Meta - HTML Object DOM Meta Class

=head1 SYNOPSIS

    use HTML::Object::DOM::Element::Meta;
    my $meta = HTML::Object::DOM::Element::Meta->new || 
        die( HTML::Object::DOM::Element::Meta->error, "\n" );

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

This interface contains descriptive metadata about a document. It inherits all of the properties and methods described in the L<HTML::Object::Element> interface.

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +----------------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::Node | --> | HTML::Object::DOM::Element | --> | HTML::Object::DOM::Element::Meta |
    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +----------------------------------+

=head1 PROPERTIES

Inherits properties from its parent L<HTML::Object::DOM::Element>

=head2 content

Gets or sets the value of meta-data property.

=head2 httpEquiv

Gets or sets the name of an HTTP response header to define for a document.

=head2 name

Gets or sets the name of a meta-data property to define for a document.

=head2 scheme

Gets or sets the name of a scheme used to interpret the value of a meta-data property.

=head1 METHODS

Inherits methods from its parent L<HTML::Object::DOM::Element>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMetaElement>, L<Mozilla documentation on meta element|https://developer.mozilla.org/en-US/docs/Web/HTML/Element/meta>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
