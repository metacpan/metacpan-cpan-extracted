use Test::More tests => 2;

BEGIN {
    chdir "t" if -d "t";
    use lib qw(.);
    require "util.pl";
}

sub cleanup {
    1 while unlink("callstack.out");
}

cleanup();

if (callstack("3", "set.pl")) {
    if (-e "callstack.out") {
	ok(file_equal("callstack.out", "cs8a.out"));
    } else {
	die "failed to create callstack.out\n";
    }
}

if (callstack("3", "reset.pl")) {
    if (-e "callstack.out") {
	ok(file_equal("callstack.out", "cs8b.out"));
    } else {
	die "failed to create callstack.out\n";
    }
}

END {
    cleanup();
}

