# Form field elements need to inherit ->type and ->_tag explicitly from
# the class data since HTML::Element uses these by looking at the hash
# slots, not by calling them as methods, so we can't use
# Class::Data::Inheritable to implicitly inherit them from class data.

use Test::More tests => 3;

use Form::Maker;

my $form = Form::Field::Text->new({ name => "hello" });
is($form->{name}, "hello", "Name set OK");
is($form->{type}, "text", "Type inherited OK");
is($form->{_tag}, "input", "Tag inherited OK");
