#! perl

use strict;
use warnings;

use CPAN::Meta::Prereqs::Filter 'filter_prereqs';
use Getopt::Long;
use Dist::Banshee::Core 'source';

GetOptions(\my %opts, qw/json only_missing|only-missing|missing omit_core|omit-core=s author versions/);

my $meta = source('gather-metadata');

my $prereqs = filter_prereqs($meta->effective_prereqs, %opts);

if (!$opts{json}) {
	my @phases = qw/build test configure runtime/;
	push @phases, 'develop' if $opts{author};

	my $reqs = $prereqs->merged_requirements(\@phases);
	$reqs->clear_requirement('perl');

	my @modules = sort { lc $a cmp lc $b } $reqs->required_modules;
	if ($opts{versions}) {
		printf "$_ = %s\n", $reqs->requirements_for_module($_) for @modules;
	}
	else {
		print "$_\n" for @modules;
	}
}
else {
	require JSON::PP;
	print JSON::PP->new->ascii->pretty->canonical->encode($prereqs->as_string_hash);
}

0;
