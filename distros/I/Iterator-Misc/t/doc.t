use strict;
use Test::More tests => 23;
use Iterator::Misc;

# Check that the documentation examples work.

my ($iter, $ref, @vals);

#  Permute examples (14)

eval  {$iter = ipermute ('one', 'two', 'three');};
is ($@, q{}, q{Permute example iterator created.});

eval {$ref  = $iter->value()};
is ($@, q{}, q{Permute iterator: grab sequence 1.});
is_deeply ($ref, ['one', 'two', 'three'], q{Permute sequence 1 correct.});

eval {$ref  = $iter->value()};
is ($@, q{}, q{Permute iterator: grab sequence 2.});
is_deeply ($ref, ['one', 'three', 'two'], q{Permute sequence 2 correct.});

eval {$ref  = $iter->value()};
is ($@, q{}, q{Permute iterator: grab sequence 3.});
is_deeply ($ref, ['two', 'one', 'three'], q{Permute sequence 3 correct.});

eval {$ref  = $iter->value()};
is ($@, q{}, q{Permute iterator: grab sequence 4.});
is_deeply ($ref, ['two', 'three', 'one'], q{Permute sequence 4 correct.});

eval {$ref  = $iter->value()};
is ($@, q{}, q{Permute iterator: grab sequence 5.});
is_deeply ($ref, ['three', 'one', 'two'], q{Permute sequence 5 correct.});

eval {$ref  = $iter->value()};
is ($@, q{}, q{Permute iterator: grab sequence 6.});
is_deeply ($ref, ['three', 'two', 'one'], q{Permute sequence 6 correct.});

eval {$ref  = $iter->value()};
ok (Iterator::X::Exhausted->caught(), q{Permute iterator is exhausted});

################################################################

# Geometric examples (9)

eval
{
    $iter = igeometric (1, 27, 3);
    push @vals, $iter->value for (1..4);
};
is ($@, q{}, q{igeometric first example created and executed});
is_deeply(\@vals, [1, 3, 9, 27], q{igeometric 1: correct result});
ok ($iter->is_exhausted(), q{igeometric 1: iterator is exhausted});

@vals = ();
eval
{
    $iter = igeometric (1, undef, 3);      # 1, 3, 9, 27, 81, ...
    push @vals, $iter->value for (1..5);
};
is ($@, q{}, q{igeometric second example created and executed});
is_deeply(\@vals, [1, 3, 9, 27, 81], q{igeometric 2: correct result});
ok ($iter->isnt_exhausted(), q{igeometric 2: iterator isn't exhausted});

@vals = ();
eval
{
    $iter = igeometric (10, undef, 0.1);   # 10, 1, 0.1, 0.01, ...
    push @vals, $iter->value for (1..4);
};
is ($@, q{}, q{igeometric third example created and executed});
is_deeply(\@vals, [10, 1, 0.1, 0.01], q{igeometric 3: correct result});
ok ($iter->isnt_exhausted(), q{igeometric 3: iterator isn't exhausted});

