package My::Form::Decorator::PostcodeCheck;
sub decorate {
  my ($class, $form) = @_;
  foreach my $field (@{ $form->fields }) {
    $field->add_validation('Form::Validator::UKPostcode') 
      if $field->name eq "postcode";
  }
  return $form;
}

#--------------------------------------------------------

package My::Form::Maker;
use base 'Form::Maker';

__PACKAGE__->add_decorator('My::Form::Decorator::PostcodeCheck');

#--------------------------------------------------------

package My::Form::Outline::Address;
use base 'Form::Outline';

__PACKAGE__->add_fields(qw/name email address1 address2 town state zip/);
__PACKAGE__->add_validation(
  email => 'Form::Validator::Email',
  state => 'Form::Validator::USState',
  zip   => 'Form::Validator::ZipCode',
);

#--------------------------------------------------------

package My::Form::Outline::AddressUK;
@ISA = ("My::Form::Outline::Address");
__PACKAGE__->remove_fields(qw/state zip/);
__PACKAGE__->add_fields(qw/county postcode/);
__PACKAGE__->add_validation(postcode => 'Form::Validator::UKPostcode');

#--------------------------------------------------------

package main;
use Test::More tests => 4;

my $maker = My::Form::Maker->new;
$maker->renderer("Form::Renderer::Test"); # a useful renderer for testing

{
	my $form = $maker->make("My::Form::Outline::Address");
    is($form."\n" , <<'EOF', "Form is what it should be");
name: text
email: text: /^[\w\-\+\._]+\@[a-zA-Z0-9][-a-zA-Z0-9\.]*\.[a-zA-Z]+$/
address1: text
address2: text
town: text
state: text: ^[A-Z][A-Z]$
zip: text: ^[0-9]{5}$
EOF
}

{
	my $form = $maker->make("My::Form::Outline::AddressUK");
	$form->add_fields(Form::Field::Checkbox->new({name => "subscribe"})); 
    is($form."\n" , <<'EOF', "Form is what it should be");
name: text
email: text: /^[\w\-\+\._]+\@[a-zA-Z0-9][-a-zA-Z0-9\.]*\.[a-zA-Z]+$/
address1: text
address2: text
town: text
county: text
postcode: text: ^[a-zA-Z]{1,2}[0-9]{1,3}[ \t]+[0-9]{1,2}[A-Za-z][A-Za-z]
subscribe: option
EOF
    is_deeply($form->decorators,[qw/
Form::Decorator::PredefinedFields
Form::Decorator::DefaultButtons
My::Form::Decorator::PostcodeCheck
/], "Decorator list is correct");
}

my $form2 = $maker->make;
$form2->add_fields("foo");
is("".$form2, "foo: text", "Hasn't affected the rest of the class");
