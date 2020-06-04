#!/usr/bin/perl
########################################################################
# score_games.t:
#   Send test boards (./game*) to each of the game engines, and search
#       the text output for specific word/score pairs, which will
#       be different based on which game engine is used.
#   v0.042: add in get_solutions() structure parsing as well -- easiest
#       to just add the checks to the already-defined games, rather
#       than having a whole other file which implements similar
#       checks to this one.
########################################################################

use 5.008;

use warnings;
use strict;
use Test::More;# tests => 274;

use IO::String;
use File::Basename qw/dirname/;
use Cwd qw/abs_path chdir/;
BEGIN: { chdir(dirname($0)); }

use Games::Literati 0.042 qw/:allGames :infoFunctions/;
sub SearchGameOut() { 0; }

sub run_game($$) {
    my $game = shift;
    my $fh = shift;
    my $stringify = '';
    my $fhString = undef;

    seek($fh, 0, 0);    # go to beginning of game input file

    open my $oldin, "<&STDIN"
        or do { warn "dup STDIN to \$fh=\\$fh: $!"; return undef; };

    close STDIN;
    open STDIN, '<&', $fh
        or do { warn "set STDIN = \$fh=\\$fh: $!"; return undef; };

    $fhString = IO::String->new($stringify);
    select $fhString;
    $| = 1;
    $game->();
    select STDOUT;
    close $fhString;

    close STDIN;
    open STDIN, '<&', $oldin
        or do { warn "set STDIN = \$oldin=\\$oldin: $!"; return undef; };

    return $stringify;
}

sub search_game($$@) {
    my $gamename = shift;
    my $fh = shift;
    my $nSolutions = shift;

    my $gameref = \&$gamename;
    my $gameout = run_game($gameref, $fh);
    my @best = ();

    # v0.042: add in
    my %solutions = get_solutions();
    is scalar keys %Games::Literati::solutions, $nSolutions, "$gamename(): \%Games::Literati::solutions hash returns right number of solutions";
    is scalar keys %solutions, $nSolutions, "$gamename(): get_solutions returns right number of solutions";

    # return to beginning of input file, and get the letters as the last line of the input file
    seek($fh, 0, 0);
    my @input = <$fh>;

    chomp foreach (@input);

    my $letters = join '', sort split //, $input[-1];

    #isnt( $gameout, undef, "$gamename(): Running with input '$letters'" );

    pattern: foreach (@_) {
        my ($score, $dest, $word, $start, $bingo, $n_tiles) = ($_->{score},$_->{dest},$_->{word},$_->{start},$_->{bingo},$_->{n_tiles});
        my $tsrc = $_->{tsrc};
        isnt( $gameout, undef, "__${tsrc}.".__LINE__."__ $gamename(): desire '${word}', in ${dest} at ${start}, worth ${score} points, using input='$letters'");

        # verify solution_data first
        my $key = "${dest} become: '${word}' starting at ${start} " . ($bingo ? '(BINGO!!!!)' : '') . " using $n_tiles tile(s)";
        ok exists $solutions{$key}, "__${tsrc}.".__LINE__."__ $gamename(): desire key='$key' exists";
        my $expected_solution = {
            word => $word,
            tiles_used => $n_tiles,
            score => $score,
            bingo => $bingo||0,
            #row => BELOW,
            #col => BELOW,
            #direction => BELOW,
            tiles_this_word => $_->{tiles_this_word},
            tiles_consumed => $_->{tiles_consumed},
        };
        ($expected_solution->{direction}, my $d) = (split ' ', $dest);      # direction and row or column
        (undef, my $s) = (split ' ', $start);                               # column or row
        $expected_solution->{row} = ($s,$d)[$expected_solution->{direction} eq 'row']; # identify based on direction
        $expected_solution->{col} = ($d,$s)[$expected_solution->{direction} eq 'row']; # identify based on direction
        is_deeply $solutions{$key}, $expected_solution, "__${tsrc}.".__LINE__."__ ".'... with correct solution{$key} hash'
            or do { diag explain $solutions{$key}, "\n"; diag explain $expected_solution, "\n"; BAIL_OUT "temporary" };

        # now parse the printout to make sure it matches
        @best = qw/0 dest word start bingo exact/;
        $best[2] = "$word not found";
        line: foreach ( split /\n/, $gameout ) {
            if( m/^\((\d+)\)\s+(\w+\s+\d+)\s+become:\s+'(.*)'\s+starting at\s+(\w+\s+\d+)\s+(.*)$/gm ) {
                my @match = ($1, $2, $3, $4, 0);
                $match[4] = 1 if '(BINGO!!!!)' eq $5;
                #printf "pos()=%-4d score=%-4d dest=%-12s word=%-12s start=%-12s bingo:%d\n", pos(), @match;

                my $similar = 1 eq 1;
                $similar &&= ${dest}  eq $match[1];
                $similar &&= ${word}  eq $match[2];
                $similar &&= ${start} eq $match[3];

                my $equiv = $similar;
                $equiv &&= ${bingo} eq $match[4]     if defined ${bingo};
                $equiv &&= $similar && ${score} eq $match[0];

                if ($equiv) {
                    @best = (@match, 1); # exact match
                    last line;
                } # equiv

                if ($similar && ($match[0] > $best[0]) ) {  # update @best if it's similar and the current score is better than the previous best score
                    @best = (@match, 0);    # not the right score, but otherwise correct
                } # similar; keep looking for exact
            } # each match
        } # each line

        #print "best = (". join(', ', @best) .")\n";
        is( $best[2], $word , "__${tsrc}.".__LINE__."__ $gamename(): Find match for '$word' in output...");
        is( $best[1], $dest , "__${tsrc}.".__LINE__."__ ... on $dest...");
        is( $best[3], $start , "__${tsrc}.".__LINE__."__ ... starting at $start...");
        if(defined $bingo) {
            is( $best[4] ? 'BINGO' : 'not BINGO', $bingo ? 'BINGO' : 'not BINGO', "__${tsrc}.".__LINE__."__ ... BINGO " . ($bingo?"is":"isn't") . " expected..."  )
        } else {
            ok( 1, "__${tsrc}.".__LINE__."__ ... not testing for BINGO");
        }
        is( $best[0], $score, "__${tsrc}.".__LINE__."__ ... Match score $score for '$word'" );
        #print "\n";
    } # each pattern

    print $gameout if SearchGameOut();
}

my $INFILE;

##### BOARD#1: compare scrabble/literati/wordswithfriends scores
open $INFILE, '<', 'game1'      or die "open game1: $!";
search_game('literati', $INFILE, 12,
    { tsrc=>__LINE__, word=>'curses'  , dest=>'row 3'    , start=>'column 8' , score=>8  , bingo=>0  , n_tiles=>5  , tiles_this_word=>'curses'    , tiles_consumed=>'urses'   },
    { tsrc=>__LINE__, word=>'serums'  , dest=>'column 3' , start=>'row 10'   , score=>24 , bingo=>0  , n_tiles=>5  , tiles_this_word=>'serums'    , tiles_consumed=>'erums'   },
    { tsrc=>__LINE__, word=>'embroils', dest=>'row 14'   , start=>'column 6' , score=>11 , bingo=>0  , n_tiles=>2  , tiles_this_word=>'embroils'  , tiles_consumed=>'em'      },
    { tsrc=>__LINE__, word=>'assure'  , dest=>'row 0'    , start=>'column 3' , score=>24 , bingo=>0  , n_tiles=>5  , tiles_this_word=>'assure'    , tiles_consumed=>'ssure'   },
    { tsrc=>__LINE__, word=>'assure'  , dest=>'column 2' , start=>'row 1'    , score=>8  , bingo=>0  , n_tiles=>5  , tiles_this_word=>'assure'    , tiles_consumed=>'ssure'   },
);

search_game('wordswithfriends', $INFILE, 12,
    { tsrc=>__LINE__, word=>'curses'  , dest=>'row 3'    , start=>'column 8' , score=>12 , bingo=>0  , n_tiles=>5  , tiles_this_word=>'curses'    , tiles_consumed=>'urses'   },
    { tsrc=>__LINE__, word=>'serums'  , dest=>'column 3' , start=>'row 10'   , score=>36 , bingo=>0  , n_tiles=>5  , tiles_this_word=>'serums'    , tiles_consumed=>'erums'   },
    { tsrc=>__LINE__, word=>'embroils', dest=>'row 14'   , start=>'column 6' , score=>17 , bingo=>0  , n_tiles=>2  , tiles_this_word=>'embroils'  , tiles_consumed=>'em'      },
    { tsrc=>__LINE__, word=>'assure'  , dest=>'row 0'    , start=>'column 3' , score=>27 , bingo=>0  , n_tiles=>5  , tiles_this_word=>'assure'    , tiles_consumed=>'ssure'   },
    { tsrc=>__LINE__, word=>'assure'  , dest=>'column 2' , start=>'row 1'    , score=>9  , bingo=>0  , n_tiles=>5  , tiles_this_word=>'assure'    , tiles_consumed=>'ssure'   },
);

search_game('scrabble', $INFILE, 12,
    { tsrc=>__LINE__, word=>'curses'  , dest=>'row 3'    , start=>'column 8' , score=>16 , bingo=>0  , n_tiles=>5  , tiles_this_word=>'curses'    , tiles_consumed=>'urses'   },
    { tsrc=>__LINE__, word=>'serums'  , dest=>'column 3' , start=>'row 10'   , score=>18 , bingo=>0  , n_tiles=>5  , tiles_this_word=>'serums'    , tiles_consumed=>'erums'   },
    { tsrc=>__LINE__, word=>'embroils', dest=>'row 14'   , start=>'column 6' , score=>36 , bingo=>0  , n_tiles=>2  , tiles_this_word=>'embroils'  , tiles_consumed=>'em'      },
    { tsrc=>__LINE__, word=>'assure'  , dest=>'row 0'    , start=>'column 3' , score=>21 , bingo=>0  , n_tiles=>5  , tiles_this_word=>'assure'    , tiles_consumed=>'ssure'   },
    { tsrc=>__LINE__, word=>'assure'  , dest=>'column 2' , start=>'row 1'    , score=>12 , bingo=>0  , n_tiles=>5  , tiles_this_word=>'assure'    , tiles_consumed=>'ssure'   },
);
close $INFILE;

##### BOARD#1ss: compare superscrabble version of game1 (centered core with extra border
open $INFILE, '<', 'game1ss'    or die "open game1ss: $!";
search_game('superscrabble', $INFILE, 13,
    { tsrc=>__LINE__, word=>'curses'  , dest=>'row 6'    , start=>'column 11', score=>16 , bingo=>0  , n_tiles=>5  , tiles_this_word=>'curses'    , tiles_consumed=>'urses'   },
    { tsrc=>__LINE__, word=>'serums'  , dest=>'column 6' , start=>'row 13'   , score=>18 , bingo=>0  , n_tiles=>5  , tiles_this_word=>'serums'    , tiles_consumed=>'erums'   },
    { tsrc=>__LINE__, word=>'embroils', dest=>'row 17'   , start=>'column 9' , score=>36 , bingo=>0  , n_tiles=>2  , tiles_this_word=>'embroils'  , tiles_consumed=>'em'      },
    { tsrc=>__LINE__, word=>'assure'  , dest=>'row 3'    , start=>'column 6' , score=>21 , bingo=>0  , n_tiles=>5  , tiles_this_word=>'assure'    , tiles_consumed=>'ssure'   },
    { tsrc=>__LINE__, word=>'assure'  , dest=>'column 5' , start=>'row 4'    , score=>12 , bingo=>0  , n_tiles=>5  , tiles_this_word=>'assure'    , tiles_consumed=>'ssure'   },
);
close $INFILE;

##### BOARD#2: BUGFIX https://rt.cpan.org/Public/Bug/Display.html?id=29539  #### vertical 'in'
open $INFILE, '<', 'game2'      or die "open game1: $!";
search_game('literati', $INFILE, 2,
    { tsrc=>__LINE__, word=>'in'      , dest=>'column 4' , start=>'row 2'    , score=>6  ,             n_tiles=>2  , tiles_this_word=>'in'        , tiles_consumed=>'in'      },
    { tsrc=>__LINE__, word=>'in'      , dest=>'row 2'    , start=>'column 4' , score=>3  ,             n_tiles=>1  , tiles_this_word=>'in'        , tiles_consumed=>'i'       },
);
close $INFILE;

##### BOARD#3: BUGFIX https://rt.cpan.org/Public/Bug/Display.html?id=29539  #### horizontal 'in'
open $INFILE, '<', 'game3'      or die "open game1: $!";
search_game('literati', $INFILE, 2,
    { tsrc=>__LINE__, word=>'in'      , dest=>'row 4'    , start=>'column 2' , score=>6  ,             n_tiles=>2  , tiles_this_word=>'in'        , tiles_consumed=>'in'      },
    { tsrc=>__LINE__, word=>'in'      , dest=>'column 2' , start=>'row 4'    , score=>3  ,             n_tiles=>1  , tiles_this_word=>'in'        , tiles_consumed=>'i'       },
);
close $INFILE;

##### BOARD#4: SuperScrabble    # v0.032002-0.032005
open $INFILE, '<', 'game4'    or die "open game4: $!";
search_game('superscrabble', $INFILE, 4,
    { tsrc=>__LINE__, word=>'in'      , dest=>'row 0'    , start=>'column 0' , score=>8  , bingo=>0  , n_tiles=>1  , tiles_this_word=>'in'        , tiles_consumed=>'i'       },     # 4W
    { tsrc=>__LINE__, word=>'in'      , dest=>'row 5'    , start=>'column 2' , score=>5  , bingo=>0  , n_tiles=>1  , tiles_this_word=>'in'        , tiles_consumed=>'i'       },     # 4L
    { tsrc=>__LINE__, word=>'in'      , dest=>'row 20'   , start=>'column 7' , score=>6  , bingo=>0  , n_tiles=>1  , tiles_this_word=>'in'        , tiles_consumed=>'i'       },     # TW
    { tsrc=>__LINE__, word=>'in'      , dest=>'row 1'    , start=>'column 16', score=>4  , bingo=>0  , n_tiles=>1  , tiles_this_word=>'in'        , tiles_consumed=>'i'       },     # TL
);
close $INFILE;

##### BOARD#5: Bingo Check
open $INFILE, '<', 'game5'    or die "open game5: $!";
search_game('literati', $INFILE, 36,
    { tsrc=>__LINE__, word=>'antlers' , dest=>'row 7'    , start=>'column 1' , score=>49 , bingo=>1  , n_tiles=>7  , tiles_this_word=>'antlers'   , tiles_consumed=>'antlers' },     # all 5 should pass: look for bingo==true
    { tsrc=>__LINE__, word=>'antler'  , dest=>'row 7'    , start=>'column 6' , score=>12 , bingo=>0  , n_tiles=>6  , tiles_this_word=>'antler'    , tiles_consumed=>'antler'  },     # force a fail on BINGO, because I am requiring bingo==0
);

search_game('wordswithfriends', $INFILE, 36,
    { tsrc=>__LINE__, word=>'antlers' , dest=>'row 7'    , start=>'column 1' , score=>53 , bingo=>1  , n_tiles=>7  , tiles_this_word=>'antlers'   , tiles_consumed=>'antlers' },     # all 5 should pass: look for bingo==true
    { tsrc=>__LINE__, word=>'antler'  , dest=>'row 7'    , start=>'column 6' , score=>16 , bingo=>0  , n_tiles=>6  , tiles_this_word=>'antler'    , tiles_consumed=>'antler'  },     # force a fail on BINGO, because I am requiring bingo==0
);

search_game('scrabble', $INFILE, 36,
    { tsrc=>__LINE__, word=>'antlers' , dest=>'row 7'    , start=>'column 1' , score=>66 , bingo=>1  , n_tiles=>7  , tiles_this_word=>'antlers'   , tiles_consumed=>'antlers' },     # all 5 should pass: look for bingo==true
    { tsrc=>__LINE__, word=>'antler'  , dest=>'row 7'    , start=>'column 6' , score=>14 , bingo=>0  , n_tiles=>6  , tiles_this_word=>'antler'    , tiles_consumed=>'antler'  },     # force a fail on BINGO, because I am requiring bingo==0
);

close $INFILE;

open $INFILE, '<', 'game5ss'    or die "open game5: $!";
search_game('superscrabble', $INFILE, 36,
    { tsrc=>__LINE__, word=>'antlers' , dest=>'row 10'   , start=>'column 4' , score=>66 , bingo=>1  , n_tiles=>7  , tiles_this_word=>'antlers'   , tiles_consumed=>'antlers' },     # all 5 should pass: look for bingo==true
    { tsrc=>__LINE__, word=>'antler'  , dest=>'row 10'   , start=>'column 9' , score=>14 , bingo=>0  , n_tiles=>6  , tiles_this_word=>'antler'    , tiles_consumed=>'antler'  },     # force a fail on BINGO, because I am requiring bingo==0
);
close $INFILE;

##### BOARD#W: Check wild as input
open $INFILE, '<', 'game_w'      or die "open game_w: $!";
search_game('wordswithfriends', $INFILE, 2,
    { tsrc=>__LINE__, word=>'ant'     , dest=>'column 2' , start=>'row 1'    , score=>2  ,             n_tiles=>2  , tiles_this_word=>'a?t'       , tiles_consumed=>'?t'      },
    { tsrc=>__LINE__, word=>'an'      , dest=>'column 2' , start=>'row 1'    , score=>1  ,             n_tiles=>1  , tiles_this_word=>'a?'        , tiles_consumed=>'?'       },
);
close $INFILE;

##### BOARD#B: Make sure all bonuses are applied to both main word and cross-word
open $INFILE, '<', 'game_b'    or die "open game5: $!";
search_game('literati', $INFILE, 66,
    { tsrc=>__LINE__, word=>'ant'     , dest=>'row 10'   , start=>'column 7' , score=> 7 ,             n_tiles=>3  , tiles_this_word=>'ant'       , tiles_consumed=>'ant'     },
    { tsrc=>__LINE__, word=>'ant'     , dest=>'row 11'   , start=>'column 0' , score=>18 ,             n_tiles=>3  , tiles_this_word=>'ant'       , tiles_consumed=>'ant'     },
    { tsrc=>__LINE__, word=>'ant'     , dest=>'column 9' , start=>'row 12'   , score=>12 ,             n_tiles=>3  , tiles_this_word=>'ant'       , tiles_consumed=>'ant'     },
    { tsrc=>__LINE__, word=>'ant'     , dest=>'column 11', start=>'row 10'   , score=>10 ,             n_tiles=>3  , tiles_this_word=>'ant'       , tiles_consumed=>'ant'     },
    { tsrc=>__LINE__, word=>'ant'     , dest=>'column 11', start=>'row 0'    , score=>18 ,             n_tiles=>3  , tiles_this_word=>'ant'       , tiles_consumed=>'ant'     },
);

search_game('wordswithfriends', $INFILE, 66,
    { tsrc=>__LINE__, word=>'ant'     , dest=>'row 11'   , start=>'column 0' , score=>24 ,             n_tiles=>3  , tiles_this_word=>'ant'       , tiles_consumed=>'ant'     },
    { tsrc=>__LINE__, word=>'ant'     , dest=>'column 11', start=>'row 0'    , score=>24 ,             n_tiles=>3  , tiles_this_word=>'ant'       , tiles_consumed=>'ant'     },
);

search_game('scrabble', $INFILE, 66,
    { tsrc=>__LINE__, word=>'ant'     , dest=>'row 0'    , start=>'column 0' , score=>18 ,             n_tiles=>3  , tiles_this_word=>'ant'       , tiles_consumed=>'ant'     },
    { tsrc=>__LINE__, word=>'ant'     , dest=>'column 11', start=>'row 10'   , score=>12 ,             n_tiles=>3  , tiles_this_word=>'ant'       , tiles_consumed=>'ant'     },
);
close $INFILE;


#### TODO:
# 1) Need to score a triple-letter in at least one of the game styles (and preferrably in all three)
# 2) In the cross-words scoring, I need an example of new-tile on each of the modifier types, and figure out why
#    there is never a non-modified score already
# Note: looking at code, Scrabble is the only one with DL/DW/TL/TW: the others all use nL and nW

done_testing();
1;
