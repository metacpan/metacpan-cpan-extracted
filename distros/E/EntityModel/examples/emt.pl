#!/usr/bin/perl
use strict;
use warnings;
use EntityModel::Log qw(:all);
EntityModel::Log->instance->min_level(0);

package Entity::Article;
use EntityModel::EntityCollection;

sub find {
	my $self = shift;
	# Parameters are passed through to the query engine, which should know better than
	# us how to reorganise and optimise them.
	return EntityModel::EntityCollection->new();
}

package main;
use Try::Tiny;

try {
	# Predefine the grouping field since we'll use this in more than one place.
	my $group_by = {
		# Specify a field and modifier
		op	=> 'date',
		field	=> 'created',
		alias	=> 'date_created'
	};

	my @found;

	# We are going to store the result into a temporary variable, which should prevent the automatic
	# commit behaviour in void context. Once this variable goes out of scope and hits cleanup, the
	# commit method will be called via DESTROY. Start by specifying some criteria to search for:
	Entity::Article->find({
		# This will be converted to ILIKE 'Test%' on most databases
		name	=> qr/^Test/i,
	})->group(
		# Use our previously-defined field specification here
		$group_by
	# Select on two fields: first is the same one we're grouping by, second is the article count
	)->select($group_by, {
		op	=> 'count',
		field	=> 'idarticle',
		alias	=> 'count',
	})->order({
	# Sort by that first field
		alias	=> 'date_created'
	})->each(sub {
	# Each item we happen to get from the query so far will pass through this function
		my ($self, $item) = @_;
		logInfo("Had item %s", $item);
		push @found, $item;
	})->done(sub {
	# On completion, just report what we found
		logInfo("Finished with %d items", scalar(@found));
	})->fail(sub {
	# Failure shouldn't happen - but we override the die-on-error default by specifying this here.
		logInfo("Failed?");
	});
} catch {
	logError("Raised error: %s", $_);
};

try {
	# Predefine the grouping field since we'll use this in more than one place.
	my $group_by = {
		# Specify a field and modifier
		op	=> 'date',
		field	=> 'created',
		alias	=> 'date_created'
	};

	my @found;

	Entity::Article->find({
	})->select(
		field	=> [qw(created title)],
	)->order({
	# Sort by that first field
		field	=> 'created',
		direction => 'desc'
	})->each(sub {
	# Each item we happen to get from the query so far will pass through this function
		my ($self, $item) = @_;
		logInfo("Had item %s", $item);
		push @found, $item;
	})->done(sub {
	# On completion, just report what we found
		logInfo("Finished with %d items", scalar(@found));
	})->fail(sub {
	# Failure shouldn't happen - but we override the die-on-error default by specifying this here.
		logInfo("Failed?");
	});
} catch {
	logError("Raised error: %s", $_);
};
