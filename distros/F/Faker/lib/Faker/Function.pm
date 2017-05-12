package Faker::Function;

use Extorter;

our $VERSION = '0.12'; # VERSION

my %functions = (
    confess   => 'Carp::confess',
    load      => 'Class::Load::load',
    merge     => 'Hash::Merge::Simple::merge',
    tryload   => 'Class::Load::try_load_class',
);

sub import {
    my $class  = shift;
    my $target = caller;

    my @parameters = map "$functions{$_}=$_",
        grep $functions{$_}, @_ if @_;

    $class->extort::into($target, $_) for @parameters;

    return;
}

1;
