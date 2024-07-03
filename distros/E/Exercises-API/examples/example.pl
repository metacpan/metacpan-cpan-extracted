#!/usr/bin/env perl

use v5.38;
use strict;
use warnings;

use FindBin qw($RealBin);
use lib "$RealBin/../lib";

use Exercises::API;

# Set API Ninja Exercise API Key
my $ea = Exercises::API->new(apikey => $ENV{'AN_EXERCISES_APIKEY'});

# A list of exercises
my @exercises = $ea->exercises;

for my $exercise (@exercises){
    print "Name: " . $exercise->name . "\n";
    print "Type: " . $exercise->type . "\n";
    print "Muscle: " . $exercise->muscle . "\n";
    print "Equipment: " . $exercise->equipment . "\n";
    print "Difficulty: " . $exercise->difficulty . "\n";
    print "Instructions: " . $exercise->instructions . "\n";

}

# Specifying the parameters
my %args = (
    name => 'press',
    type => 'strength',
    muscle => 'chest',
    difficulty => 'beginner',
    # offset => 0 (is a premium feature/parameter)
);

# A list of exercises based on the specified parameters
my @exercisesParams = $ea->exercises(%args);

for my $exercise (@exercises){
    print "Name: " . $exercise->name . "\n";
    print "Type: " . $exercise->type . "\n";
    print "Muscle: " . $exercise->muscle . "\n";
    print "Equipment: " . $exercise->equipment . "\n";
    print "Difficulty: " . $exercise->difficulty . "\n";
    print "Instructions: " . $exercise->instructions . "\n";
}