package Heap::Simple::Any;
require Heap::Simple::Wrapper;
require Heap::Simple::Function;
@ISA = qw(Heap::Simple::Wrapper Heap::Simple::Function);
$VERSION = "0.03";
use strict;

sub _REAL_KEY {
    my $heap = shift;
    return defined $heap->[0]{index} ? 
        $heap->Heap::Simple::Function::_KEY(@_) :
        qq(Carp::croak("Element type 'Any' without key code"));
}

sub _REAL_ELEMENTS_PREPARE {
    return shift->Heap::Simple::Function::_ELEMENTS_PREPARE(@_);
}

sub elements {
    return wantarray && exists $_[0][0]{index} ? (Any => shift->[0]{index}) : "Any";
}

1;
