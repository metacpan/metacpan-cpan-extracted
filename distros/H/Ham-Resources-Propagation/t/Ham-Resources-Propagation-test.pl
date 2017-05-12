#!/usr/bin/perl
#
# Ham::Resources::Propagation test module
# Test and Use procedures
#
# (c) Carlos Juan Diaz <ea3hmb at gmail.com> on Dec. 2011
#

use strict;
use warnings;
use lib '../lib';
use Ham::Resources::Propagation;

my $data = shift;
my $groups = qr/solar_data|hf|vhf|extended/i;

chomp($data);

if (!$data) 
{
	print "\nUsage: 'groups' list of groups available, 'all' for all datas, 'list' for item list, 'any data' for a valid data name or group.\n";
	exit 0;
}

my $propagation = Ham::Resources::Propagation->new('description','text'); # numeric or text
die $propagation->error_message if $propagation->is_error;

# list of availables groups of information
if ($data =~ /groups/i)
{	
	print "\nGroups availables:\n";
	print "-" x20,"\n";
	foreach (sort @{$propagation->get_groups})
	{
		  print $_."\n";
	}
	exit 1;	
}

# access items list
if ($data =~ /list/i)
{
	print "\nAll items list:\n";
	print "-" x20,"\n";
	foreach (sort @{$propagation->all_item_names})
	{
		  print $_."\n";
	}
	exit 1;
}

# access data throught get method
if ($data =~ /all/i)
{
	print "\nget method:\n";
	print "-" x20,"\n";
	foreach (@{$propagation->all_item_names}) # recommeded don't use sort
	{
		  print "$_ = ".$propagation->get($_)."\n";
	}
	exit 1;
}

# access data with category
if ($data =~ $groups)
{
	foreach (sort keys %{$propagation->{$data}})
	{
		print $_.": ".$propagation->{$data}->{$_}."\n";
	}
	exit 1;
}

# access unique data
if ($data !~ $groups)
{
	print "$data: ".$propagation->get($data);

	print "\n\n";
	exit 1;
}

