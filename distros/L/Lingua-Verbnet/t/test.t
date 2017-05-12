use Test::Simple tests => 5;

use constant DIR => 't/';

#1
use Lingua::Verbnet;
ok(1, 'Lingua::Verbnet did load');

#2
my $verbnet = Lingua::Verbnet->new(DIR.'empty.xml');
ok(1, 'Empty xml parsed');

#3
ok(!defined($verbnet->ambiguity->score('bork')),
	'No information on BORK expected in empty xml');

#4
$verbnet = Lingua::Verbnet->new(DIR.'bork.xml');
ok(2 == $verbnet->ambiguity->score('bork'),
	'Two BORK frames in bork xml => ambiguity score is 2');

#5
my @stats = $verbnet->ambiguity->hash;
ok(shift(@stats) eq 'bork'
	&& shift(@stats) == 2,
	'Exactly one known verb in the ambiguity stats hash, bork=>2');
