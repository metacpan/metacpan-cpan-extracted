#!/usr/bin/perl
########################################################################
# input_processing.t:
#   Send test board (./game_i), and make sure it gets thru all
#   the board-input error checking correctly, and scores the word
#   properly
# game_i includes:
#   * when asked if the board is correct, reply with junk (check ask-again)
#   * when asked if the board is correct, reply with no (check new board input)
#   * when asked if the board is correct, reply with yes (move forward)
#   * when asked for a row, make it too long (check row-length validation)
#   * when asked for wilds, give cell that's off the board
#   * when asked for wilds, give unpopulated cell
#   * when asked for wilds, give valid cells (move forward)
#   * when asked for tiles, give too many tiles
#   * when asked for tiles, give then in upper case (case conversion)
########################################################################

use 5.008;

use warnings;
use strict;
use Test::More tests => 18;

use IO::String;
use File::Basename qw/dirname/;
use Cwd qw/abs_path chdir/;
BEGIN: { chdir(dirname($0)); }

use Games::Literati 0.040 qw/:allGames/;
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
    my $gameref = \&$gamename;
    my $gameout = run_game($gameref, $fh);
    my @best = ();

    seek($fh, 0, 0);
    my @input = <$fh>;

    chomp foreach (@input);

    my $letters = join '', sort split //, $input[-1];

    #isnt( $gameout, undef, "$gamename(): Running with input '$letters'" );

    pattern: foreach (@_) {
        my ($score, $dest, $word, $start, $bingo) = ($_->{score},$_->{dest},$_->{word},$_->{start},$_->{bingo});
        isnt( $gameout, undef, "$gamename(): desire '${word}', in ${dest} at ${start}, worth ${score} points, using input='$letters'");
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
        is( $best[2], $word , "... Find match for '$word'...");
        is( $best[1], $dest , "... on $dest...");
        is( $best[3], $start , "... starting at $start...");
        if(defined $bingo) {
            is( $best[4] ? 'BINGO' : 'not BINGO', $bingo ? 'BINGO' : 'not BINGO', "... BINGO " . ($bingo?"is":"isn't") . " expected..."  )
        } else {
            ok( 1, "... not testing for BINGO");
        }
        is( $best[0], $score, "... Match score $score for '$word'" );
        #print "\n";
    } # each pattern

    print $gameout if SearchGameOut();
}


##### BOARD: compare scrabble/literati/wordswithfriends scores
our $INFILE;
open $INFILE, '<', 'game_i'      or die "open game1: $!";
search_game('literati', $INFILE,
    { word=>'curses', dest=>'row 3', start=>'column 8', score=>8, bingo=>0 },
    { word=>'serums', dest=>'column 3', start=>'row 10', score=>24, bingo=>0 },
    { word=>'embroils', dest=>'row 14', start=>'column 6', score=>11, bingo=>0 },
);
close $INFILE;

1;
