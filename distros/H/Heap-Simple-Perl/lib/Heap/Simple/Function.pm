package Heap::Simple::Function;
$VERSION = "0.04";
use strict;
use Carp;

sub _elements {
    my ($class, $heap, $name, $elements) = @_;
    if (!defined $elements->[1]) {
        $class->isa("Heap::Simple::Wrapper") ||
            croak "missing key function for $elements->[0]";
        return $name, "0";
    }
    $heap->[0]{index} = $elements->[1];
    return $name;
}

sub _ELEMENTS_PREPARE {
    return "my \$el_fun = \$heap->[0]{index};";
}

sub _KEY {
    return "\$el_fun->($_[1])";
}

sub _QUICK_KEY {
    return "\$heap->[0]{index}->($_[1])";
}

sub key_function {
    return shift->[0]{index};
}

sub key {
    return $_[0][0]{index}->($_[1]);
}

sub elements {
    return wantarray ? (Function => shift->[0]{index}) : "Function";
}

1;
