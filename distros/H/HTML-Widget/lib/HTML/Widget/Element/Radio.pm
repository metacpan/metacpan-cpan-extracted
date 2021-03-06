package HTML::Widget::Element::Radio;

use warnings;
use strict;
use base 'HTML::Widget::Element';
use NEXT;

__PACKAGE__->mk_accessors(qw/comment checked label value retain_default/);

=head1 NAME

HTML::Widget::Element::Radio - Radio Element

=head1 SYNOPSIS

    my $e = $widget->element( 'Radio', 'foo' );
    $e->comment('(Required)');
    $e->label('Foo');
    $e->checked('checked');
    $e->value('bar');

=head1 DESCRIPTION

Radio Element.

=head1 METHODS

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

    my $name = $self->name;

    # Search for multiple radio button with the same name
    my $multi = 0;
    my @elements = $w->find_elements( name => $name );

    for my $element (@elements) {
        next if $element eq $self;
        if ( $element->isa('HTML::Widget::Element::Radio') ) {
            $multi++;
        }
    }

    # Generate unique id
    if ($multi) {
        $w->{_stash}          ||= {};
        $w->{_stash}->{radio} ||= {};
        my $num = ++$w->{_stash}->{radio}->{$name};
        my $id = $self->id( $w, "$name\_$num" );
        $self->attributes->{id} ||= $id;
    }

    my $checked =
          defined $value
        ? ( defined $value && $value eq $self->value )
        ? 'checked'
        : undef
        : undef;

    if (   !defined $value
        && ( $self->retain_default || !$args->{submitted} )
        && $self->checked )
    {
        $checked = 'checked';
    }
    $value = $self->value;

    my $l = $self->mk_label( $w, $self->label, $self->comment, $errors );
    my $i = $self->mk_input( $w,
        { checked => $checked, type => 'radio', value => $value }, $errors );

    #$l ? ( $l->unshift_content($i) ) : ( $l = $i );
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
