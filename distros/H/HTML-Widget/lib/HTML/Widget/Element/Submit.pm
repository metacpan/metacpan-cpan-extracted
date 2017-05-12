package HTML::Widget::Element::Submit;

use warnings;
use strict;
use base 'HTML::Widget::Element::Button';
use NEXT;

=head1 NAME

HTML::Widget::Element::Submit - Submit Element

=head1 SYNOPSIS

    $e = $widget->element( 'Submit', 'foo' );
    $e->value('bar');

=head1 DESCRIPTION

Submit button element.

Inherits all methods from L<HTML::Widget::Element::Button>.

Automatically sets L<type|HTML::Widget::Element::Button/type> to C<submit>.

=head1 METHODS

=head2 new

=cut

sub new {
    return shift->NEXT::new(@_)->type('submit');
}

=head2 value

=head2 label

Sets the form field value. Is also used by the browser as the 
button label.

If not set, the browser will usually display the label as "Submit".

L</label> is an alias for L</value>.

=head2 retain_default

If true, overrides the default behaviour, so that after a field is missing 
from the form submission, the xml output will contain the default value, 
rather than be empty.

=head1 SEE ALSO

L<HTML::Widget::Element>

=head1 AUTHOR

Sebastian Riedel, C<sri@oook.de>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
