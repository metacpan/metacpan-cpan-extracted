use Test::More;

my @modules = qw/
	Mail::Queue::DB
/;

my @paths = ();

plan tests => 2 * scalar @modules;

use_ok($_) for @modules;

my $checker = 0;
eval {
	require Test::Pod;
	Test::Pod::import();
	$checker = 1;
};

for my $m (@modules) {
	my $p = $m . ".pm";
	$p =~ s!::!/!g;
	push @paths, $INC{$p};
}

END { unlink "./out.$$" };

SKIP: {
	skip "Test::Pod is not available on this host", scalar @paths
		unless $checker;
	pod_file_ok($_) for @paths;
}
