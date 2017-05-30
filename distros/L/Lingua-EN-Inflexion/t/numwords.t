use warnings;
use strict;

use Test::More;

plan tests => 547;

use Lingua::EN::Inflexion;

sub test_eq($$)
{
    PL_eq($_[0],$_[1])    ||
    PL_N_eq($_[0],$_[1])  ||
    PL_V_eq($_[0],$_[1])  ||
    PL_ADJ_eq($_[0],$_[1]);
}


for my $thresh (0..20) {
    for my $n (0..20) {
        my $threshed = noun($n)->cardinal($thresh);
        my $numwords = noun($n)->cardinal;

        if ($n < $thresh) {
            ok ( $numwords eq $threshed => "Wordified $n (<= $thresh)");
        }
        else {
            $threshed =~ s/\D//gxms;
            ok ( $threshed == $n => "Preserved $n (above $thresh)");
        }
    }
}

ok noun(    999)->cardinal(0) eq '999',    ' 999 -> 999';
ok noun(   1000)->cardinal(0) eq '1000',    '1000 -> 1000';
ok noun(  10000)->cardinal(0) eq '10000',   '10000 -> 10000';
ok noun( 100000)->cardinal(0) eq '100000',  '100000 -> 100000';
ok noun(1000000)->cardinal(0) eq '1000000', '1000000 -> 1000000';
ok noun(    999)->ordinal(0)  eq '999th',    ' 999 -> 999th';
ok noun(   1000)->ordinal(0)  eq '1000th',    '1000 -> 1000th';
ok noun(   1001)->ordinal(0)  eq '1001st',    '1001 -> 1001st';
ok noun(   1002)->ordinal(0)  eq '1002nd',    '1002 -> 1002nd';
ok noun(   1003)->ordinal(0)  eq '1003rd',    '1003 -> 1003rd';
ok noun(  10000)->ordinal(0)  eq '10000th',   '10000 -> 10000th';
ok noun( 100000)->ordinal(0)  eq '100000th',  '100000 -> 100000th';
ok noun(1000000)->ordinal(0)  eq '1000000th', '1000000 -> 1000000th';

my @nw;
NUMBER:
for my $i (0..$#nw)
{
    is ( noun($nw[$i][0])->cardinal, $nw[$i][1], "$nw[$i][0] -> $nw[$i][1]..." );
    is ( noun($nw[$i][0])->ordinal,  $nw[$i][5], '...ordinal' ) if $nw[$i][5];
}

BEGIN
{
    @nw =
    (
    [
        "0",
        "zero",
        "zero",
        "zero",
        "zero",
        "zeroth",
    ],[
        "1",
        "one",
        "one",
        "one",
        "one",
        "first",
    ],[
        "2",
        "two",
        "two",
        "two",
        "two",
        "second",
    ],[
        "3",
        "three",
        "three",
        "three",
        "three",
        "third",
    ],[
        "4",
        "four",
        "four",
        "four",
        "four",
        "fourth",
    ],[
        "5",
        "five",
        "five",
        "five",
        "five",
        "fifth",
    ],[
        "6",
        "six",
        "six",
        "six",
        "six",
        "sixth",
    ],[
        "7",
        "seven",
        "seven",
        "seven",
        "seven",
        "seventh",
    ],[
        "8",
        "eight",
        "eight",
        "eight",
        "eight",
        "eighth",
    ],[
        "9",
        "nine",
        "nine",
        "nine",
        "nine",
        "ninth",
    ],[
        "10",
        "ten",
        "one, zero",
        "ten",
        "ten",
        "tenth",
    ],[
        "11",
        "eleven",
        "one, one",
        "eleven",
        "eleven",
        "eleventh",
    ],[
        "12",
        "twelve",
        "one, two",
        "twelve",
        "twelve",
        "twelfth",
    ],[
        "13",
        "thirteen",
        "one, three",
        "thirteen",
        "thirteen",
        "thirteenth",
    ],[
        "14",
        "fourteen",
        "one, four",
        "fourteen",
        "fourteen",
        "fourteenth",
    ],[
        "15",
        "fifteen",
        "one, five",
        "fifteen",
        "fifteen",
        "fifteenth",
    ],[
        "16",
        "sixteen",
        "one, six",
        "sixteen",
        "sixteen",
        "sixteenth",
    ],[
        "17",
        "seventeen",
        "one, seven",
        "seventeen",
        "seventeen",
        "seventeenth",
    ],[
        "18",
        "eighteen",
        "one, eight",
        "eighteen",
        "eighteen",
        "eighteenth",
    ],[
        "19",
        "nineteen",
        "one, nine",
        "nineteen",
        "nineteen",
        "nineteenth",
    ],[
        "20",
        "twenty",
        "two, zero",
        "twenty",
        "twenty",
        "twentieth",
    ],[
        "21",
        "twenty-one",
        "two, one",
        "twenty-one",
        "twenty-one",
        "twenty-first",
    ],[
        "29",
        "twenty-nine",
        "two, nine",
        "twenty-nine",
        "twenty-nine",
        "twenty-ninth",
    ],[
        "99",
        "ninety-nine",
        "nine, nine",
        "ninety-nine",
        "ninety-nine",
        "ninety-ninth",
    ],[
        "100",
        "one hundred",
        "one, zero, zero",
        "ten, zero",
        "one zero zero",
        "one hundredth"
    ],[
        "101",
        "one hundred and one",
        "one, zero, one",
        "ten, one",
        "one zero one",
        "one hundred and first"
    ],[
        "110",
        "one hundred and ten",
        "one, one, zero",
        "eleven, zero",
        "one ten",
        "one hundred and tenth",
    ],[
        "111",
        "one hundred and eleven",
        "one, one, one",
        "eleven, one",
        "one eleven",
        "one hundred and eleventh",
    ],[
        "900",
        "nine hundred",
        "nine, zero, zero",
        "ninety, zero",
        "nine zero zero",
        "nine hundredth",
    ],[
        "999",
        "nine hundred and ninety-nine",
        "nine, nine, nine",
        "ninety-nine, nine",
        "nine ninety-nine",
        "nine hundred and ninety-ninth",
    ],[
        "1000",
        "one thousand",
        "one, zero, zero, zero",
        "ten, zero zero",
        "one zero zero, zero",
        "one thousandth",
    ],[
        "1001",
        "one thousand and one",
        "one, zero, zero, one",
        "ten, zero one",
        "one zero zero, one",
        "one thousand and first",
    ],[
        "1010",
        "one thousand and ten",
        "one, zero, one, zero",
        "ten, ten",
        "one zero one, zero",
        "one thousand and tenth",
    ],[
        "1100",
        "one thousand one hundred",
        "one, one, zero, zero",
        "eleven, zero zero",
        "one ten, zero",
        "one thousand one hundredth",
    ],[
        "2000",
        "two thousand",
        "two, zero, zero, zero",
        "twenty, zero zero",
        "two zero zero, zero",
        "two thousandth",
    ],[
        "10000",
        "ten thousand",
        "one, zero, zero, zero, zero",
        "ten, zero zero, zero",
        "one zero zero, zero zero",
        "ten thousandth",
    ],[
        "100000",
        "one hundred thousand",
        "one, zero, zero, zero, zero, zero",
        "ten, zero zero, zero zero",
        "one zero zero, zero zero zero",
        "one hundred thousandth",
    ],[
        "100001",
        "one hundred thousand and one",
        "one, zero, zero, zero, zero, one",
        "ten, zero zero, zero one",
        "one zero zero, zero zero one",
        "one hundred thousand and first",
    ],[
        "123456",
        "one hundred and twenty-three thousand four hundred and fifty-six",
        "one, two, three, four, five, six",
        "twelve, thirty-four, fifty-six",
        "one twenty-three, four fifty-six",
        "one hundred and twenty-three thousand four hundred and fifty-sixth",
    ],[
        "0123456",
        "one hundred and twenty-three thousand four hundred and fifty-six",
        "zero, one, two, three, four, five, six",
        "zero one, twenty-three, forty-five, six",
        "zero twelve, three forty-five, six",
        "one hundred and twenty-three thousand four hundred and fifty-sixth",
    ],[
        "1234567",
        "one million, two hundred and thirty-four thousand, five hundred and sixty-seven",
        "one, two, three, four, five, six, seven",
        "twelve, thirty-four, fifty-six, seven",
        "one twenty-three, four fifty-six, seven",
        "one million, two hundred and thirty-four thousand, five hundred and sixty-seventh",
    ],[
        "12345678",
        "twelve million, three hundred and forty-five thousand, six hundred and seventy-eight",
        "one, two, three, four, five, six, seven, eight",
        "twelve, thirty-four, fifty-six, seventy-eight",
        "one twenty-three, four fifty-six, seventy-eight",
        "twelve million, three hundred and forty-five thousand, six hundred and seventy-eighth",
    ],[
        "12_345_678",
        "twelve million, three hundred and forty-five thousand, six hundred and seventy-eight",
        "one, two, three, four, five, six, seven, eight",
        "twelve, thirty-four, fifty-six, seventy-eight",
        "one twenty-three, four fifty-six, seventy-eight",
        "twelve million, three hundred and forty-five thousand, six hundred and seventy-eighth",
    ],[
        "1234,5678",
        "twelve million, three hundred and forty-five thousand, six hundred and seventy-eight",
        "one, two, three, four, five, six, seven, eight",
        "twelve, thirty-four, fifty-six, seventy-eight",
        "one twenty-three, four fifty-six, seventy-eight",
    ],[
        "1234567890",
        "one billion, two hundred and thirty-four million, five hundred and sixty-seven thousand, eight hundred and ninety",
        "one, two, three, four, five, six, seven, eight, nine, zero",
        "twelve, thirty-four, fifty-six, seventy-eight, ninety",
        "one twenty-three, four fifty-six, seven eighty-nine, zero",
        "one billion, two hundred and thirty-four million, five hundred and sixty-seven thousand, eight hundred and ninetieth",
    ],[
        "123456789012345",
        "one hundred and twenty-three trillion, four hundred and fifty-six billion, seven hundred and eighty-nine million, twelve thousand, three hundred and forty-five",
        "one, two, three, four, five, six, seven, eight, nine, zero, one, two, three, four, five",
        "twelve, thirty-four, fifty-six, seventy-eight, ninety, twelve, thirty-four, five",
        "one twenty-three, four fifty-six, seven eighty-nine, zero twelve, three forty-five",
        "one hundred and twenty-three trillion, four hundred and fifty-six billion, seven hundred and eighty-nine million, twelve thousand, three hundred and forty-fifth",
    ],[
        "12345678901234567890",
        "twelve quintillion, three hundred and forty-five quadrillion, six hundred and seventy-eight trillion, nine hundred and one billion, two hundred and thirty-four million, five hundred and sixty-seven thousand, eight hundred and ninety",
        "one, two, three, four, five, six, seven, eight, nine, zero, one, two, three, four, five, six, seven, eight, nine, zero",
        "twelve, thirty-four, fifty-six, seventy-eight, ninety, twelve, thirty-four, fifty-six, seventy-eight, ninety",
        "one twenty-three, four fifty-six, seven eighty-nine, zero twelve, three forty-five, six seventy-eight, ninety",
        "twelve quintillion, three hundred and forty-five quadrillion, six hundred and seventy-eight trillion, nine hundred and one billion, two hundred and thirty-four million, five hundred and sixty-seven thousand, eight hundred and ninetieth",
    ],
    );
}



done_testing();

