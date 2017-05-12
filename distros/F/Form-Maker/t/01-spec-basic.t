use Test::More tests => 2;

use Form::Maker;

my $form = Form::Maker->make("Form::Outline::Login");
isa_ok($form, "Form::Maker");
like($form, qr/</, "Login form looks a bit like HTML - at least something works");
