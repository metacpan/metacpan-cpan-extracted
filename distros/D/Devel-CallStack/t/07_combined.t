use Test::More tests => 1;

BEGIN {
    chdir "t" if -d "t";
    use lib qw(.);
    require "util.pl";
}

sub cleanup {
    1 while unlink("callstack.out");
}

cleanup();

if (callstack("2,reverse,full")) {
    if (-e "callstack.out") {
	ok(file_equal("callstack.out", "cs7.out"));
    } else {
	die "failed to create callstack.out\n";
    }
}

END {
    cleanup();
}

