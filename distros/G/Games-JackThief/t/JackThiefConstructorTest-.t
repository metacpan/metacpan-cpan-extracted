#!perl
use 5.006;
use strict; use warnings;
use Games::JackThief;
use Test::More tests => 3;

my $Decks_and_Players = {
							no_of_Decks => 5, 
							no_of_Players => 10,
						};
						
eval { Games::JackThief->new($Decks_and_Players); };
if($@)
{
	print "isa check for constructor load with Param arg failed\n";
}
else
{
	ok(1);
}

eval { Games::JackThief->new(); };
if($@)
{
	print "isa check for constructor with null argv load failed\n";
}
else
{
	ok(2);
}

$Decks_and_Players = {
							no_of_Decks => undef, 
							no_of_Players => undef,
						};
						
eval { Games::JackThief->new($Decks_and_Players); };
if($@)
{
	print "isa check for constructor load with Param arg failed\n";
}
else
{
	ok(3);
}
