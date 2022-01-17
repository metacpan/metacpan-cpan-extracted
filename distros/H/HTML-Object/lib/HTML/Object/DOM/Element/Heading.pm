##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Element/Heading.pm
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
package HTML::Object::DOM::Element::Heading;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::DOM::Element );
    use HTML::Object::DOM::Element::Shared qw( :heading );
    our $VERSION = 'v0.1.0';
};

sub init
{
    my $self = shift( @_ );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{tag} = 'heading' if( !CORE::length( "$self->{tag}" ) );
    return( $self );
}

# Note: property align is inherited

1;
# XXX POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Element::Heading - HTML Object DOM Heading Class

=head1 SYNOPSIS

    use HTML::Object::DOM::Element::Heading;
    my $heading = HTML::Object::DOM::Element::Heading->new ||
        die( HTML::Object::DOM::Element::Heading->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This interface represents the different heading elements, C<h1> through C<h6>. It inherits methods and properties from the L<HTML::Object::DOM::Element> interface.

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +-------------------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::Node | --> | HTML::Object::DOM::Element | --> | HTML::Object::DOM::Element::Heading |
    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +-------------------------------------+

=head1 PROPERTIES

Inherits properties from its parent L<HTML::Object::DOM::Element>

=head2 align

Is a string representing an enumerated attribute indicating alignment of the heading with respect to the surrounding context. The possible values are C<left>, C<right>, C<justify>, and C<center>.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLHeadingElement/align>

=head1 METHODS

Inherits methods from its parent L<HTML::Object::DOM::Element>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLHeadingElement>, L<Mozilla documentation on heading element|https://developer.mozilla.org/en-US/docs/Web/HTML/Element/heading>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
