my $MODULE;

BEGIN {
	$MODULE = "Digest::SHA3";
	eval "require $MODULE" || die $@;
	$MODULE->import(qw());
}

BEGIN {
	eval "use Test::More";
	if ($@) {
		print "1..0 # Skipped: Test::More not installed\n";
		exit;
	}
}

eval "use Test::Pod::Coverage 0.08";
plan skip_all => "Test::Pod::Coverage 0.08 required for testing POD coverage" if $@;

my @privfcns = ();

if ($MODULE eq "Digest::SHA3") {
	@privfcns = qw(
		newSHA3
		shainit
		sharewind
		shawrite
	);
}

all_pod_coverage_ok( { also_private => \@privfcns } );
