use Test::More tests => 2;

use Form::Maker;

my $form = Form::Maker->make("Form::Outline::Login");
$form->remove_fields(qw/password/);
my @fields = @{$form->fields};
is(@fields, 1, "One field");
is($fields[0]->name, "username", "Right field left");
