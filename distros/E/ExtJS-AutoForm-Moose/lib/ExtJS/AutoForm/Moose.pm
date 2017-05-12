package ExtJS::AutoForm::Moose;

use warnings;
use strict;

use Moose::Role;
use JSON::Any qw();
use ExtJS::AutoForm::Moose::Util;

=head1 NAME

ExtJS::AutoForm::Moose - Moose role for ExtJS form autogeneration

=head1 VERSION

Version 0.01

=cut

our $VERSION = "0.01";

=head1 SYNOPSIS

B<WARNING:> This module is mostly on it's bare bones, and still under heavy development. This means
it is subject to all kinds of refactoring, renaming, incompatible API changes, not to mention the
bugs or lack of support for really nice Moose features and extensions (like L<MongoDBx::Class>).
See L</DESCRIPTION> and L</TODO> for more details.

On the class you want to generate an ExtJS form for:

    package MyApp::Model::MyEntity;

    use Moose;

    extends 'MyApp::Model::MyParentEntity';
    with 'ExtJS::AutoForm::Moose';

    has 'some_attribute' => { is => "rw", isa => "Str" };
    has 'some_other' => { is => "ro", isa => "Num" };

Then, somewhere else on your code:

    # Simple usage on an object instance
    $entity->extjs_fields;
    $entity->extjs_fields_json;
    $entity->extjs_formpanel;
    $entity->extjs_formpanel_json;

    # Static usage
    MyApp::Model::MyParentEntity->extjs_fields;
    MyApp::Model::MyParentEntity->extjs_formpanel;

    # Use options to control generation
    $entity->extjs_form( hierarchy => 1, strip => "MyApp::Model::", cleanup => "cute" );

=cut

=head1 DESCRIPTION

This moose role adds a couple of methods to any Moose class that use introspection to try to generate
an array of ExtJS form field descriptions or a formpanel description. If you do not yet know of ExtJS,
you can visit it's product page here: L<http://www.sencha.com/products/extjs>.

Once a class implements this role, you can call I<extjs_*> methods on an object instance or statically.

=head2 Supported moose types

So far, just a few base attribute types are supported, namely: B<Str>, B<Num>, B<Int>, B<Bool>, and B<enums>.
Any other field will inherit the extjs template definition from the common antecessor B<Any>, which creates a
DisplayField control showing an "Unsupported type" message.

Anyway, you can define custom templates for any moose types using L<ExtJS::AutoForm::Moose::Types>,
which provides a syntax curry very similar to the one used to declare types or attributes.

=head2 How it works

L<ExtJS::AutoForm::Moose> basically gets the associated Moose::Meta::Class and uses 
introspection to recursively find the entity attributes.

For each attribute, it does a few simple checks on the attribute type to find the matching
ExtJS control. Such search will recursively check parent types to provide a default control,
so that if you create an I<Str> subtype and do not declare a way to reflect that into an ExtJS
control, the default for I<Str> will be used instead.

When an association is found, the definition is loaded, and a few common config options are
set (unless they have been previously defined on the provided template):

=over 4

=item - fieldLabel

Set to the attribute name, as returned by the cleanup callback (see autoform options)

=item - readOnly

Set to true for "ro" declared attributes

=item - name

Set to the attribute name (unparsed)

=back

=head3 Attribute values

Attribute values are a bit special, since the default behaviour changes when the form is generated
through a static call to ext_js or as a method call.

On the first case, this module will try to fetch the default value for that attribute. There is a
caveat, though, since default values can be provided as callbacks and a static call has no object
to pass to that callback. This means it will probably crash, but so far, this behaviour is left
undefined.

When called as a method, though, the actual attribute value of that instance will be used.

=head1 METHODS

=over

=item extjs_fields ( I<options> )

Generate fields structure for a given class.

This method can be both invoked on an object or directly, passing a valid moose classname as the first parameter.

Available options:

=over

=item hierarchy

When set to a true value, this flag will cause attributes to be grouped in ExtJS fieldgroups using the class or role names that declared them.

=item strip

Used together with I<hierarchy>, will strip off a given string from class names. See L</SYNOPSIS>.

=item classname_cleanup

Used together with I<hierarchy>, allows to format classnames using a callback. Specifying "cute" will C<s#::# #>.

=item attribute_cleanup

Allows to format attribute using a callback. Specifying "cute" will C<s#_# #>.

=item no_readonly

Do not set readOnly config parameters on fields.

=back

=item extjs_fields_json ( I<options> )

This method does exactly the same thing as I<extjs_fields>, but returns the output encoded as JSON using L<JSON::Any>.

=item extjs_formpanel ( I<options> )

Generate a formpanel containing the reflection for a given object instance or class.

All parameters are passed directly to extjs_fields, so it's usage is identical.

=item extjs_formpanel_json ( I<options> )

This method does exactly the same thing as I<extjs_formpanel>, but returns the output encoded as JSON using L<JSON::Any>.

=back

=cut

sub extjs_fields {
    my $self = shift;
    my $meta = Class::MOP::Class->initialize(ref($self) || $self);
    my $options = {@_};

    return ExtJS::AutoForm::Moose::Util::_recursive_reflect( $meta, ref($self) ? $self : undef, $options );
}

sub extjs_fields_json
{ return JSON::Any->objToJson([shift->extjs_fields(@_)]); }

sub extjs_formpanel {
    my $self = shift;
    my @fields = $self->extjs_fields(@_);

    return {
        xtype => "form",
        items => [@fields],
    };
}

sub extjs_formpanel_json
{ return JSON::Any->objToJson([shift->extjs_formpanel(@_)]); }

=head1 TODO

There are still a lot of features to implement and a few dirty hacks to fix before this module is actually useful.

This is a list of random ideas to be considered for future versions:

=over

=item Support for Moose class-typed attributes

This must be thoroughly analized to get to a simple and flexible solution

=item Support array and hash parametrized types

I think there must be a pretty smart way to handle this

=item Support MongoDBx::Class attributes

This one is even more interesting, and includes referenced and embedded documents.

=back

=cut

=head1 AUTHOR

Quim Rovira, C<< met at cpan.org >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-moosex-extjs-reflection at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ExtJS-AutoForm-Moose>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc ExtJS::AutoForm::Moose


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


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Quim Rovira.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

ExtJS trademarks are property of Sencha Labs L<http://www.sencha.com>

=cut

1; # End of ExtJS::AutoForm::Moose
