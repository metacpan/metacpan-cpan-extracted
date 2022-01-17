##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Element/Embed.pm
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
package HTML::Object::DOM::Element::Embed;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::DOM::Element );
    use HTML::Object::DOM::Element::Shared qw( :embed );
    our $VERSION = 'v0.1.0';
};

sub init
{
    my $self = shift( @_ );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{tag} = 'embed' if( !CORE::length( "$self->{tag}" ) );
    return( $self );
}

# Note: property align inherited

# Note: property height inherited

# Note: property name inherited

# Note: property src inherited

# Note: property type inherited

# Note: property width inherited

1;
# XXX POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Element::Embed - HTML Object DOM Embed Class

=head1 SYNOPSIS

    use HTML::Object::DOM::Element::Embed;
    my $embed = HTML::Object::DOM::Element::Embed->new || 
        die( HTML::Object::DOM::Element::Embed->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This interface provides special properties (beyond the regular L<HTML::Object::Element> interface it also has available to it by inheritance) for manipulating <embed> elements.

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +-----------------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::Node | --> | HTML::Object::DOM::Element | --> | HTML::Object::DOM::Element::Embed |
    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +-----------------------------------+

=head1 PROPERTIES

Inherits properties from its parent L<HTML::Object::DOM::Element>

=head2 align

Is a string representing an enumerated property indicating alignment of the element's contents with respect to the surrounding context. The possible values are C<left>, C<right>, C<center>, and C<justify>.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLEmbedElement/align>

=head2 height

Is a string reflecting the height HTML attribute, containing the displayed height of the resource.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLEmbedElement/height>

=head2 name

Is a string representing the name of the embedded object.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLEmbedElement/name>

=head2 src

Is a string that reflects the src HTML attribute, containing the address of the resource.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLEmbedElement/src>

=head2 type

Is a string that reflects the type HTML attribute, containing the type of the resource.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLEmbedElement/type>

=head2 width

Is a string that reflects the width HTML attribute, containing the displayed width of the resource.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLEmbedElement/width>

=head1 METHODS

Inherits methods from its parent L<HTML::Object::DOM::Element>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLEmbedElement>, L<Mozilla documentation on embed element|https://developer.mozilla.org/en-US/docs/Web/HTML/Element/embed>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
