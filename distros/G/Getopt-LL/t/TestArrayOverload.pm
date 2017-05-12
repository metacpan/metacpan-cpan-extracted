package TestArrayOverload;

use overload '@{}' => sub {
    return [keys %{$_[0]}];
};

use overload 'bool' => sub {
    1
};

sub new {
    return bless {'a' => 1, 'b' => 2 }, shift;
}

1;
