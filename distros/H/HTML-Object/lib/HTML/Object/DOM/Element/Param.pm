##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Element/Param.pm
## Version v0.1.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/12/23
## Modified 2021/12/23
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::DOM::Element::Param;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::DOM::Element );
    use HTML::Object::DOM::Element::Shared qw( :param );
    our $VERSION = 'v0.1.0';
};

sub init
{
    my $self = shift( @_ );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{tag} = 'param' if( !CORE::length( "$self->{tag}" ) );
    return( $self );
}

# Note: property name inherited

# Note: property type inherited

# Note: property value inherited

# Note: property valueType
sub valueType : lvalue { return( shift->_set_get_property( 'valuetype', @_ ) ); }

1;
# XXX POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Element::Param - HTML Object DOM Param Class

=head1 SYNOPSIS

    use HTML::Object::DOM::Element::Param;
    my $param = HTML::Object::DOM::Element::Param->new || 
        die( HTML::Object::DOM::Element::Param->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This interface provides special properties (beyond those of the regular L<HTML::Object::Element> object interface it inherits) for manipulating <param> elements, representing a pair of a key and a value that acts as a parameter for an <object> element.

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +-----------------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::Node | --> | HTML::Object::DOM::Element | --> | HTML::Object::DOM::Element::Param |
    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +-----------------------------------+

=head1 PROPERTIES

Inherits properties from its parent L<HTML::Object::DOM::Element>

=head2 name

Is a string representing the name of the parameter. It reflects the name attribute.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLParamElement/name>

=head2 type

Is a string containing the type of the parameter when valueType has the "ref" value. It reflects the type attribute.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLParamElement/type>

=head2 value

Is a string representing the value associated to the parameter. It reflects the value attribute.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLParamElement/value>

=head2 valueType

Is a string containing the type of the value. It reflects the valuetype attribute and has one of the values: "data", "ref", or "object".

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLParamElement/valueType>

=head1 METHODS

Inherits methods from its parent L<HTML::Object::DOM::Element>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLParamElement>, L<Mozilla documentation on param element|https://developer.mozilla.org/en-US/docs/Web/HTML/Element/param>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
