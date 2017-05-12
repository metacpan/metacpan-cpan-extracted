#!perl -T

use Test::More tests => 8;

use Launcher::Cascade::ListOfStrings;

my $l = new Launcher::Cascade::ListOfStrings
    -list => [ qw( A B C ) ],
;

my @list = @$l;
is($list[0], 'A', 'dereferencing');
is($list[1], 'B', 'dereferencing');
is($list[2], 'C', 'dereferencing');

$l->separator(', ');
$l->preparator(sub { qq{"$_"} });
is($l->as_string(), qq{"A", "B", "C"}, 'as_string');

push @$l, 'D';
is($l->[-1], 'D', 'pushing');
is(scalar(@$l), 4, 'pushing');

my $s = shift @$l;
is($s, 'A', 'shifting');
is(scalar(@$l), 3, 'shifting');
