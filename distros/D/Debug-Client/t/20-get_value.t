#!/usr/bin/perl

use 5.010;
use strict;
use warnings FATAL => 'all';

# Turn on $OUTPUT_AUTOFLUSH
local $| = 1;

use Test::More;
use Test::Deep;
plan( tests => 6 );


#Top
use t::lib::Debugger;

start_script('t/eg/02-sub.pl');
my $debugger;
$debugger = start_debugger();
my $out = $debugger->get;


#Body
my @out;

$debugger->step_in;
$debugger->step_in;

$out = $debugger->get_value();
is( $out, '', 'nought' );

$out = $debugger->get_value('19+23');
cmp_ok( $out, '==', '42', '19+23=42 the answer' );

$debugger->__send('$abc = 23');
$out = $debugger->get_value('$abc');
cmp_ok( $out, '==', '23', 'we just set a variable $abc = 23' );

$debugger->__send('@qwe = (23, 42)');
$out = $debugger->get_value('@qwe');
like( $out, qr/42/, 'get_value of array' );


$out = $debugger->get_value('%h');
like( $out, qr/empty hash/, 'empty hash' );

$debugger->__send_np('%h = (fname => "foo", lname => "bar")');

$out = $debugger->get_value('%h');
like( $out, qr/bar/, 'hash' );


#Tail
$debugger->quit;
done_testing();

1;

__END__
