package HTML::Widget::Element::Reset;

use warnings;
use strict;
use base 'HTML::Widget::Element::Button';
use NEXT;

=head1 NAME

HTML::Widget::Element::Reset - Reset Element

=head1 SYNOPSIS

    $e = $widget->element( 'Reset', 'foo' );
    $e->value('bar');

=head1 DESCRIPTION

Reset button element.

Inherits all methods from L<HTML::Widget::Element::Button>.

Automatically sets L<type|HTML::Widget::Element::Button/type> to C<reset>.

=head1 METHODS

=head2 new

=cut

sub new {
    return shift->NEXT::new(@_)->type('reset');
}

=head2 label

=head2 value

Sets the form field value. Is also used by the browser as the 
button label.

If not set, the browser will usually display the label as "Reset".

L</label> is an alias for L</value>.

=head1 SEE ALSO

L<HTML::Widget::Element::Button>, L<HTML::Widget::Element>

=head1 AUTHOR

Sebastian Riedel, C<sri@oook.de>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
