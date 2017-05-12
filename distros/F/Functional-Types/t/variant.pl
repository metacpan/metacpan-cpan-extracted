use warnings;
use 5.016;
use Data::Dumper;

use Functional::Types;


# Maybe a = Just a | Nothing
sub Maybe { typename(@_) }    
sub Just { newtype Maybe(a),Variant(a),@_ }    
sub Nothing { newtype Maybe(a), Variant() }    


# Trio = One Int | Two Float | Three Double
sub Trio { typename }    
sub One { newtype Trio,Variant(Int),@_ }
sub Two { newtype Trio,Variant(Float),@_ }
sub Three { newtype Trio,Variant(Bool),@_ }

type my $m = Maybe(Int);
say "TYPE:".Dumper($m);
my $vj = Just(Int(42));
say "TYPE vj:".show($vj);
my $vn = Nothing;
say "TYPE vn:".show($vn);

bind $m,$vn;
say 'type of m: ',show($m);

#say 'type of m: ',Dumper($m);
say "UNTYPE m:".Dumper(untype $m);

type my $m2 = Maybe(Int);
bind $m2,$vj;
say 'type of m2: ',show($m2);
say  untype( $m2);


# Haskell-style pattern match is not possible, but we can do this:
given (variant $m) {
    when (Just) {say 'Just Int: '.show($m); }    
    when (Nothing) { say 'Nothing!'.show($m);}    
    default {die 'No match'; }
}

type my $trio = Trio;
my $t1 = One(Int(42));
my $t2 = Two(Float(4.2));
my $t3 = Three(True);
say Dumper($t2);

bind $trio, $t3;

say untype $trio;

bind $trio, $t2;
say show($trio);

say untype $trio;


sub Tree { typename(@_) };
sub Leaf { newtype Tree, Variant() };
sub Branch { newtype Tree(a), Variant(Tree,a,Tree),@_ };
type my $tree = Tree(Int);
bind $tree, Branch (Branch (Leaf, Int 41, Leaf), Int 42, Leaf);
say show($tree);
#say Dumper(untype( $tree));

