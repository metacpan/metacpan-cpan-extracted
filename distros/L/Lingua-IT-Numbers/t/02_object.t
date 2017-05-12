use Lingua::IT::Numbers qw(number_to_it);

my @TestData;

BEGIN {
  @TestData = (
	       1 => "uno",
	       100001 => "centomilauno",
	       12 => "dodici",
	       21 => "ventuno",
	       31 => "trentuno",
	       28 => "ventotto",
	       123456 => "centoventitremilaquattrocentocinquantasei",
	       '123.45' => "centoventitre virgola quarantacinque",
               '12345678901' => 
	       "dodici miliardi trecentoquarantacinque milioni seicentosettantottomilanovecentouno"
	      );
  
}


use Test::More tests => (scalar @TestData / 2);

while (@TestData) {
  my $num = Lingua::IT::Numbers->new(shift @TestData);
  my $str = shift @TestData;
  ok($str eq $num->get_string());
}

