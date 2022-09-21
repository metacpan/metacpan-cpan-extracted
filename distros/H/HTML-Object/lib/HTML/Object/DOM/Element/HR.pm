##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Element/HR.pm
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
package HTML::Object::DOM::Element::HR;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::DOM::Element );
    use vars qw( $VERSION );
    use HTML::Object::DOM::Element::Shared qw( :hr );
    our $VERSION = 'v0.2.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{tag} = 'hr' if( !CORE::length( "$self->{tag}" ) );
    return( $self );
}

# Note: property align is inherited

# Note: property color
sub color : lvalue { return( shift->_set_get_property( 'color', @_ ) ); }

# Note: property noshade
sub noshade : lvalue { return( shift->_set_get_property({ attribute => 'noshade', is_boolean => 1 }, @_ ) ); }

# Note: property size is inherited

# Note: property width is inherited

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Element::HR - HTML Object DOM HR Class

=head1 SYNOPSIS

    use HTML::Object::DOM::Element::HR;
    my $hr = HTML::Object::DOM::Element::HR->new ||
        die( HTML::Object::DOM::Element::HR->error, "\n" );

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

This interface provides special properties (beyond those of the L<HTML::Object::DOM::Element> interface it also has available to it by inheritance) for manipulating <hr> elements.

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +--------------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::Node | --> | HTML::Object::DOM::Element | --> | HTML::Object::DOM::Element::HR |
    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +--------------------------------+

=head1 PROPERTIES

Inherits properties from its parent L<HTML::Object::DOM::Element>

=head2 align

Is a string, an enumerated attribute indicating alignment of the rule with respect to the surrounding context.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLHRElement/align>

=head2 color

Is a string representing the name of the color of the rule.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLHRElement/color>

=head2 noshade

Is a boolean value that sets the rule to have no shading.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLHRElement/noshade>

=head2 size

Is a string representing the height of the rule.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLHRElement/size>

=head2 width

Is a string representing the width of the rule on the page.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLHRElement/width>

=head1 METHODS

Inherits methods from its parent L<HTML::Object::DOM::Element>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLHRElement>, L<Mozilla documentation on hr element|https://developer.mozilla.org/en-US/docs/Web/HTML/Element/hr>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
