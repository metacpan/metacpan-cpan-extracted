package Faker::Base;

use Extorter;

our $VERSION = '0.12'; # VERSION

sub import {
    my $class  = shift;
    my $target = caller;

    $class->extort::into($target, '*Data::Object::Class');
    $class->extort::into($target, '*Faker::Signature');
    $class->extort::into($target, '*Faker::Type');

    return;
}

1;
