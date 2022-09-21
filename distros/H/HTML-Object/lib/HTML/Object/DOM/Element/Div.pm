##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Element/Div.pm
## Version v0.2.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/01/06
## Modified 2022/09/18
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::DOM::Element::Div;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::DOM::Element );
    use vars qw( $VERSION );
    use HTML::Object::DOM::Element::Shared qw( :div );
    our $VERSION = 'v0.2.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{tag} = 'div' if( !CORE::length( "$self->{tag}" ) );
    return( $self );
}

# Note: property align inherited

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Element::Div - HTML Object DOM Div Class

=head1 SYNOPSIS

    use HTML::Object::DOM::Element::Div;
    my $div = HTML::Object::DOM::Element::Div->new ||
        die( HTML::Object::DOM::Element::Div->error, "\n" );

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

This interface provides special properties (beyond the regular L<HTML::Object::DOM::Element> interface it also has available to it by inheritance) for manipulating <div> elements.

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +---------------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::Node | --> | HTML::Object::DOM::Element | --> | HTML::Object::DOM::Element::Div |
    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +---------------------------------+

=head1 PROPERTIES

Inherits properties from its parent L<HTML::Object::DOM::Element>

=head2 align

Is a string representing an enumerated property indicating alignment of the element's contents with respect to the surrounding context. The possible values are "left", "right", "justify", and "center".

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLDivElement/align>

=head1 METHODS

Inherits methods from its parent L<HTML::Object::DOM::Element>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLDivElement>, L<Mozilla documentation on div element|https://developer.mozilla.org/en-US/docs/Web/HTML/Element/div>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
