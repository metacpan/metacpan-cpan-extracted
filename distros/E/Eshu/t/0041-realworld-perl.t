use strict;
use warnings;
use Test::More;
use Eshu;
use File::Spec;

# Real-world Perl files — idempotent and non-crashing

my @all = (
	'lib/Eshu.pm',
	't/lib/Sample/Router.pm',
	't/lib/Sample/Cache.pm',
);

plan tests => scalar(@all) * 2;

for my $rel (@all) {
	my $path = File::Spec->catfile($rel);
	SKIP: {
		skip "$rel not found", 2 unless -f $path;

		open my $fh, '<', $path or die "Cannot read $path: $!";
		my $src = do { local $/; <$fh> };
		close $fh;

		my $out;
		eval { $out = Eshu->indent_pl($src) };
		ok(!$@, "$rel: indent_pl does not die");

		# Idempotent
		my $out2;
		eval { $out2 = Eshu->indent_pl($out) };
		is($out2, $out, "$rel: idempotent");
	}
}
