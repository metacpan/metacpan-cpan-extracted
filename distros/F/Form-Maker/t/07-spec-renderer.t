use Test::More tests => 3;
use Form::Maker;

package Form::Renderer::Test2;
use base 'Form::Renderer::HTML';

package main;

Form::Maker->renderer("Form::Renderer::Test");
{
my $form = Form::Maker->make("Form::Outline::Login");
is($form->renderer, "Form::Renderer::Test", "Renderer set");
is("".$form, "username: text\npassword: password", "login form is testy");
}

my $form = Form::Maker->make("Form::Outline::Login");
$form->renderer("Form::Renderer::Test2");
like("".$form, qr/</, "Form is HTML again");
