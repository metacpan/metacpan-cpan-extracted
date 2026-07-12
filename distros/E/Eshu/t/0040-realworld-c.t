use strict;
use warnings;
use Test::More;
use Eshu;
use File::Spec;

# Real-world C files — idempotent and non-crashing

my @c_files = (
	'include/eshu.h',
	'include/eshu_c.h',
	'include/eshu_pl.h',
	'include/eshu_xs.h',
	't/lib/sample_hashtable.h',
	't/lib/sample_parser.c',
);

plan tests => scalar(@c_files) * 2;

for my $rel (@c_files) {
	my $path = File::Spec->catfile($rel);
	SKIP: {
		skip "$rel not found", 2 unless -f $path;

		open my $fh, '<', $path or die "Cannot read $path: $!";
		my $src = do { local $/; <$fh> };
		close $fh;

		my $out;
		eval { $out = Eshu->indent_c($src) };
		ok(!$@, "$rel: indent_c does not die");

		# Idempotent — running twice gives same result
		my $out2;
		eval { $out2 = Eshu->indent_c($out) };
		is($out2, $out, "$rel: idempotent (indent twice == indent once)");
	}
}
