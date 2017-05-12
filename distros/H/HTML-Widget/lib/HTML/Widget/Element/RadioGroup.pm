package HTML::Widget::Element::RadioGroup;

use warnings;
use strict;
use base 'HTML::Widget::Element';

*value = \&checked;

__PACKAGE__->mk_accessors(
    qw/
        comment label values labels comments checked _current_subelement
        constrain_values legend retain_default/
);

=head1 NAME

HTML::Widget::Element::RadioGroup - Radio Element grouping

=head1 SYNOPSIS

    my $e = $widget->element( 'RadioGroup', 'foo' );
    $e->comment('(Required)');
    $e->label('Foo'); # label for the whole thing
    $e->values([qw/foo bar gorch/]);
    $e->labels([qw/Fu Bur Garch/]); # defaults to ucfirst of values
    $e->comments([qw/funky/]); # defaults to empty
    $e->value("foo"); # the currently selected value
    $e->constrain_values(1);

=head1 DESCRIPTION

RadioGroup Element.

As of version 1.09, an L<In constraint|HTML::Widget::Constraint::In> is no 
longer automatically added to RadioGroup elements. Use L</constrain_values> 
to provide this functionality.

=head1 METHODS

=head2 comment

Add a comment to this Element.

=head2 label

This label will be placed next to your Element.

=head2 legend

Because the RadioGroup is placed in a C<fieldset> tag, you can also set a 
</legend> value. Note, however, that if you want the RadioGroup to be styled 
the same as other elements, the L</label> setting is recommended.

=head2 values

List of form values for radio checks. 
Will also be used as labels if not otherwise specified via L<labels>.

=head2 checked

=head2 value

Set which radio element will be pre-set to "checked".

L</value> is provided as an alias for L</checked>.

=head2 labels

The labels for corresponding L</values>.

=head2 constrain_values

If true, an L<In constraint|HTML::Widget::Constraint::In> will 
automatically be added to the widget, using the values from L</values>.

=head2 retain_default

If true, overrides the default behaviour, so that after a field is missing 
from the form submission, the xml output will contain the default value, 
rather than be empty.

=head2 new

=cut

sub new {
    my ( $class, $opts ) = @_;

    my $self = $class->NEXT::new($opts);

    my $values = $opts->{values};

    $self->values($values);

    $self;
}

=head2 prepare

=cut

sub prepare {
    my ( $self, $w, $value ) = @_;

    if ( $self->constrain_values ) {
        my $name = $self->name;

        my %seen;
        my @uniq = grep { !$seen{$_}++ } @{ $self->values };

        $w->constraint( 'In', $name )->in(@uniq)
            if @uniq;
    }

    return;
}

=head2 containerize

=cut

sub containerize {
    my ( $self, $w, $value, $errors, $args ) = @_;

    $value = $self->value
        if ( not defined $value )
        and $self->retain_default || not $args->{submitted};

    $value = '' if not defined $value;

    my $name   = $self->name;
    my @values = @{ $self->values || [] };
    my @labels = @{ $self->labels || [] };
    @labels = map {ucfirst} @values unless @labels;
    my @comments = @{ $self->comments || [] };

    my $i;
    my @radios = map {
        $self->_current_subelement( ++$i );    # yucky hack

        my $radio = $self->mk_input(
            $w,
            {   type => 'radio',
                ( $_ eq $value ? ( checked => "checked" ) : () ),
                value => $_,
            } );

        $radio->attr( class => "radio" );

        my $label = $self->mk_label( $w, shift @labels, shift @comments );
        $label->unshift_content($radio);

        $label;
    } @values;

    $self->_current_subelement(undef);

    my $fieldset = HTML::Element->new('fieldset');
    $fieldset->attr( class => 'radiogroup_fieldset' );

    my $outer_id = $self->attributes->{id} || $self->id($w);

    if ( defined $self->legend ) {
        my $legend = HTML::Element->new('legend');
        $legend->attr( class => 'radiogroup_legend' );
        $legend->push_content( $self->legend );
        $fieldset->push_content($legend);
    }

    # don't pass commment to mk_label, we'll handle it ourselves
    my $l = $self->mk_label( $w, $self->label, undef, $errors );
    if ($l) {
        $l->tag('span');
        $l->attr( for   => undef );
        $l->attr( class => 'radiogroup_label' );
    }

    if ( defined $self->comment ) {
        my $c = HTML::Element->new(
            'span',
            id    => "$outer_id\_comment",
            class => 'label_comments'
        );
        $c->push_content( $self->comment );
        $fieldset->push_content($c);
    }

    my $element = HTML::Element->new('span');
    $element->attr( class => 'radiogroup' );
    $element->push_content(@radios);
    $fieldset->push_content($element);

    if ($errors) {
        my $save = $fieldset;
        $fieldset = HTML::Element->new('span');
        $fieldset->attr( class => 'labels_with_errors' );
        $fieldset->attr( id    => $outer_id );
        $fieldset->push_content($save);
    }
    else {
        $fieldset->attr( id => $outer_id );
    }

    return $self->container( {
            element => $fieldset,
            error   => scalar $self->mk_error( $w, $errors ),
            label   => $l,
        } );
}

=head2 id

=cut

sub id {
    my ( $self, $w ) = @_;
    my $id      = $self->SUPER::id($w);
    my $subelem = $self->_current_subelement;

    return $subelem
        ? "${id}_$subelem"
        : $id;
}

=head1 CSS

=head2 Horizontal Alignment

To horizontally align the radio buttons with the label, use the following 
CSS.

    .radiogroup > label {
      display: inline;
    }

=head2 Changes in version 1.10

A RadioGroup is now rendered using a C<fieldset> tag, instead of a C<label> 
tag. This is because the individual radio buttons also use labels, and the 
W3C xhtml specification forbids nested C<label> tags.

To ensure RadioGroup elements are styled similar to other elements, you must 
change any CSS C<label> definitions to also target the RadioGroup's class. 
This means changing any C<label { ... }> definition to 
C<label, .radiogroup_fieldset { ... }>. If you're using the C<simple.css> 
example file, testing with firefox shows you'll also need to add 
C<margin: 0em;> to that definition to get the label to line up with other 
elements.

If you find the RadioGroup C<fieldset> picking up styles intended only for 
other fieldsets, you can either override those styles with your 
C<label, .radiogroup_fieldset { ... }> definition, or you can change your 
C<fieldset { ... }> definition to C<.widget_fieldset{ ... }> to specifically 
target any Fieldset elements other than the RadioGroup's.

Previously, if there were any errors, the L<label> tag was given the 
classname C<labels_with_errors>. Now, if there's errors, the RadioGroup 
C<fieldset> tag is wrapped in a C<span> tag which is given the classname 
C<labels_with_errors>. To ensure that any C<labels_with_errors> styles are 
properly displayed around RadioGroups, you must add C<display: block;> to 
your C<.labels_with_errros{ ... }> definition.

=head1 SEE ALSO

L<HTML::Widget::Element>

=head1 AUTHOR

Jess Robinson

Yuval Kogman

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
