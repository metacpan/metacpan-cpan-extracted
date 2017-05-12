use strict;
use warnings;
use Test::More;
use Lingua::PigLatin::Bidirectional;

subtest 'basic' => sub {
    
    # taken from Lingua::PigLatin
    my $expected = 'the quick red fox jumped over the lazy brown cheese ghost';
    my $string   = 'ethay ickquay edray oxfay umpedjay overway ethay azylay '
                 . 'rownbay eesechay ostghay';

    is( from_piglatin($string), $expected );
};

subtest 'word followed by punctuation marks' => sub {
    my $input  = q{iway, oklahomerway, amway oingay' otay ollegecay.};
    my $output = q{i, oklahomer, am goin' to college.};

    is( from_piglatin($input), $output );
};

subtest 'with capitalization' => sub {
    my $input  = q{Ouyay areway romfay Apanjay.};
    my $output = q{You are from Japan.};

    is( from_piglatin($input), $output );
};

subtest 'multiple lines' => sub {
    my $output = <<'OUTPUT';
You are from Japan.
I am from Japan.
OUTPUT

    my $input = <<'INPUT';
Ouyay areway romfay Apanjay.
Iway amway romfay Apanjay.
INPUT

    is( from_piglatin($input), $output );
};

done_testing();
