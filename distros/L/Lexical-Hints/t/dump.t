use lib 'tlib';
use Test::More;

sub test_hints {
    my ($hints_hash_ref, $no_lh) = @_;

    my $lh = exists $hints_hash_ref->{'Test_Compiletime_Hints->cth'};
    if ($no_lh) { ok !$lh => 'cth not in scope'; }
           else { ok  $lh => 'cth in scope';     }

    ok exists $hints_hash_ref->{'Test_Manual_Hints'} => 'manual hints in scope';
}

use Test_Manual_Hints;

{
    use Test_Compiletime_Hints 'dumping';

    BEGIN {
        my $dump = Lexical::Hints::dump();
        test_hints(eval $dump);
    }

    {
        my $dump = Lexical::Hints::dump();
        test_hints(eval $dump);
    }
}

{
    use Test_Compiletime_Hints 'dumping';

    BEGIN {
        local *STDERR;
        open *STDERR, '>', \my $dump;
        Lexical::Hints::dump();
        test_hints(eval $dump);
    }

    {
        local *STDERR;
        open *STDERR, '>', \my $dump;
        Lexical::Hints::dump();
        test_hints(eval $dump);
    }
}

{
    my $dump = Lexical::Hints::dump();
    test_hints(eval $dump, 'no_lh');
}


done_testing();
