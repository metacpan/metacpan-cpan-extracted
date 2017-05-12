use strict;
use warnings;
require 5.010_000;
package Form::Toolkit;
{
  $Form::Toolkit::VERSION = '0.008';
}

1;

__END__

=head1 NAME

Form::Toolkit - A toolkit to build Data centric Forms

=head1 PRINCIPLES

Form::Toolkit has been written with those principles in mind:

- It is context agnostic. Forms do not know about which context (Web, CLI, Curse UI, etc..) they will be rendered into.
No "rendering" helpers are available, so you are free to render them exactly like you intend to. That also means that
unit testing of your Forms is trivial. It also means your designers are perfectly free to render an datatype as they wish.
How do you render a Boolean in html? as a checkbox, as a set of radio, as a select element? With Form::Toolkit, the choice is
yours.

- It focuses on data correctness. Each field type holds a value of a fixed type of data. For instance, the Date field holds a DateTime.

- It does not get on your way. You are free to use Form::Toolkit for what it can do, and implement the more specific bits yourself.
For instance, if you have a web form that contains a bunch of fields and a Captcha, you can use Form::Toolkit to handle the standard fields,
and implement your Captcha handling in parrallel.

- It favours composition over inheritance. Most of Form::Toolkit validation capabilities are implemented using L<Moose::Role>s. That means that to
build the fields validation, you simply add Roles to those fields. You can use the provided Roles ( all in Form::Toolkit::FieldRole ) for simple
validations and constraints, but you are also perfectly free to write your own Roles to implement any business specific validation you need.

- It does not rely on any configuration files. Each of your forms is a plain class that just has to inherit from L<Form::Toolkit::Form> and
provides some contruction code. Forms should be first class citizens in your application, and letting them be just Classes allows the
flexibility you need to tailor them to your application needs.


=head1 TUTORIAL

Let us build a simple form that ask for someones name and email address (Let us call it 'Register'):

  package My::App::Form::Register;
  use Moose;
  extends qw/Form::Toolkit::Form/;

  sub build_fields{
    my ($self) = @_;
    $self->add_field('String', 'name')
      ->add_role('Trimmed') # We dont want leading or trailing spaces
      ->add_role('Mandatory') # This is mandatory
      ->add_role('MinLength', { min_length => 5 }) # Roles can be parametric
      ->add_role('MaxLength', { max_length => 100 }) # Another constraint.
      ->set_label('Your name'); # That is it for the name field

   $self->add_field('String', 'email' )
      ->add_role('Trimmed')
      ->add_role('Mandatory')
      ->add_role('Email') # This will check the input looks like an email
  }

  __PACKAGE__->meta->make_immutable();

Now build an instance of your register form:

 my $form = My::App::Form::Register->new();

Inject some values via a simple hash and check for errors:

 $form->fill_hash({ name => 'Jerome Eteve' , email => 'jerome_eteve' });

 if( $form->has_errors() ){
    print Dumper($form->dump_errors());
 }

Clear the form and try again with valid values:

 $form->clear();
 $form->fill_hash({ name => 'Jerome Eteve' , email => 'jerome.eteve@gmail.com' });
 if( $form->is_valid() ){
    my $name = $form->field('name')->value();
    my $email = $form->field('email')->value();
    ## Do something with $name and $email.
 }

=head1 COOKBOOK

=head2 Trimming all the fields automatically

If you want to trim all the fields automatically, it is quite straight forward.
Fist make sure you have a base Form in your app to inherit from:

  package My::App::Form;
  use Moose;
  extends qw/Form::Toolkit::Form/;

Then just wrap around the add_field method to make sure you always add the Trimmed role:

  around 'add_field' => sub{
    my ($orig, $self, @args) = @_;
    my $field = $self->$orig(@args);
    $field->add_role('Trimmed');
    return $field;
  };


=head2 Making forms aware of your application model

Simply make your own Form base class for your forms to inherit from:

  package My::App::Form;
  use Moose;
  extends qw/Form::Toolkit::Form/;
  has 'myapp' => ( is => 'ro' , isa => 'My::App' , required => 1 );
  1;

  ## Then your specific forms:
  package My::App::Form::Register;
  use Moose;
  extends qw/My::App::Form/;
  1;

At construction time:

 my $form = My::App::Form::Register->new({ myapp => $myapp });

=head2 Making Set fields based on a DBIC resultset.

Let us have a look our earlier Register form and add a DBIC resultset dependent Set field.

  package My::App::Form::Register;
  use Moose;
  extends qw/My::App::Form/; # Remember My::App::Form knows a My::App instance

  sub build_fields{
    my ($self) = @_;
     ....

    $self->add_field('Set', 'referal')
     ->add_role('InKVPairs',
                kvpairs => Form::Toolkit::KVPairs::DBICRs->new({ rs => $self->myapp->resultset('Referals'),
                                                                 key => 'id',
                                                                 value => 'name' }) # Will check the Set of keys given belong to these KVPairs
     ->add_role('MonoValued') # We want ONE value of this set only
     ->set_label('How did you hear about us?');
  }

=cut

