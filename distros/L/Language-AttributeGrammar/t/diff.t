use Test::More tests => 2;

BEGIN { use_ok('Language::AttributeGrammar') }

my $grammar = new Language::AttributeGrammar <<'EOG';

Cons: $/.len            = { 1 + $<tail>.len }   # length of list is 1 + length of tail
Nil:  $/.len            = { 0 }

Cons: $/.sum            = { $<head> + $<tail>.sum }
Nil:  $/.sum            = { 0 }

Root: $<list>.global_avg = { $<list>.sum / $<list>.len }
Cons: $<tail>.global_avg = { $/.global_avg }

Root: $/.diff           = { $<list>.diff }
Cons: $/.diff           = # Cons($<head> - $/.global_avg, $<tail>.diff)
    {
        bless { head => ($<head> - $/.global_avg), tail => $<tail>.diff } => 'Cons' 
    }
Nil:  $/.diff           = { bless { } => 'Nil' }

EOG

sub Root { bless { list => $_[0] } => 'Root' }
sub list { 
    if (@_) {
        bless { head => $_[0], tail => list(@_[1..$#_]) } => 'Cons';
    }
    else {
        bless { } => 'Nil';
    }
}

my $result = $grammar->apply(Root(list(1,2,3,4,5)), 'diff');
is_deeply($result, list(-2,-1,0,1,2));

# vim: ft=perl :
