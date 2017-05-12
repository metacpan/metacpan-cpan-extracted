use strict;
use warnings;
use Test::More;
use Lingua::PigLatin::Bidirectional;

subtest 'basic' => sub {
    # taken from Lingua::PigLatin
    my $input  = q{the quick red fox jumped over the lazy brown cheese ghost};
    my $output = q{ethay ickquay edray oxfay umpedjay overway ethay azylay }
               . q{rownbay eesechay ostghay};

    is( to_piglatin($input), $output );
};

subtest 'word followed by punctuation marks' => sub {
    my $input  = q{i, oklahomer, am goin' to college.};
    my $output = q{iway, oklahomerway, amway oingay' otay ollegecay.};

    is( to_piglatin($input), $output );
};

subtest 'with capitalization' => sub {
    my $input  = q{You are from Japan.};
    my $output = q{Ouyay areway romfay Apanjay.};

    is( to_piglatin($input), $output );
};

subtest 'multiple lines' => sub {
    my $input = <<'INPUT';
You are from Japan.
I am from Japan.
INPUT

    my $output = <<'OUTPUT';
Ouyay areway romfay Apanjay.
Iway amway romfay Apanjay.
OUTPUT

    is( to_piglatin($input), $output );
};

done_testing();
