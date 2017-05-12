use Test::More tests => 8;
use Form::Maker;

{
use Form::Field::Text;
use Form::Field::Password;
my @fields = ( Form::Field::Text->new({ name => "username" }),
               Form::Field::Password->new({ name => "password" }));
isa_ok($fields[0], "Form::Field::Text");
isa_ok($fields[1], "Form::Field::Password");
}

my $form = Form::Maker->make();
isa_ok($form, "Form::Maker");
$form->add_fields(qw/username password/);
is($form->decorators->[0], "Form::Decorator::PredefinedFields",
    "Predefined fields decorator is on by default");
my @fields = @{ $form->fields };
isa_ok($fields[0], "Form::Field::Text");
isa_ok($fields[1], "Form::Field::Password");

# Rendering
like($form, qr/name="password"/i, "Contains a password field");
like($form, qr/type="password"/i, "The password field is starred out");
