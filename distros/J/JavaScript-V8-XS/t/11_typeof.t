use strict;
use warnings;

use Data::Dumper;
use Test::More;

my $CLASS = 'JavaScript::V8::XS';

sub test_typeof {
    # boolean is tested separately on test_typeof_boolean()
    my %data = (
        'undefined' => [ \'DO NOT SET VALUE' ],
        'null'      => [ undef ],
        'number'    => [ 11, 3.1415 ],
        'string'    => [ '', 'gonzo' ],
        'array'     => [ [], [1, 2, 3] ],
        'object'    => [ { foo => 1, bar => 2 } ],
    );

    foreach my $type (sort keys %data) {
        my $name = "var_$type";
        my $values = $data{$type};
        foreach my $value (@$values) {
            my $vm = $CLASS->new();
            ok($vm, "created $CLASS object");
            $vm->set($name, $value) unless $type eq 'undefined';
            my $got = $vm->typeof($name);
            is($got, $type, "got correct typeof for $type");
        }
    }
}

sub test_typeof_boolean {
    my $js = <<JS;
var var_true      = true;
var var_false     = false;
var var_Boolean_1 = Boolean(1);
var var_Boolean_0 = Boolean(0);
JS
    my $vm = $CLASS->new();
    ok($vm, "created $CLASS object");

    my @booleans = qw/ var_true var_false var_Boolean_1 var_Boolean_0 /;
    $vm->eval($js);
    my $type = 'boolean';
    foreach my $boolean (@booleans) {
        my $got = $vm->typeof($boolean);
        is($got, $type, "got correct typeof for $type");
    }
}

sub test_typeof_object {
    my $js = <<JS;
function Car(make, model, year) {
  this.make = make;
  this.model = model;
  this.year = year;
}
var auto = new Car('Honda', 'Accord', 1998);
JS
    my %fields = (
        make => "string",
        model => "string",
        year => "number",
        not_there => "undefined",
    );
    my $vm = $CLASS->new();
    ok($vm, "created $CLASS object");

    $vm->eval($js);
    my $got = $vm->typeof("auto");
    is($got, 'object', "got correct typeof for auto");
    foreach my $field (sort keys %fields) {
        my $got = $vm->typeof("auto.$field");
        is($got, $fields{$field}, "got correct typeof for field $field");
    }
}

sub main {
    use_ok($CLASS);

    test_typeof();
    test_typeof_boolean();
    test_typeof_object();
    done_testing;

    return 0;
}

exit main();
