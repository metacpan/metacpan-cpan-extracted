# Hoon whitespace "test" policy

package MarpaX::Hoonlint::Policy::Test::Whitespace;

use 5.010;
use strict;
use warnings;
no warnings 'recursion';

# use Carp::Always;
use Data::Dumper;
use English qw( -no_match_vars );
use Scalar::Util qw(looks_like_number weaken);

# say STDERR join " ", __FILE__, __LINE__, "hi";

my %reanchorings = ();

my $reanchorings = \<<'EOS';
bardot:
  kettis # fixes 6, breaks 0
  cenlus # fixes 4, breaks 0
  luslus # fixes 3, breaks 2
  cenhep # fixes 1, breaks 0
barhep:
  #       1 ^=
  #       1 =.
  kettis # fixes 1, breaks 0
  tisdot # fixes 1, breaks 0
# bartar
bartar:
  #       1 ++
  # luslus # fixes 1, breaks 14
# bartis
bartis:
  #       2 :-
  #       2 %+
  #       1 %-
  #       1 ++
  colhep # fixes 2, breaks 0
  # tallCenlus # fixes 2, breaks 6
  # tallCenhep # fixes 1, breaks 3
  # luslus # fixes 1, breaks 24
# buctis
buctis:
  # tallBuccol # fixes 1, breaks 2
# cendot
cendot:
  #       4 |=
  #       3 =<
  #       1 =-
  #       1 %-
  bartis # fixes 7, breaks 0
  # tallTisgal # fixes 1, breaks 2
  # tallTishep # fixes 0, breaks 1
  cenhep
cenhep:
  # 6 %-
  # 4 =+
  # 1 =<
  # 1 :-
  cenhep # fixes 6, breaks 1
  tislus # fixes 4, breaks 2
  tisgal # fixes 1, breaks 0
  colhep # fixes 1, breaks 0
# cenket
cenket:
  #       1 =.
  # tallCendot # fixes 0, breaks 0
cenlus:
  cenhep # fixes 8, breaks 0
  tislus # fixes 11, breaks 2
colcab:
  colcab # fixes 13, breaks 0
  cenhep # fixes 12, breaks 0
  cenlus # fixes 6, breaks 0
  # 'tallColhep' # fixes 1, breaks 2
colhep:
  # 'tallColhep' # fixes 2, breaks 4
  cenlus # fixes 3, breaks 0
  colcab # fixes 3, breaks 0
  # 'tallColsig' # fixes 0, breaks 5
dottis:
  #       1 ?.
kethep:
  barhep # Needed for examples to work
  bartis
  cenhep
  colhep # fixes 3, breaks 2
  tistar
  barsig
  ketsig
  tisfas
  kethep # fixes 4, breaks 0
  tishep # partially fixes one
  tisgal # partially fixes one
  tisdot # fixes 1, breaks 0
  # 'tallBarket' # fixes 3, breaks 9
  siglus # fixes 1, breaks 0
  zapgar # fixes 1, breaks 0
  cenlus # fixes 3, breaks 0
  bardot # fixes 1, breaks 0
  # luslus # breaks tic-tac-toe, line 55
  # =+ ^= [...] ^- occurs a lot, and the reanchoring
  # seems to want to be at the KETTIS, not the TISLUS.
  # But where not followed by KETTIS, reanchoring
  # at TISLUS seems to be indicated in a lot of places.
  # This accounts for a lot of aberrations.
  kettis
  # 'tallTislus' # fixes 30, breaks 76
ketlus:
  barhep # Needed for examples to work
  bartis # fixes 97, breaks 0
  tisgal # fixes 8, breaks 0
  bardot # fixes 8, breaks 0
  bartar # fixes 4, breaks 0
  cenhep # fixes 2, breaks 0
# ketsig
ketsig:
  #       1 %+
  cenlus # fixes 1, breaks 0
kettis:
  # tallTislus # breaks 109, fixes 24
ketwut:
  luslus
  buccab
sigcab:
  #       1 |=
  bartis # fixes 1, breaks 0
sigfas:
  luslus # fixes 44, breaks 4
# siglus
siglus:
    #   25 %+
    #    3 ++
    #    2 |=
    #    1 =+
    #    1 |.
    cenlus # fixes 26, breaks 0
    # luslus # fixes 1, breaks 1
    bartis # fixes 1, breaks 0
    # tislus # fixes 0, breaks 0
    bardot # fixes 1, breaks 0
# tisbar
tisbar:
  #       1 |=
  #       1 $_
  bartis # fixes 1, breaks 0
  buccab # fixes 1, breaks 0
# tiscom
tiscom:
  #       1 =,
  tiscom # fixes 1, breaks 0
# tisdot
tisdot:
  #       1 =+
  tislus # fixes 1, breaks 0
tisgal:
  bartis # fixes 20, breaks 0
  tisgal # fixes 14, breaks 0
  cenhep # fixes 7, breaks 0
  ketlus # fixes 4, breaks 0
  tisgar # fixes 2, breaks 0
  cenlus # fixes 1, breaks 1
# tisgar
tisgar:
    # 3 %+
    # 2 ++
    # 2 =+
    # 1 =>
    # 1 =-
    cenlus # fixes 1, breaks 0
    # luslus # fixes 0, breaks 1
    # tislus # fixes 0, breaks 1
    tisgar # fixes 1, breaks 0
    # tishep # fixes 0, breaks 1
# tislus
tislus:
wutcol:
  barhep # fixes 6, breaks 0
  wutcol # fixes 3, breaks 0
  # tallTisdot # fixes 0, breaks 8
  # tallTislus # fixes 0, breaks 1
  cenhep # fixes 1, breaks 0
# wutdot
wutdot:
  #       3 |-
  #       1 =.
  #       1 ?.
  barhep # fixes 5, breaks 0
  # tallTisdot # fixes 1, breaks 3
  # tallWutdot # fixes 0, breaks 0
# wutgal
wutgal:
  #       1 |-
  barhep # fixes 1, breaks 0
# wutgar
wutgar:
  #       2 ~|
  sigbar # fixes 2, breaks 0
wutsig:
  wutsig # fixes 3, breaks 0
  tislus # fixes 2, break 1
  # tallBarhep # fixes 3, breaks 5
zapcol:
  luslus # fixes 8, breaks 1
# zapdot
zapdot:
  #       6 ++
  luslus # fixes 6, breaks 0
zapgar:
  cenhep # fixes 89, breaks 0
EOS

{

    # special cases for grammar names
    my %grammarNames = (
       luslus => 'LuslusCell',
       lustis => 'LustisCell',
       lushep => 'LushepCell',
    );

    my $currentSource;

  ITEM: for my $itemLine ( split "\n", ${$reanchorings} ) {
        my $rawItemLine = $itemLine;
        $itemLine =~ s/\s*[#].*$//;   # remove comments and preceding whitespace
        $itemLine =~ s/^\s*//;        # remove leading whitespace
        $itemLine =~ s/\s*$//;        # remove trailing whitespace
        next ITEM unless $itemLine;

        if (my ($source) = $itemLine =~ m/^(.*) *:$/) {
            $currentSource = $source;
            next ITEM;
        }

        die qq{Error in inline reanchorings: No source rune\n}
          . qq{  Problem with line: $rawItemLine\n}
          if not $currentSource;

        chomp $itemLine;
        my $target = $itemLine;

        my $grammarName = $grammarNames{$target};
        if (not defined $grammarName) {
            $grammarName = 'tall' . ucfirst $target;
        }

        $reanchorings{$currentSource}{$grammarName} = 1;

    }
}

# die Data::Dumper::Dumper(\%reanchorings);

# TODO: delete indents in favor of tree traversal

my $gapCommentDSL = <<'END_OF_DSL';
:start ::= gapComments
gapComments ::= OptExceptions Body
gapComments ::= OptExceptions
Body ::= InterPart PrePart
Body ::= InterPart
Body ::= PrePart
InterPart ::= InterComponent
InterPart ::= InterruptedInterComponents
InterPart ::= InterruptedInterComponents InterComponent

InterruptedInterComponents ::= InterruptedInterComponent+
InterruptedInterComponent ::= InterComponent Exceptions
InterComponent ::= Staircases
InterComponent ::= Staircases InterComments
InterComponent ::= InterComments

InterComments ::= InterComment+

Staircases ::= Staircase+
Staircase ::= UpperRisers Tread LowerRisers
UpperRisers ::= UpperRiser+
LowerRisers ::= LowerRiser+

PrePart ::= ProperPreComponent OptPreComponents
ProperPreComponent ::= PreComment
OptPreComponents ::= PreComponent*
PreComponent ::= ProperPreComponent
PreComponent ::= Exception

OptExceptions ::= Exception*
Exceptions ::= Exception+
Exception ::= MetaComment
Exception ::= BadComment
Exception ::= BlankLine

unicorn ~ [^\d\D]
BadComment ~ unicorn
BlankLine ~ unicorn
InterComment ~ unicorn
LowerRiser ~ unicorn
MetaComment ~ unicorn
PreComment ~ unicorn
Tread ~ unicorn
UpperRiser ~ unicorn

END_OF_DSL

# Format line and 0-based column as string
sub describeLC {
    my ( $line, $column ) = @_;
    return '@' . $line . ':' . ( $column + 1 );
}

sub describeMisindent {
    my ($difference) = @_;
    if ( $difference > 0 ) {
        return "overindented by $difference";
    }
    if ( $difference < 0 ) {
        return "underindented by " . ( -$difference );
    }
    return "correctly indented";
}

sub describeMisindent2 {
    my ( $got, $sought ) = @_;
    $DB::single = 1 if not defined $sought;
    return describeMisindent( $got - $sought );
}

sub setInheritedAttribute {
    my ( $policy, $node, $attribute, $value ) = @_;
    my $nodeIX        = $node->{IX};
    $policy->{perNode}->{$nodeIX}->{$attribute} = $value;
}

sub getInheritedAttribute {
    my ( $policy, $node, $attribute ) = @_;
    my $nodeIX        = $node->{IX};
    my $value = $policy->{perNode}->{$nodeIX}->{$attribute};
    return $value if defined $value;
    $node = $node->{PARENT};
    die qq{Ascended tree but did not find attributee "$attribute"} if not $node;
    $value = $policy->getInheritedAttribute($node, $attribute);
    return $value;
}

sub new {
    my ( $class, $lintInstance ) = @_;
    my $policy = {};
    $policy->{lint} = $lintInstance;
    my %chainable = ();
    for my $key (keys %{ $lintInstance->{backdentedRule} }, keys %{ $lintInstance->{tallNoteRule} }) {
       $chainable{$key} = 1;
    }
    $policy->{chainable} = \%chainable;
    Scalar::Util::weaken( $policy->{lint} );
    $policy->{gapGrammar} =
      Marpa::R2::Scanless::G->new( { source => \$gapCommentDSL } );
    return bless $policy, $class;
}

# Return Perl true is node is chainable
sub chainable {
    my ( $policy, $node ) = @_;
    my $chainable = $policy->{chainable};
    my $instance = $policy->{lint};
    my $grammar  = $instance->{grammar};
    my $ruleID   = $node->{ruleID};
    return if not $ruleID;
    my ($lhs)    = $grammar->rule_expand( $node->{ruleID} );
    my $lhsName  = $grammar->symbol_name($lhs);
    # say STDERR join ' ', __FILE__, __LINE__, $lhsName, ($chainable->{$lhsName} // 'na');
    return $chainable->{$lhsName};
}

# Return the node tag for the subpolicy field.
# Archetypally, this is the 6-character form of
# rune for the node's brick.
sub runeName {
    my ( $policy, $node ) = @_;
    my $instance = $policy->{lint};
    my $name     = $instance->forceBrickName($node);
    if ( my ($tag) = $name =~ /^(Lus[b-z][aeiou][b-z])Cell$/ ) {
        return lc $tag;
    }
    if ( my ($tag) = $name =~ /^optFord([B-Z][aeoiu][b-z][b-z][aeiou][b-z])$/ ) {
        return lc $tag;
    }
    if ( my ($tag) = $name =~ /^ford([B-Z][aeoiu][b-z][b-z][aeiou][b-z])$/ ) {
        return lc $tag;
    }
    if ( my ($tag) = $name =~ /^tall([B-Z][aeoiu][b-z][b-z][aeiou][b-z])$/ ) {
        return lc $tag;
    }
    if ( my ($tag) = $name =~ /^tall([B-Z][aeoiu][b-z][b-z][aeiou][b-z])Mold$/ )
    {
        return lc $tag;
    }
    return lc $name;
}

sub nodeSubpolicy {
    my ( $policy, $node ) = @_;
    return $policy->runeName($node);
}

# return standard anchor "detail" line
sub anchorDetailsBasic {
    my ( $policy, $rune, $anchorColumn ) = @_;
    my $instance = $policy->{lint};
    my ( $runeLine, $runeColumn ) = $instance->nodeLC($rune);
    my $anchorLiteral = $instance->literalLine($runeLine);
    my $anchorLexeme = substr $anchorLiteral, $anchorColumn;
    $anchorLexeme =~ s/[\s].*\z//xms;
    my $typeVerb = ( $anchorColumn == $runeColumn ) ? "anchor" : "re-anchor";
    return [qq{$typeVerb column is }
          . describeLC( $runeLine, $anchorColumn )
          . qq{ "$anchorLexeme"} ];
}

sub anchorDetails {
    my ( $policy, $rune, $anchorData ) = @_;
    my @desc     = ();
    my $instance = $policy->{lint};
    my $brick    = $anchorData->{brick};

    my ( $runeLine,  $runeColumn )  = $instance->nodeLC($rune);
    my ( $brickLine, $brickColumn ) = $instance->nodeLC($brick);
    my $anchorColumn    = $anchorData->{column};
    my $offset          = $anchorData->{offset};
    my $runeLineLiteral = $instance->literalLine($runeLine);
    $runeLineLiteral =~ s/\n\z//xms;

    if ( $anchorColumn == $runeColumn ) {
        my $brickLiteral = $instance->literalLine($runeLine);
        my $brickLexeme = substr $brickLiteral, $brickColumn;
        $brickLexeme =~ s/[\s].*\z//xms;
        return [sprintf 'anchor column is "%s" %s',
               $brickLexeme,
              describeLC( $runeLine, $anchorColumn )
              ];
    }
    push @desc,
      sprintf
're-anchor column (%d) = anchor brick column (%d) + re-anchor offset (%d)',
      $anchorColumn + 1, $brickColumn + 1, $offset;
    my $maxNumWidth    = $instance->maxNumWidth();
    my $pointersPrefix = ( ' ' x $maxNumWidth );
    my $prefixLength   = length $pointersPrefix;
    push @desc, sprintf '%s%s', $pointersPrefix, $runeLineLiteral;
    my $pointerLine = ( ' ' x ( $runeColumn + $prefixLength ) ) . q{^};
    substr( $pointerLine, ( $brickColumn + $prefixLength ),  1 ) = q{^};
    substr( $pointerLine, ( $anchorColumn + $prefixLength ), 1 ) = q{!};
    push @desc, $pointerLine;
    return \@desc;
}

# first brick node in $node's line,
# by inclusion list.
# $node if there is no prior included brick node
sub reanchorInc {
    my ( $policy, $node, $inclusions ) = @_;
    my $instance = $policy->{lint};

    my ($currentLine)  = $instance->nodeLC($node);
    my $thisNode       = $node;
    my $firstBrickNode = $node;
    my @nodes          = ();

    # Accumulate a list of the nodes on the same line as
    # the argument node
  NODE: while ($thisNode) {
        my ($thisLine) = $instance->nodeLC($thisNode);
        last NODE if $thisLine != $currentLine;
        push @nodes, $thisNode;
        $thisNode = $thisNode->{PARENT};
    }
    my $topNodeIX;
    my $brick          = $node;
    my $reanchorOffset = 0;
  SET_DATA: {
      PICK_NODE: for ( my $nodeIX = $#nodes ; $nodeIX >= 0 ; $nodeIX-- ) {
            my $thisNode  = $nodes[$nodeIX];
            my $brickName = $instance->brickName($thisNode);
            if ( defined $brickName and $inclusions->{$brickName} ) {
                $topNodeIX = $nodeIX;
                last PICK_NODE;
            }
        }
        last SET_DATA if not defined $topNodeIX;
        for (
            my $nodeIX = 1 ;    # do not include first node
            $nodeIX <= $topNodeIX ; $nodeIX++
          )
        {
            my $thisNode = $nodes[$nodeIX];
            my $nodeID   = $thisNode->{IX};
            my $thisReanchorOffset =
              $policy->{perNode}->{$nodeID}->{reanchorOffset} // 0;
            $reanchorOffset += $thisReanchorOffset;
        }
        $brick = $nodes[$topNodeIX];
    }
    my ( $brickLine, $brickColumn ) = $instance->nodeLC($brick);
    my $column  = $brickColumn + $reanchorOffset;
    my %results = (
        brick  => $brick,
        offset => $reanchorOffset,
        column => $column,
        line   => $brickLine
    );
    return $column, \%results;
}

# A "gapSeq" is an ordered subset of a node's children.
# It consists of the first child, followed by zero or more
# pairs of nodes, where each pair is a gap and it post-gap
# symbol.  It is assumed that the first child is not a gap,
# and no post-gap child is a gap.  The sequence will always
# be of odd length.
#
# Intuitively, this is usually the subset of the children with
# information useful for parsing.
sub gapSeq {
    my ( $policy, $node ) = @_;
    my $instance        = $policy->{lint};
    my $symbolReverseDB = $instance->{symbolReverseDB};
    my $children        = $node->{children};
    my $child           = $children->[0];
    my @gapSeq          = ($child);

    my $childIX = 1;
  CHILD: while ( $childIX < $#$children ) {
        $child = $children->[$childIX];
        my $symbol = $child->{symbol};
        if (   not defined $symbol
            or not $symbolReverseDB->{$symbol}->{gap} )
        {
            $childIX++;
            next CHILD;
        }
        my $nextChild = $children->[ $childIX + 1 ];
        push @gapSeq, $child, $nextChild;
        $childIX += 2;
    }
    return \@gapSeq;
}

# A variant of "gapSeq" which relaxes the assumption that
# the first child is not a gap, and which returns an
# alternating sequence of gap and post-gap.  It assumes
# that a gap does not follow another gap.
sub gapSeq0 {
    my ( $policy, $node ) = @_;
    my $instance        = $policy->{lint};
    my $symbolReverseDB = $instance->{symbolReverseDB};
    my $children        = $node->{children};
    my @gapSeq          = ();

    my $childIX = 0;
  CHILD: while ( $childIX < $#$children ) {
        my $child  = $children->[$childIX];
        my $symbol = $child->{symbol};
        if (   not defined $symbol
            or not $symbolReverseDB->{$symbol}->{gap} )
        {
            $childIX++;
            next CHILD;
        }
        my $nextChild = $children->[ $childIX + 1 ];
        push @gapSeq, $child, $nextChild;
        $childIX += 2;
    }
    return \@gapSeq;
}

# Checks a gap to see if it is OK as a pseudo-join.
# If so, returns the column at which code may resume.
# Otherwise returns -1;

sub pseudojoinColumn {
    my ( $policy, $gap ) = @_;
    my $instance   = $policy->{lint};
    my $gapLiteral = $instance->literalNode($gap);
    my $gapStart   = $gap->{start};
    my $gapEnd     = $gap->{start} + $gap->{length};

    if ($instance->runeGapNode($gap)) {
        $gapLiteral = substr( $gapLiteral, 2 );
        $gapStart += 2;
    }

    my ( $startLine, $startColumn ) = $instance->line_column($gapStart);
    my ( $endLine,   $endColumn )   = $instance->line_column($gapEnd);

    my $commentColumn;

    # first partial line (must exist)
    my $firstNewline = index $gapLiteral, "\n";
    return if $firstNewline < 0;
    my $firstColon = index $gapLiteral, ':';
    if ( $firstColon >= 0 and $firstColon < $firstNewline ) {
        ( undef, $commentColumn ) =
          $instance->line_column( $gapStart + $firstColon );
    }

    # say STDERR join ' ', __FILE__, __LINE__;
    return -1 if not $commentColumn;
    # say STDERR join ' ', __FILE__, __LINE__;

    # If the last line of the gap does not end in a newline,
    # it **cannot** contain a comment, because the parser would
    # recognize the whole comment as part of the gap.
    # So we only look for properly aligned comments in full
    # (that is, newline-terminated) lines.

    my $lastFullLine =
      ( substr $gapLiteral, -1, 1 ) eq "\n" ? $endLine : $endLine - 1;
    for my $lineNum ( $startLine + 1 .. $lastFullLine ) {
        my $literalLine = $instance->literalLine($lineNum);
        my $commentOffset = index $literalLine, ':';

    # say STDERR join ' ', __FILE__, __LINE__;
        return -1 if $commentOffset < 0;
    # say STDERR join ' ', __FILE__, __LINE__, $commentOffset, $commentColumn;
        return -1 if $commentOffset != $commentColumn;
    # say STDERR join ' ', __FILE__, __LINE__;
    }
    return $commentColumn;
}

# Is this a valid join gap?
# Return undef if not.
# Return -1 if flat join.
# Return pseudo-join column if pseudo-join.
sub checkJoinGap {
    my ( $policy, $gap ) = @_;
    my $instance   = $policy->{lint};
    my $gapLiteral = $instance->literalNode($gap);

    # say join ' ', __FILE__, __LINE__;
    # say join q{}, '[', $gapLiteral, ']';
    return -1 if $gapLiteral =~ m/\A [ ]* \z/xms;

    # say join ' ', __FILE__, __LINE__;
    my $column = $policy->pseudojoinColumn($gap);
    return $column if defined $column and $column >= 0;
    return;
}

sub deComment {
    my ( $policy, $string ) = @_;
    $string =~ s/ ([+][|]|[:][:]|[:][<]|[:][>]) .* \z//xms;
    return $string;
}

# Is this a one-line gap, or its equivalent?
sub checkOneLineGap {
    my ( $policy, $gap, $options ) = @_;
    my $instance = $policy->{lint};
    my $start    = $gap->{start};
    my $length   = $gap->{length};
    if ( $instance->runeGapNode($gap) ) {
        $start += 2;
        $length -= 2;
    }

    my $runeName      = $options->{runeName};
    my $details       = $options->{details};
    my $elementNumber = $options->{elementNumber};

    my @topicLines = ();
    my $topicLines = $options->{topicLines};
    push @topicLines, @{$topicLines} if $topicLines;

    my @mistakes  = ();
    my $end       = $start + $length;
    my ( $startLine, $startColumn ) = $instance->line_column($start);
    my ( $endLine,   $endColumn )   = $instance->line_column($end);

    # say STDERR Data::Dumper::Dumper($options);

    my ( $mainLine, $mainColumn );
    if ( my $mainNode = $options->{mainNode} ) {
        ( $mainLine, $mainColumn ) = $instance->nodeLC($mainNode);
    }
    $mainColumn //= $options->{mainColumn} // -1;

    my ( $preLine, $preColumn );
    if ( my $preNode = $options->{preNode} ) {
        ( $preLine, $preColumn ) = $instance->nodeLC($preNode);
    }
    $preColumn //= $options->{preColumn} // -1;

    my @subpolicyElements = ();
  SET_SUBPOLICY: {
        my $subpolicyArg = $options->{subpolicy};
        last SET_SUBPOLICY if not defined $subpolicyArg;
        if ( not ref $subpolicyArg ) {
            push @subpolicyElements, $subpolicyArg;
            last SET_SUBPOLICY;
        }
        push @subpolicyElements, @{$subpolicyArg};
    }

    # Criss-cross TISTIS lines are a special case
    # say STDERR join " ", __FILE__, __LINE__, $startLine, $endLine;
    if (    $startLine == $endLine
        and $instance->literal( $start - 2, 2 ) ne '=='
        and $instance->literal( $start - 2, 2 ) ne '--' )
    {
        my $msg = sprintf
          "%s %s; %s %s",
          $runeName,
          describeLC( $startLine, $startColumn ),
          "missing newline ",
          , describeLC( $startLine, $startColumn );
        return [
            {
                desc => $msg,
                subpolicy =>
                  ( join ':', @subpolicyElements, 'missing-newline' ),
                runeName     => $runeName,
                line         => $startLine,
                column       => $startColumn,
                reportLine   => $startLine,
                reportColumn => $startColumn,
                topicLines   => \@topicLines,
                details      => $details,
            }
        ];
    }

    my $bodyStartLine = $start == 0 ? $startLine : $startLine + 1;
    my $lineToPos = $instance->{lineToPos};
    if ( $bodyStartLine < $#$lineToPos ) {
        my $literalFirstLine = $instance->literalLine($bodyStartLine);
        if ( $literalFirstLine =~ /'''/ ) {

            # say join ' ', __FILE__, __LINE__, qq{"$literalFirstLine"};
            $bodyStartLine++;
        }
        if ( $literalFirstLine =~ /"""/ ) {

            # say join ' ', __FILE__, __LINE__, qq{"$literalFirstLine"};
            $bodyStartLine++;
        }
    }
    my $results = $policy->checkGapComments( $bodyStartLine, $endLine - 1,
        $mainColumn, $preColumn );
  RESULT: for my $result ( @{$results} ) {
        my $type = $result->[0];
        if ( $type eq 'vgap-blank-line' ) {
            my ( undef, $lineNum, $offset ) = @{$result};
            my $msg = sprintf
              "%s %s; %s",
              $runeName,
              describeLC( $lineNum, 0 ),
              "empty line in comment";
            push @mistakes,
              {
                desc         => $msg,
                subpolicy    => ( join ':', @subpolicyElements, 'empty-line' ),
                runeName     => $runeName,
                reportLine   => $lineNum,
                reportColumn => 0,
                line         => $lineNum,
                column       => 0,
                topicLines   => \@topicLines,
                details      => $details,
              };
            next RESULT;
        }
        if ( $type eq 'vgap-bad-comment' ) {
            my ( undef, $lineNum, $offset, $expectedOffset ) = @{$result};

            my $msg;
            if ( defined $elementNumber ) {
                $msg = sprintf
                  "%s child %d %s; %s %s",
                  $runeName,
                  $elementNumber,
                  describeLC( $lineNum, $offset ),
                  "comment",
                  describeMisindent2( $offset, $expectedOffset );
            }
            else {
                $msg = sprintf
                  "%s d %s; %s %s",
                  $runeName,
                  describeLC( $lineNum, $offset ),
                  "comment",
                  describeMisindent2( $offset, $expectedOffset );
            }
            push @mistakes,
              {
                desc      => $msg,
                subpolicy => ( join ':', @subpolicyElements, 'comment-indent' ),
                runeName  => $runeName,
                reportLine   => $lineNum,
                reportColumn => $offset,
                line         => $lineNum,
                column       => $offset,
                topicLines   => \@topicLines,
                details      => $details,
              };
        }
    }

    return \@mistakes;
}


sub checkGapComments {
    my ( $policy, $firstLine, $lastLine, $interOffset, $preOffset ) = @_;

    return if $lastLine < $firstLine;
    my $instance  = $policy->{lint};
    my $pSource   = $instance->{pHoonSource};
    my $lineToPos = $instance->{lineToPos};
  SET_PREOFFSET: {
        last SET_PREOFFSET if not defined $preOffset;
        if ( $preOffset < 0 ) {
            $preOffset = undef;    # negative offset == undefined
            last SET_PREOFFSET;
        }
        if ( $preOffset == $interOffset ) {

            # Do not allow pre-offset to be equal to inter-offset
            $preOffset = undef;
            last SET_PREOFFSET;
        }
    }
    my @mistakes = ();

    my $grammar  = $policy->{gapGrammar};
    my $recce    = Marpa::R2::Scanless::R->new( { grammar => $grammar } );
    my $startPos = $lineToPos->[$firstLine];
    my $input    = $instance->literal( $startPos,
        ( $lineToPos->[ $lastLine + 1 ] - $startPos ) );

# say STDERR join ' ', __FILE__, __LINE__, "$firstLine-$lastLine", qq{"$input"};

    if ( not defined eval { $recce->read( $pSource, $startPos, 0 ); 1 } ) {

        my $eval_error = $EVAL_ERROR;
        chomp $eval_error;
        say STDERR join ' ', __FILE__, __LINE__, "$firstLine-$lastLine",
          qq{"$input"};
        die $eval_error, "\n";
    }

    my $lineNum = 0;
  LINE:
    for ( my $lineNum = $firstLine ; $lineNum <= $lastLine ; $lineNum++ ) {
        my $line = $instance->literalLine($lineNum);

        # say STDERR join ' ', __FILE__, __LINE__, $lineNum, qq{"$line"};

      FIND_ALTERNATIVES: {
            my $expected = $recce->terminals_expected();

            # say Data::Dumper::Dumper($expected);
            my $tier1_ok;
            my @tier2         = ();
            my @failedOffsets = ();
          TIER1: for my $terminal ( @{$expected} ) {

                # say STDERR join ' ', __FILE__, __LINE__, $terminal;
                if ( $terminal eq 'InterComment' ) {
                    $line =~ m/^ [ ]* ([+][|]|[:][:]|[:][<]|[:][>]) /x;
                    my $commentOffset = $LAST_MATCH_START[1];
                    $commentOffset //= -1;

                    # say STDERR join ' ', __FILE__, __LINE__, qq{"$line"};
                    # say STDERR join ' ', __FILE__, __LINE__, $commentOffset;
                    if ( $commentOffset == $interOffset ) {

                        # say STDERR join ' ', __FILE__, __LINE__;
                        $recce->lexeme_alternative( $terminal, $line );
                        $tier1_ok = 1;
                        next TIER1;
                    }
                    push @failedOffsets, $interOffset;
                    next TIER1;
                }
                if ( $terminal eq 'Tread' ) {
                    $line =~ m/^ [ ]* ([:][:][:][:][ \n]) /x;
                    my $commentOffset = $LAST_MATCH_START[1];
                    $commentOffset //= -1;

                    # say STDERR join ' ', __FILE__, __LINE__, $commentOffset;
                    if ( $commentOffset == $interOffset ) {

                        # say STDERR join ' ', __FILE__, __LINE__;
                        $recce->lexeme_alternative( $terminal, $line );
                        $tier1_ok = 1;
                        next TIER1;
                    }
                    push @failedOffsets, $interOffset;
                    next TIER1;
                }
                if ( $terminal eq 'UpperRiser' ) {
                    $line =~ m/^ [ ]* ([:][:]) /x;
                    my $commentOffset = $LAST_MATCH_START[1];
                    $commentOffset //= -1;

                    # say STDERR join ' ', __FILE__, __LINE__, $commentOffset;
                    if ( $commentOffset == $interOffset ) {

                        # say STDERR join ' ', __FILE__, __LINE__;
                        $recce->lexeme_alternative( $terminal, $line );
                        $tier1_ok = 1;
                        next TIER1;
                    }
                    push @failedOffsets, $interOffset;
                    next TIER1;
                }
                if ( $terminal eq 'LowerRiser' ) {
                    $line =~ m/^ [ ]* ([:][:]) /x;
                    my $commentOffset = $LAST_MATCH_START[1];
                    $commentOffset //= -1;

                    # say STDERR join ' ', __FILE__, __LINE__, $commentOffset;
                    if ( $commentOffset == $interOffset + 2 ) {

                        # say STDERR join ' ', __FILE__, __LINE__;
                        $recce->lexeme_alternative( $terminal, $line );
                        $tier1_ok = 1;
                        next TIER1;
                    }
                    push @failedOffsets, $interOffset;
                    next TIER1;
                }
                push @tier2, $terminal;
            }

            # If we found a tier 1 lexeme, do not look for the "backup"
            # lexemes on the other tiers
            last FIND_ALTERNATIVES if $tier1_ok;

            my $tier2_ok;
            my @tier3 = ();
          TIER2: for my $terminal (@tier2) {
                if ( $terminal eq 'PreComment' ) {
                    next TIER2 if not defined $preOffset;
                    $line =~ m/^ [ ]* ([+][|]|[:][:]|[:][<]|[:][>]) /x;
                    my $commentOffset = $LAST_MATCH_START[1];
                    $commentOffset //= -1;

                    # say STDERR join ' ', __FILE__, __LINE__, $commentOffset;
                    if ( $commentOffset == $preOffset ) {

                        # say STDERR join ' ', __FILE__, __LINE__;
                        $recce->lexeme_alternative( $terminal, $line );
                        $tier2_ok = 1;
                        next TIER2;
                    }
                    push @failedOffsets, $preOffset;
                    next TIER2;
                }
                push @tier3, $terminal;
            }

            # If we found a tier 2 lexeme, do not look for the "backup"
            # lexemes on the other tiers
            last FIND_ALTERNATIVES if $tier2_ok;

            my @tier4 = ();
          TIER3: for my $terminal (@tier3) {
                if ( $terminal eq 'MetaComment' ) {
                    $line =~ m/^ [ ]* ([+][|]|[:][:]|[:][<]|[:][>]) /x;
                    my $commentOffset = $LAST_MATCH_START[1];
                    next TIER3 if not defined $commentOffset;
                    if ( $commentOffset == 0 ) {
                        $recce->lexeme_alternative( $terminal, $line );

                  # anything in this tier terminates the finding of alternatives
                        last FIND_ALTERNATIVES;
                    }
                    push @failedOffsets, $interOffset;
                }
                push @tier4, $terminal;
            }

          TIER4: for my $terminal (@tier4) {
                if ( $terminal eq 'BlankLine' ) {

               # say STDERR join ' ', __FILE__, __LINE__, $lineNum, qq{"$line"};
                    if ( $line =~ m/\A [\n ]* \z/xms ) {
                        $recce->lexeme_alternative( $terminal, $line );

                  # anything in this tier terminates the finding of alternatives
                        push @mistakes, [ 'vgap-blank-line', $lineNum ];
                        last FIND_ALTERNATIVES;
                    }
                }
                if ( $terminal eq 'BadComment' ) {
                    if ( $line =~ m/^ [ ]* ([+][|]|[:][:]|[:][<]|[:][>]) /x ) {
                        $recce->lexeme_alternative( $terminal, $line );
                        my $commentOffset = $LAST_MATCH_START[1];

                        my $closestHiOffset;
                        my $closestLoOffset;

                        for my $failedOffset (@failedOffsets) {
                            if ( $failedOffset > $commentOffset ) {
                                if ( not defined $closestHiOffset
                                    or $failedOffset < $closestHiOffset )
                                {
                                    $closestHiOffset = $failedOffset;
                                }
                            }
                            if ( $failedOffset < $commentOffset ) {
                                if ( not defined $closestLoOffset
                                    or $failedOffset > $closestLoOffset )
                                {
                                    $closestLoOffset = $failedOffset;
                                }
                            }
                        }
                        my $closestOffset =
                          ( $closestLoOffset // $closestHiOffset );

# say STDERR join ' ', __LINE__, 'vgap-bad-comment', $lineNum, $commentOffset, $closestOffset ;
                        push @mistakes,
                          [
                            'vgap-bad-comment', $lineNum,
                            $commentOffset,     $closestOffset
                          ];

                  # anything in this tier terminates the finding of alternatives
                        last FIND_ALTERNATIVES;
                    }
                }
            }

        }
        my $startPos = $lineToPos->[$lineNum];

        # say STDERR join ' ', __FILE__, __LINE__;
        my $eval_ok = eval {
            $recce->lexeme_complete( $startPos,
                ( $lineToPos->[ $lineNum + 1 ] - $startPos ) );
            1;
        };
        if ( not $eval_ok ) {

            my $eval_error = $EVAL_ERROR;
            chomp $eval_error;

            # say STDERR join ' ', __FILE__, __LINE__, "$firstLine-$lastLine",
            # qq{"$input"};
            die $eval_error, "\n";
        }
    }
    my $metric = $recce->ambiguity_metric();
    if ( $metric != 1 ) {
        my $issue = $metric ? "ambiguous" : "no parse";
        say STDERR $recce->show_progress( 0, -1 );
        say STDERR $input;

# say STDERR join " ", __FILE__, __LINE__,  $policy, $firstLine, $lastLine, $interOffset, $preOffset;
        die "Bad gap combinator parse: $issue\n";
    }
    return \@mistakes;
}

# TODO: refactor all pseudojoins to call the
# checkPseudojoin() method.

# If a pseudo-join,
# return a (possible empty) list of mistakes.
# Otherwise, return undef.
sub checkPseudojoin {
    my ( $policy, $gap, $options ) = @_;
    my $instance  = $policy->{lint};
        # say STDERR '[' . $instance->literalNode($gap) . ']';
    my @mistakes = ();

    # Assume that the gap is not the top of the tree.
    my $parent = $gap->{PARENT};
    my ( $parentLine, $parentColumn ) = $instance->nodeLC($parent);

    my $expected = $options->{lengths};
    my $desc            = $options->{desc};
    my $details         = $options->{details};
    my $runeName        = $options->{runeName} // $policy->runeName($parent);
    my $subpolicy       = $options->{subpolicy} // [$runeName];

    # say STDERR Data::Dumper::Dumper($options);

    my $gapLength = $gap->{length};
    my ( $gapLine, $gapColumn ) = $instance->nodeLC($gap);
    my $nextLexemeOffset = $gap->{start} + $gapLength;
    if ($instance->runeGapNode($gap)) {
       $gapColumn += 2;
       $gapLength -= 2;
    }
    my ( $nextLexemeLine, $nextLexemeColumn ) =
      $instance->line_column( $nextLexemeOffset );

    if ( not $expected ) {

        # default is to be tightly aligned
        $expected = [['tight', 2, 1]];
    }

    my @expectedColumns = ();
  LENGTH: for my $expectedItem ( @{$expected} ) {
        my ($alignDesc, $column, $isLength ) = @{$expectedItem};
        # say STDERR "alignDesc, column, isLength; $alignDesc, $column, $isLength ";
        # say STDERR "gap L,C: $gapLine, $gapColumn";
        $column += $gapColumn if $isLength;
        # say STDERR "alignDesc, column, isLength; $alignDesc, $column, $isLength ";
        push @expectedColumns, [ $alignDesc, $column ];
    }

    # If here, we are checking for pseudojoin
    my $pseudojoinColumn = $policy->pseudojoinColumn($gap);
    # say STDERR "pseudojoinColumn ", Data::Dumper::Dumper($pseudojoinColumn);

    # Return undef to show vertical gap is not a pseudojoin
    return if not defined $pseudojoinColumn;
    return if $pseudojoinColumn < 0;

    # Pseudojoin of desired length
    my $isPseudojoin;
    TEST_FOR_PSEUDOJOIN: for my $expectedColumnItem (@expectedColumns) {
        my ($alignDesc, $alignColumn) = @{$expectedColumnItem};
        # say STDERR "pseudojoinColumn alignColumn; $pseudojoinColumn, $alignColumn";
        if ($pseudojoinColumn == $alignColumn) {
            $isPseudojoin = 1;
            last TEST_FOR_PSEUDOJOIN;
        }
    }

    return if not $isPseudojoin;

    return [] if $nextLexemeColumn == $pseudojoinColumn;

    # If here, it is a problematic pseudojoin
    my $msg = sprintf
      '%s %s; %s',
      $desc,
      describeLC( $nextLexemeLine, $nextLexemeColumn ),
      describeMisindent2( $nextLexemeColumn, $pseudojoinColumn );
    push @mistakes, {
        desc         => $msg,
        subpolicy    => [ @{$subpolicy}, 'pseudojoin' ],
        line         => $nextLexemeLine,
        column       => $nextLexemeColumn,
        reportLine   => $nextLexemeLine,
        reportColumn => $nextLexemeColumn,
        topicLines   => [$parentLine],
        details      => $details,
    };

    return \@mistakes;
}

# Replace all TISTIS logic with this
sub checkTistis {
    my ( $policy, $tistis, $options ) = @_;
    my $expectedColumn = $options->{expectedColumn};
    my $tag            = $options->{tag};
    my $instance       = $policy->{lint};
    my $parent         = $tistis->{PARENT};
    my @mistakes = ();

    # TODO: Delete after development
    die if defined $options->{subpolicyTag};

    my @subpolicy = ();
    SET_SUBPOLICY: {
        my $subpolicy = $options->{subpolicy};
        if (defined $subpolicy) {
            push @subpolicy, @{$subpolicy};
            last SET_SUBPOLICY;
        }
        push @subpolicy, $policy->nodeSubpolicy($parent);
    }

    my ( $parentLine, $parentColumn ) = $instance->nodeLC($parent);
    my ( $tistisLine, $tistisColumn ) = $instance->nodeLC($tistis);
    my $literalLine = $instance->literalLine($tistisLine);

    my $runeName = $policy->runeName($parent);

    $literalLine = $policy->deComment($literalLine);
    $literalLine =~ s/\n//g;
    $literalLine =~ s/==//g;
    if ( $literalLine =~ m/[^ ]/ ) {
        my $runeLC = describeLC($parentLine, $parentColumn);
        my $msg =
          sprintf q{TISTIS %s should only share line with other TISTIS's},
          describeLC( $tistisLine, $tistisColumn );
        push @mistakes,
          {
            desc         => $msg,
            subpolicy      => [ @subpolicy, 'tistis-alone' ],
            parentLine   => $parentLine,
            parentColumn => $parentColumn,
            line         => $tistisLine,
            column       => $tistisColumn,
            reportLine         => $tistisLine,
            reportColumn       => $tistisColumn,
            details        => [ ["Starts at $runeLC"] ],
          };
        return \@mistakes;
    }

    my $tistisIsMisaligned = $tistisColumn != $expectedColumn;

    if ($tistisIsMisaligned) {
        my $lineToPos     = $instance->{lineToPos};
        my $tistisPos     = $lineToPos->[$tistisLine] + $expectedColumn;
        my $tistisLiteral = $instance->literal( $tistisPos, 2 );

        $tistisIsMisaligned = $tistisLiteral ne '==';
    }
    if ($tistisIsMisaligned) {
        my $runeLC = describeLC($parentLine, $parentColumn);
        my $msg = sprintf 'TISTIS %s; %s',
          describeLC( $tistisLine, $tistisColumn ),
          describeMisindent2( $tistisColumn, $expectedColumn );
        push @mistakes,
          {
            desc           => $msg,
            subpolicy      => [ @subpolicy, 'tistis-indent' ],
            parentLine     => $parentLine,
            parentColumn   => $parentColumn,
            line           => $tistisLine,
            column         => $tistisColumn,
            reportLine         => $tistisLine,
            reportColumn       => $tistisColumn,
            details        => [ ["Starts at $runeLC"] ],
          };
    }

    return \@mistakes;
}

# SIGGAR/SIGGAL "hints"
sub checkBont {
    my ( $policy, $node ) = @_;
    my $instance = $policy->{lint};

    # bont5d ::= CEN4H SYM4K (- DOT GAP -) tall5d
    # bont5d ::= wideBont5d
    my ( $cen, $sym, $dot, $gap, $body ) = @{ $node->{children} };
    return if not defined $gap;

    my ( $parentLine, $parentColumn ) = $instance->nodeLC($node);
    my ( $bodyLine,   $bodyColumn )   = $instance->nodeLC($body);

    # Hint's are an integral part of SIGGAR/SIGGAL which follow a
    # basically standard backdenting scheme, so this is not really
    # "re-anchoring".
    my $anchor =
      $instance->ancestorByLHS( $node, { tallSiggar => 1, tallSiggal => 1 } );
    my ( $anchorLine, $anchorColumn ) = $instance->nodeLC($anchor);
    my $runeName = $policy->runeName($anchor);

    my @mistakes = ();

  BODY_ISSUES: {
        if ( $parentLine == $bodyLine ) {
            my $msg =
              sprintf 'SIGGAR/SIGGAL hint body must not be on rune line',
              describeLC( $bodyLine, $bodyColumn );
            push @mistakes,
              {
                desc         => $msg,
                subpolicy    => [ $runeName, 'hint-body-joined' ],
                parentLine   => $parentLine,
                parentColumn => $parentColumn,
                line         => $bodyLine,
                column       => $bodyColumn,
                reportLine   => $bodyLine,
                reportColumn => $bodyColumn,
              };
            last BODY_ISSUES;
        }

        # If here parent line != body line
        my $expectedBodyColumn = $anchorColumn + 4;
        push @mistakes,
          @{
            $policy->checkOneLineGap(
                $gap,
                {
                    mainColumn => $expectedBodyColumn,
                    subpolicy  => [ $runeName, 'hint' ],
                    runeName        => $runeName,
                    subpolicy  => [$runeName],
                }
            )
          };

        if ( $bodyColumn != $expectedBodyColumn ) {
            my $msg =
              sprintf 'SIGGAL/SIGGAR hint body %s; %s',
              describeLC( $bodyLine, $bodyColumn ),
              describeMisindent2( $bodyColumn, $expectedBodyColumn );
            push @mistakes,
              {
                desc         => $msg,
                subpolicy    => [ $runeName, 'hint-body-indent' ],
                parentLine   => $parentLine,
                parentColumn => $parentColumn,
                line         => $bodyLine,
                column       => $bodyColumn,
                reportLine   => $bodyLine,
                reportColumn => $bodyColumn,
              };
        }
    }

    return \@mistakes;
}

# bonz5d ::= (- TIS TIS GAP -) optBonzElements (- GAP TIS TIS -)
# bonz5d ::= wideBonz5d
sub checkBonz5d {
    my ( $policy, $node ) = @_;
    my $instance = $policy->{lint};

    my ($initialTis1, undef, $gap, $bonzElements, $tistisGap, $finalTistis) = @{$node->{children}};
    return [] if not defined $gap;
    my $runeName = 'sigcen';
    my ( $parentLine, $parentColumn ) = $instance->nodeLC($node);
    my ( $elementsLine, $elementsColumn ) = $instance->nodeLC($bonzElements);
    my ( $tistisLine, $tistisColumn ) = $instance->nodeLC($finalTistis);
    my $anchorColumn = $parentColumn;
    my $expectedElementsColumn = $anchorColumn + 2;

    my @mistakes = ();
    push @mistakes,
      @{
        $policy->checkOneLineGap(
            $gap,
            {
                mainColumn => $anchorColumn,
                preColumn => $elementsColumn,
                runeName        => $runeName,
                subpolicy => [ $runeName, 'formulas-initial-vgap' ],
            }
        )
      };

    if ( $expectedElementsColumn != $elementsColumn ) {

        my $msg = sprintf 'formula %s; %s',
          describeLC( $elementsLine, $elementsColumn ),
          describeMisindent2( $elementsColumn, $expectedElementsColumn );
        push @mistakes,
          {
            desc         => $msg,
            subpolicy    => [ $runeName, 'formula-body-indent' ],
            parentLine   => $parentLine,
            parentColumn => $parentColumn,
            line         => $elementsLine,
            column       => $elementsColumn,
            reportLine   => $elementsLine,
            reportColumn => $elementsColumn,
          };
    }

    push @mistakes,
      @{
        $policy->checkOneLineGap(
            $tistisGap,
            {
                mainColumn => $anchorColumn,
                preColumn => $elementsColumn,
                runeName        => $runeName,
                subpolicy => [ $runeName, 'formulas-final-gap' ],
                topicLines => [$tistisLine],
            }
        )
      };

    push @mistakes,
      @{
        $policy->checkTistis(
            $finalTistis,
            {
                expectedColumn => $anchorColumn,
                tag            => $runeName,
                subpolicy => [ $runeName, 'formulas-final-tistis' ],
            }
        )
      };

  return \@mistakes;

}

# optBonzElements ::= bonzElement* separator=>GAP proper=>1
# bonzElement ::= CEN SYM4K (- GAP -) tall5d
sub checkBonzElements {
    my ( $policy, $node ) = @_;
    my $children = $node->{children};
    my @nodesToAlign = ();
    for (my $childIX = 0; $childIX <= $#$children; $childIX += 2) {
        my $element = $children->[$childIX];
        my ($cen, $sym, $gap, $body) = @{ $element->{children} };
        push @nodesToAlign, $gap, $body;
    }
    my $alignmentData = $policy->findAlignment( \@nodesToAlign );
    $policy->setInheritedAttribute($node, 'formulaAlignmentData', $alignmentData);
    return $policy->checkSeq( $node, 'sigcen-formula' );
}

sub checkBonzElement {
    my ( $policy, $node ) = @_;
    my $instance = $policy->{lint};

    # bonzElement ::= CEN SYM4K (- GAP -) tall5d
    my ( $bodyGap, $body ) = @{ $policy->gapSeq0($node) };

    my ( $parentLine, $parentColumn ) = $instance->nodeLC($node);
    my ( $bodyLine,   $bodyColumn )   = $instance->nodeLC($body);

    my $alignmentData = $policy->getInheritedAttribute($node, 'formulaAlignmentData');
    my $bodyAlignmentColumn = @{$alignmentData};

    my @mistakes = ();
    my $runeName      = 'sigcen';

  BODY_ISSUES: {
        if ( $parentLine != $bodyLine ) {
            my $msg = sprintf 'formula body %s; must be on rune line',
              describeLC( $bodyLine, $bodyColumn );
            push @mistakes,
              {
                desc         => $msg,
                subpolicy => [ $runeName, 'formula-split' ],
                parentLine   => $parentLine,
                parentColumn => $parentColumn,
                line         => $bodyLine,
                column       => $bodyColumn,
                reportLine   => $bodyLine,
                reportColumn => $bodyColumn,
              };
            last BODY_ISSUES;
        }

        # If here, bodyLine == parentLine
        last BODY_ISSUES if $bodyColumn = $bodyAlignmentColumn;
        my $gapLiteral = $instance->literalNode($bodyGap);
        my $gapLength  = $bodyGap->{length};
        last BODY_ISSUES if $gapLength == 2;
        my ( undef, $bodyGapColumn ) = $instance->nodeLC($bodyGap);

        my $msg = sprintf 'formula body %s; %s',
          describeLC( $bodyLine, $bodyColumn ),
          describeMisindent2( $gapLength, 2 );
        push @mistakes,
          {
            desc         => $msg,
            subpolicy => [ $runeName, 'formula-body-indent' ],
            parentLine   => $parentLine,
            parentColumn => $parentColumn,
            line         => $bodyLine,
            column       => $bodyColumn,
            reportLine   => $bodyLine,
            reportColumn => $bodyColumn,
          };
    }

    return \@mistakes;
}

# assumes this is a <tallAttributes> node
sub sailAttributeBodyAlignment {
    my ( $policy, $node ) = @_;
    my $instance = $policy->{lint};
    my $children = $node->{children};
    my $firstBodyColumn;
    my %firstLine       = ();
    my %bodyColumnCount = ();
    my @nodesToAlign = ();

    # Traverse first to last to make it easy to record
    # first line of occurrence of each body column
  CHILD:
    for ( my $childIX = $#$children ; $childIX >= 0 ; $childIX-- ) {
        my $attribute = $children->[$childIX];
        my ( undef, $head, $gap, $body ) = @{ $policy->gapSeq0($attribute) };
        my ( $headLine, $headColumn ) = $instance->nodeLC($head);
        my ( $bodyLine, $bodyColumn ) = $instance->nodeLC($body);
        next CHILD if $headLine != $bodyLine;
        push @nodesToAlign, $gap, $body;
    }
    return $policy->findAlignment( \@nodesToAlign );
}

sub checkSailAttribute {
    my ( $policy, $node ) = @_;
    my $instance = $policy->{lint};

    my ( $headGap, $head, $bodyGap, $body ) = @{ $policy->gapSeq0($node) };

    my ( $headLine, $headColumn ) = $instance->nodeLC($head);
    my ( $bodyLine, $bodyColumn ) = $instance->nodeLC($body);

    my $sailApex = $instance->ancestorByLHS( $node, { sailApex5d => 1 } );
    my ( $sailApexLine, $sailApexColumn ) = $instance->nodeLC($sailApex);
    my $attributes = $instance->ancestorByLHS( $node, { tallAttributes => 1 } );
    my $expectedHeadColumn = $sailApexColumn + 4;
    my ($expectedBodyColumn, $expectBodyColumnDetails) = @{$policy->sailAttributeBodyAlignment($attributes)};

    my @mistakes = ();

    # Not really a rune name
    my $runeName      = 'sail';

    # We deal with the elements list in its own node

    push @mistakes,
      @{
        $policy->checkOneLineGap(
            $headGap,
            {
                mainColumn => $expectedHeadColumn,
                runeName        => $runeName,
                subpolicy => [ $runeName, 'head-vgap' ],
                topicLines => [$headLine],
            }
        )
      };

    if ( $headColumn != $expectedHeadColumn ) {
        my $msg = sprintf
          "Sail attribute head %s; %s",
          describeLC( $headLine, $headColumn ),
          describeMisindent2( $headColumn, $expectedHeadColumn );
        push @mistakes,
          {
            desc           => $msg,
            subpolicy => [ $runeName, 'head-indent' ],
            parentLine     => $sailApexLine,
            parentColumn   => $sailApexColumn,
            line           => $headLine,
            column         => $headColumn,
                    reportLine         => $headLine,
                    reportColumn       => $headColumn,
            topicLines     => [$headLine],
          };
    }

  CHECK_BODY: {
        if ( $headLine != $bodyLine ) {
            my $msg = sprintf
              "Sail split attribute NYI %s",
              describeLC( $headLine, $headColumn );
            push @mistakes,
              {
                desc         => $msg,
                subpolicy => [ $runeName, 'split-sail' ],
                parentLine   => $sailApexLine,
                parentColumn => $sailApexColumn,
                line         => $headLine,
                column       => $headColumn,
                    reportLine         => $headLine,
                    reportColumn       => $headColumn,
                topicLines   => [$headLine],
              };
            last CHECK_BODY;
        }

        my $bodyGapLength = $bodyGap->{length};
      CHECK_GAP: {
            last CHECK_GAP if $bodyGapLength == 2;
            if ( $expectedBodyColumn < 0 ) {
                my $msg = sprintf
                  "Sail attribute body %s; %s",
                  describeLC( $bodyLine, $bodyColumn ),
                  describeMisindent2( $bodyGapLength, 2 );
                push @mistakes,
                  {
                    desc         => $msg,
                    subpolicy => [ $runeName, 'body-tight-indent' ],
                    parentLine   => $sailApexLine,
                    parentColumn => $sailApexColumn,
                    line         => $bodyLine,
                    column       => $bodyColumn,
                    reportLine         => $bodyLine,
                    reportColumn       => $bodyColumn,
                    topicLines   => [$bodyLine],
                  };
                last CHECK_GAP;
            }
            if ( $bodyColumn != $expectedBodyColumn ) {
                my $msg = sprintf
                  "Sail attribute body %s; %s",
                  describeLC( $bodyLine, $bodyColumn ),
                  describeMisindent2( $bodyColumn, $expectedBodyColumn );
                push @mistakes,
                  {
                    desc         => $msg,
                    subpolicy => [ $runeName, 'body-align-indent' ],
                    parentLine   => $sailApexLine,
                    parentColumn => $sailApexColumn,
                    line         => $bodyLine,
                    column       => $bodyColumn,
                    reportLine         => $bodyLine,
                    reportColumn       => $bodyColumn,
                    topicLines   => [$bodyLine],
                  };
            }
        }
    }

    return \@mistakes;
}

# tagged sail statement
sub checkTailOfElem {
    my ( $policy, $node ) = @_;
    my $instance  = $policy->{lint};
    my $lineToPos = $instance->{lineToPos};

    my ( $tallKids, $tistisGap, $tistis ) = @{ $node->{children} };
    return [] if $instance->symbol($tallKids) ne 'tallKidsOfElem';

    my $tallTopSail = $instance->ancestor( $node, 2 );
    my ( $tallTopSailLine, $tallTopSailColumn ) =
      $instance->nodeLC($tallTopSail);
    my ( $parentLine, $parentColumn ) = $instance->nodeLC($node);
    my ( $tistisLine, $tistisColumn ) = $instance->nodeLC($tistis);
    my $anchorColumn = $policy->getInheritedAttribute($node, 'sailAnchorColumn');

    # There is always a SEM before <tallTopSail> and this is our
    # anchor column

    my @mistakes = ();
    my $runeName      = 'sail';

    my $elementColumn = $anchorColumn + 2;

    push @mistakes,
      @{
        $policy->checkOneLineGap(
            $tistisGap,
            {
                mainColumn => $anchorColumn,
                preColumn => $elementColumn,
                runeName        => $runeName,
                subpolicy => [ $runeName, 'elem-tail' ],
                topicLines => [$tistisLine],
            }
        )
      };

    push @mistakes,
      @{
        $policy->checkTistis(
            $tistis,
            {
                tag            => $runeName,
                subpolicy => [ $runeName, 'elem-tail' ],
                expectedColumn => $anchorColumn,
            }
        )
      };

    return \@mistakes;
}

sub isTopKidsJoined {
    my ( $policy, $topKids ) = @_;
    my $instance  = $policy->{lint};
    my ($gapSem, $tallTopKidSeq) = @{ $topKids->{children} };
    my ( $topKidsLine ) = $instance->nodeLC($topKids);
    my ( $bodyLine )   = $instance->nodeLC($tallTopKidSeq);
    return $topKidsLine == $bodyLine;
}

# tallTailOfTop ::= tallKidsOfTop (- GAP TIS TIS -)
sub checkTailOfTop {
    my ( $policy, $node ) = @_;
    my $instance  = $policy->{lint};

    my ( $topKids, $tistisGap, $tistis ) = @{ $node->{children} };

    my ( $parentLine, $parentColumn ) = $instance->nodeLC($node);
    my ( $tistisLine, $tistisColumn ) = $instance->nodeLC($tistis);
    my $anchorColumn = $policy->getInheritedAttribute($node, 'sailAnchorColumn');
    my $isJoined = $policy->isTopKidsJoined($topKids);
    my $kidColumn  = $isJoined ? $anchorColumn + 4 : $anchorColumn + 2;

    my @mistakes = ();
    my $runeName = 'sail';

    push @mistakes,
      @{
        $policy->checkOneLineGap(
            $tistisGap,
            {
                mainColumn => $anchorColumn,
                preColumn => $kidColumn,
                subpolicy  => [ $runeName, 'top-tail' ],
                runeName        => $runeName,
                topicLines => [$tistisLine],
            }
        )
      };

    push @mistakes,
      @{
        $policy->checkTistis(
            $tistis,
            {
                tag            => $runeName,
                subpolicy      => [ $runeName, 'top-tail' ],
                expectedColumn => $anchorColumn,
            }
        )
      };

    return \@mistakes;
}

# Deals with SEMHEP (;-), SEMLUS (;+), SEMTAR (;*), and SEMCEN (;%).
sub checkTopSail {
    my ( $policy, $node ) = @_;
    my $instance = $policy->{lint};
    my $grammar  = $instance->{grammar};
    my $ruleID   = $node->{ruleID};
    my ( $parentLine, $parentColumn ) = $instance->nodeLC($node);

    $policy->setInheritedAttribute($node, 'sailAnchorColumn', $parentColumn - 1);

    # say STDERR "top sail:", '[' . $instance->literalNode($node) . ']';
    my ($tunaMode, $bodyGap, $body) = @{$node->{children}};
    # Note: GAP before CRAM is treated as free-form
    return [] if $instance->symbol($tunaMode) ne 'tunaMode';

    my ( $bodyLine,   $bodyColumn )   = $instance->nodeLC($body);

    my @mistakes = ();

    my $runeName = 'sail';

    my $expectedColumn;

  BODY_ISSUES: {
        if ( $parentLine != $bodyLine ) {
            my $msg = join " ",
              (
                sprintf 'Top sail body %s; must be on rune line',
                describeLC( $bodyLine, $bodyColumn )
              ),
              ( map { $grammar->symbol_display_form($_) }
                  $grammar->rule_expand($ruleID) );
            push @mistakes,
              {
                desc         => $msg,
                subpolicy => [ $runeName, 'top-sail', 'split' ],
                parentLine   => $parentLine,
                parentColumn => $parentColumn,
                line         => $bodyLine,
                column       => $bodyColumn,
                reportLine         => $bodyLine,
                reportColumn       => $bodyColumn,
              };
            last BODY_ISSUES;
        }

        # If here, bodyLine == parentLine
        my $gapLiteral = $instance->literalNode($bodyGap);
        my $gapLength  = $bodyGap->{length};
        last BODY_ISSUES if $gapLength == 2;

        my $msg = sprintf 'sail runechild %s; %s',
          describeLC( $bodyLine, $bodyColumn ),
          describeMisindent2( $gapLength, 2 );
        push @mistakes,
          {
            desc           => $msg,
                subpolicy => [ $runeName, 'top-sail', 'indent' ],
            parentLine     => $parentLine,
            parentColumn   => $parentColumn,
            line           => $bodyLine,
            column         => $bodyColumn,
                reportLine         => $bodyLine,
                reportColumn       => $bodyColumn,
          };
    }

    return \@mistakes;
}

sub checkTopKids {
    my ( $policy, $node ) = @_;
    my $instance = $policy->{lint};
    my $grammar  = $instance->{grammar};
    my $ruleID   = $node->{ruleID};

    my $children        = $node->{children};
    my ($gapSem, $tallTopKidSeq) = @{$children};
    return [] if $instance->symbol($tallTopKidSeq) eq 'CRAM';
    # Note: GAP before CRAM is treated as free-form

    my $anchorColumn = $policy->getInheritedAttribute($node, 'sailAnchorColumn');
    my ( $parentLine, $parentColumn ) = $instance->nodeLC($node);
    my ( $bodyLine,   $bodyColumn )   = $instance->nodeLC($tallTopKidSeq);
    $bodyColumn -= 1; # adjust for SEM in GAP_SEM

    my @mistakes = ();

    my $runeName = 'sail';
    my $isJoined = $parentLine == $bodyLine;
    my $expectedBodyColumn = $isJoined ? $anchorColumn + 4 : $anchorColumn + 2;
    my $topSail = $instance->ancestorByLHS( $node, { tallTopSail => 1 } );
    $policy->setInheritedAttribute($topSail, 'sailIsJoined', $isJoined);

  FIRST_KID_ISSUES: {
        if ( not $isJoined ) {
            push @mistakes,
              @{
                $policy->checkOneLineGap(
                    $gapSem,
                    {
                        mainColumn => $anchorColumn,
                        preColumn  => $expectedBodyColumn,
                        runeName        => $runeName,
                        subpolicy  => [$runeName],
                        details    => [
                            [
                                ( sprintf 'sail elem kid #1' ),
                                'inter-comment indent should be '
                                  . ( $anchorColumn + 1 ),
                                'pre-comment indent should be '
                                  . ( $expectedBodyColumn + 1 ),
                            ]
                        ],
                    }
                )
              };

            if ( $expectedBodyColumn != $bodyColumn ) {
                my $msg = sprintf 'Sail elem kid #1 body %s; %s',
                  describeLC( $bodyLine, $bodyColumn ),
                  describeMisindent2( $bodyColumn, $expectedBodyColumn );
                push @mistakes,
                  {
                    desc         => $msg,
                    subpolicy    => [ $runeName, 'elem-kids', 'body-indent' ],
                    parentLine   => $parentLine,
                    parentColumn => $parentColumn,
                    line         => $bodyLine,
                    column       => $bodyColumn,
                    reportLine   => $bodyLine,
                    reportColumn => $bodyColumn,
                  };
            }
            last FIRST_KID_ISSUES;
        }

        # If here, bodyLine == parentLine
        my $gapLiteral = $instance->literalNode($gapSem);
        my $gapLength  = $gapSem->{length};
        last FIRST_KID_ISSUES if $gapLength == 3; # length is 3 to allow for SEM in GAP_SEM
        my ( undef, $gapSemColumn ) = $instance->nodeLC($gapSem);

        my $msg = sprintf 'Sail kids body %s; %s',
          describeLC( $bodyLine, $bodyColumn ),
          describeMisindent2( $gapLength, 2 );
        push @mistakes,
          {
            desc         => $msg,
            subpolicy    => [ $runeName, 'top-kids', 'body-indent' ],
            parentLine   => $parentLine,
            parentColumn => $parentColumn,
            line         => $bodyLine,
            column       => $bodyColumn,
            reportLine   => $bodyLine,
            reportColumn => $bodyColumn,
          };
    }

    # tallTopKidSeq  ::= tallTopSail+ separator=>GAP_SEM proper=>1
    my $kids = $tallTopKidSeq->{children};
    # say STDERR join " ", __FILE__, __LINE__, $instance->symbol($tallTopKidSeq),
        # describeLC($instance->nodeLC($node));
    # say STDERR join " ", __FILE__, __LINE__, $instance->symbol($tallTopKidSeq),
      # "top kids:", ( scalar @{$kids} );
    my $childIX = 0;
    KID: for (my $childIX = 1; $childIX + 1 <= $#$kids; $childIX+=2) {
        my $kidGap = $kids->[$childIX];
        my $kid = $kids->[$childIX+1];
        my ( $kidLine, $kidColumn ) = $instance->nodeLC($kid);
        $kidColumn -= 1; # adjust for SEM in GAP_SEM

        my $kidNumber = ($childIX + 1)/2;
        # say STDERR join " ", __FILE__, __LINE__, 'kid of top [' . $instance->literalNode($kid) . ']';
            push @mistakes,
              @{
                $policy->checkOneLineGap(
                    $kidGap,
                    {
                        mainColumn => $anchorColumn,
                        preColumn  => $expectedBodyColumn,
                        runeName        => $runeName,
                        subpolicy  => [$runeName],
                        details    => [
                            [
                                ( sprintf 'sail elem kid #%d', $kidNumber),
                                'inter-comment indent should be '
                                  . ( $anchorColumn + 1 ),
                                'pre-comment indent should be '
                                  . ( $expectedBodyColumn + 1 ),
                            ]
                        ],
                    }
                )
              };

            if ( $expectedBodyColumn != $bodyColumn ) {
                my $msg = sprintf 'Sail elem kid #%d body %s; %s',
                  $kidNumber,
                  describeLC( $bodyLine, $bodyColumn ),
                  describeMisindent2( $bodyColumn, $expectedBodyColumn );
                push @mistakes,
                  {
                    desc         => $msg,
                    subpolicy    => [ $runeName, 'elem-kids', 'body-indent' ],
                    parentLine   => $parentLine,
                    parentColumn => $parentColumn,
                    line         => $kidLine,
                    column       => $kidColumn,
                    reportLine   => $kidLine,
                    reportColumn => $kidColumn,
                  };
            }
    }

    return \@mistakes;
}

sub checkElemKids {
    my ( $policy, $node ) = @_;
    my $instance = $policy->{lint};
    my $grammar  = $instance->{grammar};
    my $ruleID   = $node->{ruleID};

    my $children = $node->{children};
    my ( $gapSem, $tallElemKidSeq ) = @{$children};
    return [] if $instance->symbol($gapSem) ne 'GAP_SEM';

    my ( $bodyGap, $body ) = @{ $policy->gapSeq0($node) };

    my ( $parentLine, $parentColumn ) = $instance->nodeLC($node);
    my $anchorColumn = $policy->getInheritedAttribute($node, 'sailAnchorColumn');
    my ( $bodyLine,   $bodyColumn )   = $instance->nodeLC($body);

    my @mistakes = ();

    my $runeName = 'sail';

    # tallKidsOfElem ::= tallKidOfElem+
    # tallKidOfElem  ::= (- GAP_SEM -) tallTopSail
    my $kids = $tallElemKidSeq->{children};
    my $expectedKidColumn = $anchorColumn + 2;
  KID: for ( my $childIX = 0 ; $childIX + 1 <= $#$kids ; $childIX += 2 ) {
    # say STDERR join " ", __FILE__, __LINE__, $childIX;
        my $kidGap  = $kids->[$childIX];
        my $kidBody = $kids->[ $childIX + 1 ];
        my ( $kidBodyLine, $kidBodyColumn ) = $instance->nodeLC($kidBody);
        $kidBodyColumn -= 1; # Adjust for SEM in GAP_SEM

# say STDERR join " ", __FILE__, __LINE__, "kidBodyColumn: $kidBodyColumn";
# say STDERR join " ", __FILE__, __LINE__, "anchorColumn: $anchorColumn";
# say STDERR join " ", __FILE__, __LINE__, "$childIX: [" . $instance->symbol($kidBody) . ']';
# say STDERR join " ", __FILE__, __LINE__, "$childIX: [" . $instance->literalNode($kidBody) . ']';

        push @mistakes,
          @{
            $policy->checkOneLineGap(
                $kidGap,
                {
                    mainColumn => $anchorColumn,
                    preColumn  => $expectedKidColumn,
                    runeName        => $runeName,
                    subpolicy  => [$runeName],
                    details    => [
                        [
                            ( sprintf 'sail elem kid #%d', $childIX ),
                            'inter-comment indent should be '
                              . ( $anchorColumn + 1 ),
                            'pre-comment indent should be '
                              . ( $kidBodyColumn + 1 ),
                        ]
                    ],
                }
            )
          };

        if ( $expectedKidColumn != $kidBodyColumn ) {
            my $msg = sprintf 'Sail elem kid #%d body %s; %s',
              $childIX,
              describeLC( $kidBodyLine, $kidBodyColumn ),
              describeMisindent2( $kidBodyColumn, $expectedKidColumn );
            push @mistakes,
              {
                desc         => $msg,
                subpolicy    => [ $runeName, 'elem-kids', 'body-indent' ],
                parentLine   => $parentLine,
                parentColumn => $parentColumn,
                line         => $kidBodyLine,
                column       => $kidBodyColumn,
                reportLine   => $kidBodyLine,
                reportColumn => $kidBodyColumn,
              };
        }

    }

    return \@mistakes;
}

# Common logic for checking the running element of a hoon.
# returns a (possibly empty) list of mistakes.
#
# TODO: Some of these arguments can (should?) be computed from others.
#
sub checkRunning {
    my ( $policy, $options ) = @_;
    my $instance        = $policy->{lint};
    my $runningChildren = $options->{children};
    my $anchorColumn    = $options->{anchorColumn};
    my $expectedColumn  = $options->{expectedColumn};
    my $pseudojoin  = $options->{pseudojoin};

    my @subpolicy = ();
    my $subpolicy = $options->{subpolicy};
    push @subpolicy, @{$subpolicy} if defined $subpolicy;

    # by default, in fact always at this point, the running can be
    # found as the parent of the last running child, and the parent
    # can be found as the parent
    my $running = $runningChildren->[-1]->{PARENT};
    my $parent  = $running->{PARENT};

    my ( $runeLine,    $runeColumn )    = $instance->nodeLC($parent);
    my ( $runningLine, $runningColumn ) = $instance->nodeLC($running);

    my $anchorDetails = $options->{anchorDetails}
      // $policy->anchorDetailsBasic( $parent, $anchorColumn );

    my $runeName = $policy->runeName($parent);
    my @mistakes         = ();

    my $skipFirst = $options->{skipFirst};
    my $childIX = $skipFirst ? 3 : 2;

    # Call an column of runsteps with the same row
    # position a "pile" because "column" and the other terms are
    # too overloaded.
    my @runStepsToAlignByPile = ();
  RUNNING_LINE: while (1) {

        # The index into the runstep alignment array.
        # The alignment of the 2nd runstep
        # in a row (or line) is at index 0.
        my $pileIX = 0;
      RUNSTEP: while (1) {
            last RUNNING_LINE if $childIX + 1 > $#$runningChildren;
            my $gap       = $runningChildren->[$childIX];
            my $runStep   = $runningChildren->[ $childIX + 1 ];
            my ($gapLine) = $instance->nodeLC($gap);
            my ( $runStepLine, $runStepColumn ) = $instance->nodeLC($runStep);
            last RUNSTEP if $gapLine != $runStepLine;

            # Uses Perl's autoinstantiation
            push @{ $runStepsToAlignByPile[$pileIX] }, $gap, $runStep;
            $pileIX += 1;
            $childIX += 2;
        }

        # In this loop, childIX always points to a gap
        $childIX += 2;
    }

    my @pileAlignments = ();
  ELEMENT:
    for ( my $pileIX = 0 ; $pileIX <= $#runStepsToAlignByPile ; $pileIX++ ) {
        my $runStepsToAlign = $runStepsToAlignByPile[$pileIX];
        if ( not $runStepsToAlign ) {
            $pileAlignments[$pileIX] = [ -1, [] ];
            next ELEMENT;
        }
        $pileAlignments[$pileIX] =
          $policy->findAlignment($runStepsToAlign);
    }

    # If there are no alignments by runstep, then we check for
    # alignments among the running's children.
        my @nodesToAlignByElement;
  RUNNING_CHILD_ALIGNMENTS: {
        last RUNNING_CHILD_ALIGNMENTS if scalar @pileAlignments;
        my @bricks;
      RUNSTEP:
        for (
            my $runStepIX = ( $skipFirst ? 2 : 1 ) ;
            $runStepIX <= $#$runningChildren ;
            $runStepIX += 2
          )
        {
            my $runStep = $runningChildren->[$runStepIX];

            my $brickDescendant = $instance->brickDescendant($runStep);
            last RUNSTEP if not $brickDescendant;

              $instance->literalNode($brickDescendant);
            next RUNSTEP if not $policy->chainable($brickDescendant);

            push @bricks, $brickDescendant;
              $instance->literalNode($brickDescendant);
            my $gapSeq = $policy->gapSeq0($brickDescendant);
          BRICK_ELEMENT: for ( my $elementIX = 0 ; ; $elementIX++ ) {
                my $seqIX = $elementIX * 2;
                last BRICK_ELEMENT if $seqIX >= $#$gapSeq;
                my $gap     = $gapSeq->[$seqIX];
                my $element = $gapSeq->[ $seqIX + 1 ];
                push @{ $nodesToAlignByElement[$elementIX] }, $gap, $element;
            }
        }

        last RUNNING_CHILD_ALIGNMENTS unless scalar @nodesToAlignByElement;

        my @runStepChildAlignments = ();
      ELEMENT:
        for (
            my $elementIX = 0 ;
            $elementIX <= $#nodesToAlignByElement ;
            $elementIX++
          )
        {
            my $nodesToAlign = $nodesToAlignByElement[$elementIX];
            if ( not $nodesToAlign ) {
                $runStepChildAlignments[$elementIX] = [ -1, [] ];
                next ELEMENT;
            }
            $runStepChildAlignments[$elementIX] =
              $policy->findAlignment($nodesToAlign);
        }


        for my $brick (@bricks) {
            my $brickNodeIX = $brick->{IX};
            $policy->{perNode}->{$brickNodeIX}->{runningAlignments} =
             \@runStepChildAlignments;
        }

    }

    $childIX = 0;
    # Do the first run step
    my $gap          = $runningChildren->[$childIX];
    my ( $gapLine, $gapColumn ) = $instance->nodeLC($gap);
    my $runStep = $runningChildren->[ $childIX + 1 ];
    my ( $thisRunStepLine, $runStepColumn ) = $instance->nodeLC($runStep);

  my $runStepCount = 1;
  CHECK_FIRST_RUNNING: {
        last CHECK_FIRST_RUNNING if $skipFirst;
        last CHECK_FIRST_RUNNING if $runStepColumn == $expectedColumn;
        my @pseudojoin = ();
        push @pseudojoin, 'pseudojoin' if $pseudojoin;
        my $msg = sprintf
          "runstep #%d %s; %s",
          $runStepCount,
          describeLC( $thisRunStepLine, $runStepColumn ),
          describeMisindent2( $runStepColumn, $expectedColumn );
        push @mistakes,
          {
            desc           => $msg,
            subpolicy => [ @subpolicy, 'runstep-indent' ],
            parentLine     => $thisRunStepLine,
            parentColumn   => $runStepColumn,
            line           => $thisRunStepLine,
            column         => $runStepColumn,
            reportLine           => $thisRunStepLine,
            reportColumn         => $runStepColumn,
            topicLines     => [$runeLine],
            details        => [ [ @pseudojoin, @{$anchorDetails} ] ],
          };
    }

    my $workingRunStepLine = $thisRunStepLine;

    # Initial runsteps may be on a single line,
    # separated by one stop
    $childIX = 2;
    $runStepCount = 2;
  RUN_STEP: while ( $childIX < $#$runningChildren ) {

    my ( $thisRunStepLine, $runStepColumn ) ;

      INLINE_RUN_STEP: while (1) {
            if ( $childIX >= $#$runningChildren ) {
                last RUN_STEP;
            }
            $gap = $runningChildren->[$childIX];
            ( $gapLine, $gapColumn ) = $instance->nodeLC($gap);
            $runStep = $runningChildren->[ $childIX + 1 ];
            ( $thisRunStepLine, $runStepColumn ) = $instance->nodeLC($runStep);
            if ( $thisRunStepLine != $workingRunStepLine ) {
                last INLINE_RUN_STEP;
            }
            CHECK_COLUMN: {
            my $tightColumn = $gapColumn + 2;
            last CHECK_COLUMN if $runStepColumn == $tightColumn;
            my @allowedColumns =([ $tightColumn => 'tight' ]);

            my ( $pileAlignmentColumn, $pileAlignmentLines );
            my $thisAlignment = $pileAlignments[ $runStepCount - 2 ];
            if ($thisAlignment) {
                ( $pileAlignmentColumn, $pileAlignmentLines ) = @{$thisAlignment};
                last CHECK_COLUMN if $pileAlignmentColumn > $tightColumn
                  and $pileAlignmentColumn == $runStepColumn;
            }

            my $details;
            my @topicLines = ();
            if (defined $pileAlignmentColumn and $pileAlignmentColumn >= $tightColumn) {
                push @allowedColumns, [ $pileAlignmentColumn => 'runstep' ];
                my $oneBasedColumn = $pileAlignmentColumn + 1;
                my $pileAlignmentLines = $pileAlignmentLines;
                push @topicLines, @{$pileAlignmentLines};
                $details = [
                    [
                        sprintf 'runstep alignment is %d, see %s',
                        $oneBasedColumn,
                        (
                            join q{ },
                            map { $_ . ':' . $oneBasedColumn }
                              @{$pileAlignmentLines}
                        )
                    ]
                ];
            }
            else {
                $details = [ [ "no runstep alignment detected" ] ];
            }

            my @sortedColumns = sort { $a->[0] <=> $b->[0] } @allowedColumns;
            my $allowedDesc = join "; ",
              map { sprintf '@%d:%d (%s)', $thisRunStepLine, $_->[0]+1, $_->[1] } @sortedColumns;
            if (scalar @sortedColumns >= 2) {
               $allowedDesc = 'one of ' . $allowedDesc;
            }

            my $msg = sprintf
              'runstep #%d of running %s, line %d is at %s; should be %s',
              $runStepCount,
              describeLC( $runeLine, $runeColumn ),
              $thisRunStepLine,
              describeLC( $thisRunStepLine, $runStepColumn ),
              $allowedDesc;
            push @mistakes,
              {
                desc           => $msg,
                subpolicy      => [ @subpolicy, 'runstep-hgap' ],
                parentLine     => $runeLine,
                parentColumn   => $runeColumn,
                line           => $thisRunStepLine,
                column         => $runStepColumn,
                reportLine     => $thisRunStepLine,
                reportColumn   => $runStepColumn,
                topicLines => \@topicLines,
                details => $details,
              };
            }
            $childIX += 2;
            $runStepCount++;
        }

        $workingRunStepLine = $thisRunStepLine;

        # If the run step is mis-indented, complaints about the comments are
        # misleading and confusing.  Skip them.
        # TODO: Complain about blank lines anyway ?
        if ( $runStepColumn == $expectedColumn ) {
            push @mistakes,
              @{
                $policy->checkOneLineGap(
                    $gap,
                    {
                        mainColumn => $anchorColumn,
                        preColumn  => $runStepColumn,
                        runeName => $runeName,
                        subpolicy  => [ @subpolicy, 'runstep-vgap' ],
                        parent     => $runStep,
                        topicLines => [$runeLine],
                        details    => [
                            [
                                'inter-comment indent should be '
                                  . ( $anchorColumn + 1 ),
                                'pre-comment indent should be '
                                  . ( $expectedColumn + 1 ),
                                @{$anchorDetails},
                            ]
                        ],
                    }
                )
              };
        }

        if ( $runStepColumn != $expectedColumn ) {
            my $msg = sprintf
              "runstep #%d %s; %s",
              ( $childIX / 2 ) + 1,
              describeLC( $thisRunStepLine, $runStepColumn ),
              describeMisindent2( $runStepColumn, $expectedColumn );
            push @mistakes,
              {
                desc           => $msg,
                subpolicy => [ @subpolicy, 'runstep-indent' ],
                parentLine     => $thisRunStepLine,
                parentColumn   => $runStepColumn,
                line           => $thisRunStepLine,
                column         => $runStepColumn,
                reportLine           => $thisRunStepLine,
                reportColumn         => $runStepColumn,
                topicLines     => [$runeLine],
                details        => [ [ @{$anchorDetails} ] ],
              };
        }

        $childIX += 2;
        $runStepCount = 2;

    }

    return \@mistakes;

}

sub check_0Running {
    my ( $policy, $node ) = @_;
    my $instance = $policy->{lint};
    my ( $rune, $runningGap, $tistisGap, $tistis );
    my $runeName = $policy->runeName($node);
    my $runningChildren = [];
    my ( $runningLine, $runningColumn );
   {
        my $running;
        if ($runeName eq 'tissig') {
            my ( $firstRunstep, $firstRunningGap );
            ( $rune, $runningGap, $firstRunstep, $firstRunningGap, $running, $tistisGap, $tistis ) =
              @{ $policy->gapSeq($node) };
            push @{$runningChildren}, $runningGap, $firstRunstep, $firstRunningGap;
            ( $runningLine, $runningColumn ) = $instance->nodeLC($firstRunstep);
        } else {
            ( $rune, $runningGap, $running, $tistisGap, $tistis ) =
              @{ $policy->gapSeq($node) };
            push @{$runningChildren}, $runningGap;
            ( $runningLine, $runningColumn ) = $instance->nodeLC($running);
        }
        push @{$runningChildren}, @{ $running->{children} };
   }

    my ( $runeLine, $runeColumn ) = $instance->nodeLC($rune);
    my ( $anchorLine, $anchorColumn ) = ( $runeLine, $runeColumn );
    my $anchorData;
  CHECK_FOR_ANCHORING: {
        if ( $runeName eq 'colsig' ) {

            ( $anchorColumn, $anchorData ) = $policy->reanchorInc(
                $node,
                {
                    'tallCendot' => 1,
                    'tallCenhep' => 1,
                    'tallCenlus' => 1,
                    'tallCollus' => 1,
                    'tallKethep' => 1,
                    'tallTisfas' => 1,
                    'tallTisgar' => 1,
                }
            );
            last CHECK_FOR_ANCHORING;
        }
        if ( $runeName eq 'coltar' ) {

            # TODO: Cleanup after development
            ( $anchorColumn, $anchorData ) = $policy->reanchorInc(
                $node,
                {
                    'tallCenhep' => 1,
                }
            );
            last CHECK_FOR_ANCHORING;
        }
        if ( $runeName eq 'tissig' ) {
            ( $anchorColumn, $anchorData ) = $policy->reanchorInc(
                $node,
                {
                    'tallTisgar' => 1,
                    'tallWutlus' => 1,
                }
            );
            last CHECK_FOR_ANCHORING;
        }
    }
    my $anchorDetails;
    $anchorDetails = $policy->anchorDetails( $node, $anchorData )
      if $anchorData;

    # Arguments for the checking methods, called by this method.
    my $checkArgs = {
        node => $node,
        rune => $rune,
        runningGap => $runningGap,
        runningChildren => $runningChildren,
        tistisGap => $tistisGap,
        tistis => $tistis,
        runningLine => $runningLine,
        runningColumn => $runningColumn,
        runeName => $runeName,
        anchorLine => $anchorLine,
        anchorColumn => $anchorColumn,
        anchorDetails => $anchorDetails,
    };

    # What kind of gap?
    my $column = $policy->checkJoinGap($runningGap);

    # If column is undef, then hoon is not joined, it is split.
    return $policy->checkSplit_0Running( $checkArgs ) if not defined $column;

    # If column is -1, then hoon is joined.
    return $policy->checkJoined_0Running( $checkArgs, $column ) if $column == -1;

    # If here, it is a pseudo-join and $column is the column indicated
    # by gap.
    $checkArgs->{pseudojoin} = 1;

    # Treat it as a pseudo-join if $column matches the expected join colum
    return $policy->checkJoined_0Running( $checkArgs, $column )
      if $column == $runeColumn + 4;

    # If here the pseudo-join column is a mismatch: Treat the supposed
    # pseudo-join as an ordinary comment and the running as if it was
    # split.
    return $policy->checkSplit_0Running( $checkArgs );
}

# assumes this is a <wisp5d> node
# wisp5d ::= (- HEP HEP -)
# wisp5d ::= whap5d GAP (- HEP HEP -)
sub wispCellBodyAlignment {
    my ( $policy, $node ) = @_;
    my $instance = $policy->{lint};
    my ($whap) = @{ $node->{children} };
    return [ -1, [] ]
      if 'whap5d' ne $instance->symbol($whap);
    return $policy->whapCellBodyAlignment($whap);
}

# assumes this is a <whap5d> node
sub whapCellBodyAlignment {
    my ( $policy, $node ) = @_;
    my $instance = $policy->{lint};
    my $children = $node->{children};
    my @nodesToAlign = ();

  CHILD:
    for ( my $childIX = 0 ; $childIX <= $#$children ; $childIX += 2 ) {
        my $boog = $children->[$childIX];
        my $cell = $boog->{children}->[0];
        my ( undef, $head, $gap, $body ) = @{ $policy->gapSeq0($cell) };
        my ( $headLine ) = $instance->nodeLC($head);
        my ( $bodyLine ) = $instance->nodeLC($body);
        next CHILD unless $headLine == $bodyLine;
        # say STDERR sprintf q{Gap: "%s"}, $instance->literalNode($gap);
        # say STDERR sprintf q{Body: "%s"}, $instance->literalNode($body);
        push @nodesToAlign, $gap, $body;
    }
    return $policy->findAlignment( \@nodesToAlign );
}

sub checkWhap5d {
    my ( $policy, $node ) = @_;
    my $gapSeq           = $policy->gapSeq($node);
    my $instance         = $policy->{lint};

    my @mistakes = ();
    my $runeName = $policy->runeName($node);

    my $anchorNode = $instance->firstBrickOfLine($node);
    my ( $anchorLine, $anchorColumn ) = $instance->nodeLC($anchorNode);
    my ( $parentLine, $parentColumn ) = $instance->nodeLC($node);

    # The battery is "joined" iff it starts on the same line as the anchor,
    # but at a different column.  "Different column" to catch the case where
    # the anchor rune *is* the battery rune.
    my $joined =
      ( $anchorLine == $parentLine and $anchorColumn != $parentColumn );
    my $children       = $node->{children};
    my $childIX        = 0;
    my $expectedBoogColumn = $joined ? $parentColumn : $anchorColumn;
    my $expectedLine   = $joined ? $parentLine : $anchorLine + 1;

  CHILD: while ( $childIX <= $#$children ) {
        my $boog = $children->[$childIX];
        my ( $boogLine, $boogColumn ) = $instance->nodeLC($boog);

        if ( $boogColumn != $expectedBoogColumn ) {
            my $msg = sprintf
              "cell #%d %s; %s",
              ( $childIX / 2 ) + 1,
              describeLC( $boogLine, $boogColumn ),
              describeMisindent2( $boogColumn, $expectedBoogColumn );
            push @mistakes,
              {
                desc           => $msg,
                    subpolicy => [$runeName, 'arm-indent'],
                parentLine     => $boogLine,
                parentColumn   => $boogColumn,
                line           => $boogLine,
                column         => $boogColumn,
                reportLine           => $boogLine,
                reportColumn         => $boogColumn,
                topicLines     => [ $parentLine, $expectedLine ],
              };
        }

        $childIX++;
        last CHILD unless $childIX <= $#$children;
        my $boogGap = $children->[$childIX];
        my ( $boogGapLine, $boogGapColumn ) = $instance->nodeLC($boogGap);

        push @mistakes,
          @{
            $policy->checkOneLineGap(
                $boogGap,
                {
                    mainColumn => $expectedBoogColumn,
                    preColumn => $expectedBoogColumn+2,
                    runeName        => $runeName,
                    subpolicy => [$runeName, 'arm-vgap'],
                    topicLines => [ $parentLine, $boogGapLine ],
                }
            )
          };

        $childIX++;
    }

    return \@mistakes;

}

# wisp5d ::= (- HEP HEP -)
# wisp5d ::= whap5d GAP (- HEP HEP -)
sub checkWisp5d {
    my ( $policy, $node ) = @_;
    my @mistakes = ();
    my $instance = $policy->{lint};
    my $runeName = $policy->runeName($node);
    my ( $parentLine, $parentColumn ) = $instance->nodeLC($node);

    my $battery =
      $instance->ancestorByLHS( $node,
        { tallBarcab => 1, tallBarcen => 1, tallBarket => 1 } );
    my ( $batteryLine, $batteryColumn ) = $instance->nodeLC($battery);
    my $batteryLC = describeLC($batteryLine, $batteryColumn);

    my $anchorColumn  = $policy->getInheritedAttribute($node, 'anchorColumn');
    $anchorColumn //= $batteryColumn;

    my ( $cellBodyColumn, $cellBodyColumnLines ) =
      @{ $policy->getInheritedAttribute($node, 'cellBodyAlignmentData') };

    my ( $whap, $gap, $hep ) = @{$node->{children}};
    return [] if $instance->symbol($whap) ne 'whap5d';

    push @mistakes,
      @{
        $policy->checkOneLineGap(
            $gap,
            {
                mainColumn => $parentColumn,
                preColumn => $anchorColumn+2,
                runeName        => $runeName,
                subpolicy  => [$runeName],
                topicLines => [$batteryLine],
                details      => [ [ "Starts at $batteryLC", ] ],
            }
        )
      };

    my ( $hephepLine, $hephepColumn ) = $instance->nodeLC($hep);

    {
        my $literalLine = $instance->literalLine($hephepLine);
        $literalLine = $policy->deComment($literalLine);
        $literalLine =~ s/\n//g;
        $literalLine =~ s/--//g;
        if ( $literalLine =~ m/[^ ]/ ) {
            my $msg =
              sprintf q{HEPHEP %s should only share line with other HEPHEP's},
              describeLC( $hephepLine, $hephepColumn );
            push @mistakes,
              {
                desc         => $msg,
                subpolicy    => [ $runeName, 'hephep-alone' ],
                parentLine   => $parentLine,
                parentColumn => $parentColumn,
                line         => $hephepLine,
                column       => $hephepColumn,
                reportLine   => $hephepLine,
                reportColumn => $hephepColumn,
                details      => [ [ "Starts at $batteryLC", ] ],
              };
        }
    }

    my $expectedColumn     = $anchorColumn;
    my $hephepIsMisaligned = $hephepColumn != $expectedColumn;

    if ($hephepIsMisaligned) {
        my $lineToPos     = $instance->{lineToPos};
        my $hephepPos     = $lineToPos->[$hephepLine] + $expectedColumn;
        my $hephepLiteral = $instance->literal( $hephepPos, 2 );
        $hephepIsMisaligned = $hephepLiteral ne '--';
    }
    if ($hephepIsMisaligned) {
        my $msg = sprintf
          'battery hephep %s; %s',
          describeLC( $hephepLine, $hephepColumn ),
          describeMisindent2( $hephepColumn, $expectedColumn );
        push @mistakes,
          {
            desc         => $msg,
            subpolicy    => [ $runeName, 'hephep-indent' ],
            parentLine   => $parentLine,
            parentColumn => $parentColumn,
            line         => $hephepLine,
            column       => $hephepColumn,
            reportLine   => $hephepLine,
            reportColumn => $hephepColumn,
            topicLines   => [$batteryLine],
            details      => [ [ "Starts at $batteryLC", ] ],
          };
    }
    return \@mistakes;
}

sub checkSplitFascom {
    my ( $policy, $node ) = @_;
    my $instance  = $policy->{lint};
    my $lineToPos = $instance->{lineToPos};

    # say STDERR join " ", __FILE__, __LINE__, $instance->literalNode($node);
    my ( $bodyGap, $body, $tistisGap, $tistis ) =
      @{ $policy->gapSeq0($node) };

    my ( $runeLine,   $runeColumn )   = $instance->nodeLC($node);
    my ( $bodyLine,   $bodyColumn )   = $instance->nodeLC($body);
    my ( $tistisLine, $tistisColumn ) = $instance->nodeLC($tistis);

    my $anchorLine = $runeLine;
    my ( $anchorColumn, $anchorData ) = $policy->reanchorInc(
        $node,
        {
            fordFascen => 1,
        }
    );
    my $anchorDetails = $policy->anchorDetails( $node, $anchorData );

    my $nodeIX    = $node->{IX};
    my $chessSide = $policy->{perNode}->{$nodeIX}->{chessSide};
    my $queenside = $chessSide eq 'queenside';
    # say STDERR join " ", __FILE__, __LINE__, $chessSide;

    my @mistakes = ();
    my $runeName = $policy->runeName($node);
    my $tag      = $runeName;

    # We deal with the elements list itself,
    # in its own node

    my $expectedColumn = $anchorColumn + $queenside ? 4 : 2;
    my $expectedLine   = $runeLine + 1;

    # say STDERR join " ", __FILE__, __LINE__, $chessSide, $expectedColumn;

    push @mistakes,
      @{
        $policy->checkOneLineGap(
            $bodyGap,
            {
                mainColumn => $anchorColumn,
                runeName        => $tag,
                subpolicy => [ $runeName ],
                topicLines => [$bodyLine],
            }
        )
      };

    if ( $bodyColumn != $expectedColumn ) {
        my $msg = sprintf
          "split %s %s; %s",
          $runeName,
          describeLC( $bodyLine, $bodyColumn ),
          describeMisindent2( $bodyColumn, $expectedColumn );
        push @mistakes,
          {
            desc           => $msg,
            subpolicy => [ $runeName, 'body-indent' ],
            parentLine     => $runeLine,
            parentColumn   => $runeColumn,
            line           => $bodyLine,
            column         => $bodyColumn,
            reportLine           => $bodyLine,
            reportColumn         => $bodyColumn,
            topicLines     => [ $runeLine, $expectedLine ],
            details        => [ [ @{$anchorDetails} ] ],
          };
    }

    push @mistakes,
      @{
        $policy->checkOneLineGap(
            $tistisGap,
            {
                mainColumn => $anchorColumn,
                runeName        => $tag,
                subpolicy => [ $runeName ],
                topicLines => [ $anchorLine, $tistisLine ],
                details        => [ [ @{$anchorDetails} ] ],
            }
        )
      };

    push @mistakes,
      @{
        $policy->checkTistis(
            $tistis,
            {
                tag            => $tag,
                expectedColumn => $anchorColumn,
            }
        )
      };

    return \@mistakes;
}

sub checkJoinedFascom {
    my ( $policy, $node ) = @_;
    my $instance  = $policy->{lint};
    my $lineToPos = $instance->{lineToPos};

    my ( $bodyGap, $body, $tistisGap, $tistis ) = @{ $policy->gapSeq0($node) };

    my ( $runeLine,   $runeColumn )   = $instance->nodeLC($node);
    my ( $bodyLine,   $bodyColumn )   = $instance->nodeLC($body);
    my ( $tistisLine, $tistisColumn ) = $instance->nodeLC($tistis);
    my ( $anchorLine,   $anchorColumn )   = ( $runeLine,   $runeColumn );

    my $nodeIX    = $node->{IX};

    # Joined FASCOM is always considered queenside.

    my @mistakes = ();
    my $runeName = $policy->runeName($node);
    my $tag      = $runeName;

    # We deal with the elements list in its own node

    my $expectedColumn = $anchorColumn + 4;
    my $expectedLine   = $runeLine + 1;

    if ( $bodyColumn != $expectedColumn ) {
        my $msg = sprintf
          "joined %s %s; %s",
          $runeName,
          describeLC( $bodyLine, $bodyColumn ),
          describeMisindent2( $bodyColumn, $expectedColumn );
        push @mistakes,
          {
            desc         => $msg,
            subpolicy    => [ $runeName, 'body-indent' ],
            parentLine   => $runeLine,
            parentColumn => $runeColumn,
            line         => $bodyLine,
            column       => $bodyColumn,
            reportLine   => $bodyLine,
            reportColumn => $bodyColumn,
            topicLines   => [ $runeLine, $expectedLine ],
          };
    }

    push @mistakes,
      @{
        $policy->checkOneLineGap(
            $tistisGap,
            {
                mainColumn => $anchorColumn,
                runeName        => $tag,
                subpolicy => [ $runeName ],
                topicLines => [ $runeLine, $tistisLine ],
            }
        )
      };

    push @mistakes,
      @{
        $policy->checkTistis(
            $tistis,
            {
                tag            => $tag,
                expectedColumn => $anchorColumn,
            }
        )
      };

    return \@mistakes;
}

sub checkFascom {
    my ( $policy, $node ) = @_;
    my $instance = $policy->{lint};
    # say STDERR join " ", __FILE__, __LINE__, $instance->literalNode($node);
    my ( undef, $elements ) = @{ $policy->gapSeq0($node) };

    my ($runeLine, $runeColumn)     = $instance->nodeLC($node);
    my ($elementsLine) = $instance->nodeLC($elements);

    my $anchorLine = $runeLine;
    my ( $anchorColumn, $anchorData ) = $policy->reanchorInc(
        $node,
        {
            fordFascen => 1,
        }
    );
    my $anchorDetails = $policy->anchorDetails( $node, $anchorData );

    my $isJoined = $elementsLine == $runeLine ? 1 : 0;
    my $chessSide;
    # Joined FASCOM's are always considered queenside
    if ($isJoined) {
        $chessSide = 'queenside';
    } else {
        $chessSide = $policy->chessSideOfPairSequence($elements, $anchorColumn);
    }

    my $nodeIX = $node->{IX};
    $policy->{perNode}->{$nodeIX}->{isJoined} = $isJoined;
    $policy->{perNode}->{$nodeIX}->{chessSide} = $chessSide;

    return checkJoinedFascom( $policy, $node ) if $isJoined;
    return checkSplitFascom( $policy, $node );
}

sub checkFascomElements {
    my ( $policy, $node ) = @_;
    my $instance = $policy->{lint};
    my $children = $node->{children};

#                    say STDERR join " ", __FILE__, __LINE__, 'elements', $instance->literalNode($node);
    my $rune = $instance->ancestorByBrickName( $node, 'fordFascom' );
    my $runeNodeIX = $rune->{IX};
    my $isJoined = $policy->{perNode}->{$runeNodeIX}->{isJoined};
    my $chessSide = $policy->{perNode}->{$runeNodeIX}->{chessSide};
    my $queenside = $chessSide eq 'queenside';

    my ( $runeLine,   $runeColumn )   = $instance->nodeLC($rune);
    my ( $parentLine, $parentColumn ) = $instance->nodeLC($node);

    my $anchorLine = $runeLine;
    my ( $anchorColumn, $anchorData ) = $policy->reanchorInc(
        $rune,
        {
            fordFascen => 1,
        }
    );
    my $anchorDetails = $policy->anchorDetails( $node, $anchorData );

    my @mistakes = ();
    my $tag      = 'fascom-elements';

    my $childIX        = 0;
    my $expectedColumn = $anchorColumn + ($queenside ? 4 : 2);
  CHILD: while ( $childIX <= $#$children ) {
        my $element = $children->[$childIX];
        my ( $elementLine, $elementColumn ) = $instance->nodeLC($element);
        # say STDERR join " ", __FILE__, __LINE__, "element head #$childIX", $instance->literalNode($element);
        # say STDERR join " ", __FILE__, __LINE__, "element head #$childIX", 'actual v expected', $elementColumn, $expectedColumn ;

      CHECK_HEAD: {
            if ( $isJoined and $childIX == 0 ) {
                $expectedColumn = $elementColumn;
                last CHECK_HEAD;
            }

            if ( $elementColumn != $expectedColumn ) {
                my $msg = sprintf
                  "element %d %s; %s",
                  ( $childIX / 2 ) + 1,
                  describeLC( $elementLine, $elementColumn ),
                  describeMisindent2( $elementColumn, $expectedColumn );
                push @mistakes,
                  {
                    desc         => $msg,
                    details      => [ [ @{$anchorDetails} ] ],
                    subpolicy    => [ $tag, 'indent' ],
                    parentLine   => $parentLine,
                    parentColumn => $parentColumn,
                    line         => $elementLine,
                    column       => $elementColumn,
                    reportLine   => $elementLine,
                    reportColumn => $elementColumn,
                    topicLines   => [$runeLine],
                  };
            }
        }

        $childIX++;
        last CHILD unless $childIX <= $#$children;
        my $elementGap = $children->[$childIX];
        my ( $elementGapLine, $elementGapColumn ) =
          $instance->nodeLC($elementGap);

        push @mistakes,
          @{
            $policy->checkOneLineGap(
                $elementGap,
                {
                    mainColumn => $anchorColumn,
                    preColumn => $expectedColumn,
                    runeName        => $tag,
                subpolicy => [ $tag ],
                    topicLines => [$runeLine],
                    details    => [ [ @{$anchorDetails} ] ],
                }
            )
          };

        $childIX++;
    }

    return \@mistakes;
}

sub checkFasdot {
    my ( $policy, $node ) = @_;
    my $instance = $policy->{lint};

    my ( $bodyGap, $body, $tistisGap, $tistis ) = @{ $policy->gapSeq0($node) };

    my ( $runeLine,   $runeColumn )   = $instance->nodeLC($node);
    my ( $bodyLine,   $bodyColumn )   = $instance->nodeLC($body);
    my ( $tistisLine, $tistisColumn ) = $instance->nodeLC($tistis);

    my @mistakes = ();
    my $runeName = $policy->runeName($node);
    my $tag      = $runeName;

    # We deal with the elements list in its own node

    my $expectedColumn = $runeColumn + 4;

  CHECK_BODY: {
        if ( $bodyLine != $runeLine ) {
            my $msg = sprintf
              "%s %s; body must be on rune line",
              $runeName, describeLC( $bodyLine, $bodyColumn );
            push @mistakes,
              {
                desc         => $msg,
                subpolicy    => [ $runeName, 'body-split' ],
                parentLine   => $runeLine,
                parentColumn => $runeColumn,
                line         => $bodyLine,
                column       => $bodyColumn,
                reportLine   => $bodyLine,
                reportColumn => $bodyColumn,
                topicLines   => [$runeLine],
              };
            last CHECK_BODY;
        }

        if ( $bodyColumn != $expectedColumn ) {
            my $msg = sprintf
              "joined %s %s; %s",
              $runeName,
              describeLC( $bodyLine, $bodyColumn ),
              describeMisindent2( $bodyColumn, $expectedColumn );
            push @mistakes,
              {
                desc         => $msg,
                subpolicy    => [ $runeName, 'body-indent' ],
                parentLine   => $runeLine,
                parentColumn => $runeColumn,
                line         => $bodyLine,
                column       => $bodyColumn,
                reportLine   => $bodyLine,
                reportColumn => $bodyColumn,
                topicLines   => [$runeLine],
              };
        }
    }

    push @mistakes,
      @{
        $policy->checkOneLineGap(
            $tistisGap,
            {
                mainColumn => $runeColumn,
                runeName        => $tag,
                subpolicy  => [$runeName],
                topicLines => [ $runeLine, $tistisLine ],
            }
        )
      };

    push @mistakes,
      @{
        $policy->checkTistis(
            $tistis,
            {
                tag            => $tag,
                expectedColumn => $runeColumn,
            }
        )
      };

    return \@mistakes;
}

sub checkJogging {
    my ( $policy, $node ) = @_;
    my $instance = $policy->{lint};
    my $children = $node->{children};
    my ( $parentLine, $parentColumn ) = $instance->nodeLC($node);

    my $joggingHoonData = $policy->getInheritedAttribute($node, 'joggingHoonData');
    my $jogBaseColumn = $joggingHoonData->{jogBaseColumn};
    my $chessSide = $joggingHoonData->{chessSide};
    my $joggingHoonNode = $joggingHoonData->{node};
    my ( $anchorLine, $anchorColumn ) = $instance->nodeLC($joggingHoonNode);
    my $runeName = $policy->runeName($joggingHoonNode);

    my @mistakes = ();

    my $expectedColumn = $parentColumn;
  CHILD: for ( my $childIX = 1; $childIX <= $#$children; $childIX+=2 ) {
        my $jogGap = $children->[$childIX];
        my ( $jogGapLine, $jogGapColumn ) =
          $instance->nodeLC($jogGap);

        push @mistakes,
          @{
            $policy->checkOneLineGap(
                $jogGap,
                {
                    mainColumn => $anchorColumn,
                    preColumn => $jogBaseColumn,
                    runeName        => $runeName,
                subpolicy => [ $runeName, 'jogging' ],
                    topicLines => [$jogGapLine],
                }
            )
          };

    }

    return \@mistakes;

}

# Check "vanilla" sequence
sub checkSeq {
    my ( $policy, $node, $elementDesc ) = @_;
    my $instance = $policy->{lint};
    my $children = $node->{children};

    my ( $parentLine, $parentColumn ) = $instance->nodeLC($node);

    my $brick = $instance->brickNode($node);
    my $runeName = $brick ? $policy->runeName($brick) : 'fordfile';

    my @mistakes = ();

    my $childIX        = 0;
    my $expectedColumn = $parentColumn;
  CHILD: while ( $childIX <= $#$children ) {
        my $element = $children->[$childIX];
        my ( $elementLine, $elementColumn ) = $instance->nodeLC($element);

        if ( $elementColumn != $expectedColumn ) {
            my $msg = sprintf
              '%s %d %s; %s',
              $runeName,
              ( $childIX / 2 ) + 1,
              describeLC( $elementLine, $elementColumn ),
              describeMisindent2( $elementColumn, $expectedColumn );
            push @mistakes,
              {
                desc           => $msg,
                subpolicy => [ $runeName, 'sequence-element-indent' ],
                parentLine     => $parentLine,
                parentColumn   => $parentColumn,
                line           => $elementLine,
                column         => $elementColumn,
                reportLine           => $elementLine,
                reportColumn         => $elementColumn,
                details    => [ [ $elementDesc] ],
              };
        }

        $childIX++;
        last CHILD unless $childIX <= $#$children;
        my $elementGap = $children->[$childIX];
        my ( $elementGapLine, $elementGapColumn ) =
          $instance->nodeLC($elementGap);

        push @mistakes,
          @{
            $policy->checkOneLineGap(
                $elementGap,
                {
                    mainColumn => $expectedColumn,
                    runeName        => $runeName,
                    subpolicy => [ $runeName, 'sequence-vgap' ],
                    details    => [ [ $elementDesc] ],
                    topicLines => [$elementGapLine],
                }
            )
          };

        $childIX++;
    }

    return \@mistakes;

}

# tallBarcab ::= (- BAR CAB GAP -) till5d (- GAP -) wasp5d wisp5d
sub checkBarcab {
    my ( $policy, $node ) = @_;
    my $instance = $policy->{lint};

    # TODO: reanchoring logic, memoize anchorColumn for checkWisp5d()

    # BARCAB is special, so we need to find the components using low-level
    # techniques.
    # tallBarcab ::= (- BAR CAB GAP -) till5d (- GAP -) wasp5d wisp5d
    my ( undef, undef, $headGap, $head, $wispGap, undef, $wisp ) =
      @{ $node->{children} };
    my ( $parentLine, $parentColumn ) = $instance->nodeLC($node);
    my $anchorNode = $node;
    my ( $anchorLine, $anchorColumn ) = $instance->nodeLC($anchorNode);
    my ( $headLine,   $headColumn )   = $instance->nodeLC($head);
    my ( $wispLine,   $wispColumn )   = $instance->nodeLC($wisp);

    $policy->setInheritedAttribute( $node, 'anchorColumn', $anchorColumn );

    my $cellBodyAlignmentData = $policy->wispCellBodyAlignment($wisp);
    $policy->setInheritedAttribute( $node, 'cellBodyAlignmentData',
        $cellBodyAlignmentData );

    my @mistakes = ();
    my $runeName = 'barcab';

    my $expectedColumn;

  HEAD_ISSUES: {
        if ( $parentLine != $headLine ) {
            my $pseudojoinColumn = $policy->pseudojoinColumn($headGap);
            if ( $pseudojoinColumn <= 0 ) {
                my $msg = sprintf 'Barcab head %s; must be on rune line',
                  describeLC( $headLine, $headColumn );
                push @mistakes,
                  {
                    desc         => $msg,
                    subpolicy    => [ $runeName, 'head-split' ],
                    parentLine   => $parentLine,
                    parentColumn => $parentColumn,
                    line         => $headLine,
                    column       => $headColumn,
                    reportLine   => $headLine,
                    reportColumn => $headColumn,
                  };
                last HEAD_ISSUES;
            }
            my $expectedHeadColumn = $pseudojoinColumn;
            if ( $headColumn != $expectedHeadColumn ) {
                my $msg =
                  sprintf
'Pseudo-joined BARCEN head; head/comment mismatch; head is %s',
                  describeLC( $headLine, $headColumn ),
                  describeMisindent2( $headColumn, $expectedHeadColumn );
                push @mistakes,
                  {
                    desc         => $msg,
                    subpolicy    => [ $runeName, 'head-pseudojoin-mismatch' ],
                    parentLine   => $parentLine,
                    parentColumn => $parentColumn,
                    reportLine   => $headLine,
                    reportColumn => $headColumn,
                  };
            }
            last HEAD_ISSUES;
        }

        # If here, headLine == runeLine
        my $gapLiteral = $instance->literalNode($headGap);
        my $gapLength  = $headGap->{length};
        last HEAD_ISSUES if $gapLength == 2;
        my ( undef, $headGapColumn ) = $instance->nodeLC($headGap);

        my $msg = sprintf 'Barcab head %s; %s',
          describeLC( $headLine, $headColumn ),
          describeMisindent2( $gapLength, 2 );
        push @mistakes,
          {
            desc         => $msg,
            subpolicy    => [ $runeName, 'head-hgap' ],
            parentLine   => $parentLine,
            parentColumn => $parentColumn,
            line         => $headLine,
            column       => $headColumn,
            reportLine   => $headLine,
            reportColumn => $headColumn,
          };

    }

    $expectedColumn = $anchorColumn;
    push @mistakes,
      @{
        $policy->checkOneLineGap(
            $wispGap,
            {
                mainColumn => $anchorColumn,
                preColumn => $anchorColumn + 2,
                runeName        => $runeName,
                subpolicy  => [ $runeName, 'battery-vgap' ],
                topicLines => [$wispLine],
            }
        )
      };

    if ( $wispColumn != $expectedColumn ) {
        my $msg = sprintf 'Barcab battery %s; %s',
          describeLC( $wispLine, $wispColumn ),
          describeMisindent2( $wispColumn, $expectedColumn );
        push @mistakes,
          {
            desc         => $msg,
            subpolicy    => [ $runeName, 'battery-indent' ],
            parentLine   => $parentLine,
            parentColumn => $parentColumn,
            line         => $wispLine,
            column       => $wispColumn,
            reportLine   => $wispLine,
            reportColumn => $wispColumn,
          };
        return \@mistakes;
    }

    return \@mistakes;
}

# tallBarcen ::= (- BAR CEN GAP -) wisp5d
sub checkBarcen {
    my ( $policy, $node )    = @_;
    my ( $rune, undef, $gap,    $wisp ) = @{ $node->{children} };
    my $wispNodeIX = $wisp->{IX};
    my $instance = $policy->{lint};
    my ( $parentLine,   $parentColumn ) = $instance->nodeLC($node);
    my ( $anchorColumn, $anchorData )   = $policy->reanchorInc(
        $node,
        {
            # LustisCell => 1, # should NOT reanchor at Lustis
            # LushepCell => 1, # should NOT reanchor at Lushep
            # LuslusCell => 1, # should NOT reanchor at Luslus, per experiment
            # Reanchor at TISGAR would make sense in a lot of places in arvo corpus,
            # would not work in toe.hoon
            # tallTisgar => 1,
            tallKetbar => 1,
            tallKetwut => 1,
        }
    );
    $policy->setInheritedAttribute($node, 'anchorColumn', $anchorColumn);
    my $anchorDetails = $policy->anchorDetails( $node, $anchorData );

    my $cellBodyAlignmentData = $policy->wispCellBodyAlignment($wisp);
    $policy->setInheritedAttribute($node, 'cellBodyAlignmentData', $cellBodyAlignmentData);

    my ( $wispLine, $wispColumn ) = $instance->nodeLC($wisp);

    my @mistakes = ();
    my $runeName      = 'barcen';

    my $gapLiteral = $instance->literalNode($gap);
    my $expectedColumn;

    if ( $parentLine == $wispLine ) {
        my $gapLength = $gap->{length};
        return [] if length $gapLiteral == 2;

        my $msg = sprintf 'joined Barcen battery %s; %s',
          describeLC( $wispLine, $wispColumn ),
          describeMisindent2( $gapLength, 2 );
        push @mistakes,
          {
            desc         => $msg,
            subpolicy => [ $runeName, 'battery-hgap' ],
            parentLine   => $parentLine,
            parentColumn => $parentColumn,
            line         => $wispLine,
            column       => $wispColumn,
            reportLine         => $wispLine,
            reportColumn       => $wispColumn,
          };
        return \@mistakes;
    }

    # If here head line != battery line
    $expectedColumn = $anchorColumn;
    push @mistakes,
      @{
        $policy->checkOneLineGap(
            $gap,
            {
                mainColumn => $expectedColumn,
                runeName        => $runeName,
                subpolicy => [ $runeName ],
                details    => [
                    [ @{ $policy->anchorDetails( $node, $anchorData ) } ]
                ],
            }
        )
      };

    if ( $wispColumn != $expectedColumn ) {
        my $msg = sprintf 'split Barcen battery %s; %s',
          describeLC( $wispLine, $wispColumn ),
          describeMisindent2( $wispColumn, $expectedColumn );
        push @mistakes,
          {
            desc         => $msg,
            subpolicy => [ $runeName, 'battery-indent' ],
            parentLine   => $parentLine,
            parentColumn => $parentColumn,
            line         => $wispLine,
            column       => $wispColumn,
            reportLine         => $wispLine,
            reportColumn       => $wispColumn,
            anchorDetails  => $policy->anchorDetails( $node, $anchorData ),
          };
        return \@mistakes;
    }

    return \@mistakes;
}

# tallBarket ::= (- BAR KET GAP -) tall5d (- GAP -) wisp5d
sub checkBarket {
    my ( $policy, $node ) = @_;
    my $instance = $policy->{lint};

    # TODO: reanchoring logic, memoize anchorColumn for checkWisp5d()

    my ( $rune, undef, $headGap, $head, $wispGap, $wisp ) =
      @{ $node->{children} };
    my ( $parentLine, $parentColumn ) = $instance->nodeLC($node);
    my $anchorNode = $node;
    my ( $anchorLine,  $anchorColumn )  = $instance->nodeLC($anchorNode);
    my ( $headLine,    $headColumn )    = $instance->nodeLC($head);
    my ( $wispLine, $wispColumn ) = $instance->nodeLC($wisp);

    $policy->setInheritedAttribute($node, 'anchorColumn', $anchorColumn);

    my $cellBodyAlignmentData = $policy->wispCellBodyAlignment($wisp);
    $policy->setInheritedAttribute($node, 'cellBodyAlignmentData', $cellBodyAlignmentData);

    my @mistakes = ();
    my $tag      = 'barket';
    my $runeName = 'barket';

    my $expectedColumn;

  HEAD_ISSUES: {
        if ( $parentLine != $headLine ) {
            my $pseudojoinColumn = $policy->pseudojoinColumn($headGap);
            if ( $pseudojoinColumn <= 0 ) {
                my $msg = sprintf 'Barket head %s; must be on rune line',
                  describeLC( $headLine, $headColumn );
                push @mistakes,
                  {
                    desc         => $msg,
                    subpolicy  => [$runeName, 'head-split'],
                    parentLine   => $parentLine,
                    parentColumn => $parentColumn,
                    line         => $headLine,
                    column       => $headColumn,
                    reportLine   => $headLine,
                    reportColumn => $headColumn,
                  };
                last HEAD_ISSUES;
            }
            my $expectedHeadColumn = $pseudojoinColumn;
            if ( $headColumn != $expectedHeadColumn ) {
                my $msg =
                  sprintf
'Pseudo-joined Barket head; head/comment mismatch; head is %s',
                  describeLC( $headLine, $headColumn ),
                  describeMisindent2( $headColumn, $expectedHeadColumn );
                push @mistakes,
                  {
                    desc         => $msg,
                    subpolicy  => [$runeName, 'head-pseudojoin-match'],
                    parentLine   => $parentLine,
                    parentColumn => $parentColumn,
                    line         => $headLine,
                    column       => $headColumn,
                    reportLine   => $headLine,
                    reportColumn => $headColumn,
                  };
            }
            last HEAD_ISSUES;
        }

        # If here, headLine == runeLine
        my $gapLiteral = $instance->literalNode($headGap);
        my $gapLength  = $headGap->{length};
        last HEAD_ISSUES if $gapLength == 2;
        my ( undef, $headGapColumn ) = $instance->nodeLC($headGap);

        my $msg = sprintf 'Barket head %s; %s',
          describeLC( $headLine, $headColumn ),
          describeMisindent2( $gapLength, 2 );
        push @mistakes,
          {
            desc         => $msg,
            subpolicy  => [$runeName, 'head-hgap'],
            parentLine   => $parentLine,
            parentColumn => $parentColumn,
            line         => $headLine,
            column       => $headColumn,
            reportLine   => $headLine,
            reportColumn => $headColumn,
          };

    }

    $expectedColumn = $anchorColumn;
    push @mistakes,
      @{
        $policy->checkOneLineGap(
            $wispGap,
            {
                mainColumn => $expectedColumn,
                preColumn => $expectedColumn + 2,
                runeName        => $tag,
                subpolicy  => [$runeName, 'battery-vgap'],
                topicLines => [$wispLine],
            }
        )
      };

    if ( $wispColumn != $expectedColumn ) {
        my $msg = sprintf 'Barket battery %s; %s',
          describeLC( $wispLine, $wispColumn ),
          describeMisindent2( $wispColumn, $expectedColumn );
        push @mistakes,
          {
            desc         => $msg,
            subpolicy  => [$runeName, 'battery-indent'],
            parentLine   => $parentLine,
            parentColumn => $parentColumn,
            line         => $wispLine,
            column       => $wispColumn,
            reportLine   => $wispLine,
            reportColumn => $wispColumn,
          };
        return \@mistakes;
    }

    return \@mistakes;
}

sub checkFordHoofRune {
    my ( $policy, $lhsName, $node ) = @_;
    my $instance = $policy->{lint};

    # FASWUT is very similar to these runes.  Combine them?

    # Ford hoof runes is special, so we need to find the components using low-level
    # techniques.
    # optFordFashep ::= (- FAS HEP GAP -) fordHoofSeq (- GAP -)
    my ( undef, undef, $leaderGap, $body, $trailerGap ) =
      @{ $node->{children} };

    my $runeName = $policy->runeName($node);

    # TODO: Should we require that parent column be 0?
    my ( $parentLine, $parentColumn ) = $instance->nodeLC($node);
    my ( $bodyLine,   $bodyColumn )   = $instance->nodeLC($body);
    my ( $leaderGapLine,   $leaderGapColumn )   = $instance->nodeLC($leaderGap);
    my ( $anchorLine, $anchorColumn ) = ( $parentLine, $parentColumn );

    my @mistakes = ();
    my $tag      = $runeName;

    my $expectedColumn;

  BODY_ISSUES: {
        if ( $parentLine != $bodyLine ) {
            my $msg = sprintf '%s body %s; must be on rune line',
              $runeName,
              describeLC( $bodyLine, $bodyColumn );
            push @mistakes,
              {
                desc           => $msg,
                parentLine     => $parentLine,
                parentColumn   => $parentColumn,
                line           => $bodyLine,
                column         => $bodyColumn,
                reportLine           => $bodyLine,
                reportColumn         => $bodyColumn,
                subpolicy => [ $runeName, 'same-line' ],
              };
            last BODY_ISSUES;
        }
        my $expectedBodyColumn = $parentColumn + 4;
        if ( $bodyColumn != $expectedBodyColumn ) {
            my $msg =
              sprintf '%s body %s is %s',
              $runeName,
              describeLC( $bodyLine, $bodyColumn ),
              describeMisindent2( $bodyColumn, $expectedBodyColumn );
            push @mistakes,
              {
                desc           => $msg,
                parentLine     => $parentLine,
                parentColumn   => $parentColumn,
                line           => $bodyLine,
                column         => $bodyColumn,
                reportLine           => $bodyLine,
                reportColumn         => $bodyColumn,
                subpolicy => [ $runeName, 'hgap' ],
              };
        }
        last BODY_ISSUES;

    }

    $expectedColumn = $anchorColumn;
    push @mistakes,
      @{
        $policy->checkOneLineGap(
            $trailerGap,
            {
                mainColumn => $anchorColumn,
                runeName        => $tag,
                subpolicy => [ $runeName ],
            }
        )
      };

    return \@mistakes;
}

sub checkFordHoop {
    my ( $policy, $node ) = @_;
    my $instance = $policy->{lint};

    # TODO Split is implemented, but not split Ford-1 hoon
    # is represented in the corpus AFAICT

    my $tag = 'fasfas';

    # fordFassig ::= (- FAS SIG GAP -) tall5d
    my ( $gap, $body ) = @{ $policy->gapSeq0($node) };

    my ( $parentLine, $parentColumn ) = $instance->nodeLC($node);
    my ( $bodyLine,   $bodyColumn )   = $instance->nodeLC($body);

    my @mistakes = ();

    my $expectedBodyColumn;

  BODY_ISSUES: {
        if ( $parentLine == $bodyLine ) {
            my $expectedBodyColumn = $parentColumn + 4;
            if ( $bodyColumn != $expectedBodyColumn ) {
                my $msg =
                  sprintf 'joined %s body %s is %s',
                  $tag,
                  describeLC( $bodyLine, $bodyColumn ),
                  describeMisindent2( $bodyColumn, $expectedBodyColumn );
                push @mistakes,
                  {
                    desc           => $msg,
                subpolicy => [ $tag, 'hgap' ],
                    parentLine     => $parentLine,
                    parentColumn   => $parentColumn,
                    line           => $bodyLine,
                    column         => $bodyColumn,
                  };
            }
            last BODY_ISSUES;
        }

        # If here parent line != body line
        $expectedBodyColumn = $parentColumn;
        push @mistakes,
          @{
            $policy->checkOneLineGap(
                $gap,
                {
                    mainColumn => $expectedBodyColumn,
                    runeName        => $tag,
                subpolicy => [ $tag ],
                }
            )
          };

        if ( $bodyColumn != $expectedBodyColumn ) {
            my $msg =
              sprintf 'split %s body %s is %s',
              $tag,
              describeLC( $bodyLine, $bodyColumn ),
              describeMisindent2( $bodyColumn, $expectedBodyColumn );
            push @mistakes,
              {
                desc           => $msg,
                subpolicy => [ $tag, 'body-indent' ],
                parentLine     => $parentLine,
                parentColumn   => $parentColumn,
                line           => $bodyLine,
                column         => $bodyColumn,
              };
        }
    }

    return \@mistakes;
}

sub checkFord_1 {
    my ( $policy, $node ) = @_;
    my $instance = $policy->{lint};

    # TODO Split is implemented, but not split Ford-1 hoon
    # is represented in the corpus AFAICT

    my $runeName = $policy->runeName($node);

    # fordFassig ::= (- FAS SIG GAP -) tall5d
    my ( $gap, $body ) = @{ $policy->gapSeq0($node) };

    my ( $parentLine, $parentColumn ) = $instance->nodeLC($node);
    my ( $bodyLine,   $bodyColumn )   = $instance->nodeLC($body);

    my ( $anchorColumn, $anchorData ) = $policy->reanchorInc(
        $node,
        {
            fordFascen => 1,
        }
    );
    my $anchorDetails = $policy->anchorDetails( $node, $anchorData );

    my @mistakes = ();

    my $expectedBodyColumn;

  BODY_ISSUES: {
        if ( $parentLine == $bodyLine ) {
            my $expectedBodyColumn = $anchorColumn + 4;
            if ( $bodyColumn != $expectedBodyColumn ) {
                my $msg =
                  sprintf 'joined %s body %s is %s',
                  $runeName,
                  describeLC( $bodyLine, $bodyColumn ),
                  describeMisindent2( $bodyColumn, $expectedBodyColumn );
                push @mistakes,
                  {
                    desc         => $msg,
                    subpolicy    => [ $runeName, 'hgap' ],
                    parentLine   => $parentLine,
                    parentColumn => $parentColumn,
                    reportLine   => $bodyLine,
                    reportColumn => $bodyColumn,
                    line         => $bodyLine,
                    column       => $bodyColumn,
                    details      => [ [ @{$anchorDetails} ] ],
                  };
            }
            last BODY_ISSUES;
        }

        # If here parent line != body line
        $expectedBodyColumn = $anchorColumn;
        push @mistakes,
          @{
            $policy->checkOneLineGap(
                $gap,
                {
                    mainColumn => $expectedBodyColumn,
                    runeName        => $runeName,
                    subpolicy  => [$runeName],
                    details    => [ [ @{$anchorDetails}, ], ],
                }
            )
          };

        if ( $bodyColumn != $expectedBodyColumn ) {
            my $msg =
              sprintf 'split %s body %s is %s',
              $runeName,
              describeLC( $bodyLine, $bodyColumn ),
              describeMisindent2( $bodyColumn, $expectedBodyColumn );
            push @mistakes,
              {
                desc         => $msg,
                subpolicy    => [ $runeName, 'body-indent' ],
                details      => [ [ @{$anchorDetails} ] ],
                parentLine   => $parentLine,
                parentColumn => $parentColumn,
                line         => $bodyLine,
                column       => $bodyColumn,
              };
        }
    }

    return \@mistakes;
}

sub checkFaswut {
    my ( $policy, $node ) = @_;
    my $instance = $policy->{lint};

    # FASWUT is special, so we need to find the components using low-level
    # techniques.
    # fordFaswut ::= (- FAS WUT GAP -) DIT4K_SEQ (- GAP -)
    my ( undef, undef, $leaderGap, $body, $trailerGap ) =
      @{ $node->{children} };

    # TODO: Should we require that parent column be 0?
    my ( $parentLine, $parentColumn ) = $instance->nodeLC($node);
    my ( $bodyLine,   $bodyColumn )   = $instance->nodeLC($body);

    my @mistakes = ();
    my $runeName      = 'faswut';
    my $tag      = 'faswut';

    my $expectedColumn;

  BODY_ISSUES: {
        if ( $parentLine != $bodyLine ) {
            my $msg = sprintf 'Faswut body %s; must be on rune line',
              describeLC( $bodyLine, $bodyColumn );
            push @mistakes,
              {
                desc           => $msg,
                parentLine     => $parentLine,
                parentColumn   => $parentColumn,
                line           => $bodyLine,
                column         => $bodyColumn,
              };
            last BODY_ISSUES;
        }
        my $expectedBodyColumn = $parentColumn + 4;
        if ( $bodyColumn != $expectedBodyColumn ) {
            my $msg =
              sprintf 'body %s is %s',
              describeLC( $bodyLine, $bodyColumn ),
              describeMisindent2( $bodyColumn, $expectedBodyColumn );
            push @mistakes,
              {
                desc           => $msg,
                parentLine     => $parentLine,
                parentColumn   => $parentColumn,
                line           => $bodyLine,
                column         => $bodyColumn,
                subpolicy      => $policy->nodeSubpolicy($node) . ':hgap',
              };
        }
        last BODY_ISSUES;

    }

    $expectedColumn = $parentColumn;
    push @mistakes,
      @{
        $policy->checkOneLineGap(
            $trailerGap,
            {
                mainColumn => $expectedColumn,
                runeName        => $tag,
                subpolicy => [ $runeName ],
            }
        )
      };

    return \@mistakes;
}

# The only lutes in the arvo/ corpus are one-liners.
# We treat one-line lutes as free-form -- never any errors.
# We report "not yet implemented" for multi-line lutes.
sub checkLute {
    my ( $policy, $node ) = @_;
    my $instance = $policy->{lint};

    # lutes are special, so we need to find the components using low-level
    # techniques.
    # lute5d ::= (- SEL GAP -) tall5dSeq (- GAP SER -)
    my $children  = $node->{children};
    my $sel       = $children->[0];
    my $ser       = $children->[-1];
    my ($selLine) = $instance->nodeLC($sel);
    my ($serLine) = $instance->nodeLC($ser);

    return $instance->checkNYI($node) if $selLine != $serLine;
    return [];
}

sub checkSplit_0Running {
    my ( $policy, $args ) = @_;
    my $instance        = $policy->{lint};
    my $minimumRunsteps = $instance->{minSplit_0RunningSteps} // 0;

    my $node            = $args->{node};
    my $rune            = $args->{rune};
    my $runningGap      = $args->{runningGap};
    my $runningChildren = $args->{runningChildren};
    my $tistisGap       = $args->{tistisGap};
    my $tistis          = $args->{tistis};
    my $runningLine     = $args->{runningLine};
    my $runningColumn   = $args->{runningColumn};
    my $runeName        = $args->{runeName};
    my $anchorLine    = $args->{anchorLine};
    my $anchorColumn    = $args->{anchorColumn};
    my $anchorDetails    = $args->{anchorDetails};

    my ( $runeLine,    $runeColumn ) = $instance->nodeLC($rune);
    my ( $tistisLine,  $tistisColumn )  = $instance->nodeLC($tistis);

    my $expectedColumn = $anchorColumn + 2;

    my @mistakes = ();

    # We deal with the running list here, rather than
    # in its own node

    my $runStepCount = ( scalar @{$runningChildren} ) / 2;
    if ( $runStepCount < $minimumRunsteps ) {

        # Untested

        my $msg = sprintf '%s %s; too few runsteps; has %d, minimum is %d',
          $runeName,
          describeLC( $runningLine, $runningColumn ),
          $runStepCount, $minimumRunsteps;
        push @mistakes,
          {
            desc         => $msg,
            subpolicy => [ $runeName, 'split-runstep-count' ],
            parentLine   => $runeLine,
            parentColumn => $runeColumn,
            line         => $runningLine,
            column       => $runningColumn,
            reportLine         => $runningLine,
            reportColumn       => $runningColumn,
          };
    }

    push @mistakes,
      @{
        $policy->checkOneLineGap(
            $runningGap,
            {
                mainColumn => $anchorColumn,
                preColumn  => $expectedColumn,
                runeName        => $runeName,
                subpolicy => [ $runeName, 'running-vgap' ],
            }
        )
      };

    push @mistakes,
      @{
        $policy->checkRunning(
            {
                children       => $runningChildren,
                subpolicy => [ $runeName ],
                anchorColumn   => $anchorColumn,
                expectedColumn => $expectedColumn,
                anchorDetails  => $anchorDetails,
            }
        )
      };

    push @mistakes,
      @{
        $policy->checkOneLineGap(
            $tistisGap,
            {
                mainColumn => $anchorColumn,
                preColumn  => $expectedColumn,
                runeName        => $runeName,
                subpolicy => [ $runeName, 'tistis-vgap' ],
                topicLines => [ $anchorLine, $tistisLine ],
            }
        )
      };

    push @mistakes,
      @{
        $policy->checkTistis(
            $tistis,
            {
                subpolicy => [ $runeName ],
                tag            => $runeName,
                expectedColumn => $anchorColumn,
            }
        )
      };
    return \@mistakes;
}

sub checkJoined_0Running {
    my ( $policy, $args, $joinColumn ) = @_;
    my $instance        = $policy->{lint};
    my $maximumRunsteps = $instance->{maxJoined_0RunningSteps};

    my $node            = $args->{node};
    my $rune            = $args->{rune};
    my $runningGap      = $args->{runningGap};
    my $runningChildren = $args->{runningChildren};
    my $tistisGap       = $args->{tistisGap};
    my $tistis          = $args->{tistis};
    my $runningLine     = $args->{runningLine};
    my $runningColumn   = $args->{runningColumn};
    my $runeName        = $args->{runeName};
    my $anchorLine    = $args->{anchorLine};
    my $anchorColumn    = $args->{anchorColumn};
    my $anchorDetails    = $args->{anchorDetails};
    my $pseudojoin    = $args->{pseudojoin};

    my ( $runeLine,    $runeColumn )    = $instance->nodeLC($rune);
    my ( $tistisLine,  $tistisColumn )  = $instance->nodeLC($tistis);

    my @mistakes       = ();
    my $expectedColumn = $joinColumn >= 0 ? $joinColumn : $runeColumn + 4;

    my $runStepCount = ( scalar @{$runningChildren} ) / 2;
    if ( defined $maximumRunsteps and $runStepCount > $maximumRunsteps ) {

        # Untested
        my $msg = sprintf
          '%s; too many runsteps; has %d, maximum is %d',
          describeLC( $runningLine, $runningColumn ),
          $runStepCount, $maximumRunsteps;
        push @mistakes,
          {
            desc         => $msg,
            subpolicy => [ $runeName, 'joined-runstep-count' ],
            parentLine   => $runeLine,
            parentColumn => $runeColumn,
            line         => $runningLine,
            column       => $runningColumn,
            reportLine         => $runningLine,
            reportColumn       => $runningColumn,
          };
    }

    push @mistakes,
      @{
        $policy->checkRunning(
            {
                children       => $runningChildren,
                subpolicy => [ $runeName ],
                anchorColumn   => $anchorColumn,
                expectedColumn => $expectedColumn,
                pseudojoin => $pseudojoin,
            }
        )
      };

    push @mistakes,
      @{
        $policy->checkOneLineGap(
            $tistisGap,
            {
                mainColumn => $runeColumn,
                preColumn  => $expectedColumn,
                runeName        => $runeName,
                subpolicy => [ $runeName, 'tistis-vgap' ],
                topicLines => [ $runeLine, $tistisLine ],
            }
        )
      };

    push @mistakes,
      @{
        $policy->checkTistis(
            $tistis,
            {
                subpolicy => [ $runeName ],
                tag            => $runeName,
                expectedColumn => $runeColumn,
            }
        )
      };
    return \@mistakes;
}

sub check_1Running {
    my ( $policy, $node ) = @_;
    my $instance  = $policy->{lint};
    my $lineToPos = $instance->{lineToPos};

    my $runeName = $policy->runeName($node);

    my ( $rune, $headGap, $head, $runningGap, $running, $tistisGap, $tistis ) =
      @{ $policy->gapSeq($node) };

    my ( $runeLine,    $runeColumn )    = $instance->nodeLC($rune);
    my ( $anchorLine,  $anchorColumn )  = ( $runeLine, $runeColumn );
    my ( $headLine,    $headColumn )    = $instance->nodeLC($head);
    my ( $runningLine, $runningColumn ) = $instance->nodeLC($running);
    my ( $tistisLine,  $tistisColumn )  = $instance->nodeLC($tistis);

    my @mistakes = ();
    if ( $headLine != $runeLine ) {
        my $msg = sprintf
          "$runeName head %s; should be on rune line %d",
          describeLC( $headLine, $headColumn ),
          $runeLine;
        push @mistakes,
          {
            desc         => $msg,
            subpolicy => [ $runeName, 'head-split' ],
            parentLine   => $runeLine,
            parentColumn => $runeColumn,
            line         => $headLine,
            column       => $headColumn,
            reportLine         => $headLine,
            reportColumn       => $headColumn,
            expectedLine => $runeLine,
          };
    }

    my $expectedColumn = $runeColumn + 4;
    if ( $headColumn != $expectedColumn ) {
        my $msg = sprintf
          "$runeName head %s; %s",
          describeLC( $headLine, $headColumn ),
          describeMisindent2( $headColumn, $expectedColumn );
        push @mistakes,
          {
            desc           => $msg,
            subpolicy => [ $runeName, 'head-hgap' ],
            parentLine     => $runeLine,
            parentColumn   => $runeColumn,
            line           => $headLine,
            column         => $headColumn,
            reportLine         => $headLine,
            reportColumn       => $headColumn,
          };
    }

    $expectedColumn = $anchorColumn + 2;

    # Note: runnings are never pseudo-joined, at
    # least not in the corpus.
    if ( $headLine != $runningLine ) {
        push @mistakes,
          @{
            $policy->checkOneLineGap(
                $runningGap,
                {
                    mainColumn => $anchorColumn,
                    preColumn  => $runningColumn,
                    runeName        => $runeName,
                    subpolicy => [ $runeName ],
                }
            )
          };

        my @runningChildren = ( $runningGap, @{ $running->{children} } );

        push @mistakes,
          @{
            $policy->checkRunning(
                {
                    children       => \@runningChildren,
                subpolicy => [ $runeName ],
                    anchorColumn   => $anchorColumn,
                    expectedColumn => $expectedColumn,
                }
            )
          };

    }
    else {
        # joined, that is, $headLine == $runningLine
        my $gapLength = $runningGap->{length};

        if ( $gapLength != 2 ) {
            my $msg = sprintf
              "1-jogging running 1 %s; %s",
              describeLC( $runningLine, $runningColumn ),
              describeMisindent2( $gapLength, 2 );
            push @mistakes,
              {
                desc           => $msg,
                subpolicy => [ $runeName, 'running-hgap' ],
                parentLine     => $runeLine,
                parentColumn   => $runeColumn,
                line           => $runningLine,
                column         => $runningColumn,
                reportLine           => $runningLine,
                reportColumn         => $runningColumn,
              };
        }

        my @runningChildren = ( $runningGap, @{ $running->{children} } );

        push @mistakes,
          @{
            $policy->checkRunning(
                {
                    skipFirst      => 1,
                    children       => \@runningChildren,
                subpolicy => [ $runeName ],
                    anchorColumn   => $anchorColumn,
                    expectedColumn => $expectedColumn
                }
            )
          };

    }

    # We deal with the running list here, rather that
    # in its own node

    push @mistakes,
      @{
        $policy->checkOneLineGap(
            $tistisGap,
            {
                mainColumn => $runeColumn,
                preColumn  => $expectedColumn,
                runeName        => $runeName,
                subpolicy => [ $runeName, 'tistis-gap' ],
                topicLines => [ $runeLine, $tistisLine ],
            }
        )
      };

    $expectedColumn = $runeColumn;

    push @mistakes,
      @{
        $policy->checkTistis(
            $tistis,
            {
                tag            => $runeName,
                subpolicy      => [$runeName],
                expectedColumn => $runeColumn,
            }
        )
      };

    return \@mistakes;
}

# Find the oversize alignment for this column of elements.
# of a chain alignment
# $nodes must a ref to an array of repeating
# ( gap, body, backdentColumn ) elements
sub findChainAlignment {
    my ( $policy, $nodes ) = @_;
    my $instance = $policy->{lint};
    my %allAlignments = ();

    # local $Data::Dumper::Maxdepth = 1;
    # say STDERR join " ", __FILE__, __LINE__;

    # "wide", meaning an alignment following a gap of more than
    # one stop
    my %wideAlignments = ();
  CHILD: for ( my $bodyIX = 2 ; 1 ; $bodyIX += 3 ) {
        my $body   = $nodes->[$bodyIX -1];
        # say STDERR join " ", __FILE__, __LINE__, $bodyIX, $#$nodes;
        # say STDERR join " ", __FILE__, __LINE__, $nodes->[$bodyIX];
        last CHILD if not defined $body;
        my ( $bodyLine, $bodyColumn ) = $instance->nodeLC( $body );
        # say STDERR join " ", __FILE__, __LINE__, $bodyLine, $bodyColumn;
        my $backdentColumn   = $nodes->[$bodyIX];
        next CHILD if $bodyColumn == $backdentColumn;
        $allAlignments{$bodyColumn} //= [];
        push @{ $allAlignments{$bodyColumn} }, $bodyLine;
        my $gap       = $nodes->[ $bodyIX - 2 ];
        my $gapLength = $instance->gapLength($gap);
        next CHILD if $gapLength <= 2;
        $wideAlignments{$bodyColumn} //= [];
        push @{ $wideAlignments{$bodyColumn} }, $bodyLine;
    }

    # say STDERR join " ", __FILE__, __LINE__, scalar @{$nodes};

    return [-1, {lines => []}] if not scalar %wideAlignments;

    # wide alignments, in order first by descending count of wide instances;
    # then by descending count of all instances;
    # then by ascending first line
    my @sortedWideAlignments =
      sort {
        ( scalar @{ $wideAlignments{$b} } ) <=> ( scalar @{ $wideAlignments{$a} } )
        or ( scalar @{ $allAlignments{$b} } ) <=> ( scalar @{ $allAlignments{$a} } )
          or $wideAlignments{$a}[0] <=> $wideAlignments{$b}[0]
      }
      keys %wideAlignments;

    my $topWideColumn = $sortedWideAlignments[0];

    
    # say STDERR join " ", __FILE__, __LINE__, $topWideColumn;

    # Make sure this is actually an *alignment*, that is,
    # that there are at least 2 instances.  Otherwise,
    # ignore it.
    return [-1, {lines => []}] if scalar @{ $allAlignments{$topWideColumn} } <= 1;

    # say STDERR join " ", __FILE__, __LINE__, $topWideColumn;

    return [$topWideColumn, {lines => [splice(@{$allAlignments{$topWideColumn}}, 0, 5)]}];

}

sub chainAlignmentData {
    my ( $policy, $argNode ) = @_;
    my $instance  = $policy->{lint};
    my $chainable = $policy->{chainable};
    my $grammar   = $instance->{grammar};

    state $mortar = {
       tall5d => 1,
       norm5d => 1,
    };

    my $argNodeIX = $argNode->{IX};
    my $chainAlignmentData =
      $policy->{perNode}->{$argNodeIX}->{chainAlignmentData};
    return $chainAlignmentData if $chainAlignmentData;

    # Find the base column of the alignment
    my $alignmentBaseColumn;
    my $chainHead;
    my ( $argNodeLine, $argNodeColumn ) = $instance->nodeLC($argNode);
    my $thisNode = $argNode;
    # say STDERR join " ", __FILE__, __LINE__;
  LINK: while ($thisNode) {
    # say STDERR join " ", __FILE__, __LINE__;
        last LINK if $thisNode->{NEXT};                    # Must be rightmost
        my $symbolName = $instance->symbol($thisNode);
        if ($mortar->{$symbolName}) {
            $thisNode            = $thisNode->{PARENT};
            next LINK;
        }

        # TODO -- replace this test by always ending the LINK
        # loop on non-recognized-mortar non-chainable.
        last LINK if $symbolName =~ m/^(rick5dJog|ruck5dJog|fordHoop)$/;
    # say STDERR join " ", __FILE__, __LINE__;
        if (not $policy->chainable($thisNode) and not $instance->brickName($thisNode)) {
            say STDERR join " ", __FILE__, __LINE__, $instance->symbol($thisNode);
        }

        last LINK if not $policy->chainable($thisNode);    # Must be chainable
    # say STDERR join " ", __FILE__, __LINE__;
        my ( $thisNodeLine, $thisNodeColumn ) = $instance->nodeLC($thisNode);
        last LINK if $thisNodeLine != $argNodeLine;
    # say STDERR join " ", __FILE__, __LINE__;
        $alignmentBaseColumn = $thisNodeColumn;
        $chainHead           = $thisNode;
        $thisNode            = $thisNode->{PARENT};
    }
    # say STDERR join " ", __FILE__, __LINE__;

    return if not defined $alignmentBaseColumn;    # TODO: delete after development

    # Find the head (first link) of this alignment chain
  LINK: while ($thisNode) {
        last LINK if $thisNode->{NEXT};                    # Must be rightmost
        my $symbolName = $instance->symbol($thisNode);
        if ($mortar->{$symbolName}) {
            $thisNode            = $thisNode->{PARENT};
            next LINK;
        }
        last LINK if not $policy->chainable($thisNode);    # Must be chainable
        my ( $thisNodeLine, $thisNodeColumn ) = $instance->nodeLC($thisNode);
        last LINK if $thisNodeColumn < $alignmentBaseColumn;
        $chainHead = $thisNode if $thisNodeColumn == $alignmentBaseColumn;
        $thisNode = $thisNode->{PARENT};
    }

    # Traverse the whole chain, from the head
    $thisNode = $chainHead;
    my $parentNodeLine     = -1;
    my $parentElementCount = 0;
    my $currentChainOffset = 0;
    my $thisNodeIX;

    # Array, indexed by child index, of "silos"
    # of [ gap, body ], to align
    my @nodesToAlignByChildIX;
  LINK: while ($thisNode) {
        # say STDERR sprintf q{Traversing %s}, $instance->literalNode($thisNode);

        # End of loop tests --
        # Is it chainable?
        # Is the line,column right for the current chain?
        # CURRENT say STDERR join q{ }, __FILE__, __LINE__;
        my $symbolName = $instance->symbol($thisNode);
        # Skip if it's one of the appropriate list of mortar symbols.
        if ($mortar->{$symbolName}) {
            my $children = $thisNode->{children};
            $thisNode = $children->[$#$children];
            next LINK;
        }
        last LINK if not $policy->chainable($thisNode);
        my ( $thisNodeLine, $thisNodeColumn ) = $instance->nodeLC($thisNode);
        if ( $thisNodeColumn == $alignmentBaseColumn ) {
            $currentChainOffset = 0;
        }
        else {
            last LINK if $thisNodeLine != $parentNodeLine;
            $currentChainOffset += $parentElementCount;
        }

        # Tracks "last" node IX, so do not set $thisNodeIX before "end
        # of loop" tests.
        $thisNodeIX = $thisNode->{IX};
        # CURRENT say STDERR join q{ }, __FILE__, __LINE__;

        my @thisGapSeq   = @{ $policy->gapSeq0($thisNode) };
        my $elementCount = ( scalar @thisGapSeq ) / 2;

      ELEMENT:
        for (
            my $elementNumber = 1 ;
            $elementNumber <= $elementCount ;
            $elementNumber++
          )
        {
            my $gap           = $thisGapSeq[ $elementNumber * 2 - 2 ];
            my $element       = $thisGapSeq[ $elementNumber * 2 - 1 ];
            my ($gapLine)     = $instance->nodeLC($gap);
            my ($elementLine) = $instance->nodeLC($element);

            # Not in aligment if not on rune line
            next ELEMENT if $elementLine != $thisNodeLine;

            my $backdentColumn =
              $thisNodeColumn + ( $elementCount - $elementNumber ) * 2;
            push @{ $nodesToAlignByChildIX[$currentChainOffset + $elementNumber-1] }, $gap, $element, $backdentColumn;
        }

        $policy->{perNode}->{$thisNodeIX}->{chainAlignmentData} =
          { offset => $currentChainOffset };

        # Set "parent" data for next pass
        $parentNodeLine     = $thisNodeLine;
        $parentElementCount = $elementCount;

        # descend to rightmost child
        my $children = $thisNode->{children};
        $thisNode = $children->[$#$children];
    }

    my $lastNodeIX = $thisNodeIX;

    my @chainAlignments = ();
  ELEMENT:
    for (
        my $childIX = 0 ;
        $childIX <= $#nodesToAlignByChildIX;
        $childIX++
      )
    {
        my $nodesToAlign = $nodesToAlignByChildIX[$childIX];
        if (not $nodesToAlign) {
            $chainAlignments[ $childIX ] = [ -1, [] ];
            next ELEMENT;
        }
        $chainAlignments[ $childIX ] = $policy->findChainAlignment( $nodesToAlign);
    }

    $thisNode = $chainHead;
  LINK: while ($thisNode) {
        my $thisNodeIX = $thisNode->{IX};
        $policy->{perNode}->{$thisNodeIX}->{chainAlignmentData}->{alignments} =
          \@chainAlignments;
        last LINK if $thisNodeIX == $lastNodeIX;

        # descend to rightmost child
        my $children = $thisNode->{children};
        $thisNode = $children->[$#$children];
    }

    $chainAlignmentData = $policy->{perNode}->{$argNodeIX}->{chainAlignmentData};
    return $chainAlignmentData;
}

sub joggingHoonData {
    my ( $policy, $options, $node ) = @_;
    my $runeName = $policy->runeName($node);
    my %result   = ( node => $node, runeName => $runeName );
    my $instance = $policy->{lint};
    my $children = $node->{children};
    my $anchorColumn = $options->{anchorColumn};
    if ( not defined $anchorColumn ) {
        ( undef, $anchorColumn ) = $instance->nodeLC($node);
    }
    $result{anchorColumn} = $anchorColumn;
    my $firstOKJogLine = $options->{firstOKJogLine} // 0;
    $result{firstOKJogLine} = $firstOKJogLine;

    my $previousChild;
  CHILD: for my $childIX ( 0 .. $#$children ) {
        my $child  = $children->[$childIX];
        my $symbol = $instance->symbol($child);
        if ( $symbol ne 'rick5d' and $symbol ne 'ruck5d' ) {
            $previousChild = $child;
            next CHILD;
        }
        my ($previousChildLine) = $instance->nodeLC($previousChild);
        if ($runeName eq 'tiscol') {
            my $chessSide = 'kingside';
            $result{chessSide} = $chessSide;
            my $baseColumn = $anchorColumn + 4;
            $result{jogBaseColumn} = $baseColumn;
        } else {
            my $chessSide =
              $policy->chessSideOfJogging( $child, $anchorColumn,
                $previousChildLine + 1 );
            $result{chessSide} = $chessSide;
            my $baseColumn = $anchorColumn + ( $chessSide eq 'queenside' ? 4 : 2 );
            $result{jogBaseColumn} = $baseColumn;
        }
        my $jogBodyData = $policy->joggingBodyAlignment($child);
        ( $result{bodyAlignment}, $result{alignments} ) = @{$jogBodyData};
        return \%result;
    }
    die "No jogging found for ", $instance->symbol($node);
}

sub chessSideOfPairSequence {
    my ( $policy, $node, $runeColumn ) = @_;
    my $instance = $policy->{lint};

    my $symbolReverseDB = $instance->{symbolReverseDB};
    my $children        = $node->{children};
    my %sideCount       = ();
    my %bodyColumnCount = ();
    my $kingsideCount   = 0;
    my $queensideCount  = 0;
    my $lastLine = -1;
  CHILD: for my $childIX ( 0 .. $#$children ) {
        my $jog    = $children->[$childIX];
        my $symbol = $jog->{symbol};
        next CHILD if defined $symbol and $symbolReverseDB->{$symbol}->{gap};
        my $head = $jog->{children}->[0];
        my ( $line1, $column1 ) = $instance->line_column( $head->{start} );
        next CHILD if $line1 == $lastLine;
        $lastLine = $line1;
        # say STDERR " $column1 - $runeColumn >= 4 ";
        if ( $column1 - $runeColumn >= 4 ) {
            $queensideCount++;
            next CHILD;
        }
        $kingsideCount++;
    }
    return $kingsideCount > $queensideCount
      ? 'kingside'
      : 'queenside';
}

sub chessSideOfJogging {
    my ( $policy, $node, $runeColumn, $firstLine ) = @_;
    my $instance = $policy->{lint};

    my $symbolReverseDB = $instance->{symbolReverseDB};
    my $children        = $node->{children};
    my %sideCount       = ();
    my %bodyColumnCount = ();
    my $kingsideCount   = 0;
    my $queensideCount  = 0;
    my $lastLine = -1;
  CHILD: for my $childIX ( 0 .. $#$children ) {
        my $jog    = $children->[$childIX];
        my $symbol = $jog->{symbol};
        next CHILD if defined $symbol and $symbolReverseDB->{$symbol}->{gap};
        my $head = $jog->{children}->[0];
        my ( $line1, $column1 ) = $instance->line_column( $head->{start} );
        # Enforce a "first line" to disallow first line of joggings
        # which are not preceded by a vertical gap.
        next CHILD if $line1 < $firstLine;
        next CHILD if $line1 == $lastLine;
        $lastLine = $line1;
        # say STDERR " $column1 - $runeColumn >= 4 ";
        if ( $column1 - $runeColumn >= 4 ) {
            $queensideCount++;
            next CHILD;
        }
        $kingsideCount++;
    }
    return $kingsideCount > $queensideCount
      ? 'kingside'
      : 'queenside';
}

# Find the oversize alignment for this column of elements.
# $nodes must a ref to an array of alternating gap, body,
# nodes.
sub findAlignment {
    my ( $policy, $nodes ) = @_;
    my $instance = $policy->{lint};
    my %allAlignments = ();

    # local $Data::Dumper::Maxdepth = 1;
    # say STDERR join " ", __FILE__, __LINE__;

    # "wide", meaning an alignment following a gap of more than
    # one stop
    my %wideAlignments = ();
  CHILD: for ( my $bodyIX = 1 ; 1 ; $bodyIX += 2 ) {
        my $body   = $nodes->[$bodyIX];
        # say STDERR join " ", __FILE__, __LINE__, $bodyIX, $#$nodes;
        # say STDERR join " ", __FILE__, __LINE__, $nodes->[$bodyIX];
        last CHILD if not defined $body;
        # say STDERR join " ", __FILE__, __LINE__, $nodes->[$bodyIX];
        my ( $bodyLine, $bodyColumn ) = $instance->nodeLC( $body );
        $allAlignments{$bodyColumn} //= [];
        push @{ $allAlignments{$bodyColumn} }, $bodyLine;
        my $gap       = $nodes->[ $bodyIX - 1 ];
        my $gapLength = $instance->gapLength($gap);
        next CHILD if $gapLength <= 2;
        $wideAlignments{$bodyColumn} //= [];
        push @{ $wideAlignments{$bodyColumn} }, $bodyLine;
    }

    # say STDERR join " ", __FILE__, __LINE__, scalar @{$nodes};

    return [-1, []] if not scalar %wideAlignments;

    # wide alignments, in order first by descending count of wide instances;
    # then by descending count of all instances;
    # then by ascending first line
    my @sortedWideAlignments =
      sort {
        ( scalar @{ $wideAlignments{$b} } ) <=> ( scalar @{ $wideAlignments{$a} } )
        or ( scalar @{ $allAlignments{$b} } ) <=> ( scalar @{ $allAlignments{$a} } )
          or $wideAlignments{$a}[0] <=> $wideAlignments{$b}[0]
      }
      keys %wideAlignments;

    my $topWideColumn = $sortedWideAlignments[0];

    # say STDERR join " ", __FILE__, __LINE__, $topWideColumn;

    # Make sure this is actually an *alignment*, that is,
    # that there are at least 2 instances.  Otherwise,
    # ignore it.
    return [-1, []] if scalar @{ $allAlignments{$topWideColumn} } <= 1;

    # say STDERR join " ", __FILE__, __LINE__, $topWideColumn;

    return [$topWideColumn, [splice(@{$allAlignments{$topWideColumn}}, 0, 5)]];

}

sub joggingBodyAlignment {
    my ( $policy, $jogging ) = @_;
    my $instance  = $policy->{lint};
    my $children = $jogging->{children};

    # Traverse first to last to make it easy to record
    # first line of occurrence of each body column
    my @nodesToAlign = ();
  CHILD:
    for ( my $childIX = 0; $childIX <= $#$children ; $childIX+=2 ) {
        my $jog         = $children->[$childIX];
        my $jogChildren = $jog->{children};
        my $jogChild1 = $jogChildren->[1];
        my $jogChild2 = $jogChildren->[2];
        my ( $line1    )    = $instance->nodeLC($jogChild1);
        my ( $line2    )    = $instance->nodeLC($jogChild2);
        next CHILD if $line1 ne $line2;
        push @nodesToAlign, $jogChild1, $jogChild2;
    }
    return $policy->findAlignment( \@nodesToAlign );
}

sub check_1Jogging {
    my ( $policy, $node ) = @_;
    my $instance  = $policy->{lint};
    my $lineToPos = $instance->{lineToPos};

    my ( $rune, $headGap, $head, $joggingGap, $jogging, $tistisGap, $tistis ) =
      @{ $policy->gapSeq($node) };

    my ( $runeLine,    $runeColumn )    = $instance->nodeLC($rune);
    my ( $headLine,    $headColumn )    = $instance->nodeLC($head);
    my ( $joggingLine, $joggingColumn ) = $instance->nodeLC($jogging);
    my ( $tistisLine,  $tistisColumn )  = $instance->nodeLC($tistis);

    my $anchorLine = $runeLine;
    my ( $anchorColumn, $anchorData ) = $policy->reanchorInc(
        $node,
        {
            tallKetlus => 1,
        }
    );
    my $anchorDetails = $policy->anchorDetails( $node, $anchorData );

    my $joggingHoonData = $policy->joggingHoonData(
        { anchorColumn => $anchorColumn, firstOKJogLine => $headLine + 1 },
        $node );
    $policy->setInheritedAttribute( $node, 'joggingHoonData',
        $joggingHoonData );
    my $jogBaseColumn = $joggingHoonData->{jogBaseColumn};
    my $chessSide     = $joggingHoonData->{chessSide};

    my $joggingRules = $instance->{joggingRule};

    my @mistakes = ();
    my $runeName = $policy->runeName($node);

  CHECK_HEAD: {
        if ( $headLine != $runeLine ) {
            my $msg = sprintf
              "%s %s head %s; should be on rune line %d",
              $chessSide,
              $runeName,
              describeLC( $headLine, $headColumn ),
              $runeLine;
            push @mistakes,
              {
                desc         => $msg,
                subpolicy    => [ $runeName, 'split' ],
                parentLine   => $runeLine,
                parentColumn => $runeColumn,
                line         => $headLine,
                column       => $headColumn,
                reportLine   => $headLine,
                reportColumn => $headColumn,
                expectedLine => $runeLine,
                details => [ [ @{$anchorDetails}  ]],
              };
            last CHECK_HEAD;
        }

        my $gapLength = $headGap->{length};
        my $expectedLength = ( $chessSide eq 'kingside' ? 2 : 4 );
        if ( $gapLength != $expectedLength ) {
            my $msg = sprintf
              "%s %s head %s; %s",
              $chessSide,
              $runeName,
              describeLC( $headLine, $headColumn ),
              describeMisindent2( $gapLength, $expectedLength );
            push @mistakes,
              {
                desc         => $msg,
                subpolicy    => [ $runeName, 'head-hgap' ],
                parentLine   => $runeLine,
                parentColumn => $runeColumn,
                line         => $headLine,
                column       => $headColumn,
                reportLine   => $headLine,
                reportColumn => $headColumn,
                details => [ [ @{$anchorDetails}  ]],
              };
        }
    }

  CHECK_JOGGING_GAP: {
        if ( $headLine == $joggingLine ) {
            my $msg = sprintf
              "%s %s jogging %s should not be joined",
              $chessSide,
              $runeName,
              describeLC( $joggingLine, $joggingColumn );
            push @mistakes,
              {
                desc         => $msg,
                subpolicy    => [ $runeName, 'jogging-joined' ],
                parentLine   => $runeLine,
                parentColumn => $runeColumn,
                line         => $joggingLine,
                column       => $joggingColumn,
                reportLine   => $joggingLine,
                reportColumn => $joggingColumn,
                details => [ [ @{$anchorDetails}  ]],
              };
            last CHECK_JOGGING_GAP;
        }
        push @mistakes,
          @{
            $policy->checkOneLineGap(
                $joggingGap,
                {
                    mainColumn => $anchorColumn,
                    preColumn  => $jogBaseColumn,
                    runeName        => $runeName,
                    subpolicy  => [ $runeName, 'jogging-gap' ],
                    parent     => $rune,
                    topicLines => [$joggingLine],
                details => [ [ @{$anchorDetails}  ]],
                }
            )
          };
    }

    push @mistakes,
      @{
        $policy->checkOneLineGap(
            $tistisGap,
            {
                mainColumn => $anchorColumn,
                preColumn  => $jogBaseColumn,
                runeName        => $runeName,
                subpolicy  => [ $runeName, 'tistis-gap' ],
                topicLines => [$tistisLine],
                details => [ [ @{$anchorDetails}  ]],
            }
        )
      };

    push @mistakes,
      @{
        $policy->checkTistis(
            $tistis,
            {
                tag            => $runeName,
                subpolicy      => [$runeName],
                expectedColumn => $anchorColumn,
                details => [ [ @{$anchorDetails}  ]],
            }
        )
      };

    return \@mistakes;
}

sub check_2Jogging {
    my ( $policy, $node ) = @_;
    my $instance  = $policy->{lint};
    my $lineToPos = $instance->{lineToPos};

    my $runeName = $policy->runeName($node);
    my (
        $rune,       $headGap, $head,      $subheadGap, $subhead,
        $joggingGap, $jogging, $tistisGap, $tistis
    ) = @{ $policy->gapSeq($node) };

    my ( $runeLine,    $runeColumn )    = $instance->nodeLC($rune);
    my ( $anchorLine,  $anchorColumn )  = ( $runeLine, $runeColumn );
    my ( $headLine,    $headColumn )    = $instance->nodeLC($head);
    my ( $subheadLine, $subheadColumn ) = $instance->nodeLC($subhead);
    my ( $joggingLine, $joggingColumn ) = $instance->nodeLC($jogging);
    my ( $tistisLine,  $tistisColumn )  = $instance->nodeLC($tistis);

    my $joggingHoonData = $policy->joggingHoonData({}, $node );
    $policy->setInheritedAttribute($node, 'joggingHoonData', $joggingHoonData);
    my $jogBaseColumn = $joggingHoonData->{jogBaseColumn};
    my $chessSide = $joggingHoonData->{chessSide};
    my $isKingside   = $chessSide eq 'kingside';

    my $joggingRules = $instance->{joggingRule};

    my @mistakes = ();

    my $isJoined = $headLine == $subheadLine;
    my @subpolicy =
      ( $runeName, $chessSide, ( $isJoined ? 'joined' : 'split' ) );

    if ( $headLine != $runeLine ) {
        my $msg = sprintf
          "%s %s head %s; should be on rune line %d",
          $chessSide,
          $runeName,
          describeLC( $headLine, $headColumn ),
          $runeLine;
        push @mistakes,
          {
            desc         => $msg,
            subpolicy    => [ @subpolicy, 'head-split' ],
            parentLine   => $runeLine,
            parentColumn => $runeColumn,
            reportLine   => $headLine,
            reportColumn => $headColumn,
            line         => $headLine,
            column       => $headColumn,
          };
    }

    my $expectedHeadColumn = $anchorColumn + ( $isKingside ? 4 : 6 );
    if ( $headColumn != $expectedHeadColumn ) {
        my $msg = sprintf
          "%s %s head %s; %s",
          $chessSide,
          $runeName,
          describeLC( $headLine, $headColumn ),
          describeMisindent2( $headColumn, $expectedHeadColumn );
        push @mistakes,
          {
            desc         => $msg,
            subpolicy    => [ @subpolicy, 'head-hgap' ],
            parentLine   => $runeLine,
            parentColumn => $runeColumn,
            reportLine   => $headLine,
            reportColumn => $headColumn,
            line         => $headLine,
            column       => $headColumn,
          };
    }

    if ($isJoined) {
        my $subheadLength = $subheadGap->{length};
        if ($subheadLength != 2) {
            my ( undef, $subheadGapColumn ) = $instance->nodeLC($subheadGap);
            my $expectedSubheadColumn = $subheadGapColumn + 2;
            my $msg                   = sprintf
              "%s %s subhead %s; %s",
              $chessSide,
              $runeName,
              describeLC( $subheadLine, $subheadColumn ),
              describeMisindent2( $subheadLength, 2 );
            push @mistakes,
              {
                desc         => $msg,
                subpolicy    => [ @subpolicy, 'subhead-hgap' ],
                parentLine   => $runeLine,
                parentColumn => $runeColumn,
                reportLine   => $subheadLine,
                reportColumn => $subheadColumn,
                line         => $subheadLine,
                column       => $subheadColumn,
              };
        }
    }

    if ( not $isJoined ) {

        # If here, we have "split heads", which should follow the "pseudo-jog"
        # format

        push @mistakes,
          @{
            $policy->checkOneLineGap(
                $subheadGap,
                {
                    mainColumn => $anchorColumn,
                    runeName        => $runeName,
                    subpolicy  => [ @subpolicy, 'subhead-vgap' ],
                    topicLines => [$subheadLine],
                }
            )
          };

        my $expectedSubheadColumn = $headColumn - 2;
        if ( $subheadColumn != $expectedSubheadColumn ) {
            my $msg = sprintf
              "%s %s subhead %s; %s",
              $chessSide,
              $runeName,
              describeLC( $subheadLine, $subheadColumn ),
              describeMisindent2( $subheadColumn, $expectedSubheadColumn );
            push @mistakes,
              {
                desc         => $msg,
                subpolicy    => [ @subpolicy, 'subhead-indent' ],
                parentLine   => $runeLine,
                parentColumn => $runeColumn,
                reportLine   => $subheadLine,
                reportColumn => $subheadColumn,
                line         => $subheadLine,
                column       => $subheadColumn,
              };
        }
    }

    push @mistakes,
      @{
        $policy->checkOneLineGap(
            $joggingGap,
            {
                mainColumn => $anchorColumn,
                preColumn  => $jogBaseColumn,
                runeName        => $runeName,
                subpolicy  => [@subpolicy, 'jogging-vgap'],
                topicLines => [$joggingLine],
            }
        )
      };

    push @mistakes,
      @{
        $policy->checkOneLineGap(
            $tistisGap,
            {
                mainColumn => $anchorColumn,
                preColumn  => $jogBaseColumn,
                runeName        => $runeName,
                subpolicy  => [@subpolicy, 'tistis-vgap'],
                topicLines => [$tistisLine],
            }
        )
      };

    push @mistakes,
      @{
        $policy->checkTistis(
            $tistis,
            {
                tag            => $runeName,
                subpolicy      => [@subpolicy],
                expectedColumn => $anchorColumn,
            }
        )
      };

    return \@mistakes;
}

sub check_Jogging1 {
    my ( $policy, $node ) = @_;
    my $instance  = $policy->{lint};
    my $lineToPos = $instance->{lineToPos};

    my $runeName = $policy->runeName($node);
    my ( $rune, $joggingGap, $jogging, $tistisGap, $tistis, $tailGap, $tail ) =
      @{ $policy->gapSeq($node) };

    my ( $runeLine,    $runeColumn )    = $instance->nodeLC($rune);
    my ( $joggingLine, $joggingColumn ) = $instance->nodeLC($jogging);
    my ( $tistisLine,  $tistisColumn )  = $instance->nodeLC($tistis);
    my ( $tailLine,    $tailColumn )    = $instance->nodeLC($tail);
    my ( $anchorLine,  $anchorColumn )  = ( $runeLine, $runeColumn );

    my $joggingHoonData = $policy->joggingHoonData({}, $node );
    $policy->setInheritedAttribute($node, 'joggingHoonData', $joggingHoonData);
    my $jogBaseColumn = $joggingHoonData->{jogBaseColumn};
    my $chessSide = $joggingHoonData->{chessSide};

    my @mistakes = ();

    if ( $joggingLine != $runeLine ) {
        my $msg = sprintf
          "jogging %s; should be on rune line %d",
          describeLC( $joggingLine, $joggingColumn ),
          $runeLine;
        push @mistakes, {
            desc => $msg,
            subpolicy => [ $runeName, 'jogging', 'split' ],
            parentLine   => $runeLine,
            parentColumn => $runeColumn,
            line         => $joggingLine,
            column       => $joggingColumn,
            reportLine   => $joggingLine,
            reportColumn => $joggingColumn,
            expectedLine => $runeLine,
        };
    }

    if ( $joggingColumn != $jogBaseColumn ) {
        my $msg = sprintf
          "jogging %s; %s",
          describeLC( $joggingLine, $joggingColumn ),
          describeMisindent2( $joggingColumn, $jogBaseColumn );
        push @mistakes, {
            desc => $msg,
            subpolicy => [ $runeName, 'jogging-indent' ],
            parentLine   => $runeLine,
            parentColumn => $runeColumn,
            line         => $joggingLine,
            column       => $joggingColumn,
            reportLine   => $joggingLine,
            reportColumn => $joggingColumn,
        };
    }

    push @mistakes,
      @{
        $policy->checkOneLineGap(
            $tistisGap,
            {
                mainColumn => $anchorColumn,
                preColumn  => $jogBaseColumn,
                runeName        => $runeName,
                subpolicy  => [$runeName, 'tistis-gap'],
                topicLines => [$tistisLine],
            }
        )
      };

    push @mistakes,
      @{
        $policy->checkTistis(
            $tistis,
            {
                tag            => $runeName,
                subpolicy => [ $runeName ],
                expectedColumn => $anchorColumn + 2,
            }
        )
      };

    push @mistakes,
      @{
        $policy->checkOneLineGap(
            $tailGap,
            {
                mainColumn => $anchorColumn,
                runeName        => $runeName,
                subpolicy  => [$runeName, 'tail-vgap'],
                topicLines => [$tailLine],
            }
        )
      };

    my $expectedTailColumn = $anchorColumn;
    if ( $tailColumn != $expectedTailColumn ) {
        my $msg = sprintf
          "1-jogging tail %s; %s",
          describeLC( $tailLine, $tailColumn ),
          describeMisindent2( $tailColumn, $expectedTailColumn );
        push @mistakes,
          {
            desc         => $msg,
            subpolicy    => [ $runeName, 'tail-indent' ],
            parentLine   => $runeLine,
            parentColumn => $runeColumn,
            line         => $tailLine,
            column       => $tailColumn,
            reportLine   => $tailLine,
            reportColumn => $tailColumn,
          };
    }

    return \@mistakes;
}

sub fascomBodyAlignment {
    my ( $policy, $node ) = @_;
    my $instance = $policy->{lint};
    my $children = $node->{children};
    my $firstBodyColumn;
    my %firstLine       = ();
    my %bodyColumnCount = ();
    my @nodesToAlign = ();

  CHILD:
    for ( my $childIX = 0 ; $childIX <= $#$children ; $childIX++ ) {
        my $jog = $children->[$childIX];
        my ( $gap,      $body )       = @{ $policy->gapSeq0($jog) };
        my ( $headLine, $headColumn ) = $instance->nodeLC($jog);
        my ( $bodyLine, $bodyColumn ) = $instance->nodeLC($body);
        next CHILD unless $headLine == $bodyLine;
        push @nodesToAlign, $gap, $body;
    }
    return $policy->findAlignment( \@nodesToAlign );
}

# Find the body column, based on alignment within
# a parent hoon.
sub fascomBodyColumn {
    my ( $policy, $node ) = @_;
    my $nodeIX           = $node->{IX};
    my $fascomBodyColumn = $policy->{perNode}->{$nodeIX}->{fascomBodyColumn};
    return $fascomBodyColumn if defined $fascomBodyColumn;

    my $instance = $policy->{lint};
    my $nodeName = $instance->brickName($node);
    if ( not $nodeName or not $nodeName eq 'fordFascom' ) {

        my $fascomBodyColumn = $policy->fascomBodyColumn( $node->{PARENT} );
        $policy->{perNode}->{$nodeIX}->{fascomBodyColumn} = $fascomBodyColumn;
        return $fascomBodyColumn;
    }

    my $children = $node->{children};
  CHILD: for my $childIX ( 0 .. $#$children ) {
        my $child  = $children->[$childIX];
        my $symbol = $instance->symbol($child);
        next CHILD if $symbol ne 'fordFascomBody';
        my $children2 = $child->{children};
      CHILD2: for my $childIX2 ( 0 .. $#$children2 ) {
            my $child2  = $children2->[$childIX2];
            my $symbol2 = $instance->symbol($child2);
            next CHILD2 if $symbol2 ne 'fordFascomElements';
            my $fascomBodyData = $policy->fascomBodyAlignment($child2);
            $policy->{perNode}->{$nodeIX}->{fascomBodyData} =
              $fascomBodyData;
            return $fascomBodyData;
        }
    }
    die "No jogging found for ", $instance->symbol($node);
}

# TODO: Add a check (optional?) for queenside joggings with no
# split jogs.
sub checkFascomElement {
    my ( $policy, $node ) = @_;
    my $instance = $policy->{lint};

    my $runeNode = $instance->ancestorByBrickName( $node, 'fordFascom' );
    my $runeNodeIX = $runeNode->{IX};
    my $isJoined = $policy->{perNode}->{$runeNodeIX}->{isJoined};
    my $chessSide = $policy->{perNode}->{$runeNodeIX}->{chessSide};
    my $queenside = $chessSide eq 'queenside';

    my ( $runeLine,   $runeColumn )   = $instance->nodeLC($runeNode);
    my ( $parentLine, $parentColumn ) = $instance->nodeLC($node);
    my ( $headLine, $headColumn ) = ( $parentLine, $parentColumn );

    my ( $gap,        $body )         = @{ $policy->gapSeq0($node) };
    my ( $bodyLine,   $bodyColumn )   = $instance->nodeLC($body);

    my $anchorLine = $runeLine;
    my ( $anchorColumn, $anchorData ) = $policy->reanchorInc(
        $runeNode,
        {
            fordFascen => 1,
        }
    );
    my $anchorDetails = $policy->anchorDetails( $node, $anchorData );

    my ( $fascomBodyColumn, $fascomBodyColumnDetails ) =
      @{ $policy->fascomBodyColumn( $node, { fordFascom => 1 } ) };

    my @mistakes = ();
    my $tag      = 'fascom-element';

    my $baseColumn = $anchorColumn + ($isJoined ? 4 : 2) + ($queenside ? 2 : 0);

    if ( $headLine == $bodyLine ) {
        my $gapLength = $gap->{length};

        if ( $gapLength != 2 and $bodyColumn != $fascomBodyColumn ) {
            my $msg = sprintf 'Fascom element body %s; %s',
              describeLC( $bodyLine, $bodyColumn ),
              describeMisindent2( $bodyColumn, $fascomBodyColumn );
            push @mistakes,
              {
                desc           => $msg,
                subpolicy => [ $tag, 'body-hgap' ],
                details => [ [ @{$anchorDetails} ] ],
                parentLine     => $parentLine,
                parentColumn   => $parentColumn,
                line           => $bodyLine,
                column         => $bodyColumn,
                reportLine           => $bodyLine,
                reportColumn         => $bodyColumn,
                topicLines     => [$runeLine],
              };
        }
        return \@mistakes;
    }

    # If here head line != body line
    my $pseudojoinColumn = $policy->pseudojoinColumn($gap);
    if ( $pseudojoinColumn >= 0 ) {
        my $expectedBodyColumn = $pseudojoinColumn;
        if ( $bodyColumn != $expectedBodyColumn ) {
            my $msg =
              sprintf
'Pseudo-joined Fascom element %s; body/comment mismatch; body is %s',
              describeLC( $parentLine, $parentColumn ),
              describeMisindent2( $bodyColumn, $expectedBodyColumn );
            push @mistakes,
              {
                desc           => $msg,
                subpolicy => [ $tag, 'pseudo-comment-indent' ],
                details => [ [ @{$anchorDetails} ] ],
                parentLine     => $parentLine,
                parentColumn   => $parentColumn,
                line           => $bodyLine,
                column         => $bodyColumn,
                reportLine           => $bodyLine,
                reportColumn         => $bodyColumn,
                topicLines     => [$runeLine],
              };
        }

        # Treat the fascom body alignment as the "expected one"
        my $expectedColumn = $fascomBodyColumn;
        if ( $bodyColumn != $expectedColumn ) {
            my $msg = sprintf 'Pseudo-joined Fascom element %s; body %s',
              describeLC( $parentLine, $parentColumn ),
              describeMisindent2( $bodyColumn, $expectedBodyColumn );
            push @mistakes,
              {
                desc           => $msg,
                subpolicy => [ $tag, 'pseudo-hgap' ],
                details => [ [ @{$anchorDetails} ] ],
                parentLine     => $parentLine,
                parentColumn   => $parentColumn,
                line           => $bodyLine,
                column         => $bodyColumn,
                reportLine           => $bodyLine,
                reportColumn         => $bodyColumn,
                topicLines     => [$runeLine],
              };
        }
        return \@mistakes;
    }

    # If here, this is (or should be) a split jog
    my $expectedBodyColumn = $headColumn + ($queenside ? -2 : 2);

    if ( $bodyColumn != $expectedBodyColumn ) {
        my $msg = sprintf 'Fascom element body %s; %s',
          describeLC( $bodyLine, $bodyColumn ),
          describeMisindent2( $bodyColumn, $expectedBodyColumn );
        push @mistakes,
          {
            desc           => $msg,
            subpolicy => [ $tag, 'body-indent' ],
            details => [ [ @{$anchorDetails} ] ],
            parentLine     => $parentLine,
            parentColumn   => $parentColumn,
            line           => $bodyLine,
            column         => $bodyColumn,
            reportLine           => $bodyLine,
            reportColumn         => $bodyColumn,
            topicLines     => [$runeLine],
          };
        return \@mistakes;
    }

    push @mistakes,
      @{
        $policy->checkOneLineGap(
            $gap,
            {
                mainColumn => $expectedBodyColumn,
                runeName        => $tag,
                subpolicy => [ $tag ],
                details => [ [ @{$anchorDetails} ] ],
                topicLines => [$runeLine],
            }
        )
      };

    return \@mistakes;
}

sub checkFastis {
    my ( $policy, $node ) = @_;
    my $instance = $policy->{lint};

    # fordFastis ::= (- FASTISGAP -) SYM4K (- GAP -) horn
    my ( $headGap, $symbol, $hornGap, $horn ) = @{ $policy->gapSeq0($node) };
    my ( $parentLine, $parentColumn ) = $instance->nodeLC($node);
    my ( $symbolLine, $symbolColumn ) = $instance->nodeLC($symbol);
    my ( $hornLine,   $hornColumn )   = $instance->nodeLC($horn);

    my @mistakes = ();
    my $runeName      = 'fastis';
    my $tag      = 'fastis';

  CHECK_SYMBOL: {
        if ( $symbolLine != $parentLine ) {
            my $msg = sprintf 'fastis symbol %s; symbol must be on rune line',
              describeLC( $symbolLine, $symbolColumn );
            push @mistakes,
              {
                desc         => $msg,
                subpolicy => [ $runeName, 'same-line' ],
                parentLine   => $parentLine,
                parentColumn => $parentColumn,
                line         => $symbolLine,
                column       => $symbolColumn,
                reportLine   => $symbolLine,
                reportColumn => $symbolColumn,
              };
            last CHECK_SYMBOL;
        }

        my $expectedSymbolColumn = $parentColumn + 4;
        if ( $symbolColumn != $expectedSymbolColumn ) {
            my $msg = sprintf 'fastis symbol %s; %s',
              describeLC( $symbolLine, $symbolColumn ),
              describeMisindent2( $symbolColumn, $expectedSymbolColumn );
            push @mistakes,
              {
                desc         => $msg,
                subpolicy => [ $runeName, 'head-hgap' ],
                parentLine   => $parentLine,
                parentColumn => $parentColumn,
                line         => $symbolLine,
                column       => $symbolColumn,
                reportLine   => $symbolLine,
                reportColumn => $symbolColumn,
              };
        }
    }

  CHECK_HORN: {
        if ( $hornLine == $symbolLine ) {
            my $symbolLength       = $symbol->{length};
            my $expectedHornColumn = $symbolColumn + $symbolLength + 2;
            if ( $hornColumn != $expectedHornColumn ) {
                my $msg = sprintf 'fastis horn %s; %s',
                  describeLC( $hornLine, $hornColumn ),
                  describeMisindent2( $hornColumn, $expectedHornColumn );
                push @mistakes,
                  {
                    desc         => $msg,
                    subpolicy => [ $runeName, 'body-hgap' ],
                    parentLine   => $parentLine,
                    parentColumn => $parentColumn,
                    line         => $hornLine,
                    column       => $hornColumn,
                    reportLine   => $hornLine,
                    reportColumn => $hornColumn,
                  };
            }
            last CHECK_HORN;
        }

        # if here, horn Line != symbol line
        my $expectedHornColumn = $parentColumn + 2;

        push @mistakes,
          @{
            $policy->checkOneLineGap(
                $hornGap,
                {
                    mainColumn => $expectedHornColumn,
                    runeName        => $tag,
                subpolicy => [ $runeName ],
                }
            )
          };

        if ( $hornColumn != $expectedHornColumn ) {
            my $msg = sprintf 'fastis split horn %s; %s',
              describeLC( $hornLine, $hornColumn ),
              describeMisindent2( $hornColumn, $expectedHornColumn );
            push @mistakes,
              {
                desc         => $msg,
                subpolicy => [ $runeName, 'body-indent' ],
                parentLine   => $parentLine,
                parentColumn => $parentColumn,
                line         => $hornLine,
                column       => $hornColumn,
                reportLine   => $hornLine,
                reportColumn => $hornColumn,
              };
        }

    }

    return \@mistakes;
}

sub checkKingsideJog {
    my ( $policy, $node, $expectedHeadColumn ) = @_;
    my $instance          = $policy->{lint};
    my $fileName          = $instance->{fileName};
    my $grammar           = $instance->{grammar};
    my $ruleID            = $node->{ruleID};
    my ( $parentLine, $parentColumn ) =
      $instance->line_column( $node->{start} );

    my $joggingHoonData = $policy->getInheritedAttribute($node, 'joggingHoonData');
    my $jogBodyColumn = $joggingHoonData->{bodyAlignment};
    $jogBodyColumn //= -1;
    my $jogBodyColumnLines = $joggingHoonData->{alignments};
    my $runeName = $joggingHoonData->{runeName};
    my $brickNode = $joggingHoonData->{node};
    my ( $brickLine, $brickColumn ) = $instance->nodeLC($brickNode);
    my $baseColumn = $joggingHoonData->{jogBaseColumn};

    my @mistakes = ();

    my $children = $node->{children};
    my $head     = $children->[0];
    my $gap      = $children->[1];
    my $body     = $children->[2];
    my ( $headLine, $headColumn ) =
      $instance->line_column( $head->{start} );
    my ( $bodyLine, $bodyColumn ) =
      $instance->line_column( $body->{start} );
    my $sideDesc = 'kingside';

    if ( $headColumn != $expectedHeadColumn ) {
        my $msg = sprintf 'Jog %s head %s; %s',
          $sideDesc,
          describeLC( $headLine, $headColumn ),
          describeMisindent2( $headColumn, $expectedHeadColumn );
        push @mistakes,
          {
            desc           => $msg,
            subpolicy => [ $runeName, 'jog-head-indent' ],
            parentLine     => $parentLine,
            parentColumn   => $parentColumn,
            line           => $headLine,
            column         => $headColumn,
            reportLine           => $headLine,
            reportColumn         => $headColumn,
            topicLines     => [$brickLine],
          };
    }

    if ( $headLine == $bodyLine ) {
        my $gapLength = $gap->{length};

        if ( $gapLength != 2 and $bodyColumn != $jogBodyColumn ) {
            my $misindent;
            my $details;
            my @topicLines = ($brickLine);
            if ( $jogBodyColumn < 0 ) {
              $misindent = describeMisindent2( $gapLength, 2 );
                $details = [ [ "no inter-line alignment detected" ] ];
            }
            else {
              $misindent = describeMisindent2( $bodyColumn, $jogBodyColumn );
                my $oneBasedColumn = $jogBodyColumn + 1;
                push @topicLines, @{$jogBodyColumnLines};
                $details = [
                    [
                        sprintf 'inter-line alignment is %d, see %s',
                        $oneBasedColumn,
                        (
                            join q{ },
                            map { $_ . ':' . $oneBasedColumn }
                              @{$jogBodyColumnLines}
                        )
                    ]
                ];
            }
            my $msg = sprintf 'Jog %s body %s; %s',
              $sideDesc,
              describeLC( $bodyLine, $bodyColumn ),
              $misindent;
            push @mistakes,
              {
                desc           => $msg,
            subpolicy => [ $runeName, 'jog-body-indent' ],
                parentLine     => $parentLine,
                parentColumn   => $parentColumn,
                line           => $bodyLine,
                column         => $bodyColumn,
            reportLine           => $bodyLine,
            reportColumn         => $bodyColumn,
                topicLines     => \@topicLines,
                details        => $details,
              };
        }
        return \@mistakes;
    }

    # If here head line != body line
    my $pseudojoinColumn = $policy->pseudojoinColumn($gap);
    if ( $pseudojoinColumn >= 0 ) {
        my $expectedBodyColumn = $pseudojoinColumn;
        if ( $bodyColumn != $expectedBodyColumn ) {
            my $msg =
              sprintf
              'Pseudo-joined %s Jog %s; body/comment mismatch; body is %s',
              $sideDesc,
              describeLC( $parentLine, $parentColumn ),
              describeMisindent2( $bodyColumn, $expectedBodyColumn );
            push @mistakes,
              {
                desc           => $msg,
            subpolicy => [ $runeName, 'jog-pseudojoin-mismatch' ],
                parentLine     => $parentLine,
                parentColumn   => $parentColumn,
                line           => $bodyLine,
                column         => $bodyColumn,
            reportLine           => $bodyLine,
            reportColumn         => $bodyColumn,
                topicLines     => [$brickLine],
              };
        }
        my $headLength = $head->{length};

        # Treat the jogging body alignment as the "expected one"
        my $expectedColumn = $jogBodyColumn;
        my $raggedColumn   = $headColumn + $headLength + 2;
        if ( $bodyColumn != $raggedColumn and $bodyColumn != $expectedColumn ) {
            my $msg = sprintf 'Pseudo-joined %s Jog %s; body %s',
              $sideDesc, describeLC( $parentLine, $parentColumn ),
              describeMisindent2( $bodyColumn, $expectedBodyColumn );
            push @mistakes,
              {
                desc           => $msg,
            subpolicy => [ $runeName, 'jog-pseudojoin-indent' ],
                parentLine     => $parentLine,
                parentColumn   => $parentColumn,
                line           => $bodyLine,
                column         => $bodyColumn,
            reportLine           => $bodyLine,
            reportColumn         => $bodyColumn,
                topicLines     => [$brickLine],
              };
        }
        return \@mistakes;
    }

    # If here, this is (or should be) a split jog
    my $expectedBodyColumn = $baseColumn + 2;

    if ( $bodyColumn != $expectedBodyColumn ) {
        my $msg = sprintf 'Jog %s body %s; %s',
          $sideDesc,
          describeLC( $bodyLine, $bodyColumn ),
          describeMisindent2( $bodyColumn, $expectedBodyColumn );
        push @mistakes,
          {
            desc           => $msg,
            subpolicy => [ $runeName, 'jog-body-indent' ],
            parentLine     => $parentLine,
            parentColumn   => $parentColumn,
            line           => $bodyLine,
            column         => $bodyColumn,
            reportLine           => $bodyLine,
            reportColumn         => $bodyColumn,
            topicLines     => [$brickLine],
            details        => [
                [
                    sprintf qq{lexeme "%s" %s},
                    $instance->lexeme( $brickLine, $brickColumn ),
                    describeLC( $brickLine, $brickColumn )
                ]
            ],
          };
        return \@mistakes;
    }

    push @mistakes,
      @{
        $policy->checkOneLineGap(
            $gap,
            {
                mainColumn => $expectedBodyColumn,
                runeName        => $runeName,
                subpolicy => [ $runeName ],
                topicLines => [ $bodyLine, $brickLine ],
            }
        )
      };

    return \@mistakes;
}

sub checkQueensideJog {
    my ( $policy, $node, $expectedHeadColumn ) = @_;
    my $instance = $policy->{lint};
    my ( $parentLine, $parentColumn ) =
      $instance->line_column( $node->{start} );
    my $ruleID   = $node->{ruleID};
    my $fileName = $instance->{fileName};
    my $grammar  = $instance->{grammar};

    my @mistakes = ();

    my $joggingRules = $instance->{joggingRule};
    my $joggingHoonData = $policy->getInheritedAttribute($node, 'joggingHoonData');
    my $jogBodyColumn = $joggingHoonData->{bodyAlignment};
    $jogBodyColumn //= -1;
    my $jogBodyColumnLines = $joggingHoonData->{alignments};
    my $runeName = $joggingHoonData->{runeName};
    my $brickNode = $joggingHoonData->{node};
    my ( $brickLine, $brickColumn ) = $instance->nodeLC($brickNode);
    my $baseColumn = $joggingHoonData->{jogBaseColumn};

    my $children = $node->{children};
    my $head     = $children->[0];
    my $gap      = $children->[1];
    my $body     = $children->[2];
    my ( $headLine, $headColumn ) =
      $instance->line_column( $head->{start} );
    my ( $bodyLine, $bodyColumn ) =
      $instance->line_column( $body->{start} );
    my $sideDesc = 'queenside';

    if ( $headColumn != $expectedHeadColumn ) {
        my $msg = sprintf 'Jog %s head %s; %s',
          $sideDesc,
          describeLC( $headLine, $headColumn ),
          describeMisindent2( $headColumn, $expectedHeadColumn );
        push @mistakes,
          {
            desc           => $msg,
            subpolicy => [ $runeName, 'jog-head-indent' ],
            parentLine     => $parentLine,
            parentColumn   => $parentColumn,
            line           => $headLine,
            column         => $headColumn,
            reportLine           => $headLine,
            reportColumn         => $headColumn,
            topicLines     => [$brickLine],
          };
    }

    # Check for flat queenside misalignments
    my $expectedBodyColumn = $jogBodyColumn;
    if ( $headLine == $bodyLine ) {
        my $gapLength = $gap->{length};
        if ( $gapLength != 2 and $bodyColumn != $jogBodyColumn ) {
            my $misindent;
            my $details;
            my @topicLines = ($brickLine);
            if ($jogBodyColumn < 0) {
              $misindent = describeMisindent2( $gapLength, 2 );
               $details = [
                  [
                  "no inter-line alignment detected"
                  ]
               ];
            } else {
              $misindent = describeMisindent2( $bodyColumn, $jogBodyColumn );
               my $oneBasedColumn = $jogBodyColumn+1;
               push @topicLines, @{$jogBodyColumnLines};
               $details = [
                  [
                  sprintf 'inter-line alignment is %d, see %s', $oneBasedColumn,
                  (join q{ }, map { $_ . ':' . $oneBasedColumn } @{$jogBodyColumnLines})
                  ]
               ];
            }
            my $msg = sprintf 'Jog %s body %s; %s',
              $sideDesc,
              describeLC( $bodyLine, $bodyColumn ),
              $misindent;
            push @mistakes,
              {
                desc           => $msg,
                subpolicy => [ $runeName, 'jog-body-indent' ],
                parentLine     => $parentLine,
                parentColumn   => $parentColumn,
                line           => $bodyLine,
                column         => $bodyColumn,
            reportLine           => $bodyLine,
            reportColumn         => $bodyColumn,
                topicLines     => \@topicLines,
                details => $details,
              };
        }
        return \@mistakes;
    }

    # If here, this is a split jog
    $expectedBodyColumn = $brickColumn + 2;
    if ( $bodyColumn != $expectedBodyColumn ) {

        my $msg = sprintf 'Jog %s body %s; %s',
          $sideDesc,
          describeLC( $bodyLine, $bodyColumn ),
          describeMisindent2( $bodyColumn, $expectedBodyColumn );
        push @mistakes,
          {
            desc           => $msg,
                subpolicy => [ $runeName, 'jog-body-indent' ],
            parentLine     => $parentLine,
            parentColumn   => $parentColumn,
            line           => $bodyLine,
            column         => $bodyColumn,
            reportLine           => $bodyLine,
            reportColumn         => $bodyColumn,
            topicLines     => [$brickLine],
            details        => [
                [
                    sprintf qq{lexeme "%s" %s},
                    $instance->lexeme( $brickLine, $brickColumn ),
                    describeLC( $brickLine, $brickColumn )
                ]
            ],
          };
        return \@mistakes;
    }

    push @mistakes,
      @{
        $policy->checkOneLineGap(
            $gap,
            {
                mainColumn => $expectedBodyColumn,
                runeName        => $runeName,
                subpolicy => [ $runeName ],
                topicLines => [ $bodyLine, $brickLine ],
            }
        )
      };

    return \@mistakes;
}

# TODO: Add a check (optional?) for queenside joggings with no
# split jogs.
sub checkJog {
    my ( $policy, $node ) = @_;
    my $instance = $policy->{lint};

    my $joggingHoonData = $policy->getInheritedAttribute($node, 'joggingHoonData');
    my $jogBaseColumn = $joggingHoonData->{jogBaseColumn};

    # This is to suppress detailed complaints about the first jog 
    # of a "joined" jogging.  A complaint will be made at the jogging
    # hoon level, and the detailed ones for the jog are redundant
    # and confusing.
    my $firstOKJogLine = $joggingHoonData->{firstOKJogLine};
    my ($jogLine) = $instance->nodeLC($node);
    return [] if $jogLine < $firstOKJogLine;

    my $chessSide = $joggingHoonData->{chessSide};
    return $policy->checkQueensideJog($node, $jogBaseColumn)
      if $chessSide eq 'queenside';
    return $policy->checkKingsideJog($node, $jogBaseColumn);
}

# not yet implemented
sub checkNYI {
    my ( $policy, $node ) = @_;
    my $instance = $policy->{lint};
    my $grammar  = $instance->{grammar};
    my ( $parentLine, $parentColumn ) =
      $instance->line_column( $node->{start} );
    my $ruleID   = $node->{ruleID};
    my @mistakes = ();

    my $msg = join q{ }, 'NYI', '[' . $instance->symbol($node) . ']',
      $instance->describeNodeRange($node),
      ( map { $grammar->symbol_display_form($_) }
          $grammar->rule_expand($ruleID) );
    push @mistakes,
      {
        desc         => $msg,
        parentLine   => $parentLine,
        parentColumn => $parentColumn,
        line         => $parentLine,
        column       => $parentColumn,
      };
    return \@mistakes;
}

sub checkBackdented {
    my ( $policy, $node ) = @_;
    my $nodeIX       = $node->{IX};
    my @gapSeq       = @{ $policy->gapSeq0($node) };
    my $elementCount = ( scalar @gapSeq ) / 2;
    my $instance     = $policy->{lint};
    my ( $parentLine, $parentColumn ) = $instance->nodeLC($node);
    my @mistakes = ();
    my $runeName = $policy->runeName($node);

    my $chainOffset = 0;
    my $chainAlignments;
    my $chainAlignmentData = $policy->chainAlignmentData($node);
    if ($chainAlignmentData) {
        $chainOffset = $chainAlignmentData->{offset};
        $chainAlignments = $chainAlignmentData->{alignments};
    }

    my $runningAlignments =
      $policy->{perNode}->{$nodeIX}->{runningAlignments};
            # say STDERR join " ", __FILE__, __LINE__, "nodeIX:", $nodeIX;

    my $reanchorOffset;    # for re-anchoring logic

  ENFORCE_ELEMENT1_JOINEDNESS: {

        # TODO: Is this right?
        my $firstGap = $gapSeq[0];
        my ($gapLine) = $instance->nodeLC($firstGap);
        last ENFORCE_ELEMENT1_JOINEDNESS if $gapLine == $parentLine;
        my $gapLiteral = $instance->literalNode($firstGap);
        $gapLiteral = substr( $gapLiteral, 2 )
          if $instance->runeGapNode($firstGap);

        # Only enforce if 1st line is spaces --
        # comments, etc., are caught by the logic to follow
        last ENFORCE_ELEMENT1_JOINEDNESS unless $gapLiteral =~ /^[ ]*\n/;
        my $element = $gapSeq[1];
        my ( $elementLine, $elementColumn ) = $instance->nodeLC($element);
        my $msg = sprintf
          '%d-element backdent must be joined %s',
          $elementCount,
          describeLC( $elementLine, $elementColumn );
        push @mistakes,
          {
            desc         => $msg,
            subpolicy => [ $runeName, 'element-1-split' ],
            parentLine   => $parentLine,
            parentColumn => $parentColumn,
            line         => $elementLine,
            column       => $elementColumn,
            reportLine         => $elementLine,
            reportColumn       => $elementColumn,
          };
    }

    # my $anchorNode = $instance->anchorNode($node);
    # my ( $anchorLine, $anchorColumn ) = $instance->nodeLC($anchorNode);
    my ( $anchorLine, $anchorColumn ) = ( $parentLine, $parentColumn );
    my $anchorData;
    if ( my $sources = $reanchorings{$runeName} ) {
        ( $anchorColumn, $anchorData ) =
          $policy->reanchorInc( $node, $sources );
    }

    my $anchorDetails = [];
    $anchorDetails = $policy->anchorDetails( $node, $anchorData )
       if $anchorData;

    my ( $elementLine, $elementColumn );
  ELEMENT:
    for (
        my $elementNumber = 1 ;
        $elementNumber <= $elementCount ;
        $elementNumber++
      )
    {

        my $element = $gapSeq[ $elementNumber * 2 - 1 ];
        my $previousElementLine = $elementLine // -1;
        ( $elementLine, $elementColumn ) = $instance->nodeLC($element);
        my $gap = $gapSeq[ $elementNumber * 2 - 2 ];
        my ( $gapLine, $gapColumn ) = $instance->nodeLC($gap);
        my $backdentColumn =
          $anchorColumn + ( $elementCount - $elementNumber ) * 2;

        if ( $elementLine == $parentLine ) {

            # OK if at proper alignment for backdent
            next ELEMENT if $backdentColumn == $elementColumn;

            my $gapLength = $instance->gapLength($gap);
            next ELEMENT if $gapLength == 2;

            my $thisAlignment;
            my ( $chainAlignmentColumn, $chainAlignmentDetails );
            my $chainAlignmentLines = [];
            if ($chainAlignments) {
                $thisAlignment =
                  $chainAlignments->[ $chainOffset + $elementNumber - 1 ];
                # say STDERR "$thisAlignment = chainAlignments->[ $chainOffset + $elementNumber - 1 ]";
                ( $chainAlignmentColumn, $chainAlignmentDetails ) =
                  @{$thisAlignment};

            }

            # say STDERR join " ", __FILE__, __LINE__, $elementNumber;
            my ( $runningAlignmentColumn, $runningAlignmentDetails );
            if ($runningAlignments) {
                $thisAlignment = $runningAlignments->[ $elementNumber - 1];
                ( $runningAlignmentColumn, $runningAlignmentDetails ) =
                  @{$thisAlignment};
            }

            if (    defined $chainAlignmentColumn
                and $chainAlignmentColumn >= 0
                and defined $runningAlignmentColumn
                and $runningAlignmentColumn >= 0
                and $chainAlignmentColumn != $runningAlignmentColumn )
            {
                my $msg = sprintf
'inter-line alignment conflict; element #%d of %s at %s; running is %d but chain is %d',
                  $elementNumber,
                  describeLC( $parentLine,  $parentColumn ),
                  describeLC( $elementLine, $elementColumn ),
                  describeLC( $elementLine, $runningAlignmentColumn ),
                  describeLC( $elementLine, $chainAlignmentColumn );
                push @mistakes,
                  {
                    desc         => $msg,
                    subpolicy    => [ $runeName, 'interline-mismatch' ],
                    parentLine   => $parentLine,
                    parentColumn => $parentColumn,
                    line         => $elementLine,
                    column       => $elementColumn,
                    reportLine   => $elementLine,
                    reportColumn => $elementColumn,
                  };
            }

            my $interlineAlignmentType;
            my $interlineAlignmentColumn;
          SET_INTERLINE_ALIGNMENT: {
                if ( defined $chainAlignmentColumn
                    and $chainAlignmentColumn >= 0 )
                {
                    $interlineAlignmentType   = 'chain';
                    $interlineAlignmentColumn = $chainAlignmentColumn;
                    last SET_INTERLINE_ALIGNMENT;
                }
                if ( defined $runningAlignmentColumn)
                {
                    $interlineAlignmentType   = 'running';
                    $interlineAlignmentColumn = $runningAlignmentColumn;
                }
            }

            # say STDERR join " ", __FILE__, __LINE__, $interlineAlignmentColumn;
            next ELEMENT
              if defined $interlineAlignmentColumn
              and $interlineAlignmentColumn >= 0
              and $interlineAlignmentColumn == $elementColumn;

            my @topicLines = ();
            my $tightColumn = $gapColumn + 2;
            my @allowedColumns =([ $tightColumn => 'tight' ]);
            if ($backdentColumn > $tightColumn) {
                push @allowedColumns, [ $backdentColumn => 'backdent' ];
            }
            my $details;
            if ($interlineAlignmentColumn and $interlineAlignmentColumn >= $tightColumn) {
                push @allowedColumns, [ $interlineAlignmentColumn => $interlineAlignmentType ];
                my $oneBasedColumn = $interlineAlignmentColumn + 1;
                my $alignmentLines =
                    $interlineAlignmentType eq 'running'
                  ? $runningAlignmentDetails
                  : $chainAlignmentDetails->{lines};
                push @topicLines, @{$alignmentLines};
                $details = [
                    [
                        sprintf '%s alignment is %d, see %s',
                        $interlineAlignmentType,
                        $oneBasedColumn,
                        (
                            join q{ },
                            map { $_ . ':' . $oneBasedColumn } @{$alignmentLines}
                        )
                    ]
                ];
            }
            else {
                $details = [ [ "no chain alignment detected" ] ];
            }
            my @sortedColumns = sort { $a->[0] <=> $b->[0] } @allowedColumns;
            my $allowedDesc = join "; ",
              map { sprintf '@%d:%d (%s)', $elementLine, $_->[0]+1, $_->[1] } @sortedColumns;
            if (scalar @sortedColumns >= 2) {
               $allowedDesc = 'one of ' . $allowedDesc;
            }

            my $msg = sprintf
              'joined backdent element #%d of %s is at %s; should be %s',
              $elementNumber,
              describeLC( $parentLine, $parentColumn ),
              describeLC( $elementLine, $elementColumn ),
              $allowedDesc;
            push @mistakes,
              {
                desc           => $msg,
                subpolicy => [ $runeName, 'hgap' ],
                parentLine     => $parentLine,
                parentColumn   => $parentColumn,
                line           => $elementLine,
                column         => $elementColumn,
                reportLine     => $elementLine,
                reportColumn   => $elementColumn,
                subpolicy      => [ $runeName, 'hgap'],
                topicLines => \@topicLines,
                details => $details,
              };
            next ELEMENT;
        }

        CHECK_FOR_PSEUDOJOIN: {
            last CHECK_FOR_PSEUDOJOIN if $gapLine != $parentLine;
            last CHECK_FOR_PSEUDOJOIN if $backdentColumn == $elementColumn;
            my $msg =
              sprintf
              'Pseudo-joined backdented element %d; element/comment mismatch',
              $elementNumber;
            my $pseudojoinMistakes = $policy->checkPseudojoin(
                $gap,
                {
                    desc      => $msg,
                    subpolicy => [ $runeName, 'pseudojoin-mismatch' ],
                    expected  => [
                        [ 'tight',    $parentColumn + 4 ],
                    ]
                }
            );
            if ($pseudojoinMistakes) {
                push @mistakes, @{$pseudojoinMistakes};
                next ELEMENT;
            }
        }

        # For the use of re-anchoring logic, determine the additional offset
        # reguired for the next line after the rune line
        if ( not defined $reanchorOffset ) {
            $reanchorOffset = 2 + ( $elementCount - $elementNumber ) * 2;
            $policy->{perNode}->{$nodeIX}->{reanchorOffset} = $reanchorOffset;
        }

        if ( $elementLine == $previousElementLine ) {
            my $gapLength = $gap->{length};
            next ELEMENT if $gapLength == 2;
            my $msg       = sprintf
              'backdented element #%d %s; %s',
              $elementNumber,
              describeLC( $elementLine, $elementColumn ),
              describeMisindent2( $gapLength, 2 );
            push @mistakes,
              {
                desc         => $msg,
                subpolicy    => [ $runeName, 'hgap' ],
                parentLine   => $parentLine,
                parentColumn => $parentColumn,
                line         => $elementLine,
                column       => $elementColumn,
                reportLine   => $elementLine,
                reportColumn => $elementColumn,
                details      => [ [ @{$anchorDetails}, ] ],
              };
            next ELEMENT;
        }

        push @mistakes, @{
            $policy->checkOneLineGap(
                $gap,
                {
                    mainColumn => $anchorColumn,
                    elementNumber => $elementNumber,
                    preColumn  => $elementColumn,
                    runeName => $runeName,
                    subpolicy => [ $runeName ],
                    topicLines => [ $anchorLine, $elementLine ],
                    details => [
                        [
                            @{$anchorDetails},
                            (sprintf 'inter-comment indent should be %d; see line %d',
                              ( $anchorColumn + 1 ), $anchorLine),
                            (sprintf 'pre-comment indent should be %d; see line %d',
                              ( $elementColumn + 1 ), $elementLine)
                       ]
                    ],
                }
            )
        };

        if ( $backdentColumn != $elementColumn ) {
            my $msg = sprintf
              'backdented element #%d %s; %s',
              $elementNumber,
              describeLC( $elementLine, $elementColumn ),
              describeMisindent2( $elementColumn, $backdentColumn );
            push @mistakes,
              {
                desc           => $msg,
                subpolicy => [ $runeName, 'indent' ],
                line           => $elementLine,
                column         => $elementColumn,
                reportLine           => $elementLine,
                reportColumn         => $elementColumn,
                topicLines => [ $anchorLine ],
                details        => [ [ @{$anchorDetails}, ] ],
              };
        }
    }
    return \@mistakes;
}

# Ketdot is slightly different form other backdented hoons
sub checkKetdot {
    my ( $policy, $node ) = @_;
    my @gapSeq   = @{ $policy->gapSeq0($node) };
    my $instance = $policy->{lint};
    my ( $parentLine, $parentColumn ) = $instance->nodeLC($node);
    my @mistakes = ();
    my $runeName      = 'ketdot';
    my $tag      = 'ketdot';

    my $anchorNode =
      $instance->firstBrickOfLineInc( $node, { tallKetdot => 1 } );
    my ( $anchorLine, $anchorColumn ) = $instance->nodeLC($anchorNode);

    my $gap1     = $gapSeq[0];
    my $element1 = $gapSeq[1];
    my ( $element1Line, $element1Column ) = $instance->nodeLC($element1);

  ELEMENT: {    # Element 1

        my $expectedColumn = $parentColumn + 4;

        if ( $element1Line != $parentLine ) {
            my $msg = sprintf
              "Ketdot element 1 %s; element 1 expected to be on rune line",
              describeLC( $element1Line, $element1Column );
            push @mistakes,
              {
                desc         => $msg,
                parentLine   => $parentLine,
                parentColumn => $parentColumn,
                line         => $element1Line,
                column       => $element1Column,
              };
            last ELEMENT;
        }

        if ( $expectedColumn != $element1Column ) {
            my $msg = sprintf
              'Ketdot element 1 %s; %s',
              describeLC( $element1Line, $element1Column ),
              describeMisindent2( $element1Column, $expectedColumn );
            push @mistakes,
              {
                desc           => $msg,
                parentLine     => $parentLine,
                parentColumn   => $parentColumn,
                line           => $element1Line,
                column         => $element1Column,
              };
        }
    }

    my $gap2     = $gapSeq[2];
    my $element2 = $gapSeq[3];
    my ( $element2Line, $element2Column ) = $instance->nodeLC($element2);

  ELEMENT2: {
        if ( $element1Line != $element2Line ) {    # Element 2 split

            my $expectedColumn = $anchorColumn;

            push @mistakes,
              @{
                $policy->checkOneLineGap(
                    $gap2,
                    {
                        mainColumn => $anchorColumn,
                        runeName        => $runeName,
                subpolicy => [ $runeName ],
                    }
                )
              };

            if ( $expectedColumn != $element2Column ) {
                my $msg = sprintf
                  'Ketdot element 2 %s; %s',
                  describeLC( $element2Line, $element2Column ),
                  describeMisindent2( $element2Column, $expectedColumn );
                push @mistakes,
                  {
                    desc           => $msg,
                    parentLine     => $parentLine,
                    parentColumn   => $parentColumn,
                    line           => $element2Line,
                    column         => $element2Column,
                  };
            }
            last ELEMENT2;
        }

        # If here, joined element 2

        my $gapLiteral = $instance->literalNode($gap2);
        my $gapLength  = $gap2->{length};
        last ELEMENT2 if $gapLength == 2;
        my ( undef, $gap2Column ) = $instance->nodeLC($gap2);

        # expected length is the length if the spaces at the end
        # of the gap-equivalent were exactly one stop.
        my $expectedLength = $gapLength + ( 2 - length $gapLiteral );
        my $expectedColumn = $gap2Column + $expectedLength;

        if ( $expectedColumn != $element2Column ) {
            my $msg = sprintf
              'Ketdot element 2 %s; %s',
              describeLC( $element2Line, $element2Column ),
              describeMisindent2( $element2Column, $expectedColumn );
            push @mistakes,
              {
                desc           => $msg,
                parentLine     => $parentLine,
                parentColumn   => $parentColumn,
                line           => $element2Line,
                column         => $element2Column,
              };
        }
    }

    return \@mistakes;
}

sub checkLuslus {
    my ( $policy, $node, $cellLHS ) = @_;
    my $nodeIX       = $node->{IX};
    my $instance = $policy->{lint};
    my $runeName = $policy->runeName($node);
    my ( $parentLine, $parentColumn ) = $instance->nodeLC($node);

    my $battery = $instance->ancestorByLHS( $node, { whap5d => 1 } );
    die "battery not found" if not defined $battery;
    my ( $batteryLine, $batteryColumn ) = $instance->nodeLC($battery);
    my ( $cellBodyColumn, $cellBodyColumnLines ) =
      @{ $policy->getInheritedAttribute($node, 'cellBodyAlignmentData') };

    my $batteryHoon = $instance->brickNode($battery);
    my ( $batteryHoonLine, $batteryHoonColumn ) =
      $instance->nodeLC($batteryHoon);
    my $batteryRuneName = $policy->runeName($batteryHoon);
    my $armDesc = join ':', $batteryRuneName, $runeName, 'arm';

    my $anchorData;
    my ( $anchorColumn, $anchorLine ) = ( $parentColumn, $parentLine );
    if ( $parentLine == $batteryHoonLine ) {
        ( $anchorColumn, $anchorData ) = $policy->reanchorInc(
            $node,
            {
                'tallBarcen' => 1,
            }
        );
    }

    my $anchorDetails;
    $anchorDetails = $policy->anchorDetails( $node, $anchorData )
      if $anchorData;

    $policy->{perNode}->{$nodeIX}->{reanchorOffset} = 2;

    my @mistakes = ();

    # LuslusCell ::= (- LUS LUS GAP -) SYM4K (- GAP -) tall5d
    my ( $headGap, $head, $bodyGap, $body ) = @{ $policy->gapSeq0($node) };
    my ( $headLine, $headColumn ) = $instance->nodeLC($head);
    my ( $bodyLine, $bodyColumn ) = $instance->nodeLC($body);

    my $headGapLength = $headGap->{length};
    if ( $headGapLength != 2 ) {
        my $msg            = sprintf 'Cell head %s; %s',
          describeLC( $bodyLine, $bodyColumn ),
          describeMisindent2( $headGapLength, 2 );
        push @mistakes,
          {
            desc         => $msg,
            subpolicy    => [ $runeName, 'hgap' ],
            parentLine   => $parentLine,
            parentColumn => $parentColumn,
            line         => $headLine,
            column       => $headColumn,
            reportLine   => $headLine,
            reportColumn => $headColumn,
            topicLines   => [ $batteryLine, $batteryHoonLine ],
            details      => [
                [
                    $armDesc,
                    (
                        sprintf 'starts at %s',
                        describeLC( $batteryHoonLine, $batteryHoonColumn )
                    ),
                ]
            ],
          };
    }

    if ( $headLine == $bodyLine ) {
        my $bodyGapLength = $bodyGap->{length};

        if ( $bodyGapLength != 2 and $bodyColumn != $cellBodyColumn ) {
            my @topicLines = ( $batteryLine, $batteryHoonLine );
            my @subpolicy = ($runeName);
            my $misindent;
            my @details = (
                $armDesc,
                (
                    sprintf 'starts at %s',
                    describeLC( $batteryHoonLine, $batteryHoonColumn )
                ),
            );
            if ( $cellBodyColumn < 0 ) {
                push @subpolicy, 'bad-tight-indent';
                $misindent = describeMisindent2( $bodyGapLength, 2 );
                push @details, "no inter-line alignment detected";
            }
            else {
                push @subpolicy, 'bad-interline-indent';
                $misindent = describeMisindent2( $bodyColumn, $cellBodyColumn );
                my $oneBasedColumn = $cellBodyColumn + 1;
                push @topicLines, @{$cellBodyColumnLines};
                push @details,
                  (
                    sprintf 'inter-line alignment is %d, see %s',
                    $oneBasedColumn,
                    (
                        join q{ },
                        map { $_ . ':' . $oneBasedColumn }
                          @{$cellBodyColumnLines}
                    )
                  );
            }
            my $msg = sprintf 'Cell body %s; %s',
              describeLC( $bodyLine, $bodyColumn ), $misindent;
            push @mistakes,
              {
                desc         => $msg,
                subpolicy    => \@subpolicy,
                parentLine   => $parentLine,
                parentColumn => $parentColumn,
                line         => $bodyLine,
                column       => $bodyColumn,
                reportLine   => $bodyLine,
                reportColumn => $bodyColumn,
                topicLines   => \@topicLines,
                details      => [ [@details] ],
              };
        }
        return \@mistakes;
    }

    # If here, this is (or should be) a split cell
    my $expectedBodyColumn = $anchorColumn + 2;

    # If here head line != body line
  CHECK_FOR_PSEUDOJOIN: {
        my $pseudojoinColumn = $policy->pseudojoinColumn($bodyGap);
        last CHECK_FOR_PSEUDOJOIN if $pseudojoinColumn < 0;
        my $headLength   = $head->{length};
        my $raggedColumn = $headColumn + $headLength + 2;
        last CHECK_FOR_PSEUDOJOIN
          if $pseudojoinColumn != $raggedColumn
          and $pseudojoinColumn != $cellBodyColumn;
        if ( $pseudojoinColumn != $bodyColumn ) {

            # Works as a regular split arm, so not a
            # pseudojoing after all.
            last CHECK_FOR_PSEUDOJOIN if $bodyColumn == $expectedBodyColumn;

            my $msg =
              sprintf
              'Pseudo-joined cell %s; body/comment mismatch; body is %s',
              describeLC( $parentLine, $parentColumn ),
              describeMisindent2( $bodyColumn, $pseudojoinColumn );
            push @mistakes,
              {
                desc         => $msg,
                subpolicy    => [ $runeName, 'pseudo-comment-indent' ],
                parentLine   => $parentLine,
                parentColumn => $parentColumn,
                line         => $bodyLine,
                column       => $bodyColumn,
                reportLine   => $bodyLine,
                reportColumn => $bodyColumn,
                topicLines   => [ $batteryLine, $batteryHoonLine ],
                details      => [
                    [
                        $armDesc,
                        (
                            sprintf 'starts at %s',
                            describeLC( $batteryHoonLine, $batteryHoonColumn )
                        ),
                    ]
                ],
              };
        }
        return \@mistakes;
    }

    if ( $bodyColumn != $expectedBodyColumn ) {
        my $msg = sprintf 'cell body %s; %s',
          describeLC( $bodyLine, $bodyColumn ),
          describeMisindent2( $bodyColumn, $expectedBodyColumn );
        push @mistakes,
          {
            desc         => $msg,
            subpolicy    => [ $runeName, 'arm-body-indent' ],
            parentLine   => $parentLine,
            parentColumn => $parentColumn,
            line         => $bodyLine,
            column       => $bodyColumn,
            reportLine   => $bodyLine,
            reportColumn => $bodyColumn,
            topicLines   => [ $batteryLine, $batteryHoonLine ],
            details      => [
                [
                    $armDesc,
                    (
                        sprintf 'starts at %s',
                        describeLC( $batteryHoonLine, $batteryHoonColumn )
                    ),
                ]
            ],
          };
        return \@mistakes;
    }

    push @mistakes,
      @{
        $policy->checkOneLineGap(
            $bodyGap,
            {
                mainColumn => $expectedBodyColumn,
                runeName        => $runeName,
                subpolicy  => [$runeName],
                topicLines => [ $bodyLine, $batteryLine, $batteryHoonLine ],
                details    => [
                    [
                        $armDesc,
                        (
                            sprintf 'starts at %s',
                            describeLC( $batteryHoonLine, $batteryHoonColumn )
                        ),
                    ]
                ],
            }
        )
      };

    return \@mistakes;
}

sub validate {
    my ( $policy, $node ) = @_;
    my $instance = $policy->{lint};

    $policy->validate_node($node);
    return if $node->{type} ne 'node';
    my $children = $node->{children};
  CHILD: for my $childIX ( 0 .. $#$children ) {
        my $child = $children->[$childIX];
        $policy->validate($child);
    }
    return;
}

sub reportMistakes {
    my ( $policy, $mistakes ) = @_;
    my $instance = $policy->{lint};
    my $fileName = $instance->{fileName};

    my @pieces = ();
  MISTAKE: for my $mistake ( @{$mistakes} ) {

        my $parentLine   = $mistake->{parentLine};
        my $parentColumn = $mistake->{parentColumn};
        my $desc         = $mistake->{desc};
        my $mistakeLine  = $mistake->{line};

        # The default report location should be line, column
        # instead of parentLine, parentColumn
        $mistake->{reportLine}   //= $parentLine;
        $mistake->{reportColumn} //= $parentColumn;

        $instance->reportItem( $mistake, $desc,
            ( $mistake->{topicLines} // [] ), $mistakeLine, );
    }
    return;
}

sub validate_node {
    my ( $policy, $node ) = @_;

    my $policyShortName = $policy->{shortName};
    my $instance        = $policy->{lint};
    my $fileName        = $instance->{fileName};
    my $grammar         = $instance->{grammar};
    my $recce           = $instance->{recce};

    my $NYI_Rule               = $instance->{NYI_Rule};
    my $backdentedRule         = $instance->{backdentedRule};
    my $tallRuneRule           = $instance->{tallRuneRule};
    my $tallJogRule            = $instance->{tallJogRule};
    my $tallNoteRule           = $instance->{tallNoteRule};
    my $tallLuslusRule         = $instance->{tallLuslusRule};
    my $tall_0RunningRule      = $instance->{tall_0RunningRule};
    my $tall_1RunningRule      = $instance->{tall_1RunningRule};
    my $tall_1JoggingRule      = $instance->{tall_1JoggingRule};
    my $tall_2JoggingRule      = $instance->{tall_2JoggingRule};
    my $tall_Jogging1Rule      = $instance->{tallJogging1_Rule};

    my $ruleDB           = $instance->{ruleDB};
    my $lineToPos        = $instance->{lineToPos};
    my $symbolReverseDB  = $instance->{symbolReverseDB};

    my $parentSymbol = $node->{symbol};
    my $parentStart  = $node->{start};
    my $parentLength = $node->{length};
    my $parentRuleID = $node->{ruleID};

    # $Data::Dumper::Maxdepth = 3;
    # say Data::Dumper::Dumper($node);

    my ( $parentLine, $parentColumn ) = $instance->line_column($parentStart);
    my $parentLC = join ':', $parentLine, $parentColumn + 1;

    my $children = $node->{children};

    my $nodeType = $node->{type};
    return if $nodeType ne 'node';

    my $ruleID = $node->{ruleID};
    my ( $lhs, @rhs ) = $grammar->rule_expand( $node->{ruleID} );
    my $lhsName = $grammar->symbol_name($lhs);

    # tall node

    my $mistakes   = [];
    my $start      = $node->{start};

  GATHER_MISTAKES: {

        state $fnHash = {
           tallKidsOfTop => \&checkTopKids,
           tallKidsOfElem => \&checkElemKids,
           tallTailOfElem => \&checkTailOfElem,
           tallTailOfTop => \&checkTailOfTop,
           tallTopSail => \&checkTopSail,
           bonz5d => \&checkBonz5d,
        };
        my $fn = $fnHash->{$lhsName};
        if ($fn) {
            $mistakes = $fn->($policy, $node);
            last GATHER_MISTAKES;
        }

        if ( $lhsName eq 'optGay4i' ) {
            my $gapLength = $node->{length};
            return if $gapLength <= 0;
            my $start = $node->{start};

            # Special case for final newline
            HANDLE_SINGLE_LINE_TRAILER: {
                last HANDLE_SINGLE_LINE_TRAILER if $start + $gapLength != $lineToPos->[-1];
                my $literal = $instance->literalNode($node);
                # say STDERR join " ", __FILE__, __LINE__, $lhsName, '[' . $literal. ']';
                return if $literal =~ m/\A [^\n]* \n \z/xms;
                # say STDERR join " ", __FILE__, __LINE__, $lhsName, '[' . $literal. ']';
            }

            # say STDERR join " ", __FILE__, __LINE__, $lhsName, '[' . $instance->literalNode($node) . ']';
            my $runeName = 'fordfile';
            $mistakes =
                $policy->checkOneLineGap(
                    $node,
                    {
                        mainColumn => 0,
                        runeName        => $runeName,
                        subpolicy => [ $runeName, 'vgap' ],
                    }
                );
            # say STDERR join " ", __FILE__, __LINE__, Data::Dumper::Dumper($mistakes);
            last GATHER_MISTAKES;
        }

        my $childCount = scalar @{$children};
        if ( $childCount <= 1 ) {
            return;
        }

        my $firstChildIndent = $instance->column( $children->[0]->{start} ) - 1;

        my $gapiness = $ruleDB->[$ruleID]->{gapiness} // 0;

        my $reportType = $gapiness < 0 ? 'sequence' : 'indent';

        # TODO: In another policy, warn on tall children of wide nodes
        if ( $gapiness == 0 ) {    # wide node
            return;
        }

        if ( $gapiness < 0 ) {    # sequence
            my $previousLine = $parentLine;
          TYPE_INDENT: {

                if ( $lhsName eq 'rick5d' ) {
                    $mistakes = $policy->checkJogging($node);
                    last TYPE_INDENT;
                }
                if ( $lhsName eq 'ruck5d' ) {
                    $mistakes = $policy->checkJogging($node);
                    last TYPE_INDENT;
                }

                if ( $lhsName eq 'fordFascomElements' ) {
                    $mistakes = $policy->checkFascomElements($node);
                    last TYPE_INDENT;
                }

                if ( $lhsName eq 'fordHoopSeq' ) {
                    $mistakes = $policy->checkSeq( $node, 'hoop' );
                    last TYPE_INDENT;
                }

                if ( $lhsName eq 'hornSeq' ) {
                    $mistakes = $policy->checkSeq( $node, 'horn' );
                    last TYPE_INDENT;
                }

                if ( $lhsName eq 'optBonzElements' ) {
                    $mistakes = $policy->checkBonzElements( $node );
                    last TYPE_INDENT;
                }

                my $grandParent = $instance->ancestor( $node, 1 );
                my $grandParentName = $instance->brickName($grandParent);
                if ( $lhsName eq 'tall5dSeq' or $lhsName eq 'till5dSeq' ) {
                    if ( $grandParentName eq 'lute5d' ) {
                        last TYPE_INDENT;
                    }
                    if ( $tall_1RunningRule->{$grandParentName} ) {
                        last TYPE_INDENT;
                    }
                    if ( $tall_0RunningRule->{$grandParentName} ) {
                        last TYPE_INDENT;
                    }
                }

                if ( $lhsName eq 'whap5d' ) {
                    my $greatGrandParent =
                      $instance->ancestor( $grandParent, 1 );
                    my $greatGrandParentName =
                      $instance->brickName($greatGrandParent);

                    # TODO: remove after development?
                    die
                      unless $greatGrandParentName eq 'tallBarcab'
                      or $greatGrandParentName eq 'tallBarcen'
                      or $greatGrandParentName eq 'tallBarket';
                    $mistakes = $policy->checkWhap5d($node);
                    last TYPE_INDENT;
                }

                # By default, treat as not yet implemented
                $mistakes = $policy->checkNYI($node);
                last TYPE_INDENT if @{$mistakes};

                # should never reach here
                die "NYI";
            }

            last GATHER_MISTAKES;
        }

        # if here, gapiness > 0

      TYPE_INDENT: {

            # This would be faster as a hash

            if ( $lhsName eq "bont5d" ) {
                $mistakes = $policy->checkBont($node);
                last TYPE_INDENT;
            }

            if ( $lhsName eq "bonzElement" ) {
                $mistakes = $policy->checkBonzElement($node);
                last TYPE_INDENT;
            }

            if ( $lhsName eq 'fordFascom' ) {
                $mistakes = $policy->checkFascom($node);
                last TYPE_INDENT;
            }

            if ( $lhsName =~ '^fordFas(bar|dot)' ) {
                # say STDERR join " ", __FILE__, __LINE__, $lhsName, $instance->literalNode($node);
                $mistakes = $policy->checkFasdot($node);
                last TYPE_INDENT;
            }

            if ( $lhsName =~ m/^fordFas(buc|cab|cen|hax|sig)$/ ) {
                $mistakes = $policy->checkFord_1( $node );
                last TYPE_INDENT;
            }

            if ( $lhsName eq "fordHoop" ) {
                $mistakes = $policy->checkFordHoop( $node );
                last TYPE_INDENT;
            }

            if ( $lhsName eq "fordFastis" ) {
                $mistakes = $policy->checkFastis($node);
                last TYPE_INDENT;
            }

            if ( $lhsName eq "fordFaswut" ) {
                $mistakes = $policy->checkFaswut($node);
                last TYPE_INDENT;
            }

            if ( $lhsName eq "fordFascomElement" ) {
                $mistakes = $policy->checkFascomElement($node);
                last TYPE_INDENT;
            }

            if ( $lhsName eq "lute5d" ) {
                $mistakes = $policy->checkLute($node);
                last TYPE_INDENT;
            }

            if ( $lhsName =~ m/optFordFas(hep|lus)/ ) {
                $mistakes = $policy->checkFordHoofRune($lhsName, $node);
                last TYPE_INDENT;
            }

            if ( $lhsName eq "tallAttribute" ) {
                $mistakes = $policy->checkSailAttribute($node);
                last TYPE_INDENT;
            }

            if ( $lhsName eq "tallBarcab" ) {
                $mistakes = $policy->checkBarcab($node);
                last TYPE_INDENT;
            }

            if ( $lhsName eq "tallBarcen" ) {
                $mistakes = $policy->checkBarcen($node);
                last TYPE_INDENT;
            }

            if ( $lhsName eq "tallBarket" ) {
                $mistakes = $policy->checkBarket($node);
                last TYPE_INDENT;
            }

            if ( $lhsName eq "tallKetdot" ) {
                $mistakes = $policy->checkKetdot($node);
                last TYPE_INDENT;
            }

            if ( $lhsName eq "wisp5d" ) {
                $mistakes = $policy->checkWisp5d($node);
                last TYPE_INDENT;
            }

            if ( $NYI_Rule->{$lhsName} ) {
                $mistakes = $policy->checkNYI($node);
                last TYPE_INDENT if @{$mistakes};

                # should never reach here
                die 'NYI failure';
            }

            if ( $tallJogRule->{$lhsName} ) {
                $mistakes = $policy->checkJog($node);
                last TYPE_INDENT;
            }

            if ( $tall_0RunningRule->{$lhsName} ) {
                $mistakes = $policy->check_0Running($node);
                last TYPE_INDENT;
            }

            if ( $tall_1RunningRule->{$lhsName} ) {
                $mistakes = $policy->check_1Running($node);
                last TYPE_INDENT;
            }

            if ( $tall_1JoggingRule->{$lhsName} ) {
                $mistakes = $policy->check_1Jogging($node);
                last TYPE_INDENT;
            }

            if ( $tall_2JoggingRule->{$lhsName} ) {
                $mistakes = $policy->check_2Jogging($node);
                last TYPE_INDENT;
            }

            if ( $tall_Jogging1Rule->{$lhsName} ) {
                $mistakes = $policy->check_Jogging1($node);
                last TYPE_INDENT;
            }

            if ( $tallNoteRule->{$lhsName} ) {
                $mistakes = $policy->checkBackdented($node);
                last TYPE_INDENT;
            }

            if ( $tallLuslusRule->{$lhsName} ) {
                $mistakes = $policy->checkLuslus( $node, $lhsName );
                last TYPE_INDENT;
            }

            if ( $backdentedRule->{$lhsName} ) {
                $mistakes = $policy->checkBackdented($node);
                last TYPE_INDENT;
            }

            # By default, treat as not yet implemented
            {
                $mistakes = $policy->checkNYI($node);
                last TYPE_INDENT if @{$mistakes};

                # should never reach here
                die 'NYI failure';
            }

        }
    }

  PRINT: {
        if ( @{$mistakes} ) {
            for my $mistake ( @{$mistakes} ) {
                $mistake->{policy}    = $policyShortName;
                $mistake->{subpolicy} = $mistake->{subpolicy}
                  // $instance->diagName($node);
            }
            $policy->reportMistakes($mistakes);
            last PRINT;
        }

    }

    return;
}

1;

# vim: expandtab shiftwidth=4:
