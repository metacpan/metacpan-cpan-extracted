package Heap::Simple::Hash;
$VERSION = "0.05";
use strict;
use Carp;

my $key_name = "k0";
my %key_names;

sub _elements {
    my ($class, $heap, $name, $elements) = @_;
    croak "missing key name for $elements->[0]" unless
        defined($elements->[1]);
    $heap->[0]{index} = $elements->[1];
    return $name, $key_names{$heap->[0]{index}} ||= $key_name++ if 
        $elements->[1] =~ /\A[ -~]*\z/;
    $heap->[0]{complex} = 1;
    return $name;
}

sub _ELEMENTS_PREPARE {
    return shift->[0]{complex} ? "my \$name = \$heap->[0]{index};" : "";
}

sub _KEY {
    return shift->[0]{complex} ? 
        shift() . "->{\$name}" : shift() . "->{_STRING}"
}

sub _QUICK_KEY {
    return shift->[0]{complex} ? 
        shift() . "->{\$heap->[0]{index}}" : shift() . "->{_STRING}"
}

sub key_name {
    my $heap = shift;
    if ($heap->[0]{complex}) {
        $heap->_make('sub key_name() {
    shift->[0]{index}}');
    } else {
        $heap->_make(qq(sub key_name() {
    return _STRING;
}));
    }
    return $heap->key_name(@_);
}

sub key {
    my $heap = shift;
    if ($heap->[0]{complex}) {
        $heap->_make('sub key {
    return $_[1]->{$_[0][0]{index}}}');
    } else {
        $heap->_make('sub key {
    return $_[1]->{_STRING}}');
    }
    return $heap->key(@_);
}

sub elements {
    return wantarray ? (Hash => shift->[0]{index}) : "Hash";
}

1;
