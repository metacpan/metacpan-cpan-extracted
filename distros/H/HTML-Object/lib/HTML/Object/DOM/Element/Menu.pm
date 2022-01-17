##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Element/Menu.pm
## Version v0.1.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/01/06
## Modified 2022/01/06
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::DOM::Element::Menu;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::DOM::Element );
    use HTML::Object::DOM::Element::Shared qw( :menu );
    our $VERSION = 'v0.1.0';
};

sub init
{
    my $self = shift( @_ );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{tag} = 'menu' if( !CORE::length( "$self->{tag}" ) );
    return( $self );
}

# Note: property compact is inherited

# Note: property label
sub label : lvalue { return( shift->_set_get_property( 'label', @_ ) ); }

# Note: property type is inherited

1;
# XXX POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Element::Menu - HTML Object DOM Menu Class

=head1 SYNOPSIS

    use HTML::Object::DOM::Element::Menu;
    my $menu = HTML::Object::DOM::Element::Menu->new ||
        die( HTML::Object::DOM::Element::Menu->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

Experimental: This is an experimental technologyCheck the Browser compatibility table carefully before using this in production.

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +----------------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::Node | --> | HTML::Object::DOM::Element | --> | HTML::Object::DOM::Element::Menu |
    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +----------------------------------+

=head1 PROPERTIES

Inherits properties from its parent L<HTML::Object::DOM::Element>

=head2 compact

A Boolean value determining if the menu displays in a compact way.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMenuElement/compact>

=head2 label

A string associating the menu with a name,
displayed when the menu is used as a context menu.
This use of the <menu> element has never been implemented widely
and is now deprecated.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMenuElement/label>

=head2 type

Returns context if the menu is a context menu.
This use of the <menu> element has never been implemented widely
and is now deprecated.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMenuElement/type>

=head1 METHODS

Inherits methods from its parent L<HTML::Object::DOM::Element>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMenuElement>, L<Mozilla documentation on menu element|https://developer.mozilla.org/en-US/docs/Web/HTML/Element/menu>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
