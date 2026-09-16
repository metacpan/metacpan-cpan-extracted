package Game::Dominoes::Test::Handle;

use strict;
use warnings;

our $VERSION = '0.01';

# A filehandle that refuses to be one. Tie STDOUT or STDIN to it and any engine
# module that reads or writes says so by dying, which is what t/21-no-io.t is
# for. Test::Builder holds a duplicate of STDOUT taken before the tie, so TAP
# still gets out.

sub TIEHANDLE {
	my ($class) = @_;
	return bless {}, $class;
}

sub PRINT {
	die "wrote to a handle\n";
}

sub PRINTF {
	die "wrote to a handle\n";
}

sub WRITE {
	die "wrote to a handle\n";
}

sub READLINE {
	die "read from a handle\n";
}

sub READ {
	die "read from a handle\n";
}

sub GETC {
	die "read from a handle\n";
}

sub EOF {
	die "read from a handle\n";
}

sub OPEN {
	die "opened a handle\n";
}

sub BINMODE {
	return 1;
}

sub FILENO {
	return undef;
}

sub CLOSE {
	return 1;
}

1;
