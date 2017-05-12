#!/usr/bin/perl

# $Id: meals.pl,v 1.1 2005/06/28 07:05:32 mark Exp $

use HTML::Chunks;
use strict;

# create a new engine and read our chunk definitions

my $engine = new HTML::Chunks('meals.html');

# output the main 'mealPage' chunk.  name information
# is supplied with static text.  the 'meals' data element
# is handled by the 'outputMeals' routine.
#
# if this were run as a CGI, you'd need to output a
# content-type header as well.

$engine->output('mealPage', {
	firstName => 'Homer',
	lastName  => 'Simpson',
	meals     => \&outputMeals
});

# our first data element routine

sub outputMeals
{
	my ($engine, $element) = @_;

	# normally you would read this from a database but
	# this is easier for an example.

	my @meals = (
		[ '2001-09-09 08:15', 'One dozen assorted donuts' ],
		[ '2001-09-09 11:45', 'One giant sub sandwich' ],
		[ '2001-09-09 14:22', 'One bag of gummy worms' ],
		[ '2001-09-09 18:34', 'Bucket of BBQ' ]
	);

	# we output each meal using the 'meal' chunk.  simple.

	foreach my $meal (@meals)
	{
		$engine->output('meal', {
			date => $meal->[0],
			food => $meal->[1]
		});
	}
}
