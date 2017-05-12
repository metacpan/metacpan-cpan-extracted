package Form::Sensible;

use Moose; 
use namespace::autoclean;
use Class::MOP;
use Form::Sensible::Form;
use Form::Sensible::Field;
use Form::Sensible::Field::DateTime;
use Form::Sensible::Field::Number;
use Form::Sensible::Field::Select;
use Form::Sensible::Field::Text;
use Form::Sensible::Field::LongText;
use Form::Sensible::Field::Toggle;
use Form::Sensible::Field::Trigger;
use Form::Sensible::Field::SubForm;
use Form::Sensible::Validator;
use Form::Sensible::Validator::Result;
use Form::Sensible::DelegateConnection;

our $VERSION = "0.20023";

Moose::Exporter->setup_import_methods(
      also     => [ 'Form::Sensible::DelegateConnection' ]  
);

around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;
        
    ## this is somewhat odd, but it's a lot easier to track down with this error 
    ## than getting back an empty Form::Sensible object.  
    
    if ($#_ == 0 && ref($_[0]) && exists($_[0]->{'fields'})) {
        die "Invalid call to Form::Sensible->new() !! Form::Sensible is not meant to be instantiated.  You probably meant to call create_form()";
    } else {
        return $class->$orig(@_);
    }
};

## This module is a simple factory class which will load and create the various
## types of modules required when working with Form::Sensible

sub create_form {
    my ($class, $template) = @_;
    
    my $formhash = { %{$template} };
    delete($formhash->{'fields'});
    delete($formhash->{'field_order'});
    
    my $form = Form::Sensible::Form->new(%{$formhash});
    
    if (ref($template->{'fields'}) eq 'ARRAY') {
        foreach my $field (@{$template->{'fields'}}) {
            $form->add_field($field, $field->{name});
            #Form::Sensible::Field->create_from_flattened($field);
            #$form->add_field($newfield, $newfield->name);
        }
    } else {
        my @field_order;
        if (exists($template->{'field_order'})) {
            push @field_order, @{$template->{'field_order'}};
        } else {
            push @field_order, keys %{$template->{'fields'}};
        }
        foreach my $fieldname (@field_order) {
            $form->add_field($template->{'fields'}{$fieldname}, $fieldname);
            
            #my $newfield = Form::Sensible::Field->create_from_flattened($template->{'fields'}{$fieldname});
            #$form->add_field($newfield, $fieldname);
        }
    }
    return $form;
}

sub get_renderer {
    my ($class, $type, $options) = @_;

    my $class_to_load;
    if ($type =~ /^\+(.*)$/) {
        $class_to_load = $1;
    } else {
        $class_to_load = 'Form::Sensible::Renderer::' . $type;
    }
    Class::MOP::load_class($class_to_load);
    if (!$options) {
        $options = {};
    }
    
    return $class_to_load->new($options);
}

sub get_validator {
    my ($class, $type, $options) = @_;
 
    my $class_to_load;
    if (!defined($type)) {
        $type = "+Form::Sensible::Validator";
    }
    if ($type =~ /^\+(.*)$/) {
        $class_to_load = $1;
    } else {
        $class_to_load = 'Form::Sensible::Validator::' . $type;
    }
    Class::MOP::load_class($class_to_load);
    
    return $class_to_load->new($options);   
}



__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 NAME

Form::Sensible - A sensible way to handle form based user interface

=head1 SYNOPSIS

    use Form::Sensible;
        
    my $form = Form::Sensible->create_form( { ... } );

    my $renderer = Form::Sensible->get_renderer('HTML', { tt_config => { INCLUDE_PATH => [ '/path/to/templates' ] }}); 

    my $output = $renderer->render($form)->complete;
    
    ## Form Validation:
    
    my $validation_result = $form->validate();
    
    if ($validation_result->is_valid()) {
        ## do form was valid stuff
    } else {
        my $output_with_messages = $renderer->render($form)->complete;
    }

=head1 DESCRIPTION

Form::Sensible is a different kind of form library. Form::Sensible is not just
another HTML form creator, or a form validator, though it can do both.
Form::Sensible, instead, focuses on what forms are: a method to relay
information to and from a user interface.

Form::Sensible forms are primarily tied to the data they represent.
Form::Sensible is not tied to HTML in any way. You could render Form::Sensible
forms using any presentation system you like, whether that's HTML, console
prompts, WxPerl or voice prompts. (* currently only an HTML renderer is
provided with Form::Sensible, but work is already under way to produce
others.)

=head2 FEATURES

=over 8
=item * Easy form creation

=item * Easy form validation

=item * Ability to easily save created forms for future use

=item * Define form once, render any number of ways

=item * Flexible built-in form validator

=item * Easily extended to produce new renderers, field types and validation

=item * HTML renderer produces sane html that can be easily styled via CSS

=item * HTML renderer allows for custom templates to control all aspects of form rendering.

=item * HTML output not tied to any javascript library.

=back


=head2 Form::Sensible form lifecycle

The Form::Sensible form lifecycle works as follows:

=head3 Phase 1 - Show a form

=over 8

=item 1. Create form object

=item 2. Create or get a renderer

=item 3. Use renderer to render form

=back

=head3 Phase 2 - Validate input

=over 8

=item 1. Create form object

=item 2. Retrieve user input and place it into form 

=item 3. Validate form

=item 4. If form data is invalid, re-render the form with messages

=back

One of the most important features of Form::Sensible is that Forms, once
created, are easily stored for re-generation later. A form's definition and
state are easily converted to a hashref data structure ready for serializing.
Likewise, the data structure can be used to create a complete Form::Sensible
form object ready for use. This makes re-use of forms extremely easy and
provides for dynamic creation and processing of forms.

=head1 EXAMPLES 

=head3 Form creation from simple data structure

    use Form::Sensible;
        
    my $form = Form::Sensible->create_form( {
                                                name => 'test',
                                                fields => [
                                                             { 
                                                                field_class => 'Text',
                                                                name => 'username',
                                                                validation => { regex => '^[0-9a-z]*'  }
                                                             },
                                                             {
                                                                 field_class => 'Text',
                                                                 name => 'password',
                                                                 render_hints => { 
                                                                        'HTML' => {
                                                                                    field_type => 'password' 
                                                                                  }
                                                                        },
                                                             },
                                                             {
                                                                 field_class => 'Trigger',
                                                                 name => 'submit'
                                                             }
                                                          ],
                                            } );

This example creates a form from a simple hash structure. This example creates
a simple (and all too familiar) login form.

=head3 Creating a form programmatically

    use Form::Sensible;
    
    my $form = Form::Sensible::Form->new(name=>'test');

    my $username_field = Form::Sensible::Field::Text->new(  
                                                            name=>'username', 
                                                            validation => { regex => qr/^[0-9a-z]*$/  }
                                                         );

    $form->add_field($username_field);

    my $password_field = Form::Sensible::Field::Text->new(  
                                                            name=>'password',
                                                            render_hints => { 
                                                                                'HTML' => {
                                                                                            field_type => 'password' 
                                                                                          },
                                                                            },
                                                         );
    $form->add_field($password_field);

    my $submit_button = Form::Sensible::Field::Trigger->new( name => 'submit' );

    $form->add_field($submit_button);

This example creates the exact same form as the first example. This time,
however, it is done by creating each field object individually, and then
adding each in turn to the form.

Both of these methods will produce the exact same results when rendered.

=head3 Form validation

    ## set_values takes a hash of name->value pairs 
    $form->set_values($c->req->params);
    
    my $validation_result = $form->validate();
    
    if ($validation_result->is_valid) { 
    
        #... do stuff if form submission is ok.
    
    } else {
    
        my $renderer = Form::Sensible->get_renderer('HTML');
        my $output = $renderer->render($form)->complete;    
    }

Here we fill in the values provided to us via C<< $c->req->params >> and then run validation
on the form.  Validation follows the rules provided in the B<validation> definitions for
each field.  Whole-form validation is can also be done if provided.  When validation
is run using this process, the messages are automatically available during rendering.


=head1 METHODS

All methods in the Form::Sensible package are class methods. Note that by
C<use>ing the Form::Sensible module, the L<Form::Sensible::Form> and
L<Form::Sensible::Field::*|Form::Sensible::Field/DESCRIPTION> classes are also C<use>d.

=over 8

=item C<create_form($formhash)>

This method creates a form from the given hash structure. The hash structure
accepts all the same attributes that L<Form::Sensible::Form>'s new method
accepts. Field definitions are provided as an array under the C<field> key.
Returns the created L<Form::Sensible::Form> object.

=item C<get_renderer($render_class, $options)>

Creates a renderer of the given class using the C<$options> provided. The
format of the class name follows the convention of a bare name being appended
to C<Form::Sensible::Renderer::>. In other words if you call
C<<Form::Sensible->get_renderer('HTML', { 'foo' => 'bar' })>> Form::Sensible
will ensure the L<Form::Sensible::Renderer::HTML> class is loaded and will create
an object by passing the hashref provided to the C<new> method. If you wish to
provide a class outside of the C<Form::Sensible::Renderer::> namespace,
prepend the string with a C<+>. For example, to load the class
C<MyRenderer::ProprietaryUI> you would pass C<'+MyRenderer::ProprietaryUI'>.

=item C<get_validator($validator_class, $options)>

Creates a validator of the given class using the C<$options> provided. Follows
the same convention for class name passing as the get_renderer method.

=back


=head1 AUTHORS

Jay Kuri - E<lt>jayk@cpan.orgE<gt>

Luke Saunders - E<lt>luke.saunders@gmail.comE<gt>

Devin Austin - E<lt>dhoss@cpan.orgE<gt>

Alan Rafagudinov - E<lt>alan.rafagudinov@ionzero.comE<gt>

Andrew Moore - E<lt>amoore@cpan.orgE<gt>

=head1 SPONSORED BY

Ionzero LLC. L<http://ionzero.com/>

=head1 SEE ALSO

Form::Sensible Wiki: L<http://wiki.catalyzed.org/cpan-modules/form-sensible>

Form::Sensible Discussion: L<http://groups.google.com/group/formsensible>

Form::Sensible Github: L<https://github.com/jayk/Form-Sensible>

L<Form::Sensible>


=head1 LICENSE

Copyright 2009 by Jay Kuri E<lt>jayk@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.


=cut

