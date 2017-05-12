package HTML::Widget::Element::Upload;

use warnings;
use strict;
use base 'HTML::Widget::Element';

__PACKAGE__->mk_accessors(qw/comment label/);
__PACKAGE__->mk_attr_accessors(qw/accept maxlength size/);

=head1 NAME

HTML::Widget::Element::Upload - Upload Element

=head1 SYNOPSIS

    my $e = $widget->element( 'Upload', 'foo' );
    $e->comment('(Required)');
    $e->label('Foo');
    $e->accept('text/html');
    $e->maxlength(1000);
    $e->size(23);

=head1 DESCRIPTION

Upload Element.

Adding an Upload element automatically calls
C<$widget->enctype('multipart/form-data')> for you.

=head1 METHODS

=head2 accept

Arguments: $type

A comma-separated list of media types, as per C<RFC2045>.

=head2 prepare

=cut

sub prepare {
    my ( $self, $w ) = @_;

    # force multipart
    $w->enctype('multipart/form-data');

    return;
}

=head2 containerize

=cut

sub containerize {
    my ( $self, $w, $value, $errors ) = @_;

    $value = ref $value eq 'ARRAY' ? shift @$value : $value;

    my $l = $self->mk_label( $w, $self->label, $self->comment, $errors );
    my $i = $self->mk_input( $w, { type => 'file', value => $value }, $errors );
    my $e = $self->mk_error( $w, $errors );

    return $self->container( { element => $i, error => $e, label => $l } );
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
