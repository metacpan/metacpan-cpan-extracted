use strict;
use Test::More 0.98;
use Data::Dumper;

use Getopt::EX::RPN 'rpn_calc';
tie our %term, 'Getopt::EX::RPN';

printf "func: height=%d, width=%d\n", rpn_calc('HEIGHT'), rpn_calc('WIDTH');
printf "tie:  height=%d, width=%d\n", $term{height}, $term{WIDTH};

sub array {
    if (@_ == 1) {
	local $_ = shift;
	if (ref eq 'ARRAY') {
	    join ' ', '[', @$_, ']';
	} else {
	    '"' . $_ . '"';
	}
    } else {
	join ' ', '[', map({ array $_ } @_), ']';
    }
}

for ( [ '1{5:3+10*}{1 2 3+ +}IF' => 80 ],
      [ '0{5:3+10*}{1 2 3+ +}IF' => 6 ],
      [ '0 { 5 3 10 * }{ 1 2 3+ + } IF' => 6 ],
      [ '6:3/:4+7*' => 42 ],
      [ '6:3:/:4:+:7:*' => 42 ],
      [ qw'6 3 / 4 + 7 *' => 42 ],
      [ 'HEIGHT' => qr/^\d+$/ ],
      [ 'height' => qr/^\d+$/ ],
      [ qw'Width 0> 100 200 IF' => 100 ],
    ) {
    my @exp = map { ref eq 'ARRAY' ? @$_ : $_ } @$_;
    my $ans = pop @exp;
    my $msg = "[ @exp ] => $ans";
    if (ref $ans eq 'Regexp') {
	like rpn_calc(@exp), $ans, $msg;
    } else {
	is rpn_calc(@exp), $ans, $msg;
    }
}

done_testing;
