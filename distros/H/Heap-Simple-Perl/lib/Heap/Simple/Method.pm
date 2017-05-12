package Heap::Simple::Method;
$VERSION = "0.05";
use strict;
use Carp;

my $method_name = "k0";
my %method_names;

sub _elements {
    my ($class, $heap, $name, $elements) = @_;
    if (!defined $elements->[1]) {
        $class->isa("Heap::Simple::Wrapper") ||
            croak "missing key method for $elements->[0]";
        $heap->[0]{complex} = 1;
        return $name, "0";
    }
    $heap->[0]{index} = $elements->[1];
    return $name, $method_names{$heap->[0]{index}} ||= $method_name++ if
        $elements->[1] =~ /\A[_A-Za-z][A-Za-z0-9]*\z/;
    $heap->[0]{complex} = 1;
    return $name;
}

sub _ELEMENTS_PREPARE {
    return shift->[0]{complex} ? "my \$name = \$heap->[0]{index};" : "";
}

sub _KEY {
    return shift->[0]{complex} ? shift() . "->\$name" : shift() . "->_LITERAL";
}

sub _QUICK_KEY {
    return return shift->[0]{complex} ? "-" : shift() . "->_LITERAL"
}

sub key_method {
    my $heap = shift;
    if ($heap->[0]{complex}) {
        $heap->_make(qq(sub key_method {
    return shift->[0]{index};
}));
    } else {
        $heap->_make(qq(sub key_method() {
    return _STRING;
}));
    }
    return $heap->key_method(@_);
}

sub elements {
    return wantarray ? (Method => shift->[0]{index}) : "Method";
}

1;
