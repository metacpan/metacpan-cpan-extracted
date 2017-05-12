#!/usr/bin/perl

use warnings;
use strict;

use Getopt::Helpful;
use Data::Dumper;

# hard-coded defaults (to be over-ridden by config files and then
# command-line options (in that order))

(-d "configs") or die "You're in the wrong directory.";

my $flirp;

my $hopt = Getopt::Helpful->new(
	['r|verp=s', \$flirp, '', 'flirp'],
	'+help',
	);

my %data = (
	option => 'no',
	var    => 'default',
	);
$hopt->setup_config(
	\%data,
	'o|option=s' => ['<option>', "setting for \$option (default: '$data{option}')"],
	'v|var=s'    => ['<setting>', "setting for \$var (default: '$data{var}')"],
	);
$hopt->Get();
$hopt->config("configs/base.conf");
print Dumper(\%data);
