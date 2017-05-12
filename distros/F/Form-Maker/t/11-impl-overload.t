use Test::More tests => 5;
use overload;
use Form::Maker;

my $form = Form::Maker->make("Form::Outline::Login");
ok(overload::Overloaded($form), "Form is overloaded");
ok(overload::Overloaded($_), "Field is overloaded")
    for @{$form->fields};
ok(overload::Overloaded($_), "Button is overloaded")
    for @{$form->buttons};
