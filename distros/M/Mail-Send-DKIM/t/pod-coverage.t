#!/usr/bin/env perl
#
# The POD is the specification, so a public method that is not in it is a
# method nobody can find and nobody has agreed to keep.  Pod::Coverage says the
# same thing, but this is the one rule that matters here and it needs nothing
# that is not already installed: every public sub must have an =item or =head2 naming it.
#
# A private sub, one whose name begins with an underscore, is deliberately out
# of scope: it is not part of what a caller may use, and documenting it would
# promise otherwise.

use strict;
use warnings;

use Test::Most;

use File::Basename qw(dirname);
use File::Find qw(find);
use File::Spec;
use FindBin qw($Bin);

my $LIB = File::Spec->catdir($Bin, File::Spec->updir(), 'lib');

plan skip_all => "Cannot find $LIB" unless(-d $LIB);

sub slurp
{
	my $path = shift;

	local $/;
	open(my $fh, '<', $path) or return '';
	my $text = <$fh>;
	close($fh);

	return $text;
}

my @modules;
find({
	'no_chdir' => 1,
	'wanted' => sub {
		return unless(-f $_ && /\.pm\z/);
		push @modules, $File::Find::name;
	},
}, $LIB);

BAIL_OUT("No modules found under $LIB") unless(@modules);

foreach my $file (sort @modules) {
	(my $module = $file) =~ s/\A\Q$LIB\E[\\\/]//;
	$module =~ s/\.pm\z//;
	$module =~ s{[\\/]}{::}g;

	subtest $module => sub {
		my $source = slurp($file);

		like($source, qr/^=head1 NAME\n\n\Q$module\E/m, 'the POD names the module');

		my @methods = $source =~ /^sub\s+([a-z]\w*)\b/mg;
		ok(scalar(@methods) > 0, 'there are public methods to check');

		# Methods are items or second-level headings in bold; C<> marks an option, a file, a
		# variable or a value, so an option sharing a method's name - as
		# C<selector> in new() shares it with the selector method - does
		# not count as documenting the method.
		my %documented = map { $_ => 1 } ($source =~ /^=(?:item|head2)\s+B<([^>]+)>/mg);

		foreach my $method (sort @methods) {
			ok($documented{$method}, "B<$method> is documented as a method");
		}
	};
}

done_testing();
