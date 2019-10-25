# Hoon "tidy" utility

use 5.010;
use strict;
use warnings;
no warnings 'recursion';

package MarpaX::Hoonlint;

use Data::Dumper;
use English qw( -no_match_vars );
use Scalar::Util qw(looks_like_number weaken);
use Getopt::Long;

use MarpaX::Hoonlint::yahc;

use vars qw($VERSION $STRING_VERSION @ISA $DEBUG);
$VERSION        = '1.010000';
$STRING_VERSION = $VERSION;
## no critic (BuiltinFunctions::ProhibitStringyEval)
$VERSION = eval $VERSION;
## use critic
$DEBUG = 0;

my %separator = qw(
  hyf4jSeq DOT
  singleQuoteCord gon4k
  dem4k gon4k
  timePeriodKernel DOT
  optBonzElements GAP
  optWideBonzElements ACE
  till5dSeq GAP
  wyde5dSeq ACE
  gash5d FAS
  togaElements ACE
  wide5dJogs wide5dJoggingSeparator
  rope5d DOT
  rick5d GAP
  wideRick5d commaAce
  ruck5d GAP
  wideRuck5d commaAce
  tallTopKidSeq  GAP_SEM
  wideInnerTops ACE
  wideAttrBody commaAce
  scriptStyleTailElements GAP
  moldInfixCol2 COL
  lusSoilSeq DOG4I
  hepSoilSeq DOG4I
  infixDot DOG4I
  waspElements GAP
  whap5d GAP
  hornSeq GAP
  wideHornSeq ACE
  fordHoopSeq GAP
  tall5dSeq GAP
  wide5dSeq ACE
  fordFascomElements GAP
  optFordHithElements FAS
  fordHoofSeq commaWS
);

sub internalError {
    my ($instance) = @_;
    my $fileName = $instance->{fileName} // "[No file name]";
    my @pieces = ( "$PROGRAM_NAME $fileName: Internal Error\n", @_ );
    push @pieces, "\n" unless $pieces[$#pieces] =~ m/\n$/;
    my ( undef, $codeFilename, $codeLine ) = caller;
    die join q{}, @pieces,
      "Internal error was at $codeFilename, line $codeLine";
}

sub doNode {
    my ( $instance, @argChildren ) = @_;
    my $pSource    = $instance->{pHoonSource};
    my @results    = ();
    my $childCount = scalar @argChildren;
    no warnings 'once';
    my $ruleID = $Marpa::R2::Context::rule;
    use warnings;
    my ( $lhs, @rhs ) =
      map { $MarpaX::Hoonlint::grammar->symbol_display_form($_) }
      $MarpaX::Hoonlint::grammar->rule_expand($ruleID);
    my ( $first_g1, $last_g1 ) = Marpa::R2::Context::location();
    my ($lhsStart) =
      $MarpaX::Hoonlint::recce->g1_location_to_span( $first_g1 + 1 );

    my $node;
  CREATE_NODE: {
        if ( $childCount <= 0 ) {
            $node = {
                type   => 'null',
                symbol => $lhs,
                start  => $lhsStart,
                length => 0,
            };
            last CREATE_NODE;
        }
        my ( $last_g1_start, $last_g1_length ) =
          $MarpaX::Hoonlint::recce->g1_location_to_span($last_g1);
        my $lhsLength = $last_g1_start + $last_g1_length - $lhsStart;
      RESULT: {
          CHILD: for my $childIX ( 0 .. $#argChildren ) {
                my $child   = $argChildren[$childIX];
                my $refType = ref $child;
                next CHILD unless $refType eq 'ARRAY';

                my ( $lexemeStart, $lexemeLength, $lexemeName ) = @{$child};

                if ( $lexemeName eq 'TRIPLE_DOUBLE_QUOTE_STRING' ) {
                    my $terminator    = q{"""};
                    my $terminatorPos = index ${$pSource},
                      $terminator,
                      $lexemeStart + $lexemeLength;
                    $lexemeLength =
                      $terminatorPos + ( length $terminator ) - $lexemeStart;
                }
                if ( $lexemeName eq 'TRIPLE_QUOTE_STRING' ) {
                    my $terminator    = q{'''};
                    my $terminatorPos = index ${$pSource},
                      $terminator,
                      $lexemeStart + $lexemeLength;
                    $lexemeLength =
                      $terminatorPos + ( length $terminator ) - $lexemeStart;
                }
                $argChildren[$childIX] = {
                    type   => 'lexeme',
                    start  => $lexemeStart,
                    length => $lexemeLength,
                    symbol => $lexemeName,
                };
            }

            my $lastLocation = $lhsStart;
            if ( ( scalar @rhs ) != $childCount ) {

          # This is a non-trivial (that is, longer than one item) sequence rule.
                my $childIX = 0;
                my $lastSeparator;
              CHILD: for ( ; ; ) {

                    my $child     = $argChildren[$childIX];
                    my $childType = $child->{type};
                    $childIX++;
                  ITEM: {
                        if ( defined $lastSeparator ) {
                            my $length =
                              $child->{start} - $lastSeparator->{start};
                            $lastSeparator->{length} = $length;
                        }
                        push @results, $child;
                        $lastLocation = $child->{start} + $child->{length};
                    }
                    last RESULT if $childIX > $#argChildren;
                    my $separator = $separator{$lhs};
                    next CHILD unless $separator;
                    $lastSeparator = {
                        type   => 'separator',
                        symbol => $separator,
                        start  => $lastLocation,

                        # length supplied later
                    };
                    push @results, $lastSeparator;
                }
                last RESULT;
            }

            # All other rules
          CHILD: for my $childIX ( 0 .. $#argChildren ) {
                my $child = $argChildren[$childIX];
                push @results, $child;
            }
        }

        $node = {
            type     => 'node',
            ruleID   => $ruleID,
            start    => $lhsStart,
            length   => $lhsLength,
            children => \@results,
        };
    }

    # Add weak links
    my $children = $node->{children};
    if ( $children and scalar @{$children} >= 1 ) {
      CHILD: for my $childIX ( 0 .. $#$children ) {
            my $child = $children->[$childIX];
            $child->{PARENT} = $node;
            weaken( $child->{PARENT} );
        }
      CHILD: for my $childIX ( 1 .. $#$children ) {
            my $thisChild = $children->[$childIX];
            my $prevChild = $children->[ $childIX - 1 ];
            $thisChild->{PREV} = $prevChild;
            weaken( $thisChild->{PREV} );
            $prevChild->{NEXT} = $thisChild;
            weaken( $prevChild->{NEXT} );
        }
    }

    my $nodeCount = $instance->{nodeCount};
    $node->{IX}            = $nodeCount;
    $instance->{nodeCount} = $nodeCount + 1;

    return $node;
}

sub describeRange {
    my ( $firstLine, $firstColumn, $lastLine, $lastColumn ) = @_;
    return sprintf "@%d:%d-%d:%d", $firstLine, $firstColumn, $lastLine,
      $lastColumn
      if $firstLine != $lastLine;
    return sprintf "@%d:%d-%d", $firstLine, $firstColumn, $lastColumn
      if $firstColumn != $lastColumn;
    return sprintf "@%d:%d", $firstLine, $firstColumn;
}

sub describeNodeRange {
    my ( $instance, $node ) = @_;
    my $firstPos = $node->{start};
    my $length   = $node->{length};
    my $lastPos  = $firstPos + $length;
    my ( $firstLine, $firstColumn ) = $instance->line_column($firstPos);
    my ( $lastLine,  $lastColumn )  = $instance->line_column($lastPos);
    return describeRange( $firstLine, $firstColumn, $lastLine, $lastColumn );
}

sub lexeme {
    my ( $instance, $line, $column ) = @_;
    my $literal = $instance->literalLine($line);
    my $lexeme = substr $literal, $column;
    $lexeme =~ s/[\s].*\z//xms;
    return $lexeme;
}

sub literalNode {
    my ( $instance, $node ) = @_;
    my $start  = $node->{start};
    my $length = $node->{length};
    return $instance->literal( $start, $length );
}

sub literalLine {
    my ( $instance, $lineNum ) = @_;
    my $lineToPos = $instance->{lineToPos};
    my $startPos  = $lineToPos->[$lineNum];
    $DB::single = 1 if not defined $lineToPos->[ $lineNum + 1 ];
    my $line =
      $instance->literal( $startPos,
        ( $lineToPos->[ $lineNum + 1 ] - $startPos ) );
    return $line;
}

sub literal {
    my ( $instance, $start, $length ) = @_;
    my $pSource = $instance->{pHoonSource};
    return '' if $start >= length ${$pSource};
    return substr ${$pSource}, $start, $length;
}

sub column {
    my ( $instance, $pos ) = @_;
    my $pSource = $instance->{pHoonSource};
    return $pos - ( rindex ${$pSource}, "\n", $pos - 1 );
}

sub maxNumWidth {
    my ($instance) = @_;
    return length q{} . $#{ $instance->{lineToPos} };
}

sub contextDisplay {
    my ($instance)     = @_;
    my $pTopicLines    = $instance->{topicLines};
    my $pMistakeLines  = $instance->{mistakeLines};
    my $contextSize    = $instance->{contextSize};
    my $displayDetails = $instance->{displayDetails};
    my $lineToPos      = $instance->{lineToPos};
    my @pieces         = ();
    my %tag = map { $_ => q{>} } keys %{$pTopicLines};
    $tag{$_} = q{!} for keys %{$pMistakeLines};
    my @sortedLines = sort { $a <=> $b } map { $_ + 0; } keys %tag;

# say STDERR join " ", __FILE__, __LINE__, "# of sorted lines:", (scalar @sortedLines);
# say STDERR join " ", __FILE__, __LINE__, Data::Dumper::Dumper(\@sortedLines);
# say STDERR join " ", __FILE__, __LINE__, Data::Dumper::Dumper($pMistakeLines);
# say STDERR join " ", __FILE__, __LINE__, Data::Dumper::Dumper($lineToPos);

    if ( $contextSize <= 0 ) {
        for my $lineNum (@sortedLines) {
            my $mistakeDescs = $pMistakeLines->{$lineNum};
            for my $mistakeDesc ( @{$mistakeDescs} ) {
                my ( $mistake, $desc ) = @{$mistakeDesc};
                push @pieces, $desc, "\n";
            }
        }
        return join q{}, @pieces;
    }

    my $maxNumWidth   = $instance->maxNumWidth();
    my $lineNumFormat = q{%} . $maxNumWidth . 'd';

    # Add to @pieces a set of lines to be displayed consecutively
    my $doConsec = sub () {
        my ( $start, $end ) = @_;
        $start = 1 if $start < 1;
        $end = $#$lineToPos - 1 if $end >= $#$lineToPos;
        for my $lineNum ( $start .. $end ) {
            my $startPos     = $lineToPos->[$lineNum];
            my $line         = $instance->literalLine($lineNum);
            my $tag          = $tag{$lineNum} // q{ };
            my $mistakeDescs = $pMistakeLines->{$lineNum};
            for my $mistakeDesc ( @{$mistakeDescs} ) {
                my ( $mistake, $desc ) = @{$mistakeDesc};
                my $details = $mistake->{details};
                if ( $details and scalar @{$details} and $displayDetails > 0 ) {
                    push @pieces, '[ ', $desc, "\n";

                    # detail levels are not currently used, but are for future
                    # extensions.
                    for my $detailLevel ( @{$details} ) {
                        for my $detail ( @{$detailLevel} ) {
                            push @pieces, q{  }, $detail, "\n";
                        }
                    }
                    push @pieces, "]\n";
                }
                else {
                    push @pieces, '[ ', $desc, " ]\n";
                }
            }
            push @pieces, ( sprintf $lineNumFormat, $lineNum ), $tag, q{ },
              $line;
        }
    };

    my $lastIX = -1;
  CONSEC_RANGE: while ( $lastIX < $#sortedLines ) {
        my $firstIX = $lastIX + 1;

        # Divider line if after first consecutive range
        push @pieces, ( '-' x ( $maxNumWidth + 2 ) ), "\n" if $firstIX > 0;
        $lastIX = $firstIX;
      SET_LAST_IX: while (1) {
            my $nextIX = $lastIX + 1;
            last SET_LAST_IX if $nextIX > $#sortedLines;

    # We combine lines if by doing so, we make the listing shorter.
    # This is calculated by
    # 1.) Taking the current last line.
    # 2.) Add the context lines for the last and next lines (2*($contextSize-1))
    # 3.) Adding 1 for the divider line, which we save if we combine ranges.
    # 4.) Adding 1 because we test if they abut, not overlap
    # Doing the arithmetic, we get
            last SET_LAST_IX
              if $sortedLines[$lastIX] + 2 * $contextSize <
              $sortedLines[$nextIX];
            $lastIX = $nextIX;
        }
        $doConsec->(
            $sortedLines[$firstIX] - ( $contextSize - 1 ),
            $sortedLines[$lastIX] + ( $contextSize - 1 )
        );
    }

    return join q{}, @pieces;
}

# Set lists of topic and mistake lines in instance
sub reportItem {
    my ( $instance, $mistake, $mistakeDesc, $topicLineArg, $mistakeLineArg ) =
      @_;

    my $inclusions      = $instance->{inclusions};
    my $suppressions    = $instance->{suppressions};
    my $reportPolicy    = $mistake->{policy};

    # TODO: Is subpolicy everywhere?  Can the tag
    # named argument be eliminated?
    my $mistakeSubpolicy = $mistake->{subpolicy};

    # TODO: Change subpolicy to ALWAYS be an array
    # and eliminate the following code
    my @reportSubpolicy = ();
    SET_SUBPOLICY: {
        my $refType = ref $mistakeSubpolicy;
        if ($refType eq 'ARRAY') {
           push @reportSubpolicy, @{$mistakeSubpolicy};
           last SET_SUBPOLICY;
        }
        push @reportSubpolicy, $mistakeSubpolicy;
    }
    my $reportSubpolicy = join ':', @reportSubpolicy;

    # TODO: Usually a default of parentLine, parentColumn has already
    # been enforced.  This is a mistake and should change.
    # Add reportLine/reportColumn to all mistakes, and do not use
    # line/column.  (Can line/column be eliminated?)
    my $reportLine       = $mistake->{reportLine} // $mistake->{line};
    my $reportColumn     = $mistake->{reportColumn} // $mistake->{column};
    my $reportLC         = join ':', $reportLine, $reportColumn + 1;
    my $suppressThisItem = 0;
    my $excludeThisItem  = 0;

    $excludeThisItem = 1
      if $inclusions
      and not $inclusions->{$reportLC}{$reportPolicy}{$reportSubpolicy};
    my $suppression =
      $suppressions->{$reportLC}->{$reportPolicy}->{$reportSubpolicy};
    if ( defined $suppression ) {
        $suppressThisItem = 1;
        $instance->{unusedSuppressions}->{$reportLC}->{$reportPolicy}
          ->{$reportSubpolicy} = undef;
    }

    return if $excludeThisItem;
    return if $suppressThisItem;

    my $fileName     = $instance->{fileName};
    my $mistakeLines = $instance->{mistakeLines};

    my $topicLines = $instance->{topicLines};
    my @topicLines = ();
    push @topicLines, ref $topicLineArg ? @{$topicLineArg} : $topicLineArg;
    push @topicLines,
      grep { defined $_ }
      ( $mistakeLineArg, $mistake->{line},
        $mistake->{parentLine}, $reportLine );
    for my $topicLine (@topicLines) {
        $topicLines->{$topicLine} = 1;
    }

    my $thisMistakeDescs = $mistakeLines->{$mistakeLineArg};
    $thisMistakeDescs = [] if not defined $thisMistakeDescs;
    push @{$thisMistakeDescs},
      [
        $mistake,
        "$fileName $reportLC $reportPolicy $reportSubpolicy $mistakeDesc"
      ];
    $mistakeLines->{$mistakeLineArg} = $thisMistakeDescs;

}

sub lhsName {
    my ( $instance, $node ) = @_;
    my $grammar = $instance->{grammar};
    my $type    = $node->{type};
    return if $type ne 'node';
    my $ruleID = $node->{ruleID};
    my ( $lhs, @rhs ) = $grammar->rule_expand($ruleID);
    return $grammar->symbol_name($lhs);
}

# The "symbol" of a node.  Not necessarily unique.
sub symbol {
    my ( $instance, $node ) = @_;
    # local $Data::Dumper::Maxdepth    = 1;
    # say STDERR join " ", __FILE__, __LINE__, Data::Dumper::Dumper($node);
    my $name = $node->{symbol};
    return $name if defined $name;
    my $type = $node->{type};
    $DB::single = 1 if not $type;
    die Data::Dumper::Dumper($node)  if not $type;
    return $instance->lhsName($node) if $type eq 'node';
    return "[$type]";
}

# Can be used as test of "brick-ness"
sub brickName {
    my ( $instance, $node ) = @_;
    # local $Data::Dumper::Maxdepth    = 1;
    # say STDERR join " ", __FILE__, __LINE__, Data::Dumper::Dumper($node);
    my $type = $node->{type};
    return $instance->symbol($node) if $type ne 'node';
    my $lhsName = $instance->lhsName($node);
    return $lhsName if not $instance->{mortarLHS}->{$lhsName};
    return;
}

# Return the name of a brick by recursively climbing,
# and die if this fails.
sub forceBrickName {
    my ( $instance, $node ) = @_;
    my $brickNode = $instance->brickNode($node);
    return $instance->brickName($brickNode) if $brickNode;
    $DB::single = 1;
    die;
}

# The name of a node for diagnostics purposes.  Prefers
# "brick" symbols over "mortar" symbols.
sub diagName {
    my ( $instance, $node ) = @_;
    my $brickNode = $instance->brickNode($node);
    return $instance->brickName($brickNode) if $brickNode;
    return $instance->name($node);
}

# The "name" of a node.  Not necessarily unique
sub name {
    my ( $instance, $node ) = @_;
    my $type   = $node->{type};
    my $symbol = $instance->symbol($node);
    return $symbol if $type ne 'node';
    return $instance->lhsName($node);
}

# Determine how many spaces we need.
# Arguments are an array of strings (intended
# to be concatenated) and an integer, representing
# the number of spaces needed by the app.
# (For hoon this will always between 0 and 2.)
# Hoon's notation of spacing, in which a newline is equivalent
# a gap and therefore two spaces, is used.
#
# Return value is the number of spaces needed after
# the trailing part of the argument string array is
# taken into account.  It is always less than or
# equal to the `spacesNeeded` argument.
sub spacesNeeded {
    my ( $strings, $spacesNeeded ) = @_;
    for ( my $arrayIX = $#$strings ; $arrayIX >= 0 ; $arrayIX-- ) {

        my $string = $strings->[$arrayIX];

        for (
            my $stringIX = ( length $string ) - 1 ;
            $stringIX >= 0 ;
            $stringIX--
          )
        {
            my $char = substr $string, $stringIX, 1;
            return 0 if $char eq "\n";
            return $spacesNeeded if $char ne q{ };
            $spacesNeeded--;
            return 0 if $spacesNeeded <= 0;
        }
    }

    # No spaces needed at beginning of string;
    return 0;
}

sub testStyleCensus {
    my ($instance)      = @_;
    my $ruleDB          = $instance->{ruleDB};
    my $symbolDB        = $instance->{symbolDB};
    my $symbolReverseDB = $instance->{symbolReverseDB};
    my $grammar         = $instance->{grammar};

  SYMBOL:
    for my $symbolID ( $grammar->symbol_ids() ) {
        my $name = $grammar->symbol_name($symbolID);
        my $data = {};
        $data->{name}   = $name;
        $data->{id}     = $symbolID;
        $data->{lexeme} = 1;                     # default to lexeme
        $data->{gap}    = 1 if $name eq 'GAP';
        if ( $name =~ m/^[B-Z][AEOIU][B-Z][B-Z][AEIOU][B-Z]GAP$/ ) {
            $data->{gap}     = 1;
            $data->{runeGap} = 1;
        }
        $symbolDB->[$symbolID] = $data;
        $symbolReverseDB->{$name} = $data;
    }
    my $gapID = $symbolReverseDB->{'GAP'}->{id};
  RULE:
    for my $ruleID ( $grammar->rule_ids() ) {
        my $data = { id => $ruleID };
        my ( $lhs, @rhs ) = $grammar->rule_expand($ruleID);
        $data->{symbols} = [ $lhs, @rhs ];
        my $lhsName       = $grammar->symbol_name($lhs);
        my $separatorName = $separator{$lhsName};
        if ($separatorName) {
            my $separatorID = $symbolReverseDB->{$separatorName}->{id};
            $data->{separator} = $separatorID;
            if ( $separatorID == $gapID ) {
                $data->{gapiness} = -1;
            }
        }
        if ( not defined $data->{gapiness} ) {
            for my $rhsID (@rhs) {
                $data->{gapiness}++ if $symbolDB->[$rhsID]->{gap};
            }
        }
        $ruleDB->[$ruleID] = $data;

# say STDERR join " ", __FILE__, __LINE__, "setting rule $ruleID gapiness to", $data->{gapiness} // 'undef';
        $symbolReverseDB->{$lhs}->{lexeme} = 0;
    }

}

sub gapNode {
    my ( $instance, $node ) = @_;
    my $symbolReverseDB = $instance->{symbolReverseDB};
    my $symbol          = $node->{symbol};
    return if not defined $symbol;
    return $symbolReverseDB->{$symbol}->{gap};
}

sub runeGapNode {
    my ( $instance, $node ) = @_;
    my $symbolReverseDB = $instance->{symbolReverseDB};
    my $symbol          = $node->{symbol};
    return if not defined $symbol;
    return $symbolReverseDB->{$symbol}->{runeGap};
}

# Assumes the node *is* a gap
sub gapLength {
    my ( $instance, $node ) = @_;
    if ( $instance->runeGapNode($node) ) {
        my $gapLiteral = $instance->literalNode($node);
        return (length $gapLiteral) - 2;
    }
    return $node->{length};
}

sub line_column {
    my ( $instance, $pos ) = @_;
    $Data::Dumper::Maxdepth = 3;
    die Data::Dumper::Dumper($instance) if not defined $instance->{recce};
    my ( $line, $column ) = $instance->{recce}->line_column($pos);
    $column--;
    return $line, $column;
}

sub ancestorByBrickName {
    my ( $instance, $node, $name ) = @_;
    my $thisNode = $node;
  PARENT: while ($thisNode) {
        my $thisName = $instance->brickName($thisNode);
        return $thisNode if defined $thisName and $thisName eq $name;
        $thisNode = $thisNode->{PARENT};
    }
    return;
}

sub ancestorByLHS {
    my ( $instance, $node, $names ) = @_;
    my $thisNode = $node;
  PARENT: while ($thisNode) {
        my $thisName = $instance->lhsName($thisNode);
        return $thisNode if defined $thisName and $names->{$thisName};
        $thisNode = $thisNode->{PARENT};
    }
    return;
}

sub ancestor {
    my ( $instance, $node, $generations ) = @_;
    my $thisNode = $node;
  PARENT: while ($thisNode) {
        return $thisNode if $generations <= 0;
        $generations--;
        $thisNode = $thisNode->{PARENT};
    }
    return;
}

sub nodeLC {
    my ( $instance, $node ) = @_;
    return $instance->line_column( $node->{start} );
}

sub brickNode {
    my ( $instance, $node ) = @_;
    my $thisNode = $node;
    while ($thisNode) {
        return $thisNode if $instance->brickName($thisNode);
        $thisNode = $thisNode->{PARENT};
    }
    return;
}

# Return a brick descendent, if there is one.
# Only singletons are followed.
sub brickDescendant {
    my ( $instance, $node ) = @_;
    # local $Data::Dumper::Maxdepth    = 1;
    # say STDERR join " ", __FILE__, __LINE__, Data::Dumper::Dumper($node);
    my $thisNode = $node;
    while ($thisNode) {
        # say STDERR join " ", __FILE__, __LINE__, Data::Dumper::Dumper($thisNode);
        return $thisNode if $instance->brickName($thisNode);
        my $children = $thisNode->{children};
        return if not $children;
        $thisNode = $children->[0];
    }
    return;
}

sub brickLC {
    my ( $instance, $node ) = @_;
    return $instance->nodeLC( $instance->brickNode($node) );
}

# first brick node in $node's line --
# $node if there is no prior brick node
sub firstBrickOfLine {
    my ( $instance, $node ) = @_;
    my ($currentLine) = $instance->nodeLC($node);
    my $thisNode = $node;
    my $firstBrickNode;
  NODE: while ($thisNode) {
        my ($thisLine) = $instance->nodeLC($thisNode);
        last NODE if $thisLine != $currentLine;
        $firstBrickNode = $thisNode if $instance->brickName($thisNode);
        $thisNode = $thisNode->{PARENT};
    }
    return $firstBrickNode // $node;
}

# first brick node in $node's line,
# by inclusion list.
# $node if there is no prior included brick node
sub firstBrickOfLineInc {
    my ( $instance, $node, $inclusions ) = @_;

   # say STDERR join " ", __FILE__, __LINE__, Data::Dumper::Dumper($inclusions);
    my ($currentLine)  = $instance->nodeLC($node);
    my $thisNode       = $node;
    my $firstBrickNode = $node;
  NODE: while ($thisNode) {
        my ($thisLine) = $instance->nodeLC($thisNode);

  # say STDERR join " ", __FILE__, __LINE__, 'LC', $instance->nodeLC($thisNode);
  # say STDERR join " ", __FILE__, __LINE__, $thisLine, $currentLine;
        last NODE if $thisLine != $currentLine;
      PICK_NODE: {
            my $brickName = $instance->brickName($thisNode);

           # say STDERR join " ", __FILE__, __LINE__, ($brickName // '[undef]');
            last PICK_NODE if not defined $brickName;
            $firstBrickNode = $thisNode if $inclusions->{$brickName};

            # say STDERR join " ", __FILE__, __LINE__, $brickName;
        }
        $thisNode = $thisNode->{PARENT};
    }
    return $firstBrickNode;
}

# first brick node in $node's line,
# with exclusions.
# $node if there is no prior unexcluded brick node
sub firstBrickOfLineExc {
    my ( $instance, $node, $exclusions ) = @_;

   # say STDERR join " ", __FILE__, __LINE__, Data::Dumper::Dumper($exclusions);
    my ($currentLine)  = $instance->nodeLC($node);
    my $thisNode       = $node;
    my $firstBrickNode = $node;
  NODE: while ($thisNode) {
        my ($thisLine) = $instance->nodeLC($thisNode);

  # say STDERR join " ", __FILE__, __LINE__, 'LC', $instance->nodeLC($thisNode);
  # say STDERR join " ", __FILE__, __LINE__, $thisLine, $currentLine;
        last NODE if $thisLine != $currentLine;
      PICK_NODE: {
            my $brickName = $instance->brickName($thisNode);

           # say STDERR join " ", __FILE__, __LINE__, ($brickName // '[undef]');
            last PICK_NODE if not defined $brickName;

            # say STDERR join " ", __FILE__, __LINE__, $brickName;
            last PICK_NODE if $exclusions->{$brickName};

            # say STDERR join " ", __FILE__, __LINE__, $brickName;
            $firstBrickNode = $thisNode;
        }
        $thisNode = $thisNode->{PARENT};
    }

   # say STDERR join " ", __FILE__, __LINE__, "returning from firstBrickOfLine";

    return $firstBrickNode;
}

# nearest (in syntax tree) brick node in $node's line,
# from inclusion list
# $node if there is no nearest included brick node on same line
sub nearestBrickOfLineInc {
    my ( $instance, $node, $inclusions ) = @_;

   # say STDERR join " ", __FILE__, __LINE__, Data::Dumper::Dumper($inclusions);
    my ($currentLine) = $instance->nodeLC($node);
    my $thisNode = $node;
  NODE: while ($thisNode) {
        my ($thisLine) = $instance->nodeLC($thisNode);

  # say STDERR join " ", __FILE__, __LINE__, 'LC', $instance->nodeLC($thisNode);
  # say STDERR join " ", __FILE__, __LINE__, $thisLine, $currentLine;
        last NODE if $thisLine != $currentLine;
      PICK_NODE: {
            my $brickName = $instance->brickName($thisNode);

           # say STDERR join " ", __FILE__, __LINE__, ($brickName // '[undef]');
            last PICK_NODE if not defined $brickName;

            # say STDERR join " ", __FILE__, __LINE__, $brickName;
            # say STDERR join " ", __FILE__, __LINE__, $brickName;
            return $thisNode if $inclusions->{$brickName};
        }
        $thisNode = $thisNode->{PARENT};
    }

# say STDERR join " ", __FILE__, __LINE__, "returning from nearestBrickOfLineInc";

    return $node;
}

# nearest (in syntax tree) brick node in $node's line --
# with exclusions.
# $node if there is no nearest unexcluded brick node on same line
sub nearestBrickOfLineExc {
    my ( $instance, $node, $exclusions ) = @_;

   # say STDERR join " ", __FILE__, __LINE__, Data::Dumper::Dumper($exclusions);
    my ($currentLine) = $instance->nodeLC($node);
    my $thisNode = $node;
  NODE: while ($thisNode) {
        my ($thisLine) = $instance->nodeLC($thisNode);

  # say STDERR join " ", __FILE__, __LINE__, 'LC', $instance->nodeLC($thisNode);
  # say STDERR join " ", __FILE__, __LINE__, $thisLine, $currentLine;
        last NODE if $thisLine != $currentLine;
      PICK_NODE: {
            my $brickName = $instance->brickName($thisNode);

           # say STDERR join " ", __FILE__, __LINE__, ($brickName // '[undef]');
            last PICK_NODE if not defined $brickName;

            # say STDERR join " ", __FILE__, __LINE__, $brickName;
            last PICK_NODE if $exclusions->{$brickName};

            # say STDERR join " ", __FILE__, __LINE__, $brickName;
            return $thisNode;
        }
        $thisNode = $thisNode->{PARENT};
    }

 # say STDERR join " ", __FILE__, __LINE__, "returning from nearestBrickOfLine";

    return $node;
}

my $semantics = <<'EOS';
:default ::= action=>MarpaX::Hoonlint::doNode
lexeme default = latm => 1 action=>[start,length,name]
EOS

my $parser =
  MarpaX::Hoonlint::YAHC->new( { semantics => $semantics, all_symbols => 1 } );
my $dsl = $parser->dsl();

$MarpaX::Hoonlint::grammar = $parser->rawGrammar();
my %baseLintInstance = ();
$baseLintInstance{parser} = $parser;
$baseLintInstance{grammar} = $MarpaX::Hoonlint::grammar;

my %NYI_Rule = ();
$NYI_Rule{$_} = 1 for qw();
$baseLintInstance{NYI_Rule} = \%NYI_Rule;

my %tallRuneRule = map { +( $_, 1 ) } grep {
         /^tall[B-Z][aeoiu][b-z][b-z][aeiou][b-z]$/
      or /^tall[B-Z][aeoiu][b-z][b-z][aeiou][b-z]Mold$/
} map { $MarpaX::Hoonlint::grammar->symbol_name($_); }
  $MarpaX::Hoonlint::grammar->symbol_ids();
$baseLintInstance{tallRuneRule} = \%tallRuneRule;

# TODO: Check that these are all backdented,
my %tallNoteRule = map { +( $_, 1 ) } qw(
  tallBarhep tallBardot
  tallBuccab
  tallCendot tallColcab
  tallKetbar tallKethep tallKetlus tallKetsig tallKetwut
  tallSigbar tallSigcab tallSigfas tallSiglus
  tallTisbar tallTiscom tallTisgal
  tallWutgal tallWutgar tallWuttis
  tallZapgar
);
$baseLintInstance{tallNoteRule} = \%tallNoteRule;

my %mortarLHS = map { +( $_, 1 ) }
  qw(rick5dJog ruck5dJog rick5d ruck5d till5dSeq tall5dSeq
  fordFile fordHoop fordHoopSeq norm5d tall5d
  boog5d wisp5d whap5d);
$baseLintInstance{mortarLHS} = \%mortarLHS;

my %tallBodyRule =
  map { +( $_, 1 ) } grep { not $tallNoteRule{$_} } keys %tallRuneRule;
$baseLintInstance{tallBodyRule} = \%tallBodyRule;

# Will include:
# BuccenMold BuccolMold BucwutMold
# Buccen Buccol Bucwut Colsig Coltar Wutbar Wutpam
my %tall_0RunningRule = map { +( $_, 1 ) } qw(
  tallBuccen tallBuccenMold
  tallBuccol tallBuccolMold
  tallBucwut tallBucwutMold
  tallColsig tallColtar tallTissig
  tallWutbar tallWutpam);
$baseLintInstance{tall_0RunningRule} = \%tall_0RunningRule;

my %tall_1RunningRule =
  map { +( $_, 1 ) } qw( tallDotket tallSemcol tallSemsig tallCencolMold );
$baseLintInstance{tall_1RunningRule} = \%tall_1RunningRule;

my %tall_1JoggingRule =
  map { +( $_, 1 ) } qw(tallCentis tallCencab tallWuthep);
$baseLintInstance{tall_1JoggingRule} = \%tall_1JoggingRule;

my %tall_2JoggingRule = map { +( $_, 1 ) } qw(tallCentar tallWutlus);
$baseLintInstance{tall_2JoggingRule} = \%tall_2JoggingRule;

my %tallJogging1_Rule = map { +( $_, 1 ) } qw(tallTiscol);
$baseLintInstance{tallJogging1_Rule} = \%tallJogging1_Rule;

my %joggingRule = map { +( $_, 1 ) } (
    keys %tall_1JoggingRule,
    keys %tall_2JoggingRule,
    keys %tallJogging1_Rule
);
$baseLintInstance{joggingRule} = \%joggingRule;

my %tallLuslusRule =
  map { +( $_, 1 ) } qw(LuslusCell LushepCell LustisCell);
$baseLintInstance{tallLuslusRule} = \%tallLuslusRule;

my %barcenAnchorExceptions = ();
$barcenAnchorExceptions{$_} = 1
  for qw(tallTisgar tallTisgal LuslusCell LushepCell LustisCell);
$baseLintInstance{barcenAnchorExceptions} = \%barcenAnchorExceptions;

my %tallJogRule = map { +( $_, 1 ) } qw(rick5dJog ruck5dJog);
$baseLintInstance{tallJogRule} = \%tallJogRule;

my %tallBackdentRule = map { +( $_, 1 ) } qw(
  bonz5d
  fordFascol
  fordFasket
  fordFaspam
  fordFassem
  tallBarcol
  tallBarsig
  tallBartar
  tallBartis
  tallBuchep
  tallBuchepMold
  tallBucket
  tallBucketMold
  tallBucpat
  tallBuctisMold
  tallCenhep
  tallCenhepMold
  tallCenket
  tallCenlus
  tallCenlusMold
  tallCensig
  tallCentar
  tallColhep
  tallColket
  tallCollus
  tallDottar
  tallDottis
  tallKetcen
  tallKettis
  tallSigbuc
  tallSigcen
  tallSiggar
  tallSigpam
  tallSigwut
  tallSigzap
  tallTisdot
  tallTisfas
  tallTisgar
  tallTishep
  tallTisket
  tallTislus
  tallTissem
  tallTistar
  tallTiswut
  tallWutcol
  tallWutdot
  tallWutket
  tallWutpat
  tallWutsig
  tallZapcol
  tallZapdot
  tallZaptis
  tallZapwut
);
$baseLintInstance{backdentedRule} = \%tallBackdentRule;

$baseLintInstance{ruleDB}          = [];
$baseLintInstance{symbolDB}        = [];
$baseLintInstance{symbolReverseDB} = {};

testStyleCensus(\%baseLintInstance);

sub new {
    my ( $class, $config ) = (@_);
    my $fileName     = $config->{fileName};
    my %lint         = (%{$config}, %baseLintInstance);
    my $lintInstance = \%lint;

    bless $lintInstance, "MarpaX::Hoonlint";
    my $policies = $lintInstance->{policies};
    my $pSource  = $lintInstance->{pHoonSource};
    my $parser  = $lintInstance->{parser};
    $lintInstance->{topicLines}   = {};
    $lintInstance->{mistakeLines} = {};

    my @data = ();

    $parser->read($pSource);

    $MarpaX::Hoonlint::recce = $parser->rawRecce();
    $lintInstance->{recce}     = $MarpaX::Hoonlint::recce;
    $lintInstance->{nodeCount} = 0;

    $parser = undef;    # free up memory
    my $astRef = $MarpaX::Hoonlint::recce->value($lintInstance);

    my @lineToPos = ( -1, 0 );
    {
        my $lastPos = 0;
      LINE: while (1) {
            my $newPos = index ${$pSource}, "\n", $lastPos;

            # say $newPos;
            last LINE if $newPos < 0;
            $lastPos = $newPos + 1;
            push @lineToPos, $lastPos;
        }
    }
    $lintInstance->{lineToPos} = \@lineToPos;

   # say STDERR join " ", __FILE__, __LINE__, Data::Dumper::Dumper(\@lineToPos);

    die "Parse failed" if not $astRef;

    # local $Data::Dumper::Deepcopy = 1;
    # local $Data::Dumper::Terse    = 1;
    # local $Data::Dumper::Maxdepth    = 3;

    my $astValue = ${$astRef};

    for my $policyShortName ( keys %{$policies} ) {
        my $policyFullName = $policies->{$policyShortName};
        my $constructor    = UNIVERSAL::can( $policyFullName, 'new' );
        my $policy         = $constructor->( $policyFullName, $lintInstance );
        $policy->{shortName} = $policyShortName;
        $policy->{fullName}  = $policyFullName;
        $policy->{perNode}   = {};
        $policy->validate($astValue);
    }

    print $lintInstance->contextDisplay();

    my $unusedSuppressions = $lintInstance->{unusedSuppressions};
    for my $lc ( keys %{$unusedSuppressions} ) {
        my $perLCSuppressions = $unusedSuppressions->{$lc};
        for my $policy (
            grep { $perLCSuppressions->{$_} }
            keys %{$perLCSuppressions}
          )
        {
            my $perPolicySuppressions = $perLCSuppressions->{$policy};
            for my $subpolicy (
                grep { $perPolicySuppressions->{$_} }
                keys %{$perPolicySuppressions}
              )
            {
                say "Unused suppression: $fileName $lc $policy $subpolicy";
            }
        }
    }

    return $lintInstance;
}

1;

# vim: expandtab shiftwidth=4:
