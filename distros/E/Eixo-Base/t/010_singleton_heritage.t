package A;
use Eixo::Base::Clase qw(Eixo::Base::Singleton);

has(
    a => 1, 
    b => 2
);
#__PACKAGE__->make_singleton();


package B;
use Eixo::Base::Clase -norequire, 'A';
has(
    b => 4,
    c => 3
);

__PACKAGE__->make_singleton();


package main;
use t::test_base;

ok(
    B->a == 1,
    "Attribute inherited with its default value"
);

ok(
    B->b == 4,
    "Default value from parent attribute rewrite by children"
);

ok(
    B->c == 3,
    "New attribute getter created"
);



done_testing();


