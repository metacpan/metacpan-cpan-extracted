# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Finance-YahooJPN-QuoteDetail.t'


use Test::More tests => 3;
BEGIN { use_ok('Finance::YahooJPN::QuoteDetail') };

# Sony Corp. at Tokyo market.
my $obj = Finance::YahooJPN::QuoteDetail->new({'symbol'=>6758,'market'=>"t"});

isa_ok($obj, 'Finance::YahooJPN::QuoteDetail');

$obj->quote;
$prev_close = $obj->get_prev_close;

my $ok_msg = "ok,you can quote Sony\'s previous close price from yahoo!";
my $ng_msg = "oops!check your network to the internet!";

if($prev_close =~ m/^[\d\,]+$/){
	$msg = $ok_msg;
}else{
	$msg = $ng_msg;
}

is($msg,$ok_msg,'new(),quote(),get_prev_close()')
