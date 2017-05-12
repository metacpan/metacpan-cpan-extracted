BEGIN {
    $|++;
    my $exit_message = "";
    unless ($ENV{AUTHOR_TEST}) {
        $exit_message = "test only run when envariable AUTHOR_TEST is set";
    }
    unless ($exit_message) {
        unless (eval { require Compress::Zlib; 1 }) {
            $exit_message = "Compress::Zlib not found";
        }
    }
    if ($exit_message) {
        print "1..0 # SKIP $exit_message\n";
        eval "require POSIX; 1" and POSIX::_exit(0);
        exit;
    }
}

use strict;
use warnings;
use Test::More 'no_plan';
use English;

diag("OS == $^O");

use Compress::Zlib;
use Devel::Symdump;

diag('$Devel::Symdump::VERSION == '.$Devel::Symdump::VERSION);
diag('$Compress::Zlib::VERSION == '.$Compress::Zlib::VERSION);
diag("Perl == $]");

my $glob_ref = eval {
	no strict 'refs';
	${*{"Compress::Zlib::"}}{GZIP_NULL_BYTE};
};

ok(!$@,'reference assignment');
diag('ref($glob_ref) == "'.ref($glob_ref).'"');

_check_child(sub {
	local *ENTRY;
	diag "Checking GLOB assignment to reference...";
	*ENTRY = $glob_ref;
});

_check_child(sub {
	diag "Checking Devel::Symdump->rnew->packages...";
	Devel::Symdump->rnew->packages;
});

sub _check_child {
	local *CHILD;

	my $code = shift;
	my $pid = open(CHILD, "|-");

	unless ($pid) {
		$code->();
		exit 0;
	} else {
		my $w = waitpid($pid,0);
		ok($w != -1 && $w == $pid,'waitpid()');
		my $e = $? >> 8;
		my $s = $? & 127;
		my $c = $? & 128;
		diag "exit value = $e";
		diag "exit with signal = $s";
		diag "dumped core? $c";
		ok($s != 11,'child did not SEGV');
		ok($e == 0 && $s == 0,'child exited properly');
	}
}


# Local Variables:
# mode: cperl
# cperl-indent-level: 4
# End:
