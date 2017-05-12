use Test::More;

use Lingua::EN::Inflexion;

sub is_singular_to_plural {
    my ($sing, $plur) = @_;

    ok adj($sing)->is_singular         => "'$sing' is singular";
    is adj($sing)->plural,      $plur  => "'$sing' --> '$plur'";
}

sub is_plural_to_singular {
    my ($sing, $plur) = @_;

    ok adj($plur)->is_plural         => "'$plur' is plural";
    is adj($plur)->singular,  $sing  => "'$plur' --> '$sing'";
}

# Determiners...

is_singular_to_plural  "a"      =>  "some";
is_singular_to_plural  "an"     =>  "some";

is_plural_to_singular  "a"      =>  "some";


# Demonstratives...

is_singular_to_plural  "that"   =>  "those";
is_singular_to_plural  "this"   =>  "these";

is_plural_to_singular  "that"   =>  "those";
is_plural_to_singular  "this"   =>  "these";


# Personal possessives...

is_singular_to_plural  "my"     =>  "our";
is_singular_to_plural  "your"   =>  "your";
is_singular_to_plural  "their"  =>  "their";
is_singular_to_plural  "her"    =>  "their";
is_singular_to_plural  "his"    =>  "their";
is_singular_to_plural  "its"    =>  "their";

is_plural_to_singular  "my"     =>  "our";
is_plural_to_singular  "your"   =>  "your";
is_plural_to_singular  "their"  =>  "their";


# Normal adjectives...

is_singular_to_plural  "red"    =>  "red";
is_singular_to_plural  "tall"   =>  "tall";
is_singular_to_plural  "lonely" =>  "lonely";
is_singular_to_plural  "ox"     =>  "ox";
is_singular_to_plural  "child"  =>  "child";
is_singular_to_plural  "foot"   =>  "foot";

is_plural_to_singular  "red"    =>  "red";
is_plural_to_singular  "tall"   =>  "tall";
is_plural_to_singular  "lonely" =>  "lonely";
is_plural_to_singular  "ox"     =>  "ox";
is_plural_to_singular  "child"  =>  "child";
is_plural_to_singular  "foot"   =>  "foot";


# Possessive adjectives...

is_singular_to_plural  "woman's"   =>  "women's";
is_singular_to_plural  "lady's"   =>  "ladies'";
is_singular_to_plural  "latch's"  =>  "latches'";
is_singular_to_plural  "ox's"     =>  "oxen's";
is_singular_to_plural  "child's"  =>  "children's";
is_singular_to_plural  "foot's"   =>  "feet's";

is_plural_to_singular  "woman's"  =>  "women's";
is_plural_to_singular  "lady's"   =>  "ladies'";
is_plural_to_singular  "latch's"  =>  "latches'";
is_plural_to_singular  "ox's"     =>  "oxen's";
is_plural_to_singular  "child's"  =>  "children's";
is_plural_to_singular  "foot's"   =>  "feet's";


done_testing();
