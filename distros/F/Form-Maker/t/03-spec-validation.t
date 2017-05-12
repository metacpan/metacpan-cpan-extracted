use Test::More tests => 3;
use Form::Maker;
use Email::Valid;

{
my $form = Form::Maker->make("Form::Outline::Login");
ok(
        $form->add_validation(username => {
                perl => $Email::Valid::RFC822PAT,
                javascript =>
'/^[\w\-\+\._]+\@[a-zA-Z0-9][-a-zA-Z0-9\.]*\.[a-zA-Z]+$/'
})
, "Different validation client and server side")
}

{
my $form = Form::Maker->make("Form::Outline::Login");
ok(
    $form->add_validation(username => 'Form::Validator::Email')
, "Can add canned validation");

like($form, qr/onblur/i, "Validation needs to actually do something");
}
