##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Element/Map.pm
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
package HTML::Object::DOM::Element::Map;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::DOM::Element );
    use vars qw( $VERSION );
    use HTML::Object::DOM::Element::Shared qw( :map );
    our $VERSION = 'v0.2.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{tag} = 'map' if( !CORE::length( "$self->{tag}" ) );
    return( $self );
}

# Note: property
sub areas : lvalue { return( shift->_set_get_property( 'areas', @_ ) ); }

# Note: property name inherited

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Element::Map - HTML Object DOM Map Class

=head1 SYNOPSIS

    use HTML::Object::DOM::Element::Map;
    my $map = HTML::Object::DOM::Element::Map->new || 
        die( HTML::Object::DOM::Element::Map->error, "\n" );

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

This interface provides special properties and methods (beyond those of the regular object L<HTML::Object::Element> interface it also has available to it by inheritance) for manipulating the layout and presentation of C<map> elements.

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +---------------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::Node | --> | HTML::Object::DOM::Element | --> | HTML::Object::DOM::Element::Map |
    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +---------------------------------+

=head1 PROPERTIES

Inherits properties from its parent L<HTML::Object::DOM::Element>

=head2 areas

Is a live L<HTML::Object::DOM::Collection> representing the L<<area> elements|HTML::Object::DOM::Element::Area> associated to this <map>.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMapElement/areas>

=head2 name

Is a string representing the C<<map>> element for referencing it other context. If the id attribute is set, this must have the same value; and it cannot be C<undef> or empty.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMapElement/name>

=head1 METHODS

Inherits methods from its parent L<HTML::Object::DOM::Element>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMapElement>, L<Mozilla documentation on map element|https://developer.mozilla.org/en-US/docs/Web/HTML/Element/map>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
