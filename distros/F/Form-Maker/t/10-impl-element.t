# Each element is actually an C<HTML::Element> object, so you can also
# make any changes you need to how those get displayed.

use Test::More tests => 4;
use overload;
use Form::Maker;

my $form = Form::Maker->make("Form::Outline::Login");
isa_ok($_, "HTML::Element")
    for @{$form->fields};
isa_ok($_, "HTML::Element")
    for @{$form->buttons};
