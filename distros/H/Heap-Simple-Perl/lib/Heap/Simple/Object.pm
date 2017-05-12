package Heap::Simple::Object;
require Heap::Simple::Wrapper;
require Heap::Simple::Method;
@ISA = qw(Heap::Simple::Wrapper Heap::Simple::Method);
$VERSION = "0.03";
use strict;

sub _REAL_KEY {
    my $heap = shift;
    return defined $heap->[0]{index} ? 
        $heap->Heap::Simple::Method::_KEY(@_) :
        qq(Carp::croak("Element type 'Object' without key method"));
}

sub _REAL_ELEMENTS_PREPARE {
    return shift->Heap::Simple::Method::_ELEMENTS_PREPARE(@_);
}

sub key {
    my $heap = shift;
    if ($heap->[0]{complex}) {
        $heap->_make('sub key {
    my $heap = shift;
    _REAL_ELEMENTS_PREPARE()
    return _REAL_KEY(shift)}');
    } else {
        $heap->_make('sub key {
    return $_[1]->_LITERAL}');
    }
    return $heap->key(@_);
}

sub elements {
    return wantarray  && exists $_[0][0]{index} ? (Object => shift->[0]{index}) : "Object" ;
}

1;
