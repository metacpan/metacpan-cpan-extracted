##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Element/Select.pm
## Version v0.2.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/12/23
## Modified 2022/09/18
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::DOM::Element::Select;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::DOM::Element );
    use vars qw( $VERSION );
    use HTML::Object::DOM::Element::Shared qw( :select );
    our $VERSION = 'v0.2.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{tag} = 'select' if( !CORE::length( "$self->{tag}" ) );
    $self->{options} = [];
    $self->{_select_reset} = 1;
    my $callback = sub
    {
        my $def = shift( @_ );
        # Our children were modified from outside our package.
        # We need to check if it affects our rows and reset the cache accordingly
        unless( $def->{caller}->[0] eq ref( $self ) ||
                $def->{caller}->[0] eq 'HTML::Object::DOM::Element::Select' )
        {
            $self->reset(1);
        }
        return(1);
    };
    $self->children->callback( add => $callback );
    $self->children->callback( remove => $callback );
    return( $self );
}

sub add
{
    my $self = shift( @_ );
    return( $self->error({
        message => sprintf( "At least 1 argument is required, but only %d was provided.", scalar( @_ ) ),
        class => 'HTML::Object::SyntaxError',
    }) ) if( scalar( @_ ) < 1 );
    my( $elem, $pos ) = @_;
    return( $self->error({
        message => "Element provided is neither a HTML::Object::DOM::Element::Option object nor a HTML::Object::DOM::Element::OptGroup object.",
        class => 'HTML::Object::TypeError',
    }) ) if( !$self->_is_a( $elem => 'HTML::Object::DOM::Element::Option' ) && !$self->_is_a( $elem => 'HTML::Object::DOM::Element::OptGroup' ) );
    my $options = $self->options;
    my $size = $options->size;
    if( defined( $pos ) && CORE::length( $pos ) )
    {
        if( !$self->_is_a( $elem => 'HTML::Object::DOM::Element::Option' ) && 
            !$self->_is_a( $elem => 'HTML::Object::DOM::Element::OptGroup' ) && 
            !$self->_is_integer( $pos ) )
        {
            return( $self->error({
                message => "The offset position before which to insert the element, if provided, must be an object or an integer, but I got '" . overload::StrVal( $pos ) . "'.",
                class => 'HTML::Object::TypeError',
            }) );
        }
        elsif( $self->_is_a( $elem => 'HTML::Object::DOM::Element::Option' ) ||
               $self->_is_a( $elem => 'HTML::Object::DOM::Element::OptGroup' ) )
        {
            # Check if it is an ancestor, as per the specifications
            my $lineage = $self->lineage;
            my $lineagePos = $lineage->pos( $elem );
            if( defined( $lineagePos ) )
            {
                return( $self->error({
                    message => "Element to be added to this select element is an ancestor.",
                    class => 'HTML::Object::HierarchyRequestError',
                }) );
            }
            
            my $tmpPos = $options->pos( $elem );
            if( defined( $tmpPos ) )
            {
                $pos = $tmpPos;
            }
            else
            {
                undef( $pos );
            }
        }
        else
        {
            if( $pos < 0 )
            {
                $pos = $pos + $size;
            }
            elsif( $pos > $size )
            {
                undef( $pos );
            }
        }
    }
    $elem->detach;
    $elem->parent( $self );
    my $children = $self->children;
    if( defined( $pos ) && CORE::length( $pos ) )
    {
        my $kid = $options->index( $pos );
        my $real_pos = $children->pos( $kid );
        $children->splice( $real_pos, 0, $elem );
    }
    else
    {
        $children->push( $elem );
    }
    $self->reset(1);
    return( $self );
}

# Note: property autofocus
sub autofocus : lvalue { return( shift->_set_get_property( 'autofocus', @_ ) ); }

sub blur { return; }

# Note: method checkValidity is inherited

# Note: property disabled is inherited

sub focus { return; }

# Note: property form read-only is inherited

sub item { return( shift->options->index( @_ ) ); }

# Note: property labels read-only is inherited

# Note: property length
sub length : lvalue { return( shift->_set_get_property( 'length', @_ ) ); }

# Note: property multiple
sub multiple : lvalue { return( shift->_set_get_property( 'multiple', @_ ) ); }

# Note: property name is inherited

# Note: method namedItem is inherited from HTML::Object::DOM::Collection
sub namedItem { return( shift->options->namedItem( @_ ) ); }

sub onchange : lvalue { return( shift->on( 'change', @_ ) ); }

sub oninput : lvalue { return( shift->on( 'input', @_ ) ); }

# Note: property options read-only
# sub options { return( shift->_set_get_object( 'options', 'HTML::Object::DOM::Element::OptionsCollection', @_ ) ); }
sub options
{
    my $self = shift( @_ );
    return( $self->{_select_options} ) if( $self->{_select_options} && !$self->_is_select_reset );
    my $list = $self->children->grep(sub{ $self->_is_a( $_ => 'HTML::Object::DOM::Element::Option' ) });
    # The content of the collection is refreshed, but the collection object itself does not change, so the user can poll it
    unless( $self->{_select_options} )
    {
        $self->_load_class( 'HTML::Object::DOM::Element::OptionsCollection' ) || return( $self->pass_error );
        $self->{_select_options} = HTML::Object::DOM::Element::OptionsCollection->new || 
            return( $self->pass_error( HTML::Object::DOM::Element::OptionsCollection->error ) );
    }
    $self->{_select_options}->set( $list );
    $self->_remove_select_reset;
    return( $self->{_select_options} );
}

sub remove
{
    my $self = shift( @_ );
    my $pos  = shift( @_ );
    return( $self->error({
        message => "Index value provided ($pos) is not an integer",
        class => 'HTML::Object::IndexSizeError',
    }) ) if( !defined( $pos ) || !CORE::length( "$pos" ) || !$self->_is_integer( $pos ) );
    my $options = $self->options;
    return( $self->error({
        message => "Index value provided ($pos) is greater than the zero-based total number of options.",
        class => 'HTML::Object::IndexSizeError',
    }) ) if( $pos > $options->size );
    my $elem = $options->index( $pos );
    my $real_pos = $self->children->pos( $elem );
    return( $self->error({
        message => "Could not find the real index position of element found at offset '$pos'.",
        class => 'HTML::Object::HierarchyRequestError',
    }) ) if( !defined( $real_pos ) );
    $self->children->splice( $real_pos, 1 );
    $elem->parent( undef );
    $self->reset(1);
    return( $elem );
}

# Note: method reportValidity is inherited

# Note: property required is inherited

sub reset
{
    my $self = shift( @_ );
    if( scalar( @_ ) )
    {
        $self->_reset_select;
        # Force the rebuilding of the collection of selected options
        CORE::delete( $self->{_selected_options} );
        CORE::delete( $self->{selectedindex} );
        return( $self->SUPER::reset( @_ ) );
    }
    return( $self );
}

# Note: property selectedIndex
# This is called by the HTML::Object::DOM::Element::Option when selected
# sub selectedIndex : lvalue { return( shift->_set_get_number( 'selectedindex', @_ ) ); }
sub selectedIndex : lvalue { return( shift->_lvalue({
    set => sub
    {
        my( $self, $val ) = @_;
        return( $self->error({
            message => "Index value provided is not an integer.",
            class => 'HTML::Object::TypeError',
        }) ) if( !$self->_is_integer( $val ) );
        my $options = $self->options;
        return( $self->error({
            message => "Index value provided is greater than the zero-based total number (" . $options->size . ") of options available.",
            class => 'HTML::Object::IndexSizeError',
        }) ) if( $val > $options->size );
        $self->{selectedindex} = $val;
        my $elem = $options->index( $val );
        return( $self->error({
            message => "Somehow, the element found at position $val is not an HTML::Object::DOM::Element::Option object.",
            class => 'HTML::Object::HierarchyRequestError',
        }) ) if( !$self->_is_a( $elem => 'HTML::Object::DOM::Element::Option' ) );
        $elem->defaultSelected = 1;
        return( $elem );
    },
    get => sub
    {
        my $self = shift( @_ );
        return( $self->{selectedindex} ) if( $self->{selectedindex} && !$self->_is_select_reset );
        # Get all options
        my $options = $self->options;
        # Get all selected ones; could be empty
        my $selected = $self->selectedOptions;
        return if( $selected->is_empty );
        # Get the first selected one
        my $elem = $selected->index(0);
        # Find its index position among all options
        my $pos = $options->pos( $elem );
        # and return it.
        return( $self->{selectedindex} = $pos );
    },
}, @_ ) ); }

# Note: property selectedOptions read-only
sub selectedOptions
{
    my $self = shift( @_ );
    return( $self->{_selected_options} ) if( $self->{_selected_options} && !$self->_is_select_reset );
    my $list = $self->options->filter(sub{ $_->defaultSelected });
    $self->children->for(sub
    {
        my( $i, $elem ) = @_;
        
    });
    # The content of the collection is refreshed, but the collection object itself does not change, so the user can poll it
    unless( $self->{_selected_options} )
    {
        $self->_load_class( 'HTML::Object::DOM::Collection' ) || return( $self->pass_error );
        $self->{_selected_options} = HTML::Object::DOM::Collection->new || 
            return( $self->pass_error( HTML::Object::DOM::Collection->error ) );
    }
    $self->{_selected_options}->set( $list );
    $self->_remove_select_reset;
    return( $self->{_selected_options} );
}

# Note: method setCustomValidity is inherited

# Note: property size
sub size : lvalue { return( shift->_set_get_property( 'size', @_ ) ); }

# Note: property type read-only is inherited

# Note: property validationMessage read-only is inherited

# Note: property validity read-only is inherited

# Note: property value is inherited

# Note: property willValidate read-only is inherited

sub _is_select_reset { return( CORE::length( shift->{_select_reset} ) ); }

sub _remove_select_reset { return( CORE::delete( shift->{_select_reset} ) ); }

sub _reset_select
{
    my $self = shift( @_ );
    $self->{_select_reset}++;
    # Force it to recompute
    $self->options;
    return( $self );
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Element::Select - HTML Object DOM Select Class

=head1 SYNOPSIS

    use HTML::Object::DOM::Element::Select;
    my $select = HTML::Object::DOM::Element::Select->new || 
        die( HTML::Object::DOM::Element::Select->error, "\n" );

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

This interface represents a C<<select>> HTML Element. These elements also share all of the properties and methods of other HTML elements via the L<HTML::Object::DOM::Element> interface.

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +------------------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::Node | --> | HTML::Object::DOM::Element | --> | HTML::Object::DOM::Element::Select |
    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +------------------------------------+

=head1 PROPERTIES

Inherits properties from its parent L<HTML::Object::DOM::Element>

=head2 autofocus

A boolean value reflecting the autofocus L<HTML attribute|HTML::Object::DOM::Attribute>, which indicates whether the control should have input focus when the page loads, unless the user overrides it, for example by typing in a different control. Only one form-associated element in a document can have this attribute specified.

Example:

    <select id="mySelect" autofocus>
        <option>Option 1</option>
        <option>Option 2</option>
    </select>

    # Check if the autofocus attribute on the <select>
    my $hasAutofocus = $doc->getElementById('mySelect')->autofocus;

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLSelectElement/autofocus>

=head2 disabled

A boolean value reflecting the disabled L<HTML attribute|HTML::Object::DOM::Attribute>, which indicates whether the control is disabled. If it is disabled, it does not accept clicks.

Example:

    <label>
        Allow drinks?
        <input id="allow-drinks" type="checkbox" />
    </label>

    <label for="drink-select">Drink selection:</label>
    <select id="drink-select" disabled>
        <option value="1">Water</option>
        <option value="2">Beer</option>
        <option value="3">Pepsi</option>
        <option value="4">Whisky</option>
    </select>

    my $allowDrinksCheckbox = $doc->getElementById( 'allow-drinks' );
    my $drinkSelect = $doc->getElementById( 'drink-select' );

    $allowDrinksCheckbox->addEventListener( change => sub
    {
        if( $event->target->checked )
        {
            $drinkSelect->disabled = 0; # false
        }
        else
        {
            $drinkSelect->disabled = 1; # true
        }
    }, { capture => 0});

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLSelectElement/disabled>

=head2 form

Read-only.

An L<HTML::Object::DOM::Element::Form> referencing the form that this element is associated with. If the element is not associated with of a <form> element, then it returns C<undef>.

Example:

    <form id="pet-form">
        <label for="pet-select">Choose a pet</label>
        <select name="pets" id="pet-select">
            <option value="dog">Dog</option>
            <option value="cat">Cat</option>
            <option value="parrot">Parrot</option>
        </select>

        <button type="submit">Submit</button>
    </form>

    <label for="lunch-select">Choose your lunch</label>
    <select name="lunch" id="lunch-select">
            <option value="salad">Salad</option>
            <option value="sandwich">Sandwich</option>
    </select>

    my $petSelect = $doc->getElementById( 'pet-select' );
    my $petForm = $petSelect->form; # <form id="pet-form">

    my $lunchSelect = $doc->getElementById( 'lunch-select' );
    my $lunchForm = $lunchSelect->form; # undef

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLSelectElement/form>

=head2 labels

Read-only.

A L<HTML::Object::DOM::NodeList> of L<label elements|HTML::Object::DOM::Element::Label> associated with the element.

Example:

    <label id="label1" for="test">Label 1</label>
    <select id="test">
        <option value="1">Option 1</option>
        <option value="2">Option 2</option>
    </select>
    <label id="label2" for="test">Label 2</label>

    window->addEventListener( DOMContentLoaded => sub
    {
        my $select = $doc->getElementById( 'test' );
        for( my $i = 0; $i < $select->labels->length; $i++ )
        {
            say( $select->labels->[$i]->textContent ); # "Label 1" and "Label 2"
        }
    });

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLSelectElement/labels>

=head2 length

An unsigned long that reflects the number of L<option elements|HTML::Object::DOM::Element::Option> in this select element.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLSelectElement/length>

=head2 multiple

A boolean value reflecting the multiple L<HTML attribute|HTML::Object::DOM::Attribute>, which indicates whether multiple items can be selected.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLSelectElement/multiple>

=head2 name

A string reflecting the name L<HTML attribute|HTML::Object::DOM::Attribute>, containing the name of this control used by servers and DOM search functions.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLSelectElement/name>

=head2 options

Read-only.

An L<OptionsCollection|HTML::Object::DOM::Element::OptionsCollection> representing the set of L<option elements|HTML::Object::DOM::Element::Option> contained by this element.

Example:

    <label for="test">Label</label>
    <select id="test">
        <option value="1">Option 1</option>
        <option value="2">Option 2</option>
    </select>

    window->addEventListener( DOMContentLoaded => sub
    {
        my $select = $doc->getElementById( 'test' );
        for( my $i = 0; $i < $select->options->length; $i++ )
        {
            say( $select->options->[$i]->label ); # "Option 1" and "Option 2"
        }
    });

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLSelectElement/options>

=head2 required

A boolean value reflecting the required L<HTML attribute|HTML::Object::DOM::Attribute>, which indicates whether the user is required to select a value before submitting the form.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLSelectElement/required>

=head2 selectedIndex

A long reflecting the index of the first selected L<option element|HTML::Object::DOM::Element::Option>. The value C<undef> indicates no element is selected.

Example:

    <p id="p">selectedIndex: 0</p>
    <select id="select">
        <option selected>Option A</option>
        <option>Option B</option>
        <option>Option C</option>
        <option>Option D</option>
        <option>Option E</option>
    </select>

    my $selectElem = $doc->getElementById('select');
    my $pElem = $doc->getElementById('p');

    # When a new <option> is selected
    $selectElem->addEventListener( change => sub
    {
        my $index = $selectElem->selectedIndex;
        # Add that data to the <p>
        $pElem->innerHTML = 'selectedIndex: ' . $index;
    })

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLSelectElement/selectedIndex>

=head2 selectedOptions

Read-only.

An L<Collection|HTML::Object::DOM::Collection> representing the set of L<option elements|HTML::Object::DOM::Element::Option> that are selected.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLSelectElement/selectedOptions>

=head2 size

A long reflecting the size L<HTML attribute|HTML::Object::DOM::Attribute>, which contains the number of visible items in the control. The default is 1, unless multiple is true, in which case it is 4.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLSelectElement/size>

=head2 type

Read-only.

A string represeting the form control's type. When multiple is true, it returns C<select-multiple>; otherwise, it returns C<select-one>.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLSelectElement/type>

=head2 validationMessage

Read-only.

A string representing a localized message that describes the validation constraints that the control does not satisfy (if any). This attribute is the empty string if the control is not a candidate for constraint validation (willValidate is false), or it satisfies its constraints.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLSelectElement/validationMessage>

=head2 validity

Read-only.

A L<ValidityState|HTML::Object::DOM::ValidityState> object reflecting the validity state that this control is in.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLSelectElement/validity>

=head2 value

A string reflecting the value of the form control. Returns the value property of the first selected option element if there is one, otherwise the empty string.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLSelectElement/value>

=head2 willValidate

Read-only.

A boolean value that indicates whether the button is a candidate for constraint validation. It is false if any conditions bar it from constraint validation.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLSelectElement/willValidate>

=head1 METHODS

Inherits methods from its parent L<HTML::Object::DOM::Element>

=head2 add

Provided with an C<item> and optionally an position offset C<before> which to insert the item and this adds an element to the collection of option elements for this select element.

=over 4

=item C<item> is an L<Option element|HTML::Object::DOM::Element::Option> or L<OptGroup element|HTML::Object::DOM::Element::OptGroup>

=item C<before> is optional and an element of the collection, or an index of type long, representing the item should be inserted before. If this parameter is C<undef> (or the index does not exist), the new element is appended to the end of the collection.

=back

Example:

    my $sel = $doc->createElement( 'select' );
    my $opt1 = $doc->createElement( 'option' );
    my $opt2 = $doc->createElement( 'option' );

    $opt1->value = 1;
    $opt1->text = "Option: Value 1";

    $opt2->value = 2;
    $opt2->text = "Option: Value 2";

    # No second argument; no 'before' argument
    $sel->add( $opt1, undef );
    # Equivalent to above
    $sel->add( $opt2 );

Produces the following, conceptually:

    <select>
        <option value="1">Option: Value 1</option>
        <option value="2">Option: Value 2</option>
    </select>

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLSelectElement/add>

=head2 blur

Under perl, of course, this does nothing.

Under JavaScript, this removes the input focus from this element. This method is now implemented on L<HTML::Object::DOM::Element>.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLSelectElement/blur>

=head2 checkValidity

Checks whether the element has any constraints and whether it satisfies them. If the element fails its constraints, the browser fires a cancelable invalid event at the element (and returns false).

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLSelectElement/checkValidity>

=head2 focus

Under perl, of course, this does nothing.

Under JavaScript, this gives input focus to this element. This method is now implemented on L<HTML::Object::DOM::Element>.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLSelectElement/focus>

=head2 item

Gets an item from the options collection for this L<select element|HTML::Object::DOM::Select> by providing a zero-based index position.

Example:

    <select id="myFormControl">
        <option id="o1">Opt 1</option>
        <option id="o2">Opt 2</option>
    </select>

    # Returns the OptionElement representing #o2
    my $sel = $doc->getElementById( 'myFormControl' );
    my $elem1 = $sel->item(1); # Opt 2

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLSelectElement/item>

=head2 namedItem

Gets the item in the options collection with the specified name. The name string can match either the id or the name attribute of an option node.

Example:

    <select id="myFormControl">
        <option id="o1">Opt 1</option>
        <option id="o2">Opt 2</option>
    </select>

    my $elem1 = $doc->getElementById( 'myFormControl' )->namedItem( 'o1' ); # Returns the OptionElement representing #o1

This is, in effect, a shortcut for C<$select->options->namedItem>

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLSelectElement/namedItem>

=head2 remove

Removes the element at the specified index (zero-based) from the options collection for this select element and return it.

Example:

    <select id="existingList" name="existingList">
        <option value="1">Option: Value 1</option>
        <option value="2">Option: Value 2</option>
        <option value="3">Option: Value 3</option>
    </select>

    my $sel = $doc->getElementById( 'existingList' );
    my $removed = $sel->remove(1);

HTML is now:

    <select id="existingList" name="existingList">
        <option value="1">Option: Value 1</option>
        <option value="3">Option: Value 3</option>
    </select>

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLSelectElement/remove>

=head2 reportValidity

This method reports the problems with the constraints on the element, if any, to the user. If there are problems, it fires a cancelable invalid event at the element, and returns false; if there are no problems, it returns true.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLSelectElement/reportValidity>

=head2 setCustomValidity

Sets the custom validity message for the selection element to the specified message. Use the empty string to indicate that the element does not have a custom validity error.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLSelectElement/setCustomValidity>

=head1 EVENTS

Event listeners for those events can also be found by prepending C<on> before the event type:

C<click> event listeners can be set also with C<onclick> method:

    $e->onclick(sub{ # do something });
    # or as an lvalue method
    $e->onclick = sub{ # do something };

Note that, under perl, almost no event are fired, but you can trigger them yourself.

=head2 change

Fires when the user selects an option, but since there is no user interaction, this event is fired when the C<selectedIndex> value changes, which you can change yourself.

Example:

    <label>Choose an ice cream flavor:
        <select class="ice-cream" name="ice-cream">
            <option value="">Select One …</option>
            <option value="chocolate">Chocolate</option>
            <option value="sardine">Sardine</option>
            <option value="vanilla">Vanilla</option>
        </select>
    </label>

    <div class="result"></div>

    my $selectElement = $doc->querySelector('.ice-cream');

    $selectElement->addEventListener( change => sub
    {
        my $result = $doc->querySelector( '.$result' );
        $result->textContent = "You like " . $event->target->value;
    });

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/change_event>

=head2 input

Fires when the value of an <input>, <select>, or <textarea> element has been changed.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/input_event>

=head2 reset

Reset the cache flag so that some data will be recomputed. The cache is design to avoid doing useless computing repeatedly when there is no change of data.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLSelectElement>, L<Mozilla documentation on select element|https://developer.mozilla.org/en-US/docs/Web/HTML/Element/select>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
