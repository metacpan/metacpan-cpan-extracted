use Test::More tests => 3;

BEGIN { use_ok('Language::AttributeGrammar') }
BEGIN { use_ok('Language::AttributeGrammar::Parser') }

my $grammar = new Language::AttributeGrammar <<'EOG';

# find the minimum from the leaves up
Leaf: $/.min = { $<value> }
Branch: $/.min = {
    $<left>.min <= $<right>.min ? $<left>.min : $<right>.min;
}

# propagate the global minimum downward
ROOT:   $/.gmin       = { $/.min }
Branch: $<left>.gmin  = { $/.gmin }
Branch: $<right>.gmin = { $/.gmin }

# reconstruct the minimized result
Leaf:   $/.result  = { bless { value => $/.gmin } => 'Leaf' }
Branch: $/.result  = { bless { left  => $<left>.result, 
                               right => $<right>.result } => 'Branch' }

EOG

sub Leaf   { bless { value => $_[0] } => 'Leaf' }
sub Branch { bless { left => $_[0], right => $_[1] } => 'Branch' }

my $tree = Branch(
            Branch(Leaf(2), Leaf(3)),
            Branch(Leaf(1), Branch(Leaf(5), Leaf(9))));
my $result = Branch(
            Branch(Leaf(1), Leaf(1)),
            Branch(Leaf(1), Branch(Leaf(1), Leaf(1))));

is_deeply($grammar->apply($tree, 'result'), $result);


# vim: ft=perl :
