#!perl -wT

# Check the GB database is sensible

use strict;
use warnings;
use Test::Most tests => 6;
use lib 't/lib';
use MyLogger;
# use Data::Dumper;

BEGIN {
	use_ok('Locale::Places::DB::GB');
}

GB: {
	Locale::Places::DB::init(directory => 'lib/Locale/Places/databases');
	my $places = new_ok('Locale::Places::DB::GB' => [logger => new_ok('MyLogger'), no_entry => 1]);

	my $dover = $places->fetchrow_hashref({ data => 'Dover' });
	$dover = $places->selectall_hashref({ code2 => $dover->{'code2'} });

	my $found;

	foreach my $entry(@{$dover}) {
		next if(!defined($entry->{'type'}));
		# diag(Data::Dumper->new([\$entry])->Dump());

		if($entry->{'type'} eq 'en') {
			is($entry->{'data'}, 'Dover', 'English');
			$found++;
		} elsif($entry->{'type'} eq 'fr') {
			is($entry->{'data'}, 'Douvres', 'French');
			$found++;
		}
	}

	is($found, 2, 'Should have been 2 matches');
}
