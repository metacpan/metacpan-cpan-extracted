#!/usr/bin/perl
use strict;
use warnings;
use 5.010;

use Data::Dumper   qw(Dumper);
use Getopt::Long   qw(GetOptions);
use MetaCPAN::API;
my $mcpan = MetaCPAN::API->new;

my @modules = @ARGV;

usage() if not @modules;

my %dependencies;

my %CORE = map { $_ => 1 } qw(
	perl
	warnings
	strict
	FindBin
);

while (@modules) {
	handle_module(shift @modules);
}

sub handle_module {
	my ($module) = @_;

	return if $CORE{$module};
	return if $dependencies{$module};


	say "Processing $module";
	# special case as the MetaCPAN authors refuse to bend to the whims of MLEHMANN.
	if ($module eq 'common::sense') {
		$dependencies{$module} = 'common-sense';
		return;
	}

	# get the distribution that provides this module
	my $rm = $mcpan->fetch( "module/$module",
    	fields => 'distribution,version',
    );
	$dependencies{$module} = $rm->{distribution};

	# get the list of dependencies,
    my $rd = $mcpan->fetch( "release/$rm->{distribution}",
		fields => 'dependency',
	);
	push @modules, map { $_->{module} } @{ $rd->{dependency} };
    #print Dumper $rd;
	#print Dumper \@modules;


    # list of dependencies
    # phases:
    # print Dumper [uniq map { $_->{phase} } @{ $r->{dependency} }];
    #       'develop',
    #      'test',
    #      'runtime',
    #      'configure'
    #print Dumper [map { $_->{module} }
    #    grep { $_->{phase} eq 'runtime' or $_->{phase} eq 'test' }
    #    @{ $r->{dependency} }];

	#die Dumper $r;
}


# TODO: we should probably provide a list of URLs to dowload,
# and even provide an option to downlad all the files,
# and then maybe even to arrange them as a local CPAN mirror.


sub usage {
	print <<"END";
$0 Module::Name [more Module::Names]

Given a list of modules on the command line
provide a full list of modules that are required by these modules.
That is, a full dependency list

Further ideas: provide a list of common dependencies or a list of modules that answers the qestion
What extra dependencies will the second module bring in?
END
	exit;
}


