package Game::Fake::Terminal;

use strict;
use warnings;

use Getopt::Long ();

our $VERSION = '0.01';

our @CALLS;
our $STATUS = 0;
our $DIE;
our $MISBEHAVE;
our $OUT;

sub run {
	my ($class, @argv) = @_;
	push @CALLS, [@argv];
	if ($MISBEHAVE) {
		$SIG{INT} = sub { 1 };
		Getopt::Long::Configure('bundling');
		binmode $OUT || \*STDOUT, ':encoding(UTF-8)';
		my $previous = select $OUT || \*STDOUT;
		$| = 1;
		select $previous;
	}
	die $DIE if defined $DIE;
	return $STATUS;
}

1;
