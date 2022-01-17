##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Element/Head.pm
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
package HTML::Object::DOM::Element::Head;
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
    $self->{tag} = 'head' if( !CORE::length( "$self->{tag}" ) );
    return( $self );
}

# Note: property profile
sub profile : lvalue { return( shift->_set_get_property( 'profile', @_ ) ); }

1;
# XXX POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Element::Head - HTML Object DOM Head Class

=head1 SYNOPSIS

    use HTML::Object::DOM::Element::Head;
    my $head = HTML::Object::DOM::Element::Head->new ||
        die( HTML::Object::DOM::Element::Head->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This interface contains the descriptive information, or metadata, for a document. This object inherits all of the properties and methods described in the L<HTML::Object::DOM::Element> interface.

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +----------------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::Node | --> | HTML::Object::DOM::Element | --> | HTML::Object::DOM::Element::Head |
    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +----------------------------------+

=head1 PROPERTIES

Inherits properties from its parent L<HTML::Object::DOM::Element>

=head2 profile

Is a string representing the URIs of one or more metadata profiles (white space separated).

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLHeadElement/profile>

=head1 METHODS

Inherits methods from its parent L<HTML::Object::DOM::Element>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLHeadElement>, L<Mozilla documentation on head element|https://developer.mozilla.org/en-US/docs/Web/HTML/Element/head>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
