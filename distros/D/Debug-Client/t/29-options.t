#!/usr/bin/perl

use 5.010;
use strict;
use warnings FATAL => 'all';

# Turn on $OUTPUT_AUTOFLUSH
local $| = 1;

use Test::More;
use Test::Deep;
plan( tests => 4 );


#Top
use t::lib::Debugger;

start_script('t/eg/14-y_zero.pl');
my $debugger;
$debugger = start_debugger();
$debugger->get;


#Body
my $out;
$out = $debugger->get_options();
ok( $out =~ m/CommandSet.=.'(\d+)'/s, 'get options' );
diag("Info: ComamandSet = '$1'");

$debugger->set_breakpoint( 't/eg/14-y_zero.pl', '14' );

$out = $debugger->set_option('frame=2');
like( $out, qr/frame.=.'2'/s, 'set options' );

my @out;
eval { $debugger->run };
if ($@) {
	diag($@);
} else {
	diag(@out);
	local $TODO = "Array ref request";
}

$out = $debugger->set_option('frame=0');
like( $out, qr/frame.=.'0'/s, 'reset options' );

$out = $debugger->set_option();
like( $out, qr/missing/s, 'missing option' );


#Tail
$debugger->quit;
done_testing();

1;

__END__
