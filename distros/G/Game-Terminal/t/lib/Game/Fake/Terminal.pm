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

sub options {
	return [
		{ name => 'level', type => 'int', min => 1, max => 3, help => 'how hard it plays' },
		{ name => 'watch', type => 'flag', help => 'nobody plays' },
	];
}

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
