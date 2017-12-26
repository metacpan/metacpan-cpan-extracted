use strict;
use Digest::SHA;

my $skip;

BEGIN {
	eval "use Test::More";
	$skip = $@ ? 1 : 0;
	unless ($skip) {
		eval "use Test::Pod::Coverage 0.08";
		$skip = 2 if $@;
	}
}

if ($skip == 1) {
	print "1..0 # Skipped: Test::More not installed\n";
	exit;
}

if ($skip == 2) {
	print "1..0 # Skipped: Test::Pod::Coverage 0.08 required\n";
	exit;
}

my @privfcns = qw(
	newSHA
	shainit
	sharewind
	shawrite
);

all_pod_coverage_ok( { also_private => \@privfcns } );
