package ExtJS::AutoForm::Moose::Types;

use warnings;
use strict;

use Moose::Exporter;
use JSON::Any;
use Carp qw(confess);

=head1 NAME

ExtJS::AutoForm::Moose::Types - Manage extjs form generation for Moose types

=cut

=head1 SYNOPSIS

Those are in fact the current type reflections implemented, except for enum, which is treated in a special way so far:

    reflect 'Any'  => extjs { {
        xtype => "displayfield",
        fieldLabel=> "Unsupported field type"
    } };

    reflect 'Str'  => extjs { {
        xtype => "textfield",
        value => \&ExtJS::AutoForm::Moose::Types::value_or_default
    } };

    reflect 'Num'  => extjs { {
        xtype => "numberfield",
        allowDecimals => JSON::Any::true,
        value => \&ExtJS::AutoForm::Moose::Types::value_or_default
    } };

    reflect 'Int'  => extjs { {
        xtype => "numberfield",
        allowDecimals => JSON::Any::false,
        value => \&ExtJS::AutoForm::Moose::Types::value_or_default
    } };

    reflect 'Bool' => extjs { {
        xtype => "checkbox",
        checked => \&ExtJS::AutoForm::Moose::Types::value_or_default_bool
    } };

=head1 DESCRIPTION

This module does two things: hold the registry of known type contraints reflections, and provide a bit of
curry to ease adding reflections for new types based on their type name.

=head2 Syntax curry

=over

=item reflect 'I<type_name>' => extjs { I<code returning a hash template> }

Create a new moose type constraint to extjs field association.

The template parameter must be specified as a perl function that returns a hash that will be,
at some point, encoded as JSON and sent to a browser. You can use callbacks as values on this
hash, which will be called and it's result used as the generated key value (See callbacks in
L</TEMAPLTE FORMAT> below).

=back

=head2 Template format

The template format is the one used by ExtJS Component class creation. This means it does all
it's job using xtypes and does not use any javascript functions.

=head2 Customizing tamplate values using callbacks

Any template hash value can be a callback instead of a plain value, which allows further
customization of the generated extjs description.

Those callbacks receive two parameters: the object instance (undef when generation has been
called statically), and the L<Moose::Meta::Attribute> instance for that attribute.

Example:

    sub enum_values($$) {
        my ($obj,$attribute) = @_;
        return $attribute->type_constraint->values;
    }

See L</REFLECTION HELPERS> below for a list of helper callbacks provided by default.

=head2 Javascript functions on the generated result?

Using javascript isn't straight-forward because the generated result is usually encoded as
JSON, which by itself does not support javascript functions.

In those cases you need to use javascript functions, you've got a few options:

=over

=item * Don't

If you read the ExtJS API docs carefully, you'll notice there's really not that much that cannot
be controlled through config parameters.

=item * Extend the base ExtJS components

It's not difficult, and you can register those as a new xtype.

=item * Encode the generated structure yourself

This seems like a dirty hack to me, and you'll probably be meriting for a place in hell, but...

Since JSON does not allow functions, you cannot use any of the available JSON modules supported
by JSON::Any. You can get around this by writing your own structure to JSON encoder that knows
how to handle that.

You could also replace any functions on the whole structure with tokens and replace those tokens
on the resulting JSON.

=back

=cut

#
# EXPORTING
#
Moose::Exporter->setup_import_methods(
    as_is => [ qw(
        reflect extjs
    ) ],
);

our %REGISTRY = ();

#
# SYNTAX CURRY
#
sub extjs(&) { { template => $_[0] } }

sub reflect($$;$) {
    my $type_name = shift;
    my %p = map { %{$_} } @_; #really useless here. done this way since I was hoping to extend own Moose (sub)type sugar

    unless(ref($p{template}) eq "CODE")
    {
        local $Carp::CarpLevel = $Carp::CarpLevel + 1;
        confess("A callback must be provided for type reflection");
    }

    my $test = $p{template}->();

    unless(ref($test) && ref($test) eq "HASH")
    {
        local $Carp::CarpLevel = $Carp::CarpLevel + 1;
        confess("The callback provided for '$type_name' reflection does not return a hash structure");
    }

    $REGISTRY{$type_name} = $p{template};
}

#
# Base TypeConstraint reflections
#
reflect 'Any'  => extjs { {
    xtype => "displayfield",
    fieldLabel=> "Unsupported field type"
} };

reflect 'Str'  => extjs { {
    xtype => "textfield",
    value => \&ExtJS::AutoForm::Moose::Types::value_or_default
} };

reflect 'Num'  => extjs { {
    xtype => "numberfield",
    allowDecimals => JSON::Any::true,
    value => \&ExtJS::AutoForm::Moose::Types::value_or_default
} };

reflect 'Int'  => extjs { {
    xtype => "numberfield",
    allowDecimals => JSON::Any::false,
    value => \&ExtJS::AutoForm::Moose::Types::value_or_default
} };

reflect 'Bool' => extjs { {
    xtype => "checkbox",
    checked => \&ExtJS::AutoForm::Moose::Types::value_or_default_bool
} };

reflect '__ENUM__' => extjs { {
   xtype => "combo",
   store => \&ExtJS::AutoForm::Moose::Types::enum_values,
} };

=head1 REFLECTION HELPERS

The following subroutines are provided as helpers for common checks and transformations used on
the ExtJS templates.

=over

=cut

=item value_or_default

Returns the current value of this attribute for the given object, or it's default value if reflection
was done directly on the class

=cut
sub value_or_default($$) {
    my ($obj,$attribute) = @_;
    return $obj ? $attribute->get_value($obj) : $attribute->default(undef);
}

=item value_or_default_bool

Does the same as the previous helper, but it returns a JSON boolean value suitable for JSON::Any encoding

=cut
sub value_or_default_bool($$) {
    my ($obj,$attribute) = @_;
    return JSON::Any::true if ( $obj ? $attribute->get_value($obj) : $attribute->default(undef) );
    return JSON::Any::false;
}

=item required_attribute_bool

Returns a JSON true value when this attribute is required, false otherwise

 =cut
sub required_attribute_bool($$) {
    my ($obj,$attribute) = @_;
    return $attribute->is_required ? JSON::Any::true : JSON::Any::false;
}

=item enum_values

Returns an array containing the enum-type attribute values. See L<Moose::Meta::TypeConstraint::Enum>.

=cut
sub enum_values($$) {
    my ($obj,$attribute) = @_;
    return $attribute->type_constraint->values;
}

=back

=cut

=head1 AUTHOR

Quim Rovira, C<< quim at rovira.cat >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-moosex-extjs-reflection at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Moosex-ExtJS-Reflection>.  I will
be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc ExtJS::AutoForm::Moose::Types


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ExtJS-AutoForm-Moose>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/ExtJS-AutoForm-Moose>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/ExtJS-AutoForm-Moose>

=item * Search CPAN

L<http://search.cpan.org/dist/ExtJS-AutoForm-Moose/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Quim Rovira.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

ExtJS trademarks are property of Sencha Labs L<http://www.sencha.com>

=cut

1; # End of ExtJS::AutoForm::Moose::Types
