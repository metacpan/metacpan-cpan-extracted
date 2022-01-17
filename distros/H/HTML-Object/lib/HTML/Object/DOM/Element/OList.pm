##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Element/OList.pm
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
package HTML::Object::DOM::Element::OList;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::DOM::Element );
    use HTML::Object::DOM::Element::Shared qw( :ol );
    our $VERSION = 'v0.1.0';
};

sub init
{
    my $self = shift( @_ );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{tag} = 'ol' if( !CORE::length( "$self->{tag}" ) );
    return( $self );
}

# Note: property compact is inherited

# Note: property reversed
sub reversed : lvalue { return( shift->_set_get_property({ attribute => 'reversed', is_boolean => 1 }, @_ ) ); }

# Note: property start
sub start : lvalue { return( shift->_set_get_property( 'start', @_ ) ); }

# Note: property type is inherited

1;
# XXX POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Element::OList - HTML Object DOM OL List Class

=head1 SYNOPSIS

    use HTML::Object::DOM::Element::OList;
    my $ol = HTML::Object::DOM::Element::OList->new || 
        die( HTML::Object::DOM::Element::OList->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This interface provides special properties (beyond those defined on the regular L<HTML::Object::Element> interface it also has available to it by inheritance) for manipulating ordered list elements.

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +-----------------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::Node | --> | HTML::Object::DOM::Element | --> | HTML::Object::DOM::Element::OList |
    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +-----------------------------------+

=head1 PROPERTIES

Inherits properties from its parent L<HTML::Object::DOM::Element>

=head2 compact

Is a boolean value indicating that spacing between list items should be reduced. This property reflects the C<compact> attribute only, it does not consider the line-height CSS property used for that behavior in modern pages.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLOListElement/compact>

=head2 reversed

Is a boolean value reflecting the C<reversed> and defining if the numbering is descending, that is its value is true, or ascending (false).

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLOListElement/reversed>

=head2 start

Is a long value reflecting the start and defining the value of the first number of the first element of the list and reflects the C<start> attribute.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLOListElement/start>

=head2 type

Is a string value reflecting the C<type> and defining the kind of marker to be used to display. It can have the following values:

=over 4

=item * '1' meaning that decimal numbers are used: 1, 2, 3, 4, 5, …

=item * 'a' meaning that the lowercase latin alphabet is used:  a, b, c, d, e, …

=item * 'A' meaning that the uppercase latin alphabet is used: A, B, C, D, E, …

=item * 'i' meaning that the lowercase latin numerals are used: i, ii, iii, iv, v, …

=item * 'I' meaning that the uppercase latin numerals are used: I, II, III, IV, V, …

=back

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLOListElement/type>

=head1 METHODS

Inherits methods from its parent L<HTML::Object::DOM::Element>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLOListElement>, L<Mozilla documentation on ol element|https://developer.mozilla.org/en-US/docs/Web/HTML/Element/ol>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
