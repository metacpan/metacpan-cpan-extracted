# -*- mode: Perl; -*-
package ClassAutoloadTest;

use parent qw(Eve::Test);

use strict;
use warnings;

use Test::More;
use Test::Exception;

sub setup : Test(setup) {
    my $self = shift(@_);
    $self->{object} = Eve::ClassAutoloadTest::Dummy->new();
};

sub test_get_property : Test(2) {
    my $object = shift(@_)->{object};
    is($object->property, 'value');
    is($object->another_property, 'another value');
}

sub test_set_property : Test(2) {
    my $object = shift(@_)->{object};
    $object->property = 'yet another value';
    is($object->property, 'yet another value');
    $object->property = 'agane another value';
    is($object->property, 'agane another value');
}

sub test_getter_calls : Test(2) {
    my $object = shift(@_)->{object};
    is($object->getter_property, 'getter called');
    is($object->another_getter_property, 'another getter called');
}

sub test_setter_calls : Test(2) {
    my $object = shift(@_)->{object};
    is(($object->setter_property = 'some value'),
       'setter called with some value');
    is(($object->another_setter_property = 'some another value'),
       'another setter called with some another value');
}

sub test_get_non_property : Test(2) {
    my $object = shift(@_)->{object};
    my $class_name = 'Eve::Error::Attribute';

    throws_ok(
        sub { my $a =  $object->non_property },
        qr/$class_name: Property non_property does not exist/);
    throws_ok(
        sub { my $a =  $object->another_non_property },
        qr/$class_name: Property another_non_property does not exist/);
}

sub test_set_non_property : Test(2) {
    my $object = shift(@_)->{object};
    my $class_name = 'Eve::Error::Attribute';

    throws_ok(
        sub { $object->non_property = 'some non value' },
        qr/$class_name: Property non_property does not exist/);
    throws_ok(
        sub { $object->another_non_property = 'some another non value' },
        qr/$class_name: Property another_non_property does not exist/);
}

sub test_call_non_method : Test(2) {
    my $object = shift(@_)->{object};
    my $class_name = 'Eve::Error::Attribute';

    throws_ok(
        sub { $object->non_method() },
        qr/$class_name: Method non_method does not exist/);
    throws_ok(
        sub { $object->another_non_method() },
        qr/$class_name: Method another_non_method does not exist/);
}

sub test_call_property_as_method : Test(2) {
    my $object = shift(@_)->{object};
    my $class_name = 'Eve::Error::Attribute';

    throws_ok(
        sub { $object->property() },
        qr/$class_name: Method property does not exist/);
    throws_ok(
        sub { $object->another_property() },
        qr/$class_name: Method another_property does not exist/);
}

1;

package Eve::ClassAutoloadTest::Dummy;

use parent qw(Eve::Class);

sub init {
    my $self = shift;
    $self->{'property'} = 'value';
    $self->{'another_property'} = 'another value';
    $self->{'getter_property'} = 'value';
    $self->{'another_getter_property'} = 'value';
    $self->{'setter_property'} = 'value';
    $self->{'another_setter_property'} = 'value';
}

sub _get_getter_property {
    return 'getter called';
}

sub _get_another_getter_property {
    return 'another getter called';
}

sub _set_setter_property {
    my ($self, $value) = @_;
    $self->{'setter_property'} = 'setter called with '.$value;
    return $self->{'setter_property'};
}

sub _set_another_setter_property {
    my ($self, $value) = @_;
    $self->{'another_setter_property'} =
        'another setter called with '.$value;
    return $self->{'setter_property'};
}

1;
