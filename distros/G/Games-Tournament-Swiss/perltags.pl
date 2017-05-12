#!/usr/bin/perl

use IO::All;

use Perl::Tags;
use Perl::Tags::Naive::Field;
my $naive_tagger = Perl::Tags::Naive::Field->new( max_level=>2 );
$naive_tagger->process(
    files =>	[
    		'lib/Games/Tournament.pm',
    		'lib/Games/Tournament/Swiss.pm',
    		'lib/Games/Tournament/Contestant.pm',
    		'lib/Games/Tournament/Contestant/Swiss.pm',
    		'lib/Games/Tournament/Card.pm',
    		'lib/Games/Tournament/Swiss/Bracket.pm',
    		'lib/Games/Tournament/Swiss/Pairing.pm',
    		't/Games/Tournament/Swiss/Test.pm',
		],
    refresh=>1
);
"$naive_tagger" > io("./tags");
