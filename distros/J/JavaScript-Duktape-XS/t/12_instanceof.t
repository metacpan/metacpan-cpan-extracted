use strict;
use warnings;

use Test::More;

my $CLASS = 'JavaScript::Duktape::XS';

sub test_instanceof {
    my $js = <<JS;
function Car(make, model, year) {
  this.make = make;
  this.model = model;
  this.year = year;
}

var honda = new Car('Honda', 'Accord', 1998);
honda.older = new Car('Ford', 'T', 1945);
var empty = [];
JS
    my %data = (
        'honda' => {
            1 => [ 'Car', 'Object' ],
            0 => [ 'Array', 'Gonzo' ],
        },
        'honda.older' => {
            1 => [ 'Car', 'Object' ],
            0 => [ 'Array', 'Gonzo' ],
        },
        'empty' => {
            1 => [ 'Array', 'Object' ],
            0 => [ 'Car', 'Gonzo' ],
        },
    );
    my $vm = $CLASS->new();
    ok($vm, "created $CLASS object");

    $vm->eval($js);

    foreach my $name (sort keys %data) {
        my $cases = $data{$name};
        foreach my $should (sort keys %$cases) {
            my $classes = $cases->{$should};
            foreach my $class (@$classes) {
                my $got = $vm->instanceof($name, $class);
                is(!!$got, !!$should, sprintf("%s %s a %s", $name, $should ? 'is' : 'is not', $class));
            }
        }
     }
}

sub main {
    use_ok($CLASS);

    test_instanceof();
    done_testing;

    return 0;
}

exit main();
