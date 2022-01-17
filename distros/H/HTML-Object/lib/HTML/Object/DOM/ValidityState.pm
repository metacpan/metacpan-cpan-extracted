##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/ValidityState.pm
## Version v0.1.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/12/23
## Modified 2021/12/23
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::DOM::ValidityState;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic );
    our $VERSION = 'v0.1.0';
};

sub init
{
    my $self = shift( @_ );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    return( $self );
}

# Note: property
sub badInput : lvalue { return( shift->_set_get_boolean( 'badinput', @_ ) ); }

# Note: property
sub customError : lvalue { return( shift->_set_get_boolean( 'customerror', @_ ) ); }

# Note: property
sub patternMismatch : lvalue { return( shift->_set_get_boolean( 'patternmismatch', @_ ) ); }

# Note: property
sub rangeOverflow : lvalue { return( shift->_set_get_boolean( 'rangeoverflow', @_ ) ); }

# Note: property
sub rangeUnderflow : lvalue { return( shift->_set_get_boolean( 'rangeunderflow', @_ ) ); }

# Note: property
sub stepMismatch : lvalue { return( shift->_set_get_boolean( 'stepmismatch', @_ ) ); }

# Note: property
sub tooLong : lvalue { return( shift->_set_get_boolean( 'toolong', @_ ) ); }

# Note: property
sub tooShort : lvalue { return( shift->_set_get_boolean( 'tooshort', @_ ) ); }

# Note: property
sub typeMismatch : lvalue { return( shift->_set_get_boolean( 'typemismatch', @_ ) ); }

# Note: property
sub valid : lvalue { return( shift->_set_get_boolean( 'valid', @_ ) ); }

# Note: property
sub valueMissing : lvalue { return( shift->_set_get_boolean( 'valuemissing', @_ ) ); }

1;
# XXX POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::ValidityState - HTML Object DOM Valid State Class

=head1 SYNOPSIS

    use HTML::Object::DOM::ValidityState;
    my $validity = HTML::Object::DOM::ValidityState->new || 
        die( HTML::Object::DOM::ValidityState->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

The C<ValidityState> interface represents the validity states that an element can be in, with respect to constraint validation. Together, they help explain why an element's value fails to validate, if it is not valid.

This is used only so that some properties work (like L<HTML::Object::DOM::Element::Button/validity>), but since this is for interactive interface, which perl does not provide, it has limited use. Anyhow, you can set those boolean values yourself.

=head1 PROPERTIES

For each of these boolean properties, a value of true indicates that the specified reason validation may have failed is true, with the exception of the valid property, which is true if the element's value obeys all constraints.

=head2 badInput

A boolean value that is true if the user has provided input that the browser is unable to convert.

Example:

    <input type="number" id="age">

    my $input = $doc->getElementById( 'age' );
    if( $input->validity->badInput )
    {
        say( "Bad $input detected…" );
    }
    else
    {
        say( "Content of $input OK." );
    }

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/ValidityState/badInput>

=head2 customError

A boolean value indicating whether the element's custom validity message has been set to a non-empty string by calling the element's setCustomValidity() method. This C<setCustomValidity> method is implemented in L<HTML::Object::DOM::Element::Input>, L<HTML::Object::DOM::Element::Object> and L<HTML::Object::DOM::Element::Select>

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/ValidityState/customError>

=head2 patternMismatch

A boolean value that is true if the value does not match the specified pattern, and false if it does match. If true, the element matches the C<:invalid> CSS pseudo-class.

Example:

    <p>
    <label>Enter your phone number in the format (123)456-7890
        (<input name="tel1" type="tel" pattern="[0-9]{3}" placeholder="###" aria-label="3-digit area code" size="2"/>)-
         <input name="tel2" type="tel" pattern="[0-9]{3}" placeholder="###" aria-label="3-digit prefix" size="2"/> -
         <input name="tel3" type="tel" pattern="[0-9]{4}" placeholder="####" aria-label="4-digit number" size="3"/>
    </label>
    </p>

    input:invalid {
        border: red solid 3px;
    }

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/ValidityState/patternMismatch>

=head2 rangeOverflow

A boolean value that is true if the value is greater than the maximum specified by the max attribute, or false if it is less than or equal to the maximum. If true, the element matches the C<:invalid> and :out-of-range and CSS pseudo-classes.

Example:

    <input type="number" min="20" max="40" step="2" />

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/ValidityState/rangeOverflow>

=head2 rangeUnderflow

A boolean value that is true if the value is less than the minimum specified by the min attribute, or false if it is greater than or equal to the minimum. If true, the element matches the C<:invalid> and :out-of-range CSS pseudo-classes.

Example:

    <input type="number" min="20" max="40" step="2" />

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/ValidityState/rangeUnderflow>

=head2 stepMismatch

A boolean value that is true if the value does not fit the rules determined by the step attribute (that is, it is not evenly divisible by the step value), or false if it does fit the step rule. If true, the element matches the C<:invalid> and :out-of-range CSS pseudo-classes.

Example:

    <input type="number" min="20" max="40" step="2" />

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/ValidityState/stepMismatch>

=head2 tooLong

A boolean value that is true if the value exceeds the specified maxlength for L<HTML::Object::DOM::Element::Input> or L<HTML::Object::DOM::Element::TextArea> objects, or false if its length is less than or equal to the maximum length. Note: This property is never true in Gecko, because elements' values are prevented from being longer than maxlength. If true, the element matches the C<:invalid> and C<:out-of-range> CSS pseudo-classes.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/ValidityState/tooLong>

=head2 tooShort

A boolean value that is true if the value fails to meet the specified minlength for L<HTML::Object::DOM::Element::Input> or L<HTML::Object::DOM::Element::TextArea> objects, or false if its length is greater than or equal to the minimum length. If true, the element matches the C<:invalid> and C<:out-of-range> CSS pseudo-classes.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/ValidityState/tooShort>

=head2 typeMismatch

A boolean value that is true if the value is not in the required syntax (when type is email or url), or false if the syntax is correct. If true, the element matches the C<:invalid> CSS pseudo-class.

Example:

    <p>
     <label>
        Enter an email address:
        <input type="email" value="example.com" />
     </label>
    </p>
    <p>
     <label>
        Enter a URL:
        <input type="url" value="example.com" />
        </label>
    </p>

    input:invalid {
        border: red solid 3px;
    }

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/ValidityState/typeMismatch>

=head2 valid

A boolean value that is true if the element meets all its validation constraints, and is therefore considered to be valid, or false if it fails any constraint. If true, the element matches the C<:valid> CSS pseudo-class; the :invalid CSS pseudo-class otherwise.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/ValidityState/valid>

=head2 valueMissing

A boolean value that is true if the element has a required attribute, but no value, or false otherwise. If true, the element matches the C<:invalid> CSS pseudo-class.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/ValidityState/valueMissing>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/ValidityState>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
