##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Element/Picture.pm
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
package HTML::Object::DOM::Element::Picture;
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
    $self->{tag} = 'picture' if( !CORE::length( "$self->{tag}" ) );
    return( $self );
}

1;
# XXX POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Element::Picture - HTML Object DOM Picture Class

=head1 SYNOPSIS

    use HTML::Object::DOM::Element::Picture;
    my $picture = HTML::Object::DOM::Element::Picture->new ||
        die( HTML::Object::DOM::Element::Picture->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

Experimental: This is reportedly an experimental technology. Check the Browser compatibility table carefully before using this in production.

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +-------------------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::Node | --> | HTML::Object::DOM::Element | --> | HTML::Object::DOM::Element::Picture |
    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +-------------------------------------+

=head1 PROPERTIES

Inherits properties from its parent L<HTML::Object::DOM::Element>

=head1 METHODS

Inherits methods from its parent L<HTML::Object::DOM::Element>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLPictureElement>, L<Mozilla documentation on picture element|https://developer.mozilla.org/en-US/docs/Web/HTML/Element/picture>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
