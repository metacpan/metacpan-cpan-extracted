#===============================================================================
#
#      PODNAME:  Sgf2Dg.pm
#     ABSTRACT:  Sgf2Dg.pm
#     ABSTRACT:  turn Smart Go Format (SGF) files into diagrams
#
#       AUTHOR:  Reid Augustin (REID), <reid@hellosix.com>
#===============================================================================
#
#   perl code to turn an SGF file into diagrams
#
#   Copyright (C) 1997-2005 Reid Augustin reid@hellosix.com
#                      1000 San Mateo Dr.
#                      Menlo Park, CA 94025 USA
#

use 5.005;
use strict;
use warnings;

package Games::Go::Sgf2Dg;

use Exporter 'import';
use IO::File;
use File::Spec;
use Games::Go::Sgf2Dg::Diagram; # the go diagram module

our $VERSION = '4.252'; # VERSION
my $VERSION = 'pre-relase'; # delete this line after build

our @EXPORT_OK = qw(
    );

=head1 NAME

Games::Go::Sgf2Dg - convert Smart Go Format (SGF) files to diagrams similar to
those seen in Go books and magazines.

=head1 SYNOPSIS

sgf2dg [ option ... ] file[.sgf|.mgt]

=head1 DESCRIPTION

B<Games::Go::Sgf2Dg> takes a Smart Go Format (SGF) file I<filename> or
I<filename>.sgf or I<filename>.mgt and produces a diagram file
I<filename>.suffix where suffix is determined by the B<converter>
(see below).

B<Games::Go::Sgf2Dg> modualizes the sgf2dg script.  As such, it parses the
command line (B<@ARGV>) directly, and has only one callable method: B<run>,
called as follows (by the sgf2dg script):

    Games::Go::Sgf2Dg->run;

The default B<converter> is Dg2TeX which converts the Diagram to TeX
source code (sgf2dg is a superset replacement for the sgf2tex script
and package).  If you have the GOOE fonts (provided in the same
package as sgf2dg) correctly installed on your system you will be
able to tex I<filename>.tex to produce a .dvi file.  You can of
course embed all or parts of I<filename>.tex into other TeX
documents.

=cut


use constant a_MINUS_1 => ord('a') - 1; # base of SGF coordinates is 'a'

my (undef, undef, $myName) = File::Spec->splitpath($0);

my $commandLine = "$0 " . join(' ', @ARGV);

my $help = <<HELP_END;
$myName [options] [file.sgf]

    -h | -help                 print this message and exit
    -v | -version              print version number and exit
    -verbose                   print diagnostic information
    -i | -in                   input file name (STDIN for standard input)
    -o | -out                  output file name (STDOUT for standard output)
    -t | -top                  top line in diagram
    -b | -bottom               bottom line in diagram
    -l | -left                 leftmost line in diagram
    -r | -right                rightmost line in diagram
    -crop                      auto-crop diagram
    -break | -breakList        a list of first move in each diagram
    -m | -movesPerDiagram      number of moves per diagram
    -d | -doubleDigits         label stones modulo 100
    -n | -newNumbers           begin each diagram with number 1
    -rv | -relativeVarNums     start each variation from 1
    -av | -absoluteVarNums     move numbers in variation == main line numbers
    -cv | -correlativeVarNums  start main variations from 1 
    -rl | -repeatLast          repeat last move as first in next diagram
    -ic | -ignoreComments      ignore SGF comments
    -il | -ignoreLetters       ignore SGF letters
    -im | -ignoreMarks         ignore SGF marks
    -iv | -ignoreVariations    ignore SGF variations
    -ip | -ignorePass          ignore SGF pass moves
    -ia | -ignoreAll           ignore SGF comments, letters, marks, variations, and passes
    -firstDiagram              first diagram to print
    -lastDiagram               last diagram to print
    -initialDiagram            print initial setup diagram
    -placeHandi                place handicap stones on board (old style)
    -coords                    print coordinates
    -cs | -coordStyle style    coordinate style: normal, sgf, or numeric
    -c | -convert | -converter name of a Diagram converter (see below)
    -simple                    use a very simple TeX format
    -mag number                TeX \\magnification - default is 1000
    -twoColumn                 use two-column format
    -bigFonts                  use fonts magnified 1.2 times
    -texComments               \\, {, and } in comments not modified
    -floatControl string       'string' controls float (diagram) placement

    The -i and -o options are not needed with normal usage:
             $myName [options] name
 is equivalent to:
             $myName [options] -i name -o name.tex 
 or          $myName [options] -i name.sgf -o name.tex
 and         $myName [options] name.

 for those of you who are fans of tab completion.

    The breakList consists of a comma-separated list of numbers (NO
 spaces). Each number will be the last move in one diagram.
 -movesPerDiagram sets an upper limit on the number of moves per
 diagram. The default movesPerDiagram is 50 unless a breakList
 (without -movesPerDiagram) is set, in which case movesPerDiagram is
 set to a very large number. -breakList and -movesPerDiagram may be
 combined.

    -doubleDigits and -newNumbers are alternative schemes for avoiding
 large numerals.  -doubleDigits limits stone numbers to be between 1
 and 100.  Stone number 101 prints as 1.  -newNumbers causes each
 diagram to start with number 1.

    If you use -doubleDigits and -repeatLast together, you'll get
 warnings because there is no font character for stones numbered 0.
 The diagrams with 100, 200, 300, etc. as the first move will
 complain, and those stones will show with their real numbers.

    By default, variation diagrams start with stone number 1
 (-relativeVarNums).  Alternatively, variation numbers can be the
 same as the numbers in the main diagram (-absoluteVarNums) or they
 can start from 1 at the beginning of each variation tree
 (-correlativeVarNums).

    -coords adds coordinates to right and bottom edges.

    -coordStyle style sets the coordinate style.  The default is
 normal which puts descending numbers on the vertical axis and ascending
 letters (skipping I) on the horizontal axis.  style may also be set to
 sgf to see the coordinates used inside the SGF file, or to one of:

    ++    ascending numbers on both axes (0,0 in upper left)
    +-    ascending x axis, descending y axis (0,0 in lower left)
    -+    both ascending numbers on both axes (0,0 in upper right)
    --    descending numbers on both axes (0,0 in lower right)

    Recent SGF formats require AB (add-black) to place handicap stones
 on the board.  Use -placeHandi for old style SGF files that don't
 contain the explicit AB notations.

    -converter changes the output converter.  The default converter
 is Games::Go::Sgf2Dg::Dg2Tex.  All converters get 'Games::Go::Sgf2Dg::Dg2'
 prepended, so you should enter only the part after Dg2.  The
 default is thus equivilent to '-converter TeX'.  Converters
 supplied with this release are (case sensitive):

    TeX       - Donald Knuth's typesetting language
    Mp        - MetaPost embedded in TeX (Encapsulated PostScript)
    ASCII     - ASCII art
    PDF       - Portable Document Format
    Ps        - PostScript
    Tk        - perl/Tk NoteBook window
    TkPs      - PostScript from the Tk NoteBook
    SL        - Sensei's Library (by Marcel Gruenauer)

    Example:    \$ $myName ... -converter ASCII ...

    See the perldoc or man pages for details on converter-specific
 options (eg: 'perldoc Games::Go::Sgf2Dg::Dg2TeX' or 'man Games::Go::Sgf2Dg::Dg2PDF').

    -simple (Dg2TeX) uses a very simple TeX format. This option may be
 useful if you intend to edit the resulting TeX file by hand.

    -mag (Dg2TeX) changes the default \\magnification from 1000.

    -twoColumn (Dg2TeX) uses a two-column format with small fonts.

    -texComments (Dg2TeX) is appropriate if your sgf comments contain TeX.
 If this option is NOT used, \\ { and } are replaced by /, [ and ]
 since these characters are not available in TeX roman fonts. If
 -texComments is used, these changes are not made, so you can add
 TeX code to {\\bf change fonts} in your comments.

    -floatControl 'control_string' (Dg2TeX)
 Normally (not -simple and not -twoColumn), Dg2TeX floats the diagram to
 the left or the right of the accompanying text.  -floatControl allows you
 to specify the position of each diagram.  control_string is a sequence of
 letters which specify where each diagram should be positioned.  The
 letters may be:

        'l'  : diagram left
        'r'  : diagram right
        'a'  : alternate left and right
        other: random left or right

 control_string letters are consumed, one per diagram, until one letter is
 left.  The final letter is used for all remaining diagrams.

 The default control_string is 'rx' which places the first diagram on
 the right (text on the left) and all remaining diagrams are placed
 randomly.


    More details on $myName can be found in the perldoc or man
 pages: 'perldoc $myName' or 'man $myName'.

HELP_END

# some global variables (we'll need to localize some of them)
our ($diagram,          # current Diagram
     $variationDepth,   # how many levels deep in variations (0 == main line)
     $removedCount,     # number of stones removed at start of diagram
     $moveNum,          # move number
     $currentLetter,    # for adding a bunch of letters in sequence
     @lastMove1,        # copy of the last move in case repeatLast is true
     @lastMove2,        # copy of the last move in case repeatLast is true
     );

$variationDepth = 0;
$moveNum = 0;

my $rootDiagram;
my $diagramId = 0;
my $diagramNum = 1;     # current diagram number
my $variationNum = 0;   # current variation number
my @parentDiagram;      # list of refs to parent diagrams (for variations)
# other globals
my %option;             # command line options
my @nodePlays;          # save plays in each node to check
                        #     for captures after moves are finalized

my @ungotten;           # this array will hold 'ungotten' chars from $fileID
my $gotten = '';        # this is helpful when debugging to see how much of the file has been read

# code to handle sgf file formats

sub getC {
    my ($fileID) = @_;
    my ($chr);

    if (scalar(@ungotten)) {
        $chr = shift(@ungotten);
    } else {
        $chr = getc($fileID);
        if (defined($chr)) {
            $gotten .= $chr;
        } else {
            $chr = '';
        }
    }
    return($chr);
}

sub ungetC {
    my ($fileID, $chr) = @_;

    unshift(@ungotten, $chr);
}

sub skipToToken {
    my ($fileID) = @_;
    my ($chr);

    for(;;) {
        $chr = getC($fileID);
        if ((not(defined($chr)) or 
             ($chr eq '')) and
            eof($fileID)) {
            return '';
        }
        if ($chr =~ m/\S/) {
            return($chr);       # non-blank
        }
    }
}

sub printVerbose {
    my (@msg) = @_;

    printIndent(@msg) if ($option{verbose});
}

sub printIndent {
    my (@msg) = @_;

    print(STDERR ' ' x $variationDepth);
    print(STDERR @msg);
}

sub SGF_ReadFile {
    my ($fileID) = @_;
    my ($chr, $start);

    my $prevChr = "\n";
    for(;;) {
        $chr = getC($fileID);                   # collect chars til we see '(' as first char on a line
                                                # this allows emails and news postings to be read - the
                                                # pre-amble will get skipped here.
        if (($prevChr eq "\n") and
            ($chr eq '(')) {
            SGF_ProcessVariation ($fileID);     # got the first line of the SGF part
            return;
        } elsif (($chr eq '') and eof($fileID)) {
            die("Couldn't find the start of the SGF part (no \"(\" as first character on a line).\n");
        }
        $prevChr = $chr;
    }
}

# SGF nesting: (m1 (m2 (m3)(v3 of m3 in m2)(v4 of m3 in m2))(v1m of m2 in m1 (v2m)(v1.1 of v2m in v1m))(v2 of m2 in m1))
# So:  'non-)(' means spawn variation group off main line here (but main line continues)
#      ')('     means variation starting here
#      '))'     means end of variation group here

sub SGF_ProcessVariation {
    my ($fileID) = @_;

# printIndent("SGF_ProcessVariation depth is $variationDepth\n");
    my $prevChr = '(';          # we start off inside the first '('
    my $nestCount = 1;          # we're already inside first '('
    for ( ; ; ) {
        my $chr = skipToToken($fileID);
        if ($chr eq '') {
            die("SGF_ProcessVariation: end of file without closing \")\".\n");
        } elsif ($chr eq '(') {
            if ($prevChr eq ')') {     # new variation
                return if ($option{ignoreVariations});           # done with main line
                $variationDepth++;
                local $diagram = $parentDiagram[0]->next;       # each variation in this group starts from this parent
                local $removedCount = $removedCount;
                local $moveNum = $parentDiagram[0]->var_on_move;
                local @lastMove2;
                local @lastMove1;
                printIndent("Parsing Variation on move $moveNum\n");
                # link back to parent which is 2 levels up:
                my $parent = $parentDiagram[0]->parent;
                # add to parent's variation list.  Note: variation
                # will be on next move (unless stones are removed)
                push(@{$parent->user->{variations}{$moveNum+1}}, $diagram);
                $diagram->var_on_move($moveNum + 1);
                $diagram->parent($parent),
                $diagram->user({id => $diagramId++});
                if (($option{varNumbersFlag} eq 'relative') or          # each variation starts at 1
                    ($option{varNumbersFlag} eq 'correlative' and       # each root variation starts at 1
                    ($variationDepth <= 1))) {
                    $moveNum = 0;
                }
                SGF_ProcessVariation($fileID);
                $variationDepth--;
                $chr = ')';                     # done with variation
                # and now continue with the main line
            } elsif (not $option{ignoreVariations}) {
                $nestCount++;
                # create a new diagram from starting from the
                # current position.  this new diagram is really a
                # place holder since we have to spawn another level
                # of diagrams when we start parsing the variations
                unshift (@parentDiagram, $diagram->next);       # put a fresh diagram on the parent stack
                $parentDiagram[0]->parent($diagram);            # point back to parent
                $parentDiagram[0]->var_on_move($moveNum);       # and remember move number
                                                                #    where variation was spawned
                $parentDiagram[0]->user({id => $diagramId++});
                printIndent("Creating Variation(s) at move $moveNum\n");
            }
        } elsif ($chr eq ')') {                 # end of a variation
            $nestCount--;
            if ($prevChr eq ')') {
                shift(@parentDiagram);                  # done with this group of variations
            }
            if ($nestCount <= 0) {
                printVerbose('SGF_ProcessVariation done: ');
                return;
            }
        } else {                                # a node
            ungetC($fileID, $chr) if ($chr ne ';');     # hmm, missing ';'?
            SGF_ProcessNode($fileID);
            $diagram->node if (defined($diagram));
            while (@nodePlays) {
                my $coords = shift @nodePlays;
                CheckForDeadGroups(SGF2Coords($coords));    # check for captures
            }
        }
        # initialDiagram option patch from Marcel Gr?nauer <hanekomu@gmail.com> Sun, 12 Jul 2009
        if ($option{initialDiagram}) {
            unless (our $did_print_initial_diagram) {
                $diagram->{actions_done}++;
                finishDiagram($diagram, 'initial diagram');
                $did_print_initial_diagram++;
            }
        }
        if ((@{$option{breakList}} > 0) and
            ($diagram->last_number >= $option{breakList}[0])) {
            printVerbose('BreakList: ');
            my $m = shift(@{$option{breakList}});
            @lastMove2 = @lastMove1;        # use last 1 for repeatLast
            finishDiagram(undef, "BreakList at move $m");
        }
        if (($diagram->last_number - $diagram->first_number + 1) >= $option{movesPerDiagram} + $option{repeatLast}) {
            printVerbose('movesPerDiagram: ');
            @lastMove2 = @lastMove1;        # use last 1 for repeatLast
            finishDiagram(undef, "movesPerDiagram");
        }
        if ($option{doubleDigits} and
            ($option{newNumbers} ?
                    ($diagram->last_number - $diagram->first_number >= 100) :
                    (($diagram->first_number != $diagram->last_number) and
                     ($diagram->last_number % 100 == 0)))) {
            printVerbose('doubleDigits: ');
            @lastMove2 = @lastMove1;        # use last 1 for repeatLast
            finishDiagram(undef, "doubleDigits");
        }
        $prevChr = $chr;
    } 
}

sub SGF_ProcessNode {
    my ($fileID) = shift;
    my ($propVal, @propList, $prop, $p);

    local $currentLetter = 'a';         # start each node with a new set of letters

    # sadly, the properties can be in any order.  for example, you might have
    #    a mark before the stone that is to be marked.  so we'll accumulate
    #    all the properties and put them into some sane order.
    my %props;
    for(;;) {
        my $shortPropID = SGF_GetShortPropID(SGF_GetPropID($fileID));
        last if ($shortPropID eq '');
        while((defined (my $propVal = SGF_GetPropVal($fileID)))) {
            push(@{$props{$shortPropID}}, $propVal);
        }

    }
    foreach my $p (sort { &PropOrder } keys(%props)) {
        SGF_ProcessProperty($p, $props{$p});
    }
}

# specify order in which to process properties:
my %propOrder = ( N  => 0,      # first because it always flushes
                  AE => 15,     # might flush
                  AB => 20,     # might flush
                  AW => 20,     # might flush
                  B  => 25,     # changes $moveNum
                  W  => 25,     # changes $moveNum
                                # marks, letter, comments, etc all after
                  );

sub PropOrder {
    my $aa = $propOrder{$a} || 100;
    my $bb = $propOrder{$b} || 100;
    return ($aa <=> $bb);
}

# called every time stones are added or played
sub SGF_ProcessProperty {
    my ($shortPropID, $propVals) = @_;

    foreach my $propVal (@{$propVals}) {
    # Move properties
        if (($shortPropID eq 'W') or            # W[pt]       Play white move
            ($shortPropID eq 'B')) {            # B[pt]       Play black move
            $moveNum++;
            if (($propVal eq '') or             # new style pass
                (($option{boardSizeX} <= 19) and
                 ($option{boardSizeY} <= 19) and
                 ($propVal eq 'tt'))) {         # old (non-scalable) style pass
                unless($option{ignorePass}) {
                    printVerbose("Pass($shortPropID), move=$moveNum\n");
                    $diagram->property($moveNum, $shortPropID, 'pass');
                }
            } else {
                printVerbose("Playing $propVal, color=$shortPropID, move=$moveNum\n");
                my $int = $diagram->get($propVal);
                $diagram->put($propVal, $shortPropID, $moveNum);
                @lastMove2 = @lastMove1;
                @lastMove1 = ($propVal, $shortPropID, $moveNum);
                push(@nodePlays, $propVal);
            }
        } elsif ($shortPropID eq 'KO') {        # KO          force illegal move
            # ignore
            printVerbose("$shortPropID (force move), move=$moveNum\n");
            $diagram->property($moveNum, $shortPropID, '')
        } elsif ($shortPropID eq 'MN') {        # MN[num]  set move number
            printVerbose("Set move number to $propVal at move $moveNum\n");
            $moveNum = $propVal - 1;        # TODO does this work at all?
    # Setup properties
        } elsif (($shortPropID eq 'AW') or      # AW[pt]      AddWhite 
                 ($shortPropID eq 'AB')) {      # AB[pt]      AddBlack
            finishDiagram(undef, "AddB/W");        # need a new diagram
            my $color = substr($shortPropID, 1, 1);
            printVerbose("Add $color stone to $propVal at move $moveNum\n");
            foreach(composed_pt($propVal)) {
                $diagram->put($_, $color);
            }
        } elsif ($shortPropID eq 'AE') {        # AE[pt]      AddEmpty
            finishDiagram(undef, "AddEmpty");
            printVerbose("Empty (remove) $propVal at move $moveNum\n");
            unless ($diagram->last_number) { # if no stones played yet
                # keep track of number of stones removed at the
                # start of the diagram so we can figure out which
                # move in the parent diagram spawned the variation
                $removedCount++;
                $diagram->user->{removedCount} = $removedCount;
            }
            foreach(composed_pt($propVal)) {
                $diagram->remove($_);
            }
        } elsif ($shortPropID eq 'PL') {        #PL[W|B]      set Player
            # ignore
            printVerbose("$shortPropID $propVal (set player), move=$moveNum\n");
            $diagram->property($moveNum, $shortPropID, $propVal)
    # Node annotation properties
        } elsif ($shortPropID eq 'C') {         # C[text]     Comment
            unless ($option{ignoreComments}) {
                if ($propVal =~ m/\S/m) {           # if nothing but whitespace, delete
                    printVerbose("Add comment at move $moveNum:\n$propVal\n");
                    $diagram->property($moveNum, $shortPropID, text($propVal));
                }
            }
        } elsif (($shortPropID eq 'DM') or      # DM[dbl]     Even position
                 ($shortPropID eq 'GB') or      # GB[dbl]     Good for black
                 ($shortPropID eq 'GW') or      # GW[dbl]     Good for white
                 ($shortPropID eq 'HO') or      # HO[dbl]     Hotspot
                 ($shortPropID eq 'UC')) {      # UC[dbl]     Unclear
            # ignore ?
            printVerbose("$shortPropID $propVal (position evaluation), move=$moveNum\n");
            $diagram->property($moveNum, $shortPropID, $propVal)
        } elsif ($shortPropID eq 'N') {         # N[stxt]     Name (node name)
            if(defined($propVal) and
               ($propVal ne '')) {              # no name? return
                finishDiagram(undef, "Named node");     # node names should be at the start of the diagram
                if ($diagram->last_number) {
                    @lastMove2 = @lastMove1;    # use last 1 for repeatLast
                }
                $propVal = simple_text($propVal);
                printVerbose("Node name to $propVal at move $moveNum\n");
                $diagram->property($moveNum, $shortPropID, $propVal);
            }
        } elsif ($shortPropID eq 'V ') {        # V[real]     Value (estimated game score)
            # ignore ?
            printVerbose("$shortPropID $propVal (value estimate), move=$moveNum\n");
            $diagram->property($moveNum, $shortPropID, $propVal)
    # Move annotation properties
        } elsif (($shortPropID eq 'BM') or      # BM[dbl]     bad move
                 ($shortPropID eq 'DO') or      # DO          doubtful move
                 ($shortPropID eq 'IT') or      # IT          interesting move
                 ($shortPropID eq 'TE')) {      # TE[dbl]     tesuji (good move)
            # ignore?
            printVerbose("$shortPropID $propVal (move evaluation), move=$moveNum\n");
            $diagram->property($moveNum, $shortPropID, $propVal)
    # Markup properties
        } elsif ($shortPropID eq 'AR') {        # AR[c_pt]    Arrow
            printVerbose("Arrow: $propVal move $moveNum\n");
            $diagram->property($moveNum, $shortPropID, $propVal)
        } elsif ($shortPropID eq 'DD') {        # DD[elst]    Dim points: DD[] clears any previous dimming
            printVerbose("Dim $propVal move $moveNum\n");
            $diagram->property($moveNum, $shortPropID, $propVal)
        } elsif ($shortPropID eq 'LB') {        # LB[pt:stxt] Label point with text
            unless ($option{ignoreMarks}) {
                my ($item, $coord, $label);
                foreach $item (split(/\s+/, $propVal)) {
                    ($coord, $label) = ($item =~ m/(.*):(.*)/);
                    if (length($coord) != 2) {   # didn't work? hmmm, let's try the other way around
                        ($label, $coord) = ($label, $coord);
                    }
                    $label = simple_text($label);
                    printVerbose("Label \"$label\" at $coord move $moveNum\n");
                    $diagram->label($coord, $label);
                }
            }
        } elsif ($shortPropID eq 'LN') {        # LN[c_pt]    Line
            printVerbose("Line: $propVal move $moveNum\n");
            $diagram->property($moveNum, $shortPropID, $propVal)
        } elsif (
                 ($shortPropID eq 'CR') or      # CR[pt]      circle
                 ($shortPropID eq 'M') or       # M[pt]       old style mark
                 ($shortPropID eq 'MA') or      # MA[pt]      mark (X)
                 ($shortPropID eq 'SQ') or      # SQ[pt]      square
                 ($shortPropID eq 'TR')) {      # TR[pt]      triangle
            $shortPropID = 'TR' if (($shortPropID eq 'M') or            # old style marks were assumed to be triangles
                                    ($option{converter} eq 'SL') or     # Sensei's Library only understands one kind of mark
                                    ($option{converter} eq 'ASCII'));   # ASCII converter only understands one kind of mark
            unless ($option{ignoreMarks}) {
                printVerbose("$shortPropID mark at $propVal move $moveNum\n");
                foreach(composed_pt($propVal)) {
                    $diagram->mark($_, $shortPropID);
                }
            }
        } elsif ($shortPropID eq 'SL') {        # SL[pt]      Select points (markup unknown)
            printVerbose("Select points $propVal move $moveNum\n");
            $diagram->property($moveNum, $shortPropID, $propVal)
    # Root properties
        } elsif (($shortPropID eq 'AP') or      # AP[stxt:stxt] application name:version
                 ($shortPropID eq 'CA') or      # CA[stxt]    charset
                 ($shortPropID eq 'FF') or      # FF[1-4]     FileFormat
                 ($shortPropID eq 'GM') or      # GM[1-16]    Game
                 ($shortPropID eq 'ST')) {      # ST[0-3]     how to show variations (style?)
            # ignore
            printVerbose("$shortPropID $propVal (root property), move=$moveNum\n");
            $diagram->property(0, $shortPropID, $propVal)
        } elsif ($shortPropID eq 'SZ') {        # SZ[num[:num] board size [cols[:rows]]
            if ($propVal =~ m/(\d+):(\d+)/) {
                $option{boardSizeX} = $1;
                $option{boardSizeY} = $2;
            } else {
                $option{boardSizeX} = $propVal;
                $option{boardSizeY} = $propVal;
            }
    # Game info properties
        } elsif (($shortPropID eq 'AN') or       # AN[stxt]     annotater (name)
                 ($shortPropID eq 'BR') or       # BR[stxt]     Black rank
                 ($shortPropID eq 'WR') or       # WR[stxt]     White rank
                 ($shortPropID eq 'BT') or       # BT[stxt]     black team
                 ($shortPropID eq 'WT') or       # WT[stxt]     white team
                 ($shortPropID eq 'CP') or       # CP[stxt]     copyright
                 ($shortPropID eq 'DT') or       # DT[stxt]     Date
                 ($shortPropID eq 'EV') or       # EV[stxt]     Event
                 ($shortPropID eq 'ON') or       # ON[stxt]     opening information
                 ($shortPropID eq 'OT') or       # OT[stxt]     overtime description (byo-yomi)
                 ($shortPropID eq 'PC') or       # PC[stxt]     place game was played
                 ($shortPropID eq 'PB') or       # PB[stxt]     Player Black
                 ($shortPropID eq 'PW') or       # PW[stxt]     Player White
                 ($shortPropID eq 'RE') or       # RE[stxt]     result
                 ($shortPropID eq 'RO') or       # RO[stxt]     round
                 ($shortPropID eq 'RU') or       # RU[stxt]     rules
                 ($shortPropID eq 'SO') or       # SO[stxt]     source
                 ($shortPropID eq 'US')) {       # US[stxt]     user/program who entered the game
            $propVal = simple_text($propVal);
            printVerbose("${shortPropID} $propVal (game info), move=$moveNum\n");
            $diagram->property(0, $shortPropID, $propVal);
        } elsif (($shortPropID eq 'GC') or       # GC[text]   game comment
                 ($shortPropID eq 'TM')) {       # TM[real]   time limits
            $propVal = simple_text($propVal);
            printVerbose("${shortPropID} $propVal (game info), move=$moveNum\n");
            $diagram->property(0, $shortPropID, $propVal);
    # Timing properties
        } elsif (($shortPropID eq 'BL') or      # BL[real]    BlackLeft (time)
                 ($shortPropID eq 'WL') or      # WL[real]    WhiteLeft (time)
                 ($shortPropID eq 'OB') or      # OB[num]     Black moves left (after this move)
                 ($shortPropID eq 'OW')) {      # OW[num]     White moves left
            # ignore
            printVerbose("${shortPropID} $propVal (time/byo-yomi info), move=$moveNum\n");
            $diagram->property($moveNum, $shortPropID, $propVal);
    # Go-specific properties
        } elsif ($shortPropID eq 'HA' and       # HA[num]     handicap, but should not place stones, notation only
                 $propVal !~ m/\D/ and          # digits only
                 $propVal >= 2) {               # at least two
            printVerbose("Handicap $propVal at move $moveNum\n");
            if ($option{placeHandi}) {
                foreach(@{hoshi($propVal)}) {
                    printVerbose("Place handicap on $_\n");
                    $diagram->put($_, 'B');
                }
            }
            $diagram->property(0, $shortPropID, $propVal);  # a game property
        } elsif ($shortPropID eq 'KM') {        # KM[real]    komi
            printVerbose("Komi $propVal at move $moveNum\n");
            $diagram->property(0, $shortPropID, $propVal);  # a game property
        } elsif (($shortPropID eq 'TB') or      # TB[el_pt]   black territory
                 ($shortPropID eq 'TW')) {      # TW[el_pt]   white territory
            my $color = substr($shortPropID, 1, 1);
            printVerbose("Territory for $color at $propVal move $moveNum\n");
            $diagram->territory($shortPropID, $propVal);
    #Misc. properties
        } elsif ($shortPropID eq 'L') {         # L[pt]   next letter at pt (deprecated)
            unless ($option{ignoreLetters}) {
                $diagram->label($propVal, $currentLetter);
                printVerbose("Letter \"$currentLetter\" at $propVal move $moveNum\n");
                $currentLetter++;
            }
        } elsif ($shortPropID eq 'FG') {        # FG[pt:stext]] Figure - see spec
            unless ($option{ignoreComments}) {
                printVerbose("${shortPropID} $propVal, move=$moveNum\n");
                $diagram->property($moveNum, 'C', $propVal);    # treat like a comment
            }
        } elsif ($shortPropID eq 'PM') {        # PM[num]       Print mode: 0=>no numbers, 1=>normal 2=>modulo 100 (see spec for details)
            # ignore
            printVerbose("${shortPropID} $propVal, move=$moveNum\n");
            $diagram->property($moveNum, $shortPropID, $propVal);
        } elsif ($shortPropID eq 'VW') {        # VW[pt:pt]     View parts of board - show only listed points, VW[] clears any previous views
            printVerbose("View $propVal\n");
            if ($propVal ne '') {
                foreach (composed_pt($propVal)) {
                    $diagram->view($_);
                }
                finishDiagram(undef, "VieW");   # views need to end the diagram
            } else {
                $diagram->view($_);             # clears a previous view
            }
        } elsif (($shortPropID eq 'BS') or      # BS[stext]     BlackSpecies (deprecated)
                 ($shortPropID eq 'WS')) {      # WS[stext]     WhiteSpecies (deprecated)
            printVerbose("Species (${shortPropID}) $propVal\n");
            $diagram->property(0, $shortPropID, $propVal);
        } else {
            printVerbose("Unknown property: ${shortPropID} $propVal, move=$moveNum\n");
            $diagram->property($moveNum, $shortPropID, $propVal);       # shrug
        }
    }
}

# a property is an ID followed by value(s)
# the propertyID consists of text
sub SGF_GetPropID {
    my ($fileID) = @_;
    my ($chr, $pos);
    my ($propID) = '';

    $chr = skipToToken($fileID);
    while ($chr ne '') {
        if ($chr =~ m/\w/) {
            $propID .= $chr;
        } else {
            ungetC($fileID, $chr);
            last;
        }
        $chr = getC($fileID);
    }
    return($propID);
}

# a property is an ID followed by value(s)
# proertyVals consists of stuff inside brackets []
sub SGF_GetPropVal {
    my ($fileID) = @_;
    my ($chr, $pos);
    my ($propVal) = '';

    $chr = skipToToken($fileID);
    if ($chr ne '[') {
        ungetC($fileID, $chr);
        return undef;   # no more property values
    }
    for(;;) {
        $chr = getC($fileID);
        if ($chr eq '\\') {
            $propVal .= '\\' . getC($fileID);
        } elsif ($chr eq ']') {
            return($propVal);
        } elsif (($chr eq '') and eof($fileID)) {
            print(STDERR "Unterminated property: $propVal\n");
            return($propVal);
        } else {
            $propVal .= $chr;
        }
    }
}

sub SGF_GetShortPropID {
    my ($propID) = @_;

    return('') unless (defined($propID));
    $propID =~ s/[a-z]//g;      # just get rid of all lower case letters
    return($propID);
}

sub SGF2Coords {
    my ($coords) = @_;
    my ($x, $y) = unpack('C2', $coords);

    return($x - a_MINUS_1, $y - a_MINUS_1);
}

sub Coords2SGF {
    my ($x, $y) = @_;

    $x = chr($x + a_MINUS_1);
    $y = chr($y + a_MINUS_1);
    return("$x$y");
}

sub text {
    my ($text) = @_;

    $text =~ s/\n\r/\n/gm;      # all newline/returns to newlines
    $text =~ s/\r\n/\n/gm;      # all return/newlines to newlines
    $text =~ s/\r/\n/gm;        # all stand-alone returns to newlines
    $text =~ s/\\\n//gm;        # remove backslashed newlines
    $text =~ s/(\s)/($1 eq "\n") ? "\n" : ' '/egm;  # convert all non-newline whitespace into space
    $text =~ s/\\(.)/$1/gm; # other backslashed chars are taken literally
    return $text;
}

sub simple_text {
    my ($text) = @_;

    $text = text($text);
    $text =~ s/\n/ /gm;     # all remaining newlines turn into spaces
    return $text;
}

# composed points look like pt:pt (or perhaps just pt or even '').  pt:pt means
#   all the points in the rectangle from upper left to lower right.
sub composed_pt {
    my ($text) = @_;

    if (my ($p1, $p2) = ($text =~ m/^(.+):(.+)$/)) {
        my ($x1, $y1) = split('', $p1);
        my ($x2, $y2) = split('', $p2);
        ($x2, $x1) = ($x1, $x2) if ($x1 gt $x2);
        ($y2, $y1) = ($y1, $y2) if ($y1 gt $y2);
        my @r;
        foreach my $y ($y1 .. $y2) {
            foreach my $x ($x1 .. $x2) {
                push (@r, "$x$y");
            }
        }
        return @r;
    }
    return $text;
}

# returns a ref to list of SGF coords for hoshi (or handicap) points
sub hoshi {
    my ($num) = @_;

    if ($option{boardSizeX} != $option{boardSizeY}) {
        return;
    }
    my %hoshiTable = (21 => [4, 11, 18],
                      19 => [4, 10, 16],
                      17 => [4, 9,  14],
                      15 => [4, 8,  12],
                      13 => [4, 7,  10],
                      11 => [4, 5,  8 ],
                       9 => [3, 5,  7 ],
                       7 => [2, 4,  6 ],
                       5 => [2, 3,  4 ],
                       );

    unless(defined($num)) {
        # 11x11 and smaller get 5 hoshi points
        $num = ($option{boardSizeX} > 11) ? 9 : 5;
    }
    my ($a, $b, $c);
    if (exists($hoshiTable{$option{boardSizeX}})) {
        ($a, $b, $c) = @{$hoshiTable{$option{boardSizeX}}};
    } else {
        print(STDERR "I don't know about hoshi/handicaps for boardSize $option{boardSizeX}\n");
        return;
    }

    my @hoshi;
    push(@hoshi, Coords2SGF($a,$c), Coords2SGF($c,$a)) if ($num >= 2);
    push(@hoshi, Coords2SGF($c,$c))          if ($num >= 3);
    push(@hoshi, Coords2SGF($a,$a))          if ($num >= 4);
    push(@hoshi, Coords2SGF($b,$b))          if (($num == 5) or
                                       ($num == 7) or
                                       ($num == 9));
    push(@hoshi, Coords2SGF($a,$b), Coords2SGF($c,$b)) if ($num >= 6);
    push(@hoshi, Coords2SGF($b,$a), Coords2SGF($b,$c)) if ($num >= 8);
    if (($num > 9) or ($num < 2)) {
        print(STDERR "Handicap is $num - I can only handle 2 through 9.\n");
    }
    return \@hoshi;
}

sub CheckForDeadGroups {
    my ($x, $y) = @_;

    my $color = $diagram->game_stone(Coords2SGF($x, $y));
    return unless(defined($color));
    my $otherColor = ($color eq 'black') ? 'white' : 'black';
    CheckIfDead($x + 1, $y, $otherColor); # first check the four neighboring stones of the other color
    CheckIfDead($x - 1, $y, $otherColor);
    CheckIfDead($x, $y + 1, $otherColor);
    CheckIfDead($x, $y - 1, $otherColor);
    CheckIfDead($x, $y,     $color);      # and finally we need to check the stone just placed
}

sub CheckIfDead {
    my ($x, $y, $color) = @_;

    my $stone = $diagram->game_stone(Coords2SGF($x, $y));
    return unless(defined($stone) and   # no stone/group here to check
                  ($stone eq $color));  # color doesn't match
    unless (HasLibs($x, $y, $color, {}, 0)) {
        RemoveGroup($x, $y, $color);    # no liberties? - it's dead!
    }
}

sub HasLibs {
    my ($x, $y, $color, $been_here, $depth) = @_;

    if ($depth > 1000) {
        die("Oops, recursion > 1000 while checking for liberties at move $moveNum coords ($x,$y)\n" .
            "This isn't supposed to be possible!  Aborting...\n");
    }
    if (($x < 1) or ($x > ($option{boardSizeX})) or ($y < 1) or ($y > ($option{boardSizeY}))) {
        return(0);              # oops! off the board.
    }
    return 0 if (exists($been_here->{"$x,$y"})); # we've been here before
    $been_here->{"$x,$y"} = 1;     # mark that we've been here
    my $thisStone = $diagram->game_stone(Coords2SGF($x, $y));
    return 1 unless(defined($thisStone));       # empty, the group has liberties
    return(0) if ($thisStone ne $color);        # this is an opponents stone - no liberties here!
    # this is a connected stone of the same color
    $depth++;
    if (HasLibs($x + 1, $y, $color, $been_here, $depth) or
        HasLibs($x - 1, $y, $color, $been_here, $depth) or
        HasLibs($x, $y + 1, $color, $been_here, $depth) or
        HasLibs($x, $y - 1, $color, $been_here, $depth)) {
        return(1);              # yes! we're alive!
    }
    return(0);                  # uh-oh! no liberties yet...
}

sub RemoveGroup {
    my ($x, $y, $color) = @_;

    my $thisStone = $diagram->game_stone(Coords2SGF($x, $y));
    if (defined($thisStone) and
        ($thisStone eq $color)) {
        $diagram->capture(Coords2SGF($x, $y));
        RemoveGroup($x + 1, $y, $color);  # remove any connected stones of the same color
        RemoveGroup($x - 1, $y, $color);
        RemoveGroup($x, $y + 1, $color);
        RemoveGroup($x, $y - 1, $color);
    }
}

sub finishDiagram {
    my ($d, $cause) = @_;

    $d = $diagram unless(defined($d));
    return unless ($d->actions_done);       # no new actions pending? just use current diagram
    if (exists($d->user->{mainId})) {
        printVerbose("Finish Diagram ", $d->user->{mainId}, " at move $moveNum due to $cause\n");
    } else {
        printVerbose("Finish Variation at move $moveNum due to $cause\n");
    }
    my $prevDiagram = $d;
    $diagram = $d->next;                    # start a fresh diagram
    $diagram->user({id => $diagramId++});   # init user hash
    if (exists($prevDiagram->user->{mainId})) {
        my $mainId = $prevDiagram->user->{mainId} + 1;
        $diagram->user->{mainId} = $mainId;
        printIndent("Parsing Diagram $mainId at move $moveNum\n");
    } else {
        printIndent("Parsing Variation continuation at move $moveNum\n");
    }
    $prevDiagram->user->{next} = $diagram;      # link from previous to new diagram
    if ($option{repeatLast} and
        defined($lastMove2[0])) {
        $diagram->renumber($lastMove2[0], $lastMove2[1], undef, $lastMove2[2]);
    }
}

sub CompareVariation {

    my @aa = split(/\./, $a);
    my @bb = split(/\./, $b);

    my ($ii, $max, $return);
#print "CompareVariation($a, $b)\n";
    if (@aa > @bb) {
        $max = @aa;
    } else {
        $max = @bb;
    }
    for ($ii = 0; $ii < $max; $ii++) {
        $aa[$ii] = -1 unless(defined($aa[$ii]));
        $bb[$ii] = -1 unless(defined($bb[$ii]));
        $return = ($aa[$ii] <=> $bb[$ii]);
#print("ii=$ii, aa=$aa[$ii], bb=$bb[$ii], returns $return\n");
        last unless ($return == 0);
    }
    return($return);
}

sub nameDiagram {
    my ($diagram, $sequence, $level) = @_;

    my ($name, $type, $num);
    if ($level) {
        if ($sequence) {
            $name = "Variation $variationNum.$sequence";
        } else {
            $variationNum++;
            $name = "Variation $variationNum";
        }
    } else {
        $name = "Diagram $diagramNum";
        $diagramNum++;
    }
    if (0) {
        my $id = $diagram->user->{id} || '?';   # helpful for debugging
        $diagram->name("$id: $name");
    } else {
        $diagram->name($name);
    }
    if ($level) {
        if ($sequence) {
            $diagram->name(" (continued)")
        } else {
            my $rc = $diagram->user->{removedCount} || 0;
            # adjust "variation on move" for removed stone count
            $diagram->var_on_move($diagram->var_on_move - $rc);
        }
    }
    return ($diagramNum - 1, $name);
}

sub convertDiagram {
    my ($dg2, $diagram, $level) = @_;

    my $sequence = 0;
    while (defined($diagram)) {
        my ($dNum, $dName) = nameDiagram($diagram, $sequence++, $level);
        if(($dNum >= $option{firstDiagram}) and
           ($dNum <= $option{lastDiagram})) {
            auto_bounds($dg2, $diagram);    # crop (auto-bounds) courtesy of Marcel
                                            #   Gruenauer and Dg2SL
            $diagram->hoshi(@{hoshi()});    # add hoshi points to board
            $diagram->offset($diagram->first_number - 1) if ($option{newNumbers} and
                                                             $diagram->first_number);
            printIndent("Converting $dName\n");
            $dg2->convertDiagram($diagram);
            my $vars = $diagram->user->{variations};
            if (defined($vars) and
                not $option{ignoreVariations}) {
                foreach my $moveNum (sort(keys(%{$vars}))) {
                    foreach my $varD (@{$vars->{$moveNum}}) {
                        convertDiagram($dg2, $varD, $level + 1);
                    }
                }
            }
        }
        $diagram = $diagram->user->{next};
    }
}


sub set_defaults {
    #
    # set the defaults
    #
    $option{topLine} = $option{leftLine} = 1;
    $option{bottomLine} = $option{rightLine} = 19;
    $option{varNumbersFlag} = 'relative';
    $option{doubleDigits} = 0;
    $option{repeatLast} = 0;
    $option{newNumbers} = 0;
    $option{firstDiagram} = 1;
    $option{lastDiagram} = 10000;
    $option{initialDiagram} = 0;
    $option{boardSizeX} = 19;
    $option{boardSizeY} = 19;
    $option{coords_style} = 'normal';   # standard coordinate style
    $option{breakList} = [];
    $option{coords} = 0;
    $option{coordStyle} = 'normal';
    $option{floatControl} = 'rx';
    $option{verbose} = 0;
    $option{placeHandi} = 0;

    $option{converter} = 'TeX';

    if ($myName =~ m/sgf2(.*)/) {
        if (($1 ne 'tex') and
            ($1 ne 'diagram') and
            ($1 ne 'dg')) {
            $option{converter} = $1;
        }
    }
}

=head1 OPTIONS

=over 4

=item B<-h > | B<-help>

Print a help message and quit.

=item B<-i> | B<-in>  <filename> | <filename>.sgf | <filename>.mgt

Specifies the input filename. (STDIN or none for standard input.)
This option is not needed in ordinary use.

=item B<-o> | B<-out> <filename>

Specifies the output file. ('STDOUT' for standard output.) If the
input file is <filename>, <filename>.sgf or <filename>.mgt, then
<filename>.I<converter> is the default (see the B<converter> option).
This option is not needed in ordinary usage.

=item B<-t> | B<-top> <top line number>

Specifies the top line to print. Default is 1.

=item B<-b> | B<-bottom> <bottom line number>

Specifies the bottom line to print. Default is 19.

=item B<-l> | B<-left> <left line number>

Specifies the leftmost line to print. Default is 1.

=item B<-r> | B<-right> <right line number> 

Specifies the rightmost line to print. Default is 19.

=item B<-break> | B<-breakList> <break list>

'break list' is a list of moves, separated by comma, with no spaces. These 
are breakpoints: each will be the last move in one diagram. 

=item B<-m> | B<-movesPerDiagram> <moves per diagram>

'moves per diagram' is a positive integer, specifying the maximal number of
moves per diagram. Default is 50 unless B<-break> or B<-breakList> is set, in
which case the default is set to a very large number (10,000). The two options
B<-breakList> and B<-movesPerDiagram> may be used together.

=item B<-n> | B<-newNumbers>

Begin each diagram with the number 1. The actual move numbers are still used
in the label.

B<-newNumbers> and B<-doubleDigits> are alternative schemes for
avoiding three-digit numbers in the diagrams. They should probably not be used
together.

=item B<-d> | B<-doubleDigits>

If the first move of a diagram exceeds 100, the move number is reduced modulo
100. The actual move numbers are still used in the label.  B<-newNumbers> and
B<-doubleDigits> are alternative schemes for avoiding three-digit numbers in
the diagrams. They should probably not be used together.

=item B<-rl> | B<-repeatLast>

The last move in each diagram is the first move in the next. This
emulates a common style for annotating Go games.

=item B<-ic> | B<-ignoreComments>

Comments embedded in the SGF with the C property are ignored.

=item B<-il> | B<-ignoreLetters>

Letters embedded in the SGF with the L or LB property are ignored.

=item B<-im> | B<-ignoreMarks>

Marks embedded in the SGF with the M or MA property are ignored.

=item B<-ip> | B<-ignorePass>

Passes are ignored. In sgf, a pass is a move at the fictitious point tt.
Without this option, sgf2dg indicates passes in the diagram comments.

=item B<-ia> | B<-ignore all>

Ignore SGF letters, marks, variations and passes.

=item B<-firstDiagram> <diagram number>

Specifies the first diagram to print. Default is 1.

=item B<-lastDiagram> <diagram number>

Specifies the last diagram to print. Default is to print all
diagrams until the end.

=item B<-coords>

Adds coordinates to right and bottom edges.

=item B<-verbose>

Print diagnostic messages as the conversion proceeds.  Most SGF
properties produce some kind of message.

=item B<-converter> | B<-convert>

Selects different output converter plugins.  Converters available
with the current distribution package are:

=over 4

=item   L<Games::Go::Sgf2Dg::Dg2TeX>       TeX source (default)

=item   L<Games::Go::Sgf2Dg::Dg2Mp>        MetaPost embedded in TeX

=item   L<Games::Go::Sgf2Dg::Dg2ASCII>     simple ASCII diagrams

=item   L<Games::Go::Sgf2Dg::Dg2PDF>       Portable Document Format (PDF)

=item   L<Games::Go::Sgf2Dg::Dg2Ps>        PostScript

=item   L<Games::Go::Sgf2Dg::Dg2Tk>        Perl/Tk NoteBook/Canvas

=item   L<Games::Go::Sgf2Dg::Dg2TkPs>      PostScript via Dg2Tk (Dg2Ps is prefered)

=item   L<Games::Go::Sgf2Dg::Dg2SL>        Sensei's Library (by Marcel Gruenauer)

=back

B<converter>s are quite easy to write - should take just a few hours if
you are already conversant with the conversion target.  If you would
like to create a B<converter> plugin module, the easiest way is
probably to grab a copy of Dg2Ps.pm (for example) and modify it.
Once it's working, please be sure to send us a copy so we can add it
to the distribution.

Converters are always prepended with 'Games::Go::Sgf2Dg::Dg2', so to select
the ASCII converter instead of the default TeX converter, use:

    -converter ASCII

Converter names are case sensitive.

The default output filename suffix is determined by the converter:
the converter name is lower-cased to become the suffix, so the ASCII
converter produces <filename>.ascii from <filename>.sgf.

You can also select different B<converter>s by changing the name of
the sgf2dg script (or better, make symbolic links, or copies if
your system can't handle links).  The B<converter> name is extracted
from the name with this regular expression:

    m/sgf2(.*)/

Anything after 'sgf2' is assumed to be the name of a B<converter>
module.  For example, let's create a link to the script:

    $ cd /usr/local/bin
    $ ln -s sgf2dg sgf2Xyz

Executing:

    $ sgf2Xyz foo.sgf [ options ]

attempts to use Games::Go::Sgf2Dg::Dg2Xyz as the B<converter>.  The
B<converter> name extracted from the script name is case sensitive.

Note that three extracted names are treated specially:

=over 4

=item   tex

=item   diagram

=item   dg

=back

These three names (when extracted from the script name) always
attempt to use Games::Go::Sgf2Dg::Dg2TeX as the B<converter>.

=back

=head1 CONVERTER OPTIONS

Converters may be added dynamically as plugins, so this list only
includes converter plugin modules that are included with the Sgf2Dg
distribution.

Converter options are prepended with the converter name so that
option xyz for converter Games::Go::Sgf2Dg::Dg2Abc is written on the command
line as:

    $ sgf2dg ... -Abc-xyz ...
    
Converter options that take arguments must be quoted so that the
shell passes the option and any arguments as a single ARGV.  For
example, if the xyz option for converter Dg2Abc takes 'foo' and
'bar' as additional arguments, the command line would be:

    $ sgf2dg ... "-Abc-xyz foo bar" ...

or a more realistic example of changing the background color:

    $ sgf2dg genan-shuwa -converter Tk "-Tk-bg #d2f1b4bc8c8b"

Since Sgf2Dg is a super-set replacement for the Sgf2TeX package,
TeX holds the default position for converters.  Because of this
historically priviledged position, the Dg2TeX options below do
not need to be prepended with 'TeX-'.  All of the following
options apply to the Dg2TeX converter.

Other plugins available at the time of release are Dg2Mp, Dg2ASCII,
Dg2PDF, Dg2Ps, Dg2Tk and Dg2TkPs.  Dg2ASCII and Dg2TkPs take no
additional options.  Dg2Tk doesn't explicitly accept options, but it
attempts to pass unrecognized options to the Tk::Canvas widgets at
creation time (which is why the example above works).

For more information about converter-specific options, please refer
to the perldoc or manual pages:

    $ perldoc Games::Go::Sgf2Dg::Dg2PDF

or

    $ man Games::Go::Sgf2Dg::Dg2Ps

=head2 Dg2TeX options

=over 4

=item B<-simple>

(Dg2TeX) This generates very simple TeX which may not look so
good on the page, but is convenient if you intend to edit the
TeX.

=item B<-mag number>

(Dg2TeX) Changes the default \\magnification from 1000 to number.

=item B<-twoColumn>

(Dg2TeX) This generates a two-column format using smaller fonts.

=item B<-bigFonts>

(Dg2TeX) Use fonts magnified 1.2 times.

=item B<-texComments>

(Dg2TeX) If this option is NOT used then the characters {, } and
\ found in comments are replaced by [, ] and /, since TeX roman
fonts do not have these characters. If this option is used, these
substitutions are not made, so you can embed TeX source (like
{\bf change fonts}) directly inside the comments.

=item B<-floatControl 'control_string'>

(Dg2TeX) Dg2TeX can float the diagram to the left or the right of
the accompanying text.  B<-floatControl> allows you to specify the position
of each diagram.  B<control_string> is a sequence of letters which specify
where each diagram should be positioned.  The letters may be:

=over 4

=item 'l': left

=item 'r': right

=item 'a': alternate

=item other: random

=back

B<control_string> letters are consumed, one per diagram, until there is
only one letter left.  The final letter is used for all remaining diagrams.

The default B<control_string> is 'rx' which places the first diagram on the
right (text on the left) and all remaining diagrams are placed randomly.

=back

=cut

#
# parse the command line arguments:
#
my ($inHandle, $outHandle,  $inFileName, $outFileName);

sub parse_command_line {
    my ($arg, @unknownOpt);
    while (scalar(@ARGV)) {
        $arg = shift(@ARGV);
        if (($arg eq '-d') or ($arg eq '-doubleDigits')) {
            $option{doubleDigits} = 1 
        } elsif (($arg eq '-i') or ($arg eq '-in')) {
            $inFileName = shift(@ARGV);
        } elsif (($arg eq '-o') or ($arg eq '-out')) {
            $outFileName = shift(@ARGV);
        } elsif (($arg eq '-m') or ($arg eq '-movesPerDiagram')) {
            $option{movesPerDiagram} = shift(@ARGV);
        } elsif (($arg eq '-n') or ($arg eq '-newNumbers')) {
            $option{newNumbers} = 1;
        } elsif (($arg eq '-av') or ($arg eq '-absoluteVarNums')) {
            $option{varNumbersFlag} = 'absolute';
        } elsif (($arg eq '-rv') or ($arg eq '-relativeVarNums')) {
            $option{varNumbersFlag} = 'relative';
        } elsif (($arg eq '-cv') or ($arg eq '-correlativeVarNums')) {
            $option{varNumbersFlag} = 'correlative';
        } elsif (($arg eq '-im') or ($arg eq '-ignoreMarks')) {
            $option{ignoreMarks} = 1;
        } elsif (($arg eq '-ic') or ($arg eq '-ignoreComments')) {
            $option{ignoreComments} = 1;
        } elsif (($arg eq '-il') or ($arg eq '-ignoreLetters')) {
            $option{ignoreLetters} = 1;
        } elsif (($arg eq '-ip') or ($arg eq '-ignorePass')) {
            $option{ignorePass} = 1;
        } elsif (($arg eq '-iv') or ($arg eq '-ignoreVariations')) {
            $option{ignoreVariations} = 1;
        } elsif (($arg eq '-ia') or ($arg eq '-ignoreAll')) {
            $option{ignoreVariations} = 1;
            $option{ignoreComments} = 1;
            $option{ignoreLetters} = 1;
            $option{ignoreMarks} = 1;
            $option{ignorePass} = 1;
        } elsif (($arg eq '-rl') or ($arg eq '-repeatLast')) {
            $option{repeatLast} = 1;
        } elsif (($arg eq '-break') or ($arg eq '-breakList')) {
            my $breaks = '';
            while (@ARGV and
                   $ARGV[0] =! m/[\d,]*/) {
                $breaks .= shift @ARGV;
            }
            @{$option{breakList}} = sort {$a <=> $b} split(/,/, $breaks);
        } elsif (($arg eq '-t') or ($arg eq '-top')) {
            $option{topLine} = shift(@ARGV);
        } elsif (($arg eq '-b') or ($arg eq '-bottom')) {
            $option{bottomLine} = shift(@ARGV);
        } elsif (($arg eq '-l') or ($arg eq '-left')) {
            $option{leftLine} = shift(@ARGV);
        } elsif (($arg eq '-r') or ($arg eq '-right')) {
            $option{rightLine} = shift(@ARGV);
        } elsif ($arg eq '-crop') {
            $option{crop} = 1;
        } elsif ($arg eq "-placeHandi") {
            $option{placeHandi} = 1;
        } elsif ($arg eq "-coords") {
            $option{coords} = 1;
        } elsif (($arg eq '-cs') or ($arg eq "-coordStyle")) {
            $option{coordStyle} = lc(shift(@ARGV));
            my %legal = (normal => 1, sgf    => 1,
                        '++'   => 1, '+-'   => 1,
                        '-+'   => 1, '--'   => 1);
            unless (exists($legal{$option{coordStyle}})) {
                die "illegal coordStyle: $option{coordStyle}, must be: normal, sgf, ++, +-, -+, or --\n";
            }
        } elsif ($arg eq '-firstDiagram') {
            $option{firstDiagram} = shift(@ARGV);
        } elsif ($arg eq '-lastDiagram') {
            $option{lastDiagram} = shift(@ARGV);
        } elsif (($arg eq '-h') or ($arg eq '-help')) {
            print($help);
            exit(0);
        } elsif (($arg eq '-v')or($arg eq '-version')) {
            print("$myName $VERSION\n");
            exit(0);
        } elsif ($arg eq '-verbose') {
            $option{verbose} = 1;
        } elsif (($arg eq '-converter') or
                ($arg eq '-convert')) {
            $option{converter} = shift(@ARGV);
            $option{converter} =~ s/.*Games::Go::Sgf2Dg::Dg2//;
        } elsif ($arg eq '-texComments') {
            $option{converterOption}{texComments} = 1;
        } elsif ($arg eq '-bigFonts') {
            $option{converterOption}{bigFonts} = 1;
        } elsif ($arg eq '-simple') {
            $option{converterOption}{simple} = 1;
        } elsif ($arg eq '-mag') {
            $option{converterOption}{mag} = shift(@ARGV);
        } elsif ($arg eq '-twoColumn') {
            $option{converterOption}{twoColumn} = 1;
        } elsif ($arg eq "-floatControl") {
            unless (@ARGV) {
                die("Please specify a control_string for the floatControl option\n")
            }
            $option{converterOption}{floatControl} = lc(shift(@ARGV));
        } elsif (substr($arg, 0, 1) eq '-') {
            push(@unknownOpt, $arg);        # worry about it later...
        } else {
            $inFileName = $arg;
        }
    }

    foreach (@unknownOpt) {
        if (m/^-$option{converter}-(.*)/) {
            my $cnvOpt = $1;
            if ($cnvOpt =~ m/(\S+)\s+(.*)/) {
                $option{converterOption}{$1} = $2;
            } else {
                $option{converterOption}{$cnvOpt} = 1;
            }
        } else {
            print("\nUnknown option: $_\n");
            print($help);
            exit(1);
        }
    }

    if ($option{converter} eq 'SL') {
        # set some options especially for Sensei's Library
        if(exists($option{movesPerDiagram})) {
            if ($option{movesPerDiagram} > 10) {
                print "Warning: Sensei's Library won't accept movesPerDiagram greater than 10\n";
                print "I'll continue, but the output may not be valid\n";
            }
        } else {
            $option{movesPerDiagram} = 10;
        }
        $option{newNumbers} = 1;        # turn on newNumbers
    }

    unless(exists($option{movesPerDiagram})) {
        $option{movesPerDiagram} = scalar(@{$option{breakList}}) ? 10000 : 50
    }
}

sub run {

    set_defaults();
    parse_command_line();
    # open the input file handle
    if (not defined($inFileName) or ($inFileName eq '-')) {
        $inFileName = 'STDIN';
        $inHandle = \*STDIN;
    } else {
        if (!-e $inFileName) {
            if (-e "$inFileName.sgf") {
                $inFileName = "$inFileName.sgf";
            } elsif (-e "${inFileName}sgf") {
                $inFileName = "${inFileName}sgf";
            } else {
                if (-e "$inFileName.mgt") {
                    $inFileName = "$inFileName.mgt";
                } else {
                    die("Can't find $inFileName, $inFileName.sgf or $inFileName.mgt\n");
                }
            }
        }
        $inHandle = IO::File->new("<$inFileName") or
            die("Can't open $inFileName for reading: $!\n");
    }

    # convert the input filename into an output filename
    unless (defined ($outFileName)) {
        if ($inFileName eq  'STDIN') {
            $outFileName = 'STDOUT';
        } else {
            $outFileName = $inFileName;
            unless ($outFileName =~ s/.sgf$//i) {
                $outFileName =~ s/.mgt$//i;
            }
        }
        $outFileName =~ s/.*\///;   # output into current directory
    }
    # create the root diagram object
    $rootDiagram = $diagram = Games::Go::Sgf2Dg::Diagram->new(
        callback    => \&finishDiagram,
        boardSizeX  => $option{boardSizeX},
        boardSizeY  => $option{boardSizeY},
        coord_style => $option{coordStyle}
    );
    $diagram->user({first  => 'first',      # init user hash
                    mainId => 1,
                    id     => $diagramId++});   # id isn't really used for anything,
                                                #   but it helps during debug

    # create the converter object (early so we get errors right away)
    my $fullConvName = "Games::Go::Sgf2Dg::Dg2$option{converter}";
    eval "require $fullConvName;";
    die "Couldn't require $fullConvName: $@" if $@;

    my $converter;
    eval "\$converter = $fullConvName->new(
            doubleDigits => \$option{doubleDigits},
            coords       => \$option{coords},
            \%{\$option{converterOption}});";

    die "Couldn't create new $fullConvName converter: $@" if $@;

    # parse the SGF into the diagrams
    printIndent("Parsing Diagram 1 at move $moveNum\n");
    SGF_ReadFile($inHandle);
    close($inHandle);                       # don't need this anymore

    $converter->configure(
            boardSizeX   => $option{boardSizeX},
            boardSizeY   => $option{boardSizeY},
            %{$option{converterOption}}
            );
    # handle the output file
    if (($outFileName eq 'STDOUT') or ($outFileName eq '-')) {
        $converter->configure(file => \*STDOUT);
        $converter->configure(filename => 'STDOUT');
    } else {
        my $outSuffix = lc $option{converter};
        unless ($outFileName =~ m/.$outSuffix$/i) {
            $outFileName .= ".$outSuffix";  # tack on the converter extension
        }
        $converter->configure(file => ">$outFileName");
    }

    # add an attribution comment
    $converter->comment(
    "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    This file was created by $myName $VERSION with the following command line:

    $commandLine

    $myName was created by Reid Augustin.  The go fonts, TeX
    macros and TeX programming were designed by Daniel Bump.

    More information about the $myName package can be found at:

                http://match.stanford.edu/bump/go.html

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    ");

    # now print the diagrams
    convertDiagram($converter, $rootDiagram, 0);

    $converter->close;
}

# The auto_bounds method is borrowed (stolen?) from Marcel Gruenauer's 
#    Dg2SL converter for Sensei's Library (with slight modifications).
#    We also use this for the VW (view) control property to make sure
#    our coordinates don't extend past the VieW boundaries.
#
# set topLine, bottomLine, etc. based on the extent of the current diagram

sub auto_bounds {
    my ($dg2, $diagram) = @_;

    my $vw = exists($diagram->property()->{0}{VW});
    if (not $vw and
        not $option{crop}) {
        $dg2->configure(leftLine => $option{leftLine},
                        rightLine => $option{rightLine},
                        topLine => $option{topLine},
                        bottomLine => $option{bottomLine});
        return;
    }
    my $left = $option{boardSizeX};
    my $top = $option{boardSizeY};
    my $right = my $bottom = 0;

    # Visit each intersection in this diagram to determine the bounds
    foreach my $y (1 .. $option{boardSizeY}) {
        foreach my $x (1 ..  $option{boardSizeX}) {
            my $int = $diagram->get($dg2->diaCoords($x, $y));
            next unless ($vw ?  exists ($int->{VW}) :
                                (exists ($int->{black}) or
                                 exists ($int->{white})));
            $left   = $x if ($x < $left);
            $right  = $x if ($x > $right);
            $top    = $y if ($y < $top);
            $bottom = $y if ($y > $bottom);
        }
    }
    # Now we have the boundaries of the visible stones.

    # Note: VieW has priority over crop option
    unless ($vw) { # if ($option{crop}) {
        # Leave two empty lines on each side.
        $left -= 2;
        $right += 2;
        $top -= 2;
        $bottom += 2;

        # don't leave out just border lines
        $left   = 1 if $left <= 2;
        $right  = $dg2->{boardSizeX} if $right >= $dg2->{boardSizeX} - 1;
        $top    = 1 if $top <= 2;
        $bottom = $dg2->{boardSizeY} if $bottom >= $dg2->{boardSizeY} - 1;

        # don't cut off one line away from the border 
        $left   = $option{leftLine}   unless $left   > 2;
        $right  = $option{rightLine}  unless $right  < $dg2->{boardSizeX} - 1;
        $top    = $option{topLine}    unless $top    > 2;
        $bottom = $option{bottomLine} unless $bottom < $dg2->{boardSizeY} - 1;
    }
    $dg2->configure(leftLine => $left,
                    rightLine => $right,
                    topLine => $top,
                    bottomLine => $bottom);
}

1;

__END__

=head1 SEE ALSO

=over

=item o sgfsplit(1)   - splits a .sgf file into its component variations

=back

=head1 AUTHOR

sgf2dg was written by Reid Augustin, E<lt>reid@hellosix.comE<gt>

The GOOE fonts and TeX macros were designed by Daniel Bump
(bump@math.stanford.edu).  Daniel hosts the GOOE and sgf2dg home page at:

=over 4

L<http://match.stanford.edu/bump/go.html>

=back
