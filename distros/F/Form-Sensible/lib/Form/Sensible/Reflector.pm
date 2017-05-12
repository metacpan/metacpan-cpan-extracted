package Form::Sensible::Reflector;
use Moose;
use namespace::autoclean;
use Carp;

our $VERSION = "0.01";
eval $VERSION;

# ABSTRACT: A simple reflector class for Form::Sensible

=head1 $self->with_trigger

Add a submit button to the form.  Defaults to 0.

=cut

#has 'with_trigger' => (
#    is => 'rw',
#    lazy => 1,
#    default => 0,
#);

sub reflect_from {
    my ( $self, $handle, $options) = @_;

   	my $form;
    if (exists($options->{'form'})) {
        if ( ref($options->{'form'}) eq 'HASH' ) {
    		$form = $self->create_form_object($handle, $options->{'form'});
        } elsif ( ref($options->{'form'}) &&
                  UNIVERSAL::can($options->{'form'}, 'isa') &&
                  $options->{'form'}->isa('Form::Sensible::Form') ) {

            $form = $options->{'form'};
        }
        else {
            croak "form element provided in options, but it's not a form or a hash.  What am I supposed to do with it?";
        }
    } else {
        if ( exists( $options->{'form_name'} ) ) {
            $form = $self->create_form_object($handle, { name => $options->{'form_name'} });
        } else {
            $form = $self->create_form_object($handle, undef);
        }
    }


    my @allfields = $self->get_all_field_definitions($handle, $options, $form);

    foreach my $field_def (@allfields) {
        $form->add_field( $field_def );
    }

    if (exists($options->{'with_trigger'}) && $options->{'with_trigger'}) {
        $form->add_field(Form::Sensible::Field::Trigger->new( name => 'submit' ));
    }
    return $self->finalize_form($form, $handle);
}

sub get_all_field_definitions {
    my ($self, $handle, $options, $form) = @_;

    my @allfields;
    my @fields = $self->get_fieldnames( $form, $handle );

    #my @definitions;
    if ( exists( $options->{'fieldname_filter'} )
        && ref( $options->{'fieldname_filter'} ) eq 'CODE' )
    {
        @fields = $options->{'fieldname_filter'}->(@fields);
    }

# this little chunk of code walks a fieldmap, if provided, and ensures that there
# is a map entry for every field we know about.  If none was provided, it creates
# one for the field set to undef - which means do not add the field to the form.

    my $fieldmap = { map { $_ => $_ } @fields };
    if ( exists( $options->{'fieldname_map'} )
        && ref( $options->{'fieldname_map'} ) eq 'HASH' )
    {
        foreach my $field (@fields) {
            if ( exists( $options->{'fieldname_map'}{$field} ) ) {
                $fieldmap->{$field} = $options->{'fieldname_map'}{$field};
            } else {
                $fieldmap->{$field} = undef;
            }
        }
    }

    my $additionalfields = {};

    ## copy any additional_fields provided so that we can process them later.
    ## we have to do this because we modify our $additionalfields hash as we work on it, so we don't want
    ## just a ref to what was provided.  Deleting other people's data is unkind.

    if (exists($options->{'additional_fields'}) && ref($options->{'additional_fields'}) eq 'ARRAY') {
        foreach my $additional_field (@{$options->{'additional_fields'}}) {
            $additionalfields->{$additional_field->{'name'}} = $additional_field;
            push @fields, $additional_field->{'name'};
        }
    }

    foreach my $fieldname (@fields) {
        my $new_fieldname = $fieldname;
        if (exists($fieldmap->{$fieldname})) {
            $new_fieldname = $fieldmap->{$fieldname};
        }
        #warn "Processing: " . $fieldname . " as " . $new_fieldname;

        if (defined($new_fieldname) || exists($additionalfields->{$new_fieldname} )) {
            my $field_def;
            if (exists($additionalfields->{$new_fieldname})) {
                $field_def = $additionalfields->{$new_fieldname};
                delete($additionalfields->{$new_fieldname});
            } else {
                $field_def = $self->get_field_definition( $form, $handle, $fieldname );
                next unless defined $field_def;
            }
            $field_def->{name} = $new_fieldname;
            push @allfields, $field_def;
        }
    }

    return @allfields;
}

sub create_form_object {
    my ($self, $handle, $form_options) = @_;

    if (!defined($form_options)) {
        croak "No form provided, and no form name provided.  Give me something to work with?";
    }
    return Form::Sensible::Form->new($form_options);
}

sub finalize_form {
    my ($self, $form, $handle) = @_;

    return $form;
}

__PACKAGE__->meta->make_immutable;
1;

=head1 NAME

Form::Sensible::Reflector - A base class for writing Form::Sensible reflectors.

=cut

=head1 SYNOPSIS

    my $reflector = Form::Sensible::Reflector::SomeSubclass->new();

    my $generated_form = $reflector->reflect_from($data_source, $options);

=head1 DESCRIPTION

A Reflector in Form::Sensible is a class that inspects a data source and
creates a form based on what it finds there. In other words it creates a form
that 'reflects' the data elements found in the data source.

A good example of this would be to create forms based on a DBIx::Class
result_source (or table definition.) Using the DBIC reflector, you could
create form for editing a user's profile information simply by passing the
User result_source into the reflector.

This module is a base class for writing reflectors, meaning you do not use
this class directly. Instead you use one of the subclasses that deal with your
data source type.

=head1 USAGE

    my $reflector = Form::Sensible::Form::Reflector::SomeSubclass->new();
    
    my $generated_form = $reflector->reflect_from($data_source, $options);

By default, a Reflector will create a new form using the exact fields found
within the datasource.  It is possible, however, to adjust this behavior
using the C<$options> hashref passed to the C<reflect_from> call.

=head2 Adjusting the parameters of your new form

    my $generated_form = $reflector->reflect_from($data_source,
                                                  {
                                                    form => {
                                                        name => 'profile_form',
                                                        validation => {
                                                            code => sub { ... }
                                                        }
                                                    }
                                                  });

If you want to adjust the parameters of the new form, you can provide a hashref
in the C<< $options->{form} >> that will be passed to the
C<< Form::Sensible::Form->new() >> call.

=head2 Providing your own form

    $reflector->reflect_from($data_source,
                            {
                                form => $my_existing_form_object
                            }
                            );

If you do not want to create a new form, but instead want the fields appended
to an existing form, you can provide an existing form object in the options
hash ( C<< $options->{form} >> )

=head2 Adding additional fields

    $reflector->reflect_from($data_source,
                            {
                                additional_fields => [
                                                {
                                                    field_class => 'Text',
                                                    name => 'process_token',
                                                    render_hints => {
                                                        field_type => 'hidden',
                                                    }
                                                },
                                                {
                                                    field_class => 'Trigger',
                                                    name => 'submit'
                                                }
                                            ]
                            }

This allows you to add fields to your form in addition to the ones provided by
your data source.  It also allows you to override your data source, as any
additional field with the same name as a reflected field will take precedence
over the reflected field.  This is also a good way to automatically add triggers
to your form, such as a 'submit' or 'save' button.

B<NOTE:> The reflector base class used to add a submit button automatically. The
additional_fields mechanism replaces that functionality.  This means your reflector
call needs to add the submit button, as shown above, or it needs to be added
programmatically later.

=head2 Changing field order

    $reflector->reflect_from($data_source,
                            {
                                ## sort fields alphabetically
                                fieldname_filter => sub {
                                                        return sort(@_);
                                                    },
                            }
                            );

If you are unhappy with the order that your fields are displaying in you can
adjust it by providing a subroutine in C<< $options->{'fieldname_filter'} >>.
The subroutine takes the list of fields as returned by C<< get_fieldnames() >>
and should return an array (not an array ref) of the fields in the new order.
Note that you can also remove fields this way.  Note also that no checking
is done to verify that the fieldnames you return are valid, if you return
any fields that were not in the original array, you are likely to cause an
exception when the field definition is created.

=head2 Changing field names

$reflector->reflect_from($data_source,
                        {
                            ## change 'logon' field to be 'username' in the form
                            ## and other related adjustments.
                            fieldname_map => {
                                                logon => 'username',
                                                pass => 'password',
                                                address => 'email',
                                                home_num => 'phone',
                                                parent_account => undef,
                                            },
                        }
                        );

By default, the C<Form::Sensible> field names are exactly the same as the data
source's field names. If you would rather not expose your internal field names
or have other reason to change them, you can provide a
C<< $options->{'fieldname_map'} >> hashref to change them on the fly. The
C<fieldname_map> is simply a mapping between the original field name and the
C<Form::Sensible> field name you would like it to use. If you use this method
you must provide a mapping for B<ALL> fields as a missing field (or a field
with an undef value) is treated as a request to remove the field from the form
entirely.

=head1 CREATING YOUR OWN REFLECTOR

Creating a new reflector class is extraordinarily simple. All you need to do
is create a subclass of Form::Sensible::Reflector and then create two
subroutines: C<get_fieldnames> and C<get_field_definition>.

As you might expect, C<get_fieldnames> should return an array containing the
names of the fields that are to be created. C<get_field_definition> is then
called for each field to be created and should return a hashref representing
that field suitable for passing to the
L<Form::Sensible::Field|Form::Sensible::Field/"METHODS">'s
C<create_from_flattened> method.

Note that in both cases, the contents of C<$datasource> are specific to your
reflector subclass and are not inspected in any way by the base class.

=head2 Subclass Boilerplate

    package My::Reflector;
    use Moose;
    use namespace::autoclean;
    extends 'Form::Sensible::Reflector';
    
    sub get_fieldnames {
        my ($self, $form, $datasource) = @_;
        my @fieldnames;
        
        foreach my $field ($datasource->the_way_to_get_all_your_fields()) {
            push @fieldnames, $field->name;
        }
        return @fieldnames;
    }
    
    sub get_field_definition {
        my ($self, $form, $datasource, $fieldname) = @_;
        
        my $field_definition = {
            name => $fieldname
        };
        
        ## inspect $datasource's $fieldname and add things to $field_definition
        
        return $field_definition;
    }

Note that while the C<$form> that your field will likely be added to is
available for inspection, your reflector should NOT make changes to the passed
form.  It is present for inspection purposes only.  If your module DOES have a
reason to look at C<$form>, be aware that in some cases, such as when only the
field definitions are requested, C<$form> will be null.  Your reflector should
do the sensible thing in this case, namely, not crash.

=head2 Customizing the forms your reflector creates

If you need to customize the form object that your reflector will return,
there are two methods that Form::Sensible::Reflector will look for. You only
need to provide these in your subclass if you need to modify the form object
itself.  If not, the default behaviors will work fine. The first is
C<create_form_object> which C<Form::Sensible::Reflector> calls in order to
instantiate a form object. It should return an instantiated
L<Form::Sensible::Form> object. The default C<create_form_object> method
simply passes the provided arguments to the
L<Form::Sensible::Form/"METHODS">'s C<new> call:

    sub create_form_object {
        my ($self, $handle, $form_options) = @_;
        
        return Form::Sensible::Form->new($form_options);
    }

Note that this will B<NOT> be called if the user provides a form object, so if
special adjustments are absolutely required, you should consider making those
changes using the C<finalize_form> method described below.

The second method is C<finalize_form>.  This method is called after the
form has been created and all the fields have been added to the form.  This
allows you to do any final form customization prior to the form actually
being used.  This is a good way to add whole-form validation, for example:

    sub finalize_form {
        my ($self, $form, $handle) = @_;

        return $form;
    }

Note that the C<finalize_form> call must return a form object.  Most of the
time this will be the form object passed to the method call.  The return
value of C<finalize_form> is what is returned to the user calling C<reflect_from>.

=head2 Author's note

This is a base class to write reflectors for things like, configuration files,
or my favorite, a database schema.

The idea is to give you something that creates a form from some other source
that already defines form-like properties, ie a database schema that already
has all the properties and fields a form would need.

I personally hate dealing with forms that are longer than a search field or
login form, so this really fits into my style.

=head1 AUTHORS

Devin Austin <dhoss@cpan.org>
Jay Kuri <jayk@cpan.org>

=cut

=head1 ACKNOWLEDGEMENTS

Jay Kuri <jayk@cpan.org> for his awesome Form::Sensible library and helping me
get this library in tune with it.

=cut

=head1 SEE ALSO

L<Form::Sensible>
L<Form::Sensible> Wiki: L<http://wiki.catalyzed.org/cpan-modules/form-sensible>
L<Form::Sensible> Discussion: L<http://groups.google.com/group/formsensible>

=cut
