#!perl

use Test::More tests => 6;

use strict;
use warnings;

use Test::Exception;

use JSPL;
use JSPL::TrapHandler;

my $count = 0;

sub trap_handler {
    my ($cx, $op, $data) = @_;
    $count++;
    return 1;
}

my $rt1 = JSPL::Runtime->new();
my $cx1 = $rt1->create_context();

$cx1->eval(q!  1;  !);
is($count, 0, "All ready");

$rt1->set_interrupt_handler(\&trap_handler);
$cx1->eval(q!  2;  !),
isnt($count, 0, "Now up");

$count = 0;
$rt1->set_interrupt_handler(undef);
$cx1->eval(q!  2;  !);
is($count, 0, "Cleared");

$count = 0;
$rt1->set_interrupt_handler("trap_handler");
$cx1->eval(q!  2;  !);
isnt($count, 0, "Now up");

my $aborted = 0;
$rt1->set_interrupt_handler(
    sub {
	is($_[2], 'END', 'Data ok');
	$aborted++; return 0;
    }, 
    "END"
);
$cx1->eval(q!2; "foo";!);
is($aborted, 1, 'aborted');

$rt1->set_interrupt_handler(undef);
