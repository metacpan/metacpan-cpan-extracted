package HTML::Widget::Element::Hidden;

use warnings;
use strict;
use base 'HTML::Widget::Element';
use NEXT;

__PACKAGE__->mk_accessors(qw/value retain_default/);

=head1 NAME

HTML::Widget::Element::Hidden - Hidden Element

=head1 SYNOPSIS

    my $e = $widget->element( 'Hidden', 'foo' );
    $e->value('bar');

=head1 DESCRIPTION

Hidden Element.

=head1 METHODS

=head2 value

Default value is 1.

=head2 retain_default

If true, overrides the default behaviour, so that after a field is missing 
from the form submission, the xml output will contain the default value, 
rather than be empty.

=head2 new

=cut

sub new {
    shift->NEXT::new(@_)->value(1);
}

=head2 containerize

=cut

sub containerize {
    my ( $self, $w, $value, $errors, $args ) = @_;

    $value = ref $value eq 'ARRAY' ? shift @$value : $value;

    $value = $self->value
        if ( not defined $value )
        and $self->retain_default || not $args->{submitted};

    my $i = $self->mk_input( $w, { type => 'hidden', value => $value } );

    return $self->container( { element => $i } );
}

=head1 SEE ALSO

L<HTML::Widget::Element>

=head1 AUTHOR

Sebastian Riedel, C<sri@oook.de>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
