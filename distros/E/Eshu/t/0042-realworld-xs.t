use strict;
use warnings;
use Test::More;
use Eshu;
use File::Spec;

# Real-world XS files — idempotent and non-crashing

my @all = (
	'lib/Eshu.xs',
	't/lib/sample_vec3.xs',
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
		eval { $out = Eshu->indent_xs($src) };
		ok(!$@, "$rel: indent_xs does not die");

		# Idempotent
		my $out2;
		eval { $out2 = Eshu->indent_xs($out) };
		is($out2, $out, "$rel: idempotent");
	}
}
