use strict;
package main;
use Test::More;
use Test::Exception;
use Class::Load ':all';

BEGIN {
    try_load_class('Moose')
       or plan skip_all => "Moose required to run these tests";
    plan qw/no_plan/;
    use_ok 'IOC::Slinky::Container';
    use_ok 'YAML';
    require 't/objects1.pm';
}

my $conf;
my $c;
my $o;
my $p;

$conf = <<YML;
---
container:
    some_item:
        _class: "Item"
    generic_car:
        _class: "Car"
        _constructor_args:
            brand: "Generic"
    vios1:
        _lookup_id: "somevios"
        _class: "Car"
        _constructor_args:
            brand: "Toyota"
        type: "Sedan"
        model: "Vios"
        year: 2011
    nested_ctor:
        _class: "Car"
        _constructor_args:
            brand: "Test"
            test_item:
                _class: "Item"
    ref_ctor:
        _class: "Car"
        _constructor_args:
            brand: "Test"
            test_item: { _ref: some_item }
    setter_ctor:
        _class: "Car"
        _constructor_args:
            brand: "Test"
        test_item:
            _class: "Item"

    ref_setter:
        _class: "Car"
        _constructor_args:
            brand: "Test"
        test_item: { _ref: some_item }

    ctor_passthru:
        _class: "NonMooseThing"
        _constructor_passthru: 1
        _constructor_args:
            - name: "FooBar"
              key2: 1234  
            
YML

$c = IOC::Slinky::Container->new( config => Load($conf) );

# minimal
isa_ok $c->lookup('some_item'), 'Item';

# w/ minimal constructor
isa_ok $c->lookup('generic_car'), 'Car';

# w/ minimal constructor + setter
$o = $c->lookup('vios1');
isa_ok $o, 'Car';
is $o->brand, 'Toyota';
is $o->type, 'Sedan';
is $o->model, 'Vios';
is $o->year, 2011;

# aliased
$p = $c->lookup('somevios');
is $o, $p;

# nested constructor
$o = $c->lookup('nested_ctor');
isa_ok $o->test_item, 'Item';

# ref in constructor
$o = $c->lookup('ref_ctor');
is $o->test_item, $c->lookup('some_item');

# constructor in setter
$o = $c->lookup('setter_ctor');
isa_ok $o->test_item, 'Item';

# ref in setter
$o = $c->lookup('ref_setter');
is $o->test_item, $c->lookup('some_item');

$o = $c->lookup('ctor_passthru');
is $o->{name}, 'FooBar';
is $o->{key2}, 1234;

pass "done";

__END__
