##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Element/FieldSet.pm
## Version v0.2.1
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/12/23
## Modified 2024/04/30
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::DOM::Element::FieldSet;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::DOM::Element );
    use vars qw( $VERSION );
    use HTML::Object::DOM::Element::Shared qw( :fieldset );
    our $VERSION = 'v0.2.1';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{tag} = 'audio' if( !CORE::length( "$self->{tag}" ) );
    $self->{type} = 'fieldset';
    return( $self );
}

# Note: method checkValidity inherited

# Note: property disabled inherited

# Note: property read-only
sub elements
{
    my $self = shift( @_ );
    my $children = $self->children;
    # my $form_elements = $self->new_array( [qw( button datalist fieldset input label legend meter optgroup option output progress select textarea )] );
    # <https://developer.mozilla.org/en-US/docs/Web/API/HTMLFormElement/elements#value>
    my $form_elements = $self->new_array( [qw( button fieldset input object output select textarea )] );
    my $list = $form_elements->as_hash;
    my $results = $children->grep(sub{ exists( $form_elements->{ $_->tag } ) });
    my $col = $self->new_collection_elements;
    $col->push( $results->list );
    return( $col );
}

# Note: property read-only form inherited

# Note: property name inherited

# Note: method reportValidity inherited

# Note: method setCustomValidity inherited

# Note: property read-only different from the attribute type
sub type : lvalue { return( shift->_set_get_scalar_as_object( 'type' ) ); }

# Note: property validationMessage inherited

# Note: property validity inherited

# Note: property willValidate inherited

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Element::FieldSet - HTML Object DOM Field Set Class

=head1 SYNOPSIS

    use HTML::Object::DOM::Element::FieldSet;
    my $set = HTML::Object::DOM::Element::FieldSet->new || 
        die( HTML::Object::DOM::Element::FieldSet->error, "\n" );

=head1 VERSION

    v0.2.1

=head1 DESCRIPTION

This interface provides special properties and methods (beyond the regular L<HTML::Object::Element> interface it also has available to it by inheritance) for manipulating the layout and presentation of C<<fieldset>> elements.

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +--------------------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::Node | --> | HTML::Object::DOM::Element | --> | HTML::Object::DOM::Element::FieldSet |
    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +--------------------------------------+

=head1 PROPERTIES

Inherits properties from its parent L<HTML::Object::DOM::Element>

=head2 disabled

A boolean value reflecting the disabled HTML attribute, indicating whether the user can interact with the control.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLFieldSetElement/disabled>

=head2 elements

Read-only.

The L<form elements|https://developer.mozilla.org/en-US/docs/Web/API/HTMLFormElement/elements> belonging to this field set. It returns a L<collection object|HTML::Object::DOM::Collection> of such elements found inside the fieldset.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLFieldSetElement/elements>, see this docu also for L<list of form elements|https://developer.mozilla.org/en-US/docs/Web/HTML/Element/form#see_also>

=head2 form

Read-only.

An L<HTML::Object::DOM::Element::Form> object referencing the containing form element, if this element is in a form, otherwise it returns C<undef>.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLFieldSetElement/form>

=head2 name

A string reflecting the name HTML attribute, containing the name of the field set. This can be used when accessing the field set in JavaScript. It is not part of the data which is sent to the server.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLFieldSetElement/name>

=head2 type

Read-only.

Returns the string C<fieldset> as a L<scalar object|Module::Generic::Scalar>.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLFieldSetElement/type>

=head2 validationMessage

A string representing a localized message that describes the validation constraints that the element does not satisfy (if any). This is the empty string if the element is not a candidate for constraint validation (willValidate is false), or it satisfies its constraints.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLFieldSetElement/validationMessage>

=head2 validity

A L<HTML::Object::DOM::ValidityState> representing the validity states that this element is in.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLFieldSetElement/validity>

=head2 willValidate

A boolean value false, because <fieldset> objects are never candidates for constraint validation.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLFieldSetElement/willValidate>

=head1 METHODS

Inherits methods from its parent L<HTML::Object::DOM::Element>

=head2 checkValidity

Set or get a boolean value, because under perl it does not do any checks.

Normally, under JavaScript, this always returns true because <fieldset> objects are never candidates for constraint validation.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLFieldSetElement/checkValidity>

=head2 reportValidity

Set or get a boolean value, because under perl it does not do any checks.

Normally, under JavaScript, this always returns true because <fieldset> objects are never candidates for constraint validation.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLFieldSetElement/reportValidity>

=head2 setCustomValidity

Sets a custom validity message for the field set. If this message is not the empty string, then the field set is suffering from a custom validity error, and does not validate.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLFieldSetElement/setCustomValidity>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLFieldSetElement>, L<Mozilla documentation on fieldset element|https://developer.mozilla.org/en-US/docs/Web/HTML/Element/fieldset>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
