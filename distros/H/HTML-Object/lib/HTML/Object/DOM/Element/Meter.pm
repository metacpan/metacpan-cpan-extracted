##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Element/Meter.pm
## Version v0.1.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/01/10
## Modified 2022/01/10
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::DOM::Element::Meter;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::DOM::Element );
    use HTML::Object::DOM::Element::Shared qw( :meter );
    our $VERSION = 'v0.1.0';
};

sub init
{
    my $self = shift( @_ );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{tag} = 'meter' if( !CORE::length( "$self->{tag}" ) );
    return( $self );
}

# Note: property high
sub high : lvalue { return( shift->_set_get_property( 'high', @_ ) ); }

# Note: property labels read-only is inherited

# Note: property low
sub low : lvalue { return( shift->_set_get_property( 'low', @_ ) ); }

# Note: property max is inherited

# Note: property min is inherited

# Note: property optimum
sub optimum : lvalue { return( shift->_set_get_property( 'optimum', @_ ) ); }

# Note: property value is inherited

1;
# XXX POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Element::Meter - HTML Object DOM Meter Class

=head1 SYNOPSIS

    use HTML::Object::DOM::Element::Meter;
    my $meter = HTML::Object::DOM::Element::Meter->new || 
        die( HTML::Object::DOM::Element::Meter->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

The HTML <meter> elements expose the HTMLMeterElement interface, which provides special properties and methods (beyond the L<HTML::Object::DOM::Element> object interface they also have available to them by inheritance) for manipulating the layout and presentation of <meter> elements.

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +-----------------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::Node | --> | HTML::Object::DOM::Element | --> | HTML::Object::DOM::Element::Meter |
    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +-----------------------------------+

=head1 PROPERTIES

Inherits properties from its parent L<HTML::Object::DOM::Element>

=head2 high

A double representing the value of the high boundary, reflecting the high attribute.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMeterElement/high>

=head2 labels

Read-only.

A C<NodeList> of <label> elements that are associated with the element.

Example:

    my $labelElements = meter->labels;

    <label id="label1" for="test">Label 1</label>
    <meter id="test" min="0" max="100" value="70">70</meter>
    <label id="label2" for="test">Label 2</label>

Another example:

    window->addEventListener( DOMContentLoaded => sub
    {
        my $meter = $doc->getElementById( 'test' );
        for( my $i = 0; $i < $meter->labels->length; $i++ )
        {
            say( $meter->labels->[$i]->textContent ); # "Label 1" and "Label 2"
        }
    });

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMeterElement/labels>

=head2 low

A double representing the value of the low boundary, reflecting the lowattribute.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMeterElement/low>

=head2 max

A double representing the maximum value, reflecting the max attribute.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMeterElement/max>

=head2 min

A double representing the minimum value, reflecting the min attribute.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMeterElement/min>

=head2 optimum

A double representing the optimum, reflecting the optimum attribute.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMeterElement/optimum>

=head2 value

A double representing the currrent value, reflecting the value attribute.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMeterElement/value>

=head1 METHODS

Inherits methods from its parent L<HTML::Object::DOM::Element>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMeterElement>, L<Mozilla documentation on meter element|https://developer.mozilla.org/en-US/docs/Web/HTML/Element/meter>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

