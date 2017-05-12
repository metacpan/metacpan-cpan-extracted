use Lingua::IT::Numbers qw(number_to_it);

my @TestData;

my $num = "223.12";

BEGIN {
  @TestData = (
	       {decimal => 3},"duecentoventitre virgola centoventi",
	       {decmode => 'fract',
		decimal => 3},"duecentoventitre e centoventi millesimi"
	      );
}

use Test::More tests => (scalar @TestData / 2);

while (@TestData) {
  my $opts = shift @TestData;
  my $obj = Lingua::IT::Numbers->new($num,%$opts);
  my $str = shift @TestData;
  ok($str eq $obj->get_string());
}

	       
