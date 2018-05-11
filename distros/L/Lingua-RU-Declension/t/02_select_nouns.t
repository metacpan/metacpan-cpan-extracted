use 5.014;
use utf8;

use Test::More;
use Test::More::UTF8;

use Lingua::RU::Declension;

my $rus = Lingua::RU::Declension->new();

my $fem_filter = sub {
    my $noun_data = shift;
    return 1 if $noun_data->{gender} eq "f";
    return 0;
   };

my @fem_nouns = $rus->select_nouns($fem_filter);

my %expected = (
   'кость'  => 1,
   'кошка'  => 1,
   'нота'   => 1,
   'мышь'   => 1,
   'книга'  => 1,
   'работа' => 1,
   'ошибка' => 1,
   'баня'   => 1,
   'линия'  => 1,
);

is(scalar @fem_nouns, scalar keys %expected, "got expected number of nouns");

for ( @fem_nouns ) {
    ok( exists $expected{$_}, "got expected noun $_" )
}

done_testing();