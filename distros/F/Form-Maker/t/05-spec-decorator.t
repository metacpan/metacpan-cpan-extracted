use Test::More tests => 1;
use Form::Maker;
package My::Form::Decorator::Test;

sub decorate {
    my ($class, $form) = @_;
    Test::More::ok(1, "Decorator called");
}

package My::Form::Maker;
use base 'Form::Maker';
__PACKAGE__->add_decorators('My::Form::Decorator::Test');

package main;
my $form = My::Form::Maker->make("Form::Outline::Login");
my $x = "$form"; # Force a rendering

