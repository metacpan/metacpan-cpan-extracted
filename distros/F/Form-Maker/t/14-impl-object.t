# Using Form::Maker->make as an object as well as a class
use Form::Maker;
use Test::More tests => 4;

package Foo;
sub a { 1};
package main;

my $x = Form::Maker->new; 
$x->renderer("Foo"); 
my $form = $x->make;
isa_ok($form, "Form::Maker"); 
is(Form::Maker->renderer, "Form::Renderer::HTML", "Original renderer kept");
is($x->renderer, "Foo", "Maker object has a new renderer");
is($form->renderer, "Foo", "Form has parent's renderer");
