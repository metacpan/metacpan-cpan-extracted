#!perl
use 5.014;
use strict;
use warnings;
use Test::More;

# AN ATTRIBUTE EATS A METHOD OF THE SAME NAME. Object::Proto::Sugar installs
# an accessor for every `has`, into the package, under the attribute's own
# name, and if the package already has a sub there the accessor replaces it
# and nothing is said. A grep of each .pm for both.

my @modules = sort glob('lib/Game/Snake/*.pm'), 'lib/Game/Snake.pm';
my $with_attributes = 0;
for my $file (@modules) {
	open my $fh, '<', $file or die "$file: $!";
	my ($package, @has, %sub);
	while (my $line = <$fh>) {
		last if $line =~ /^__END__/;
		$package = $1 if $line =~ /^package\s+(\S+);/;
		push @has, $1 if $line =~ /^has\s+(\w+)/;
		push @has, split ' ', $1 if $line =~ m{^has\s+\[qw[/(]([^/)]*)[/)]\]};
		$sub{$1} = 1 if $line =~ /^sub\s+(\w+)/;
	}
	next unless @has;
	$with_attributes++;
	my @hit = grep { $sub{$_} } @has;
	is("@hit", '', "$package: none of (@has) is also a sub");
	ok(!$sub{has}, "$package has no method called has");
}
cmp_ok($with_attributes, '>=', 5, "$with_attributes classes declare attributes");

done_testing();
