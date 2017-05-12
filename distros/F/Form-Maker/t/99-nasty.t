use Test::More 'no_plan';
use Form::Maker;

# THINGS TO THINK ABOUT - AND TEST FOR ONCE THOUGHT ABOUT!

# Adding two fields with the same name?
{
    my $form = Form::Maker->make("Form::Outline::Login");
    eval { 
        $form->add_fields(Form::Field::Checkbox->new({ name => "username" }));
    };
    like($@, qr/already have a/, "Can't add two fields with the same name");
    
}

# What about buttons with the same name as form elements?
{
    my $form = Form::Maker->make("Form::Outline::Login");
    eval { $form->add_button("username"); };
    like($@, qr/already have a/, "Can't add a button when we have a form field");
}
# Conversely...
{
    my $form = Form::Maker->make("Form::Outline::Login");
    $form->add_fields("submit");
    eval { my $stringy =length($form) };
    like($@, qr/already have a/, "Can't add a field when we have a button");
}

# Adding validation (or anything else) to a non-existent field.
{
    my $form = Form::Maker->make("Form::Outline::Login");
    eval {
    $form->add_validation(
        phone    => "Form::Validator::PhoneNumber"
    );
    };
    like($@, qr/non-existant/, "Adding validation to a non-existant field");
}

# Check that a form with no fields and/or no buttons works correctly
{ my $form = Form::Maker->make();
    $form->decorators([]);
  like($form, qr/form.*\/form/ms, "Empty form behaves");
}

# Adding multiple validations
{
    my $form = Form::Maker->make("Form::Outline::Login");
    $form->add_validation( username    => qr/^[a-z]+$/);
    $form->add_validation( username    => "Form::Validator::ZipCode" );
    like($form, qr/0-9/, "Second validation wins");
}

# I'm not sure that inheriting validators from class to object data
# works, since validators is an array reference.

# Decoration needs to be done when form elements are stringified individually
{
    my $form = Form::Maker->make("Form::Outline::Login");
    my $elems = join "", $form->fields;
    ok($form->{decorated}, 
        "Form has been decorated before stringifying fields");
}
{
    my $form = Form::Maker->make("Form::Outline::Login");
    my $elems = $form->start;
    ok($form->{decorated}, 
        "Form has been decorated before stringifying non-field elements");
}
