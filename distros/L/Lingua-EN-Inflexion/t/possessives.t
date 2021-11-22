use Test::More;
plan tests => 40;


use Lingua::EN::Inflexion;


note "Plural possessive nouns...";

is noun(q{Albino's})->plural,   q{Albinos'} => q{Albino's -> Albinos'};
is noun(q{albino's})->plural,   q{albinos'} => q{albino's -> albinos'};
is noun(q{Dog's})->plural,      q{Dogs'}    => q{Dog's    -> Dogs'};
is noun(q{dog's})->plural,      q{dogs'}    => q{dog's    -> dogs'};
is noun(q{woman's})->plural,    q{women's}  => q{woman's  -> women's};
is noun(q{women's})->plural,    q{women's}  => q{women's  -> women's};

is noun(q{Albinos'})->plural,   q{Albinos'} => q{Albinos' -> Albinos'};
is noun(q{albinos'})->plural,   q{albinos'} => q{albinos' -> albinos'};
is noun(q{Dogs'})->plural,      q{Dogs'}    => q{Dogs'    -> Dogs'};
is noun(q{dogs'})->plural,      q{dogs'}    => q{dogs'    -> dogs'};


note "Singular possessive nouns...";

is noun(q{Albino's})->singular, q{Albino's} => q{Albino's -> Albino's};
is noun(q{albino's})->singular, q{albino's} => q{albino's -> albino's};
is noun(q{Dog's})->singular,    q{Dog's}    => q{Dog's    -> Dog's};
is noun(q{dog's})->singular,    q{dog's}    => q{dog's    -> dog's};
is noun(q{woman's})->singular,  q{woman's}  => q{woman's  -> woman's};
is noun(q{women's})->singular,  q{woman's}  => q{women's  -> woman's};

is noun(q{Albinos'})->singular, q{Albino's} => q{Albinos' -> Albino's};
is noun(q{albinos'})->singular, q{albino's} => q{albinos' -> albino's};
is noun(q{Dogs'})->singular,    q{Dog's}    => q{Dogs'    -> Dog's};
is noun(q{dogs'})->singular,    q{dog's}    => q{dogs'    -> dog's};


note "Plural possessive adjectives...";

is adj(q{Albino's})->plural,   q{Albinos'} => q{Albino's -> Albinos'};
is adj(q{albino's})->plural,   q{albinos'} => q{albino's -> albinos'};
is adj(q{Dog's})->plural,      q{Dogs'}    => q{Dog's    -> Dogs'};
is adj(q{dog's})->plural,      q{dogs'}    => q{dog's    -> dogs'};
is adj(q{woman's})->plural,    q{women's}  => q{woman's  -> women's};
is adj(q{women's})->plural,    q{women's}  => q{women's  -> women's};

is adj(q{Albinos'})->plural,   q{Albinos'} => q{Albinos' -> Albinos'};
is adj(q{albinos'})->plural,   q{albinos'} => q{albinos' -> albinos'};
is adj(q{Dogs'})->plural,      q{Dogs'}    => q{Dogs'    -> Dogs'};
is adj(q{dogs'})->plural,      q{dogs'}    => q{dogs'    -> dogs'};


note "Singular possessive adjectives...";

is adj(q{Albino's})->singular, q{Albino's} => q{Albino's -> Albino's};
is adj(q{albino's})->singular, q{albino's} => q{albino's -> albino's};
is adj(q{Dog's})->singular,    q{Dog's}    => q{Dog's    -> Dog's};
is adj(q{dog's})->singular,    q{dog's}    => q{dog's    -> dog's};
is adj(q{woman's})->singular,  q{woman's}  => q{woman's  -> woman's};
is adj(q{women's})->singular,  q{woman's}  => q{women's  -> woman's};

is adj(q{Albinos'})->singular, q{Albino's} => q{Albinos' -> Albino's};
is adj(q{albinos'})->singular, q{albino's} => q{albinos' -> albino's};
is adj(q{Dogs'})->singular,    q{Dog's}    => q{Dogs'    -> Dog's};
is adj(q{dogs'})->singular,    q{dog's}    => q{dogs'    -> dog's};


done_testing();

