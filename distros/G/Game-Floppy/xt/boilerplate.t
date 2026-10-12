#!perl
use 5.014;
use strict;
use warnings;
use Test::More;

# Module::Starter writes this file with EVERY assertion inside a TODO block, so
# it is green over the template it was meant to catch. The modules are checked
# for real here, and so are README and Changes.

sub boilerplate_in {
	my ($filename, %regex) = @_;
	open(my $fh, '<', $filename) or die "couldn't open $filename for reading: $!";
	my @found;
	while (my $line = <$fh>) {
		for my $desc (sort keys %regex) {
			push @found, "$desc (line $.)" if $line =~ $regex{$desc};
		}
	}
	return @found;
}

my @modules = ('lib/Game/Floppy.pm', sort glob('lib/Game/Floppy/*.pm'));
cmp_ok(scalar(@modules), '>=', 6, scalar(@modules) . ' modules read');
for my $module (@modules) {
	my @found = boilerplate_in($module,
		'the great new $MODULENAME' => qr/ - The great new /,
		'boilerplate description'   => qr/Quick summary of what the module/,
		'stub function definition'  => qr/function[12]/,
	);
	is("@found", '', "$module contains no boilerplate text");
}

{
	my @readme = boilerplate_in('README',
		'The README is used...'      => qr/The README is used/,
		"'version information here'" => qr/to provide version information/,
	);
	is("@readme", '', 'README contains no boilerplate text');
	my @changes = boilerplate_in('Changes',
		'placeholder date/time' => qr(Date/time),
		'unsuspecting world'    => qr/unsuspecting world/,
	);
	is("@changes", '', 'Changes contains no boilerplate text');
	open my $changes, '<', 'Changes' or die "Changes: $!";
	my @entries = grep { /\A[0-9]/ } <$changes>;
	close $changes;
	like($entries[0], qr/\A0\.[0-9]{2}    [0-9]{4}-[0-9]{2}-[0-9]{2}$/, 'the newest entry of Changes is a version and a date');
	require Game::Floppy;
	like($entries[0], qr/\A\Q$Game::Floppy::VERSION\E /, 'and it is the version of the distribution');
}

done_testing();
