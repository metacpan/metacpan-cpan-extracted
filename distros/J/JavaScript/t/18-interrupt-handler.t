#!perl

use Test::More tests => 5;

use strict;
use warnings;

use Test::Exception;

use JavaScript;

my $count = 0;

sub trap_handler {
    my ($cx, $op) = @_;
    $count++;
    return 1;
}

my $rt1 = JavaScript::Runtime->new();
my $cx1 = $rt1->create_context();

$cx1->eval(q!
1;
!);
is($count, 0);

$rt1->set_interrupt_handler(\&trap_handler);
$cx1->eval(q!2;!),
isnt($count, 0);

$count = 0;
$rt1->set_interrupt_handler(undef);
$cx1->eval(q!2;!);
is($count, 0);

$count = 0;
$rt1->set_interrupt_handler("trap_handler");
$cx1->eval(q!2;!);
isnt($count, 0);

my $aborted = 0;
$rt1->set_interrupt_handler(sub { $aborted++; return 0; });
$cx1->eval(q!2; "foo";!);
is($aborted, 1);
