use lib './lib';
use strict;
use warnings;
use JavaScript::Duktape;
use Test::More;

my $js  = JavaScript::Duktape->new();
my $duk = $js->duk;

my $str = '849764516362997810229384298347982374872983749827348072983470923740923094720374092374273472394792834798';
$duk->push_perl($str);
is $duk->get_string(-1), $str;

my $num = 84976;
$duk->push_perl($num);
is $duk->get_number(-1), $num;

done_testing(2);
