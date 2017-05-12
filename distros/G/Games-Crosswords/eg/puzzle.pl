use Games::Crosswords;

# The example is the first puzzle from <The guardian quick crosswords Vol.1>

$c = new Games::Crosswords({
    TABLE =><<EOF
......@......
.@.@.@.@.@.@.
.......@.....
.@.@.@.@.@.@.
.....@.......
.@@@.@.@@@.@.
@...........@
.@.@@@.@.@@@.
.......@.....
.@.@.@.@.@.@.
.....@.......
.@.@.@.@.@.@.
......@......
EOF
,
    LEXICON =>
    {
	DOWN =>
	    [
	     [ 0, 0, 'Very early computer?', 'abacus' ],
	     [ 0, 2, 'Spot on', 'exact' ],
	     [ 0, 4, 'Talks nonsense', 'drivels' ],
	     [ 0, 8, 'A farewell to the French', 'adieu' ],
	     [ 0, 10, 'Middle Eastern capital', 'baghdad' ],
	     [ 0, 12, 'Whole', 'entire' ],
	     [ 1, 6, 'Essentials', 'necessities' ],
	     [ 6, 2, 'Spirit of hair', 'ringlet' ],
	     [ 6, 8, 'Large flightless bird', 'ostrich' ],
	     [ 7, 0, 'European peninsula', 'iberia' ],
	     [ 7, 12, 'Part of flower\'s reproductive system', 'stamen' ],
	     [ 8, 4, 'Sam - at the pawnshop?', 'uncle' ],
	     [ 8, 10, 'Goldsmith\'s rating?', 'carat' ],
	     ],
	ACROSS =>
	    [
	     [ 0, 0, 'They are made in compensation', 'amends' ],
	     [ 0, 7, 'Wager', 'gamble' ],
	     [ 2, 0, 'Greed', 'avarice' ],
	     [ 2, 8, 'Form of cast metal', 'ingot' ],
	     [ 4, 0, 'Release', 'untie' ],
	     [ 4, 6, 'South American reppublic', 'ecuador' ],
	     [ 6, 1, 'Join battle', 'crossswords' ],
	     [ 8, 0, 'Feast', 'banquet' ],
	     [ 8, 8, 'Kind of understanding', 'tacit' ],
	     [ 10, 0, 'Momento, often holy', 'relic' ],
	     [ 10, 6, 'Pithy phrase', 'epigram' ],
	     [ 12, 0, 'Stag horn', 'antler' ],
	     [ 12, 7, 'Himalayan state', 'bhutan' ],
	     ],
    }
});

print F $c->genpuzzle('tmp.tex');

`latex tmp.tex ; dvips tmp.dvi -o test.ps`;
