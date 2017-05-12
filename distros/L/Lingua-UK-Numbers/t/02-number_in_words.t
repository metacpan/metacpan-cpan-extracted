use Lingua::UK::Numbers qw/number_in_words/;

use utf8;
use Test::More;

my %masculine = (
    '0'          => 'нуль',
    '1'          => 'один',
    '102'        => 'сто два',
    '1000000000' => "один мільярд",
    '122456781'  => "сто двадцять два мільйони чотириста п'ятдесят шість тисяч сімсот вісімдесят один"
);

foreach my $num ( sort { $a <=> $b } keys %masculine ) {
    my $words = $masculine{$num};
    is( number_in_words($num, 'MASCULINE'), $words, "Masculine number $num" );
}


my %feminine = (
    '0'          => 'нуль',
    '1'          => 'одна',
    '102'        => 'сто дві',
    '1000000000' => "один мільярд",
    '122456781'  => "сто двадцять два мільйони чотириста п'ятдесят шість тисяч сімсот вісімдесят одна"
);

foreach my $num ( sort { $a <=> $b } keys %feminine ) {
    my $words = $feminine{$num};
    is( number_in_words($num, 'FEMININE'), $words, "Feminine number $num" );
}


done_testing();
