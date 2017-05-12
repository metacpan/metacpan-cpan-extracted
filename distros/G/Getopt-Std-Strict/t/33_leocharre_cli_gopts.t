use Test::Simple 'no_plan';
use strict;
use lib './lib';

BEGIN { @ARGV = qw(-a -b this -c) }

use Getopt::Std::Strict 'ab:c', 'opt';




my $a = opt('a');
ok ( $a, "a: $a" );


my $b = opt('b');

ok($b, "b $b");

my $c = opt('c');

ok $OPT{b};




ok ( !eval{ my $bull = opt('g'); } );





 ok( $main::opt_b, "optb $main::opt_b" );

ok( $opt_b, "\$opt_b $opt_b");

ok( $opt_b eq $OPT{b});

$opt_b = 'hahaha';

ok $OPT{b} eq 'hahaha';

ok opt('b') eq 'hahaha'; 

ok $opt_a;
ok $opt_c;




