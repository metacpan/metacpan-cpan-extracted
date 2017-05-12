use strict;
use warnings;
use utf8;

use FindBin;
use lib ("lib", "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch");

use Lingua::RU::Money::XS qw(rur2words);
use Test::Spec;
use Test::Exception;

describe "Some basic tests:" => sub {
	# Suppress warnings and dies messages
	open STDERR, '>', '/dev/null';
	it "Synopsis" => sub { is rur2words(123456789012345.00),
	"сто двадцать три триллиона четыреста пятьдесят шесть миллиардов семьсот восемьдесят девять миллионов двенадцать тысяч триста сорок пять рублей 00 копеек";
	};
	it "Negative value" => sub { dies_ok { rur2words(-3.14) }, "Negative amount can't be processed"; };
	it "Max value" => sub { is rur2words(999999999999999.93), "девятьсот девяносто девять триллионов девятьсот девяносто девять миллиардов девятьсот девяносто девять миллионов девятьсот девяносто девять тысяч девятьсот девяносто девять рублей 00 копеек"; };
	it "Overflow" => sub { dies_ok { rur2words(999999999999999.94) }, "Given amount can't be processed due to the type overflow"; };
};

runtests unless caller;
