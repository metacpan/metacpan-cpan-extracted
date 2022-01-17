##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Element/Unknown.pm
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
package HTML::Object::DOM::Element::Unknown;
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

1;
# XXX POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Element::Unknown - HTML Object DOM Unknown Element Class

=head1 SYNOPSIS

    use HTML::Object::DOM::Element::Unknown;
    my $unknown = HTML::Object::DOM::Element::Unknown->new || 
        die( HTML::Object::DOM::Element::Unknown->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

The C<Unknown> element interface represents an invalid L<HTML element|HTML::Object::DOM::Element> and derives from the HTML Element interface, but without implementing any additional properties or methods.

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +-------------------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::Node | --> | HTML::Object::DOM::Element | --> | HTML::Object::DOM::Element::Unknown |
    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +-------------------------------------+

=head1 PROPERTIES

Inherits properties from its parent L<HTML::Object::DOM::Element>

=head1 METHODS

Inherits methods from its parent L<HTML::Object::DOM::Element>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLUnknownElement>, L<Specifications|https://html.spec.whatwg.org/multipage/dom.html#htmlunknownelement>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
