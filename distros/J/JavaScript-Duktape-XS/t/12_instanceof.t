use strict;
use warnings;

use Ref::Util qw/ is_scalarref /;
use Test::More;
use JavaScript::Duktape::XS;

sub test_instanceof {
    my $js = <<JS;
function Car(make, model, year) {
  this.make = make;
  this.model = model;
  this.year = year;
}
var auto = new Car('Honda', 'Accord', 1998);
auto.older = new Car('Ford', 'T', 1945);
JS
    my %data = (
        'auto'       => [ 'Car', 'Object' ],
        'auto.older' => [ 'Car', 'Object' ],
    );
    my $duk = JavaScript::Duktape::XS->new();
    ok($duk, "created JavaScript::Duktape::XS object");
    $duk->eval($js);

    foreach my $name (sort keys %data) {
        my $classes = $data{$name};
        foreach my $class (@$classes) {
            my $got = $duk->instanceof($name, $class);
            ok($got, "$name is a $class");
        }
    }
}

sub main {
    test_instanceof();
    done_testing;

    return 0;
}

exit main();
