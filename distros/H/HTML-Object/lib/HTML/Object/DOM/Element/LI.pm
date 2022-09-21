##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Element/LI.pm
## Version v0.2.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/01/06
## Modified 2022/09/18
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::DOM::Element::LI;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::DOM::Element );
    use vars qw( $VERSION );
    use HTML::Object::DOM::Element::Shared qw( :li );
    our $VERSION = 'v0.2.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{tag} = 'li' if( !CORE::length( "$self->{tag}" ) );
    return( $self );
}

# Note: property type is inherited

# Note: property value is inherited

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Element::LI - HTML Object DOM LI Class

=head1 SYNOPSIS

    use HTML::Object::DOM::Element::LI;
    my $li = HTML::Object::DOM::Element::LI->new ||
        die( HTML::Object::DOM::Element::LI->error, "\n" );

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

This interface exposes specific properties and methods (beyond those defined by regular L<HTML::Object::DOM::Element> interface it also has available to it by inheritance) for manipulating list elements.

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +--------------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::Node | --> | HTML::Object::DOM::Element | --> | HTML::Object::DOM::Element::LI |
    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +--------------------------------+

=head1 PROPERTIES

Inherits properties from its parent L<HTML::Object::DOM::Element>

=head2 type

Is a string representing the type of the bullets, C<disc>, C<square> or C<circle>. As the standard way of defining the list type is via the CSS list-style-type property, use the CSSOM methods to set it via a script.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLLIElement/type>

=head2 value

Is a long indicating the ordinal position of the list element inside a given <ol>. It reflects the value attribute of the HTML <li> element, and can be smaller than 0. If the <li> element is not a child of an C<ol> element, the property has no meaning.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLLIElement/value>

=head1 METHODS

Inherits methods from its parent L<HTML::Object::DOM::Element>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLLIElement>, L<Mozilla documentation on li element|https://developer.mozilla.org/en-US/docs/Web/HTML/Element/li>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
