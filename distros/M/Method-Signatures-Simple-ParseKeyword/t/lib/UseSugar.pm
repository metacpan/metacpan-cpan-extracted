package UseSugar;

use sugar;

method make ($class: %args) {
    bless {%args}, $class;
}

method stuff ($x = 2) {
    $self->{stuff} + $x;
}

1;
