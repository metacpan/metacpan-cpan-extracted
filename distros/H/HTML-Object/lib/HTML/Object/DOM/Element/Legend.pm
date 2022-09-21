##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Element/Legend.pm
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
package HTML::Object::DOM::Element::Legend;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::DOM::Element );
    use vars qw( $VERSION );
    use HTML::Object::DOM::Element::Shared qw( :legend );
    our $VERSION = 'v0.2.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{tag} = 'legend' if( !CORE::length( "$self->{tag}" ) );
    return( $self );
}

# Note: property accessKey inherited

# Note: property align inherited

# Note: property form inherited

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Element::Legend - HTML Object DOM Legend Class

=head1 SYNOPSIS

    use HTML::Object::DOM::Element::Legend;
    my $legend = HTML::Object::DOM::Element::Legend->new || 
        die( HTML::Object::DOM::Element::Legend->error, "\n" );

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

The L<HTML::Object::DOM::Element::Legend> is an interface allowing to access properties of the C<<legend>> elements. It inherits properties and methods from the L<HTML::Object::Element> interface.

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +------------------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::Node | --> | HTML::Object::DOM::Element | --> | HTML::Object::DOM::Element::Legend |
    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +------------------------------------+

=head1 PROPERTIES

Inherits properties from its parent L<HTML::Object::DOM::Element>

=head2 accessKey

Is a string representing a single-character access key to give access to the element.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLLegendElement/accessKey>

=head2 align

Is a string representing the alignment relative to the form set

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLLegendElement/align>

=head2 form

Is a L<HTML::Object::DOM::Element::Form> representing the form that this legend belongs to. If the legend has a L<fieldset element|HTML::Object::DOM::Element::FieldSet> as its parent, then this attribute returns the same value as the form attribute on the parent L<fieldset element|HTML::Object::DOM::Element::FieldSet>. Otherwise, it returns C<undef>.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLLegendElement/form>

=head1 METHODS

Inherits methods from its parent L<HTML::Object::DOM::Element>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLLegendElement>, L<Mozilla documentation on legend element|https://developer.mozilla.org/en-US/docs/Web/HTML/Element/legend>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
