package Heap::Simple::Array;
$VERSION = "0.03";
use strict;
use Carp;

sub _elements {
    my ($class, $heap, $name, $elements) = @_;
    if (defined($elements->[1])) {
        $elements->[1] =~ /^\s*(-?\d+)\s*$/ || Carp::croak "index '$elements->[1]' for $elements->[0] elements is not an integer";
        $heap->[0]{index} = $1+0;
    } else {
        $heap->[0]{index} = 0;
    }
    return $name, $heap->[0]{index};
}

sub _KEY {
    return $_[1] . "->[$_[0][0]{index}]"
}

sub _QUICK_KEY {
    return $_[1] . "->[$_[0][0]{index}]"
}

sub key_index {
    my $heap = shift;
    $heap->_make("sub key_index() {
    return $heap->[0]{index};
}");
    return $heap->key_index(@_);
}

sub elements {
    return wantarray ? (Array => shift->[0]{index}) : "Array";
}

1;
