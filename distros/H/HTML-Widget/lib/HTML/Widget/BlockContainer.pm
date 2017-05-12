package HTML::Widget::BlockContainer;

use warnings;
use strict;
use base 'HTML::Widget::Container';
use Carp qw/croak/;

__PACKAGE__->mk_accessors(qw/content pre_content post_content wrap_sub/);

=head1 NAME

HTML::Widget::BlockContainer - Block Container

=head1 DESCRIPTION

A Container for Block elements.  See L<HTML::Widget::Element::Block>
and L<HTML::Widget::Container>.

=head1 METHODS

=cut

sub _build_element {
    my ( $self, $element ) = @_;

    return () unless $element;
    if ( ref $element eq 'ARRAY' ) {
        croak("Not expecting an array");
    }

    my $wrap_sub = $self->wrap_sub || sub { return (@_); };

    my $e = $element->clone;
    $e->push_content( @{ $self->pre_content } ) if $self->pre_content;
    $e->push_content( map { &$wrap_sub( $_->as_list ); } @{ $self->content } );
    $e->push_content( @{ $self->post_content } ) if $self->post_content;

    if ( $self->label ) {
        my $l = $self->label->clone;
        $e = $l->push_content($e);
    }

    return ($e);
}

=head1 AUTHOR

Michael Gray, C<mjg@cpan.org>

=cut

1;
