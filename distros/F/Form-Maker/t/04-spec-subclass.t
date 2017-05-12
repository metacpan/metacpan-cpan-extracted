package My::Form::Outline::Login;
use Form::Outline::Login;
use base 'Form::Outline::Login';
package main;
use Test::More tests => 6;
use Form::Maker;
my $form = Form::Maker->make("My::Form::Outline::Login");
isa_ok($form, "Form::Maker");
my @fields = @{ $form->fields };
is(@fields, 2, "Two fields");
isa_ok($fields[0], "Form::Field::Text");
is($fields[0]->name, "username", "First field is username");

isa_ok($fields[1], "Form::Field::Password");
is($fields[1]->name, "password", "Second field is password");
