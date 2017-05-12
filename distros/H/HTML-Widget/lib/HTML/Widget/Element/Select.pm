package HTML::Widget::Element::Select;

use warnings;
use strict;
use base 'HTML::Widget::Element';
use HTML::Widget::Error;

*value            = \&selected;
*constrain_values = \&constrain_options;

__PACKAGE__->mk_accessors(
    qw/comment label multiple options selected constrain_options
        retain_default/
);

__PACKAGE__->mk_attr_accessors(qw/size/);

=head1 NAME

HTML::Widget::Element::Select - Select Element

=head1 SYNOPSIS

    my $e = $widget->element( 'Select', 'foo' );
    $e->comment('(Required)');
    $e->label('Foo');
    $e->size(23);
    $e->options( foo => 'Foo', bar => 'Bar' );
    $e->selected(qw/foo bar/);
    $e->constrain_options(1);

=head1 DESCRIPTION

Select Element.

As of version 1.09, an L<In constraint|HTML::Widget::Constraint::In> is no 
longer automatically added to Select elements. Use L</constrain_options> to 
provide this functionality.

=head1 METHODS

=head2 comment

Add a comment to this Element's label.

=head2 label

This label will be placed next to your Element.

=head2 size

If set to 1, the select element is displayed as a pop-up menu, otherwise the
element is displayed as a list box, with the size determining the display 
height in rows. The default size is 1.

=head2 multiple

    $widget->element( 'Select', 'foo' )->multiple( 1 );

If the multiple attribute is set, the select element is rendered as a list
box, and the user may select multiple options.

If the size is not set, the default size (height) is the number of elements.
If the size is set to 1, the element is rendered as a pop-up menu.

=head2 options

A list of options in key => value format. Each key is the unique id of an
option tag, and its corresponding value is the text displayed in the element.

=head2 selected

=head2 value

A list of keys (unique option ids) which will be pre-set to "selected".
Can also be addressed as value for consistency with the other elements

L</value> is an alias for L</selected>.

=head2 constrain_options

=head2 constrain_values

If true, an L<In constraint|HTML::Widget::Constraint::In> will 
automatically be added to the widget, using the key names from L</options>.

L</constrain_values> is an alias for L</constrain_options>.

=head2 retain_default

If true, overrides the default behaviour, so that after a field is missing 
from the form submission, the xml output will contain the default value, 
rather than be empty.

=head2 prepare

=cut

sub prepare {
    my ( $self, $w, $value ) = @_;

    if ( $self->constrain_values ) {
        my $name = $self->name;

        my %options = @{ $self->options } if ( ref $self->options );

        my @uniq = keys %options;

        $w->constraint( 'In', $name )->in(@uniq)
            if @uniq;
    }

    return;
}

=head2 process

=cut

sub process {
    my ( $self, $params, $uploads ) = @_;

    my $errors;
    my $name = $self->name;

    # only allow multiple values is multiple() is true
    if ( !$self->multiple() && ref $params->{$name} eq 'ARRAY' ) {
        push @$errors,
            HTML::Widget::Error->new( {
                name    => $name,
                type    => 'Multiple',
                message => 'Multiple Selections Not Allowed',
            } );
    }
    return $errors;
}

=head2 containerize

=cut

sub containerize {
    my ( $self, $w, $value, $errors, $args ) = @_;

    my $options = $self->options;
    my @options = ref $options eq 'ARRAY' ? @$options : ();
    my @o;
    my @values;
    if ( defined $value ) {
        @values = ref $value eq 'ARRAY' ? @$value : ($value);
    }
    elsif ( $self->retain_default || !$args->{submitted} ) {
        @values =
            ref $self->selected eq 'ARRAY'
            ? @{ $self->selected }
            : ( $self->selected );
    }

    # You might be tempted to say 'while ( my $key = shift( @temp_options ) )'
    # here, but then that falls if the first element is a 0 :-) So we do the
    # following bit of nastiness instead:

    my @temp_options = @options;
    while ( scalar @temp_options ) {

        my $key    = shift(@temp_options);
        my $value  = shift(@temp_options);
        my $option = HTML::Element->new( 'option', value => $key );
        for my $val (@values) {
            if ( ( defined $val ) && ( $val eq $key ) ) {
                $option->attr( selected => 'selected' );
                last;
            }
        }
        $option->push_content($value);
        push @o, $option;
    }

    my $label = $self->mk_label( $w, $self->label, $self->comment, $errors );

    $self->attributes->{class} ||= 'select';
    my $selectelm = HTML::Element->new('select');
    $selectelm->push_content(@o);

    # if ($label) {
    #     $label->push_content($selectelm);
    # }
    #
    #    $l ? ( $l->push_content($i) ) : ( $l = $i );

    my $id = $self->id($w);
    $selectelm->attr( id   => $id );
    $selectelm->attr( name => $self->name );

    $selectelm->attr( multiple => 'multiple' )
        if $self->multiple;

    $selectelm->attr( $_ => ${ $self->attributes }{$_} )
        for ( keys %{ $self->attributes } );

    #    $l->push_content($i);

    my $e = $self->mk_error( $w, $errors );

    return $self->container(
        { element => $selectelm, error => $e, label => $label } );
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
