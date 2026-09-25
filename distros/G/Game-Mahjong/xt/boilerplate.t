#!perl
use 5.010;
use strict;
use warnings;
use File::Find ();
use Test::More;

# No Module::Starter sentence survives anywhere in the tree: not the README's
# "The README is used to introduce the module", not the Changes' "Date/time",
# not "The great new" in a module. The list of files is the tree, not a
# hand-kept list.

my %BOILERPLATE = (
	'the great new $MODULENAME'   => qr/ - The great new /,
	'boilerplate description'     => qr/Quick summary of what the module/,
	'stub function definition'    => qr/function[12]/,
	'the README is used to'       => qr/The README is used to introduce/,
	'Date/time'                   => qr/Date\/time/,
	'unsuspecting world'          => qr/unsuspecting world/,
);

my @files;
File::Find::find({
	no_chdir => 1,
	wanted   => sub {
		return unless -f $File::Find::name;
		return unless m{\.(?:pm|t|pl|xs|c|h)\z} || m{/(?:README|Changes)\z};
		return if m{/blib/};
		push @files, $File::Find::name;
	},
}, '.');

plan tests => scalar @files;

for my $file (sort @files) {
	open my $fh, '<', $file or do { fail("cannot read $file"); next };
	my %hit;
	while (my $line = <$fh>) {
		for my $what (keys %BOILERPLATE) {
			push @{ $hit{$what} }, $. if $line =~ $BOILERPLATE{$what};
		}
	}
	close $fh;
	# This file names the patterns it looks for, so it is the one file the
	# patterns are allowed in.
	%hit = () if $file =~ m{xt/boilerplate\.t\z};
	ok(!%hit, "$file carries no boilerplate")
		or diag map { "$_ on lines @{ $hit{$_} }\n" } sort keys %hit;
}
