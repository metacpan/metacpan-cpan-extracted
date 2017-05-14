use Test::More tests => 66;
use FLAT;

# use Data::Dumper;

my $reg;

sub regex { FLAT::Regex->new(@_) }

is( ref regex("a"),
    "FLAT::Regex",
    "blessed reference" );

is( regex( "(((a)bc)def)ghi" )->as_string,
    "abcdefghi",
    "Collapse parens for concatenation" );

is( regex( "(((a)+b+c)+d+e+f)+g+h+i" )->as_string,
    "a+b+c+d+e+f+g+h+i",
    "Collapse parens for alternation" );
    
is( regex( "((a+(b+(cd)))*)+e" )->as_string,
    "(a+b+cd)*+e",
    "Parens kept for precedence" );

is( regex("#")->as_string,
    "#",
    "Null regex" );

is( regex("[]")->as_string,
    "[]",
    "epsilon" );

is( regex("[#][ ][foo][*][a][1][23]")->as_string,
    "[#][ ][foo][*]a1[23]",
    "special [] characters as string" );

is( regex("  a\tb\nc \n\t d")->as_string,
    "abcd",
    "whitespace ignored" );

for ( ")ab",  "a(bc(d)", "ab)cd(ef", "a+b+", "a++b", "+a", "h**", "a+*", "" ) {
    eval { regex($_) };
    ok( $@,
        "Parse error caught: $_" );
}

$reg = regex( "abc+def+ghi*+(a+b)*" );
is( $reg->as_string,
    $reg->reverse->reverse->as_string,
    "Reversal operation idempotent" );

#####

ok( regex("#")->is_empty,
    "is_empty (atomic)" );

ok( ! regex("[#]")->is_empty,
    "is_empty (atomic)" );

ok( ! regex("[foo]")->is_empty,
    "is_empty (atomic)" );

ok( ! regex("[]")->is_empty,
    "is_empty (atomic)" );

ok( ! regex("[ ]")->is_empty,
    "is_empty (atomic)" );
    
ok( regex("a#a")->is_empty,
    "is_empty (concatenation)" );

ok( ! regex("aa")->is_empty,
    "is_empty (concatenation)" );

ok( ! regex("#*")->is_empty,
    "is_empty (star)" );

ok( ! regex("[#]*")->is_empty,
    "is_empty (star)" );

ok( ! regex("#+b")->is_empty,
    "is_empty (alternation)" );

ok( regex("#+#")->is_empty,
    "is_empty (alternation)" );



ok( regex("a")->is_finite,
    "is_finite (atomic)" );

ok( regex("#")->is_finite,
    "is_finite (atomic)" );

ok( regex("#*")->is_finite,
    "is_finite (star)" );

ok( ! regex("[#]*")->is_finite,
    "is_finite (star)" );

ok( regex("[]*")->is_finite,
    "is_finite (star)" );

ok( regex("([]+ [][])*")->is_finite,
    "is_finite (star)" );

ok( ! regex("a*")->is_finite,
    "is_finite (star)" );

ok( regex("a+b")->is_finite,
    "is_finite (alternation)" );

ok( ! regex("a+a*")->is_finite,
    "is_finite (alternation)" );
    
ok( regex("aa")->is_finite,
    "is_finite (concatenation)" );

ok( ! regex("a*a")->is_finite,
    "is_finite (concatenation)" );

####

$reg = regex("ab(c|de|f*)(g|[])");
my $p = $reg->as_perl_regex(anchored => 1);

for (qw[ abcg abc abdeg abde ab abg abfffg abff ]) {
    ok( /$p/,
        "as_perl_regex (positives)" );

    ok( $reg->contains($_),
        "contains (positives)" );
}

for (qw[ aabcg ac abcdeg abdef abffgg ]) {
    ok( ! /$p/,
        "as_perl_regex (negatives)" );

    ok( ! $reg->contains($_),
        "contains (negatives)" );
}
