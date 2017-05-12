use Test::More tests => 11;
use Form::Maker;
my $form = Form::Maker->make("Form::Outline::Login");
ok($form->start, "Has a beginning");
ok($form->fieldset, "Has fields");
ok($form->fieldset_start, "Has a field start");
ok($form->fieldset_end, "Has a field end");
ok($form->end, "Has an end");
is($form->fieldset,
    (join "", $form->fieldset_start, @{$form->fields}, $form->fieldset_end),
    "Fieldset is made up of all the right components");
is("".$form->buttons,
    (join "", @{$form->buttons}),
    "Buttons are made of their individual parts");
isa_ok($_, "HTML::Element") for 
    @{$form->buttons},
    @{$form->fields};
