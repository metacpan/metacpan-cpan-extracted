#!perl

use strict;
use warnings;

use Test::More 0.89;
use lib 't/lib';
use Test::LivesOK 'lives_ok';

use ExtUtils::Builder::Planner;

use File::Spec::Functions 'catfile';

my $planner = ExtUtils::Builder::Planner->new;
$planner->load_extension("Callback");

my $sources = $planner->create_pattern(file => "*.src");
my %sources;
my $destination = $planner->create_subst(
	on => $sources,
	subst => sub {
		my ($source) = @_;
		my $destination = catfile('build', $source);
		$destination =~ s/\.src$/\.dest/;
		$sources{$source}++;
		$planner->create_node(
			target => $destination,
		);
	}
);

$planner->add_seen('foo.src');
$planner->create_node(target => 'bar.src');
$planner->add_seen('baz.nosrc');

is_deeply(\%sources, { 'foo.src' => 1, 'bar.src' => 1}, 'Seen expected sources');

done_testing;
