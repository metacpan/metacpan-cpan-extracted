##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Element/HTML.pm
## Version v0.1.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/01/05
## Modified 2022/01/05
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::DOM::Element::HTML;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::DOM::Element );
    our $VERSION = 'v0.1.0';
};

sub init
{
    my $self = shift( @_ );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    return( $self );
}

# Note: property version
sub version : lvalue { return( shift->_set_get_property( 'version', @_ ) ); }

1;
# XXX POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Element::HTML - HTML Object DOM HTML Class

=head1 SYNOPSIS

    use HTML::Object::DOM::Element::HTML;
    my $html = HTML::Object::DOM::Element::HTML->new || 
        die( HTML::Object::DOM::Element::HTML->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

The L<HTML::Object::DOM::Element::Html> interface serves as the root node for a given HTML document. This object inherits the properties and methods described in the L<HTML::Object::DOM::Element> interface.

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +----------------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::Node | --> | HTML::Object::DOM::Element | --> | HTML::Object::DOM::Element::HTML |
    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +----------------------------------+

=head1 PROPERTIES

Inherits properties from its parent L<HTML::Object::DOM::Element>

=head2 version

Is a string representing the version of the HTML Document Type Definition (DTD) that governs this document. This property should not be used any more as it is non-conforming. Omit it.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLHtmlElement/version>

=head1 METHODS

Inherits methods from its parent L<HTML::Object::DOM::Element>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLHTmlElement>, L<Mozilla documentation on hr element|https://developer.mozilla.org/en-US/docs/Web/HTML/Element/html>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
