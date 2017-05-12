BEGIN { $| = 1; print "1..2\n"; }
END { print "not ok 1\n" unless $loaded; }
use Games::Chess::Referee;
$loaded = 1;
print "ok 1\n";

use strict;
use UNIVERSAL 'isa';
$^W = 1;
my $n = 1;
my $success;


sub do_test (&)
{
	my ($test) = @_;
	$n++;
	$success = 1;
	&$test;
	print 'not ' unless $success;
	print "ok $n\n";
}

sub fail
{
	my ($mesg) = @_;
	print STDERR $mesg, "\n";
	$success = 0;
}

my @moves = (
	['N'],

	['M', 'Pe2-e4',		'Pe7-e5'],
	['M', 'Pd2-d3',		'Pc7-c6'],

	['S'],

	['M', 'Ng1-h3',		'Bf8-c5'],
	['M', 'Bc1-g5',		'Qd8-a5+'],
	['M', 'Pc2-c3',		'Ng8-f6'],
	['M', 'Bf1-e2',		'Pd7-d6'],

	['S'],

	['M', '0-0',		'0-0'],
	['M', 'Pb2-b3',		'Bc5-a3'],
	['M', 'Pb3-b4',		'Qa5-a6'],
	['M', 'Bg5-e3',		'Pc6-c5'],
	['M', 'Pb4xc5',		'Ba3xc5'],
	['M', 'Pd3-d4!',	'Qa6-c6'],

	['S'],

	['M', 'Pd4xc5',		'Qc6xe4'],
	['M', 'Pf2-f3?',	'Qe4xe3+'],
	['M', 'Kg1-h1',		'Qe3xc5'],
	['M', 'Qd1-b3',		'Pd6-d5'],
	['M', 'Qb3-a3',		'Qc5-e3'],
	['M', 'Qa3-c1?',	'Qe3xe2'],

	['S'],

	['M', 'Nh3-g5',		'Pe5-e4'],
	['M', 'Pf3xe4',		'Pd5xe4'],
	['M', 'Nb1-a3',		'Rf8-d8'],
	['M', 'Pc3-c4',		'Rd8-d2'],
	['M', 'Na3-b5??',	'Qe2xg2#'],

	['S']
);


#
# do_test()
#

do_test {
	print "1998-12-15 Ondrick vs. Purdy, Chicago\n";

	foreach my $move (@moves) {
		my @data = @$move;

		if      ($data[0] eq 'N') {
			new_game();
		} elsif ($data[0] eq 'S') {
			show_board();
		} elsif ($data[0] eq 'M') {
			fail("Move failed."), return 0 unless move($data[1], $data[2]);
		} else {
			fail("Unknown command.");
			return 0;
		}
	}

	print "Checkmate.\n";

	return 1;
}


#
# End of file.
#
