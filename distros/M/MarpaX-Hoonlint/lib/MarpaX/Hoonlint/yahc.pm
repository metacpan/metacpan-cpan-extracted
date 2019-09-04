use 5.010;
use strict;
use warnings;
use English qw( -no_match_vars );
use Data::Dumper;

use Marpa::R2 6.000;

# This code uses as its grammar reference the code in
# the arvo repo: https://github.com/urbit/arvo
# File sys/hoon.hoon: https://github.com/urbit/arvo/blob/master/sys/hoon.hoon
# as of commit 7dc3eb1cfacaaafd917697a544bdcf7f22e09eeb

package MarpaX::Hoonlint::YAHC;

use English qw( -no_match_vars );

sub deprecated {
    my $slg      = $Marpa::R2::Context::slg;
    my $rule_id  = $Marpa::R2::Context::rule;
    my ($lhs_id) = $slg->rule_expand($rule_id);
    return [ 'deprecated', $slg->symbol_display_form($lhs_id) ];
}


# === Automatically generated Marpa rules ===

# Here is meta-programming to write piece 2

# ace and gap are not really char names,
# and are omitted
my %glyphs = (
    bar => '|',
    bas => '\x5c', # '\'
    buc => '$',
    cab => '_',
    cen => '%',
    col => ':',
    com => ',',
    doq => '"',
    dot => '.',
    fas => '/',
    gal => '<',
    gar => '>',
    hax => '#',
    hep => '-',
    kel => '{',
    ker => '}',
    ket => '\\^',
    lus => '+',
    pal => '(',
    pam => '&',
    par => ')',
    pat => '@',
    pel => '(',
    per => ')',
    sel => '\x5b', # '['
    sem => ';',
    ser => '\x5d', # ']'
    sig => '~',
    soq => '\'',
    tar => '*',
    tec => '`',
    tis => '=',
    wut => '?',
    zap => '!',
);

my @glyphRules = ();
for my $glyphName (sort keys %glyphs) {
    my $glyph = $glyphs{$glyphName};
    my $ucGlyphName = uc $glyphName;
    my $uc4hGlyphName = $ucGlyphName . '4H';
    my $lcGlyphName = $glyphName . '4h';
    push @glyphRules, "$ucGlyphName ~ $lcGlyphName";
    push @glyphRules, "$uc4hGlyphName ~ $lcGlyphName";
    push @glyphRules, "$lcGlyphName ~ [" . $glyph . q{]};
    push @glyphRules, "inaccessible_ok ::= $ucGlyphName";
    push @glyphRules, "inaccessible_ok ::= $uc4hGlyphName";
}
my $glyphAutoRules = join "\n", @glyphRules;

my $mainDSL = do { $RS = undef; <DATA> };

my @dslAutoRules = ();
DESC: for my $desc (split "\n", $mainDSL) {
    my $originalDesc = $desc;
    chomp $desc; # remove newline
    next DESC if not $desc =~ s/^[#] FIXED: //;
    $desc =~ s/^\s+//; # eliminate leading spaces
    $desc =~ s/\s+$//; # eliminate trailing spaces
    my ($rune, @samples) = split /\s+/, $desc;
    die $originalDesc if not $rune;
    push @dslAutoRules, doFixedRune( $rune, @samples );
}
my $dslAutoRules = join "\n", @dslAutoRules;

# Assemble the base BSL
my $baseDSL = join "\n", $mainDSL, $glyphAutoRules, $dslAutoRules;

my $defaultSemantics = <<'EOS';
# start and length will be needed for production
# :default ::= action => [name,start,length,values]
:default ::= action => [name,values]
lexeme default = latm => 1
EOS

sub divergence {
    die join '', 'Unrecoverable internal error: ', @_;
}

# Given an input and an offset into that input,
# it reads a triple quote (''').  The return values
# are the parse value and a new offset in the input.
# Errors are thrown.

sub getTripleQuote {
    my ( $input, $offset ) = @_;
    my $input_length = length ${$input};
    my $resume_pos;
    my $this_pos;

    my $nextNL = index ${$input}, "\n", $offset;
    if ($nextNL < 0) {
      die join '', 'Newline missing after triple quotes: "', ${$input}, '"'
    }
    my $initiator = substr ${$input}, $offset, $nextNL-$offset;
    if ($initiator ne "'''" and $initiator !~ m/^''' *::/) {
      die join '', 'Disallowed characters after initial triple quotes: "', $initiator, '"'
    }

    pos ${$input} = $offset;
    my ($indent) = ${$input} =~ /\G( *)[^ ]/g;
    my $terminator = $indent . "'''";

    my $terminatorPos = index ${$input}, $terminator, $nextNL;
    my $value = substr ${$input}, $nextNL+1, ($terminatorPos - $nextNL);

    say STDERR "Left main READ loop" if $MarpaX::Hoonlint::YAHC::DEBUG;

    # Return ref to value and new offset
    return \$value, $terminatorPos + length $terminator;
}

# Given an input and an offset into that input,
# it reads a triple double quote (""").  The return values
# are the parse value and a new offset in the input.
# Errors are thrown.

# TODO: Needs to implement reading of sump(5d)

sub getTripleDoubleQuote {
    my ( $input, $offset ) = @_;
    my $input_length = length ${$input};
    my $resume_pos;
    my $this_pos;

    my $nextNL = index ${$input}, "\n", $offset;
    if ($nextNL < 0) {
      die join '', 'Newline missing after triple double quotes: "',
	${$input}, '"'
    }
    my $initiator = substr ${$input}, $offset, $nextNL-$offset;
    if ($initiator ne q{"""}) {
      die join '',
	'Disallowed characters after initial triple double quotes: "', $initiator, '"'
    }

    pos ${$input} = $offset;
    my ($indent) = ${$input} =~ /\G( *)[^ ]/g;
    my $terminator = $indent . q{"""};

    my $terminatorPos = index ${$input}, $terminator, $nextNL;
    my $value = substr ${$input}, $nextNL+1, ($terminatorPos - $nextNL);

    say STDERR "Left main READ loop" if $MarpaX::Hoonlint::YAHC::DEBUG;

    # Return ref to value and new offset
    return \$value, $terminatorPos + length $terminator;
}

# Given an input and an offset into that input,
# it reads unmarkdown.  The return values
# are the parse value and a new offset in the input.
# Reading is not intelligent -- it finds a terminator, and
# treats the unmarkdown as a string.
# Errors are thrown.

sub getCram {
    # $DB::single = 1;

    my ( $input, $origOffset ) = @_;
    my $input_length = length ${$input};
    my $resume_pos;
    my $this_pos;

    my $semiPos = rindex ${$input}, ';', $origOffset;
    my $previousNlPos = rindex ${$input}, "\n", $semiPos;
    my $indent = $semiPos - ($previousNlPos + 1);
    my $firstNlPos = index ${$input}, "\n", $semiPos;
    my $valueStartPos      = $semiPos + 2;
    my $nextNlPos = $firstNlPos;
    # say STDERR qq{origOffset: }, substr(${$input}, $origOffset, 20);
    # say STDERR qq{First NL pos: }, substr(${$input}, $firstNlPos, 20);

    if ($indent <= 0) {
	# say STDERR "indent=$indent; nextNlPos=$nextNlPos";
        LINE: while ($nextNlPos >= 0) {
            pos ${$input} = $nextNlPos + 1;
            if ( ${$input} =~ m/\G [ ]* == [\n]/xms ) {
                my $terminatorStartPos = $LAST_MATCH_START[0];
                my $terminatorEndPos   = $LAST_MATCH_END[0];
                my $value              = substr( ${$input}, $valueStartPos,
                    $terminatorStartPos - $valueStartPos );
                return \$value, $nextNlPos;
            }
	    $nextNlPos = index ${$input}, "\n", $nextNlPos+1;
        }
	# If here, end of string is EOF
	my $inputLength = length ${$input};
	my $value = substr ${$input}, $valueStartPos, $inputLength - $valueStartPos;
	return \$value, $inputLength;
    }

    # If here, indent > 0
    my $indentString = (' ' x $indent);

    LINE: while ($nextNlPos >= 0) {
	# say STDERR "LINE: indent=$indent; nextNlPos=$nextNlPos";
	pos ${$input} = $nextNlPos + 1;
	# say STDERR qq{Pos set to: }, substr(${$input}, $nextNlPos+1, 20);
	if ( ${$input} =~ m/\G $indentString [ ]* == [\n]/xms ) {
	    my $terminatorStartPos = $LAST_MATCH_START[0];
	    # say STDERR qq{TISTIS found: }, substr(${$input}, $terminatorStartPos, 20);
	    my $value              = substr( ${$input}, $valueStartPos,
		$terminatorStartPos - $valueStartPos );
	    # Continue parsing after TISTIS?  Or before?
	    return \$value, $nextNlPos;
	}
	
	if ( (substr ${$input}, $nextNlPos+1, $indent) eq $indentString ) {
	    $nextNlPos = index ${$input}, "\n", $nextNlPos+1;
	    # say STDERR qq{Continuing cram, nextNlPos=$nextNlPos};
	    # say STDERR qq{Continuing cram: }, substr(${$input}, $nextNlPos, 20);
	    next LINE;
	}
	# If here, outdent
	# say STDERR qq{Outdent, returning at: }, substr(${$input}, $nextNlPos+1, 20);
	my $value              = substr ${$input}, $valueStartPos,
	  ($nextNlPos + 1) - $valueStartPos;
	return \$value, $nextNlPos+1;
    }

    # Premature EOF if here
    return;
}

# The 'semantics' named argument must be considered "internal"
# for now -- any change in the grammar could break any or all of
# apps.  When the grammar can be frozen, the 'semantics' argument
# can become a "documented" feature.
#
# In the meantime, applications which want stability can simply
# copy in this file lexically, losing the advantage of updates,
# but guaranteeing stability.
sub new {
    my ($class, @argHashes) = @_;
    my $self      = {};
    for my $argHash (@argHashes) {
      ARG_NAME: for my $argName ( keys %{$argHash} ) {
            if ( $argName eq 'all_symbols' ) {
                $self->{all_symbols} = $argHash->{all_symbols};
                next ARG_NAME;
            }
            if ( $argName eq 'semantics' ) {
                $self->{semantics} = $argHash->{semantics};
                next ARG_NAME;
            }
            die "MarpaX::Hoonlint::YAHC::new() called with unknown arg name: $argName";
        }
    }
    my $semantics = $self->{semantics} // $defaultSemantics;
    if ( $self->{all_symbols} ) {
        ## show all symbols
        $baseDSL =~ s/[(][-] //g;
        $baseDSL =~ s/ [-][)]//g;
    }
    else {
        ## hide selected symbols
        $baseDSL =~ s/[(][-] /(/g;
        $baseDSL =~ s/ [-][)]/)/g;
    }
    my $dsl = $semantics . $baseDSL;

    my $grammar = Marpa::R2::Scanless::G->new( { source => \$dsl } );
    $self->{dsl} = $dsl;
    $self->{grammar} = $grammar;
    return bless $self, $class;
}

sub recceStart {
    my ($self) = @_;
    my $debug = $MarpaX::Hoonlint::YAHC::DEBUG;
    my $recce = Marpa::R2::Scanless::R->new(
        {
            grammar         => $self->{grammar},
            ranking_method  => 'high_rule_only',
            trace_lexers    => ( $debug ? 1 : 0 ),
            trace_terminals => ( $debug ? 1 : 0 ),
        }
    );
    $self->{recce} = $recce;
    return $self;
}

sub dsl {
    my ($self) = @_;
    return $self->{dsl};
}

sub rawGrammar {
    my ($self) = @_;
    return $self->{grammar};
}

sub rawRecce {
    my ($self) = @_;
    return $self->{recce};
}

sub read {
    my ($self, $input) = @_;
    $self->recceStart();
    my $recce = $self->{recce};
    my $debug = $MarpaX::Hoonlint::YAHC::DEBUG;
    my $input_length = length ${$input};
    my $this_pos;
    my $ok = eval { $this_pos = $recce->read( $input ) ; 1; };
    if (not $ok) {
       say STDERR $recce->show_progress(0, -1) if $debug;
       die $EVAL_ERROR;
    }

    # The main read loop.  Read starting at $offset.
    # If interrupted execute the handler logic,
    # and, possibly, resume.
    say STDERR "this_pos=$this_pos ; input_length=$input_length" if $debug;

  READ:
    while ( $this_pos < $input_length ) {

	my $resume_pos;

        # Only one event at a time is expected -- more
        # than one is an error.  No event means parsing
        # is exhausted.

        my $events      = $recce->events();
        my $event_count = scalar @{$events};
        if ( $event_count < 0 ) {
            last READ;
        }
        if ( $event_count != 1 ) {
            divergence("One event expected, instead got $event_count");
        }

        # Find the event name

        my $event = $events->[0];
        my $eventName  = $event->[0];

	say STDERR "$eventName event" if $MarpaX::Hoonlint::YAHC::DEBUG;

        if ( $eventName eq 'tripleQuote' ) {
            my $value_ref;
            ( $value_ref, $resume_pos ) = getTripleQuote( $input, $this_pos );
	    return if not $value_ref;
            my $result = $recce->lexeme_read(
                'TRIPLE_QUOTE_STRING',
                $this_pos,
                ( length ${$value_ref} ),
                [ ${$value_ref} ]
            );
            say STDERR "lexeme_read('TRIPLE_QUOTE_STRING',...) returned ",
              Data::Dumper::Dumper( \$result )
              if $MarpaX::Hoonlint::YAHC::DEBUG;
        }

	# TODO: tripeDoubleQuote must allow sump(5d)
        if ( $eventName eq 'tripleDoubleQuote' ) {
            my $value_ref;
            ( $value_ref, $resume_pos )
	      = getTripleDoubleQuote( $input, $this_pos );
	    return if not $value_ref;
            my $result = $recce->lexeme_read(
                'TRIPLE_DOUBLE_QUOTE_STRING',
                $this_pos,
                ( length ${$value_ref} ),
                [ ${$value_ref} ]
            );
            say STDERR "lexeme_read('TRIPLE_DOUBLE_QUOTE_STRING',...) returned ",
              Data::Dumper::Dumper( \$result )
              if $MarpaX::Hoonlint::YAHC::DEBUG;
	}

        if ( $eventName eq '^CRAM' ) {
            my $value_ref;
            ( $value_ref, $resume_pos )
	      = getCram( $input, $this_pos );
	    if (not $value_ref) {
		# TODO: After development, add "if $debug"
		say STDERR $recce->show_progress( 0, -1 );
		my $badStart = substr ${$input}, $this_pos, 50;
		die join '', 'Problem in getCram: "', $badStart, '"';
	    }
            my $result = $recce->lexeme_read(
                'CRAM',
                $this_pos,
                ( length ${$value_ref} ),
                [ ${$value_ref} ]
            );
            say STDERR "lexeme_read('CRAM',...) returned ",
              Data::Dumper::Dumper( \$result )
              if $MarpaX::Hoonlint::YAHC::DEBUG;
	}

	if (not $resume_pos) {
	  die "read() ended prematurely\n",
	    "  input length = $input_length\n",
	    "  length read = $this_pos\n",
	    qq{  the cause was an "$eventName" event};
	}

	say STDERR "this_pos=$this_pos ; input_length=$input_length" if $debug;

	# say STDERR qq{Resuming at "}, substr ${$input}, $resume_pos, 50;

        my $ok = eval { $this_pos = $recce->resume($resume_pos); 1; };
        if ( not $ok ) {
            say STDERR $recce->show_progress( 0, -1 ) if $debug;
            die $EVAL_ERROR;
        }

    }
    return;
}

sub parse {
    my ($input) = @_;
    my $debug = $MarpaX::Hoonlint::YAHC::DEBUG;
    my $self = MarpaX::Hoonlint::YAHC->new();
    $self->read($input);
    my $recce = $self->{recce};

    if ( 0 ) {
    # if ( $recce->ambiguity_metric() > 1 ) {

        # The calls in this section are experimental as of Marpa::R2 2.090
        my $asf = Marpa::R2::ASF->new( { slr => $recce } );
        say STDERR 'No ASF' if not defined $asf;
        my $ambiguities = Marpa::R2::Internal::ASF::ambiguities($asf);
        my @ambiguities = grep { defined } @{$ambiguities}[ 0 .. 1 ];
        die
          "Parse of BNF/Scanless source is ambiguous\n",
          Marpa::R2::Internal::ASF::ambiguities_show( $asf, \@ambiguities );
    } ## end if ( $recce->ambiguity_metric() > 1 )
    # }

    my $valueRef = $recce->value();
    if ( !$valueRef ) {
	say STDERR $recce->show_progress( 0, -1 ) if $debug;
        die "input read, but there was no parse";
    }

    return $valueRef;
}

# Takes one argument and returns a ref to an array of acceptable
# nodes.  The array may be empty.  All scalars are acceptable
# leaf nodes.  Acceptable interior nodes have length at least 1.
sub prune {
    no warnings 'recursion';
    my ($v) = @_;

    state $deleteIfEmpty = {
        optKets => 1,
    };

    state $nonSemantic = {
        doubleStringElements => 1,
        fordFile             => 1,
        fordHoop             => 1,
        fordHoopSeq          => 1,
        hoonExpression       => 1,
        wideLong5d           => 1,
        norm5d               => 1,
        norm5dMold           => 1,
        rope5d               => 1,
        rump5d               => 1,
        scad5d               => 1,
        scat5d               => 1,
        tall5d               => 1,
        tall5dSeq            => 1,
        teakChoice           => 1,
        till5d               => 1,
        till5dSeq            => 1,
        togaElements         => 1,
        wedeFirst            => 1,
        wide5d               => 1,
        wide5dChoices        => 1,
        wide5dJog            => 1,
        wide5dJogging        => 1,
        wide5dJogs           => 1,
        wide5dSeq            => 1,
        wideNorm5d           => 1,
        wideNorm5dMold       => 1,
        wideTeakChoice       => 1,
        wyde5d               => 1,
        wyde5dSeq            => 1,
    };

    return [] if not defined $v;
    my $reftype = ref $v;
    return [$v] if not $reftype; # An acceptable leaf node
    return prune($$v) if $reftype eq 'REF';
    divergence("Tree node has reftype $reftype") if $reftype ne 'ARRAY';
    my @source = grep { defined } @{$v};
    my $element_count = scalar @source;
    return [] if $element_count <= 0; # must have at least one element
    my $name = shift @source;
    my $nameReftype = ref $name;
    # divergence("Tree node name has reftype $nameReftype") if $nameReftype;
    if ($nameReftype) {
      my @result = ();
      ELEMENT:for my $element ($name, @source) {
	if (ref $element eq 'ARRAY') {
	  push @result, grep { defined }
		  map { @{$_}; }
		  map { prune($_); }
		  @{$element}
		;
	  next ELEMENT;
	}
	push @result, $_;
      }
      return [@result];
    }
    if (defined $deleteIfEmpty->{$name} and $element_count == 1) {
      return [];
    }
    if (defined $nonSemantic->{$name}) {
      # Not an acceptable branch node, but (hopefully)
      # its children are acceptable
      return [ grep { defined }
	      map { @{$_}; }
	      map { prune($_); }
	      @source
	    ];
    }

    # An acceptable branch node
    my @result = ($name);
    push @result, grep { defined }
	    map { @{$_}; }
	    map { prune($_); }
	    @source;
    return [\@result];
}

# takes LC alphanumeric rune name and samples
# for N-fixed rune and returns the Marpa rules
# for the tall and the 2 regular wide forms.
sub doFixedRune {
    my ($runeName, @samples) = @_;
    my @result = (join ' ', '#', (uc $runeName), @samples);
    my $glyphName1 = substr($runeName, 0, 3);
    my $glyphName2 = substr($runeName, 3, 3);
    my $glyph1 = $glyphs{$glyphName1} or die "no glyph for $glyphName1";
    my $glyph2 = $glyphs{$glyphName2};
    my $glyphLexeme1 = ($glyphName1) . '4h';
    my $glyphLexeme2 = ($glyphName2) . '4h';
    my $tallLHS = 'tall' . ucfirst $runeName;
    my $wideLHS = 'wide' . ucfirst $runeName;
    my $tallRuneLexeme = (uc $runeName) . 'GAP';
    my $wideRuneLexeme = (uc $runeName) . 'PEL';

    # norm5d ::= tallBarhep
    push @result, 'norm5d ::= ' . $tallLHS;

    # wideNorm5d ::= wideBarhep
    push @result, 'wideNorm5d ::= ' . $wideLHS;

    # tallBarhep ::= (- BAR4H HEP4H GAP -) tall5d (- GAP -) tall5d
    push @result, $tallLHS . ' ::= (- '
      . $tallRuneLexeme
      . ' -) ' . (join ' (- GAP -) ', @samples);
    state $wideEquiv = {
        bont5d => 'wideBont5d',
        bonz5d => 'wideBonz5d',
        mold   => 'wyde5d',
        tall5d => 'wide5d',
        rack5d => 'wideRack5d',
        rick5d => 'wideRick5d',
        ruck5d => 'wideRuck5d',
        teak5d => 'wideTeak5d',
    };
    my @wideSamples = map { $wideEquiv->{$_} // $_; } @samples;

    # wideBarhep ::= (- BARHEPPEL -) wide5d (- ACE -) wide5d (- PER -)
    push @result, $wideLHS . ' ::= (- '
    . $wideRuneLexeme
    . ' -) ' . (join ' (- ACE -) ', @wideSamples) . q{ (- PER -)};

    # BARHEPGAP ~ bar4h hep4h gap4k
    # BARHEPPEL ~ bar4h hep4h pel4h
    push @result, "$tallRuneLexeme ~ $glyphLexeme1 $glyphLexeme2 gap4k";
    push @result, "$wideRuneLexeme ~ $glyphLexeme1 $glyphLexeme2 pel4h";

    return join "\n", @result, '';
}

1;

# The "FIXED:" comments lines are descriptons of the fixed length runes
# (1-fixed, 2-fixed, 3-fixed and 4-fixed) for auto-generation
# of Marpa rules for the various regular formats, both
# tall and wide.
#
# The format is
#
#   rune type1 type2 ...

# Organization is by hoon.hoon (and Hoon Library) sections: 4a, 5d, etc.;
# and within that alphabetically by "face" name

__DATA__

# === CHARACTER SET ===

# Unicorn is a non-existence character used for various
# tricks: error rules, TODO rules, inaccessbile symbols,
# etc.
UNICORN ~ unicorn
unicorn ~ [^\d\D]

# === Hoon 4i library ===

DOG4I ~ dog4i
dog4i ~ dot4h gay4i

doh4i ~ hep4h hep4h gay4i

GAY4I ~ gay4i
gay4i ~ # empty
gay4i ~ gap4k

LOW4I ~ low4i
low4i ~ [a-z]

NUD4I ~ nud4i
nud4i ~ [0-9]

# the printable characters
prn4i ~ [\x20-\x7e\x80-\xff]
PRN4I_SEQ ~ prn4i+

# vul4i ~ '::' optNonNLs nl

# === Hoon 4j library ===

bip4j ::= bip4j_Piece
  (- DOG4I -) bip4j_Piece
  (- DOG4I -) bip4j_Piece
  (- DOG4I -) bip4j_Piece
  (- DOG4I -) bip4j_Piece
  (- DOG4I -) bip4j_Piece
  (- DOG4I -) bip4j_Piece
bip4j_Piece ::= ASCII_0
bip4j_Piece ::= QEX4J

# Two hex numbers
bix4j ~ six4j six4j

MOT4J ~ mot4j
mot4j ~ [12] sid4j
mot4j ~ sed4j

dum4j ~ sid4j+

DIM4J ~ dim4j # a natural number
dim4j ~ '0'
dim4j ~ dip4j

DIP4J ~ dip4j
dip4j ~ [1-9] dip4jRest
dip4jRest ~ [0-9]*

fed4j ::= huf4j doh4i hyf4jSeq
fed4j ::= hof4j
fed4j ::= haf4j
fed4j ::= TIQ4J

haf4j ::= TEP4J TIP4J

# In hoon.hoon, hef and hif differ in semantics.
hef4j ::= TIP4J TIQ4J

hex4j ~ '0'
hex4j ~ qex4j
hex4j ~ qex4j dog4i qix4jSeq

# In hoon.hoon, hef and hif differ in semantics.
hif4j ::= TIP4J TIQ4J

hof4j ::= hef4j HEP hif4j
hof4j ::= hef4j HEP hif4j HEP hif4j
hof4j ::= hef4j HEP hif4j HEP hif4j HEP hif4j

huf4j ::= hef4j
huf4j ::= hef4j HEP hif4j
huf4j ::= hef4j HEP hif4j HEP hif4j
huf4j ::= hef4j HEP hif4j HEP hif4j HEP hif4j

hyf4j ::= hif4j HEP hif4j
hyf4jSeq ::= hyf4j+ separator=>DOT proper=>1

lip4j ::= lib4j_Piece
  (- DOG4I -) lib4j_Piece
  (- DOG4I -) lib4j_Piece
  (- DOG4I -) lib4j_Piece
lib4j_Piece ::= ASCII_0
lib4j_Piece ::= ted4j

sed4j ~ [1-9]

sex4j ~ [1-9a-f]

sid4j ~ [0-9]

# hexadecimal digit
six4j ~ [0-9a-f]

siv4j ~ [0-9a-v]

ted4j ~ sed4j
ted4j ~ sed4j sid4j
ted4j ~ sed4j sid4j sid4j
ted4j ~ sed4j sid4j sid4j sid4j

QEX4J ~ qex4j
qex4j ~ sex4j
qex4j ~ sex4j hit4k
qex4j ~ sex4j hit4k hit4k
qex4j ~ sex4j hit4k hit4k hit4k

qix4j ~ six4j six4j six4j six4j
QIX4J_SEQ ~ qix4jSeq
qix4jSeq ~ qix4j+ separator=>dot4h proper=>1

# tep, tip and tiq have different semantics in hoon.hoon
TEP4J ~ low4i low4i low4i
TIP4J ~ low4i low4i low4i
TIQ4J ~ low4i low4i low4i

urs4j ::= ursChoice*
ursChoice ::= NUD4I | LOW4I | HEP | DOT | SIG | CAB

urx4j ::= urxChoice*
urxChoice ::= NUD4I | LOW4I | HEP | CAB | DOT
urxChoice ::= SIG hex4j DOT
urxChoice ::= SIG SIG DOT

VUM4J ~ vum4j
vum4j ~ siv4j+

# === Hoon 4k library ===

SYM4K ~ sym4k
CEN_SYM4K ~ cen4h sym4k
sym4k ~ low4i sym4kRest
hig4k ~ [A-Z]

sym4kRest ~ # empty
sym4kRest ~ sym4kRestChars
sym4kRestChars ~ sym4kRestChar+
sym4kRestChar ~ low4i | nud4i | hep4h

VEN4K ~ ven4k
ven4k ~ carCdr
ven4k ~ carCdrPairs
ven4k ~ carCdrPairs carCdr
carCdrPairs ~ carCdrPair+
carCdrPair ~ [-+][<>]
carCdr ~ [-+]

qut4k ::= (- SOQ -) <singleQuoteCord> (- SOQ -)
<singleQuoteCord> ::= qut4k_Piece* separator=>gon4k proper=>1
qut4k_Piece ::= qit4k+
qit4k ::= <SINGLE_QUOTED_CHARS>
qit4k ::= <SINGLE_QUOTED_BAS>
qit4k ::= <SINGLE_QUOTED_SOQ>
qit4k ::= <SINGLE_QUOTED_HEX_CHAR>

<SINGLE_QUOTED_CHARS> ~ unescapedSingleQuoteChar+
# All the printable (non-control) characters except
# bas (x5c) and soq (x27)
unescapedSingleQuoteChar ~ [\x20-\x26\x28-\x5b\x5d-\x7e\x80-\xff]
<SINGLE_QUOTED_BAS> ~ bas4h bas4h
<SINGLE_QUOTED_SOQ> ~ bas4h soq4h
<SINGLE_QUOTED_HEX_CHAR> ~ bas4h mes4k

# <TRIPLE_QUOTE_START> triggers an event -- the quoted
# string is actually supplies as <TRIPLE_QUOTE_STRING>.
qut4k ::= <TRIPLE_QUOTE_START>
qut4k ::= <TRIPLE_QUOTE_STRING>
:lexeme ~ <TRIPLE_QUOTE_START> event=>tripleQuote pause=>before
<TRIPLE_QUOTE_START> ~ ['] ['] [']
<TRIPLE_QUOTE_STRING> ~ unicorn # implemented with a combinator

dem4k ::= DIT4K_SEQ+ separator=>gon4k proper=>1

DIT4K_SEQ ~ dit4kSeq
dit4kSeq ~ dit4k+
dit4k ~ [0-9]

# MES4K ~ mes4k
mes4k ~ hit4k hit4k

# HIT4K ~ hit4k
hit4k ~ dit4k
hit4k ~ [a-fA-F]

gon4k ~ bas4h gay4i fas4h

# === Hoon 4l library ===

crub4l ::= date
crub4l ::= timePeriod
crub4l ::= fed4j
crub4l ::= DOT urs4j
crub4l ::= SIG urx4j
crub4l ::= HEP urx4j

date ::= date_part1
date ::= date_part1 DOT DOT date_part2
date ::= date_part1 DOT DOT date_part2 DOT DOT date_part3
date_part1 ::= DIM4J optHep DOT MOT4J DOT DIP4J
optHep ::= # empty
optHep ::= HEP
date_part2 ::= dum4j DOT dum4j DOT dum4j
date_part3 ::= QIX4J_SEQ

timePeriod ::= timePeriodKernel timePeriodFraction
timePeriod ::= timePeriodKernel
timePeriodKernel ::= timePeriodByUnit+ separator=>DOT proper=>1
timePeriodByUnit ::= timePeriodDays
timePeriodByUnit ::= timePeriodHours
timePeriodByUnit ::= timePeriodMinutes
timePeriodByUnit ::= timePeriodSeconds
timePeriodDays ::= LAPSE_DAYS
LAPSE_DAYS ~ 'd' dim4j
timePeriodHours ::= LAPSE_HOURS
LAPSE_HOURS ~ 'h' dim4j
timePeriodMinutes ::= LAPSE_MINUTES
LAPSE_MINUTES ~ 'm' dim4j
timePeriodSeconds ::= LAPSE_SECONDS
LAPSE_SECONDS ~ 's' dim4j
timePeriodFraction ::= (- DOT DOT -) QIX4J_SEQ

# nuck(4l) is the coin parser
nuck4l ::= SYM4K

# tash(4l) is the signed dime parser
nuck4l ::= tash4l
tash4l ::= HEP bisk4l
tash4l ::= HEP HEP bisk4l

# perd(4l) parses dimes or tuples without their standard prefixes
nuck4l ::= DOT4H perd4l

# Can be either '$~' or '%~'
# -- both seem to have the same semantics
nuck4l ::= moldNullSig
moldNullSig ::= SIG

# perd(4l) parses sig-prefixed coins after the sig prefix
nuck4l ::= SIG twid4l

# TODO: Finish perd4l
perd4l ::= zust4l

# TODO: royl(4l) NYI
royl4l ::= UNICORN

zust4l ::= bip4j
zust4l ::= lip4j
zust4l ::= royl4l
zust4l ::= ASCII_y
zust4l ::= ASCII_n
ASCII_y ~ 'y'
ASCII_n ~ 'n'

twid4l ::= ASCII_0 VUM4J
twid4l ::= crub4l
ASCII_0 ~ '0'

nuck4l ::= bisk4l
# bisk(4l) parses unsigned dimes of any base
bisk4l ::= NUMBER

#     :~  :-  ['a' 'z']  (cook |=(a/@ta [%$ %tas a]) sym)
#         :-  ['0' '9']  (stag %$ bisk)
#         :-  '-'        (stag %$ tash)
#         :-  '.'        ;~(pfix dot perd)
#         :-  '~'        ;~(pfix sig ;~(pose twid (easy [%$ %n 0])))

# === Hoon 5d library ===

# 5d library: bonk

bonk5d ::= CEN4H SYM4K COL4H SYM4K DOT4H DOT4H dem4k
bonk5d ::= CEN4H SYM4K COL4H SYM4K DOT4H dem4k
bonk5d ::= CEN4H SYM4K DOT4H dem4k
bonk5d ::= CEN4H SYM4K

# 5d library: bont

bont5d ::= CEN4H SYM4K (- DOT GAP -) tall5d
bont5d ::= wideBont5d
wideBont5d ::= CEN4H SYM4K (- DOT -) wide5d
wideBont5d ::= CEN4H SYM4K (- DOT ACE -) wide5d

# 5d library: bony

# one or more equal signs
bony5d ::= TIS+

# 5d library: bonz

bonz5d ::= (- TIS TIS GAP -) optBonzElements (- GAP TIS TIS -)
bonz5d ::= wideBonz5d
wideBonz5d ::= SIG
wideBonz5d ::= (- PEL -) optWideBonzElements (- PER -)
optBonzElements ::= bonzElement* separator=>GAP proper=>1
bonzElement ::= CEN SYM4K (- GAP -) tall5d
optWideBonzElements ::= wideBonzElement* separator=>ACE proper=>1
wideBonzElement ::= CEN SYM4K (- ACE -) wide5d

till5d ::= norm5dMold rank=>20
till5d ::= wyde5d rank=>10
wyde5d ::= wideNorm5dMold rank=>20
wyde5d ::= scad5d
till5dSeq ::= till5d+ separator=>GAP proper=>1
wyde5dSeq ::= wyde5d+ separator=>ACE proper=>1

# 5d library: boog
# Always tall

# TODO: Needs elaboration from hoon.hoon
# TODO: Need to add apse:docs
# TODO: What is the meaning of these various types of battery element?
boog5d ::= LuslusCell
boog5d ::= LushepCell
boog5d ::= LustisCell
LuslusCell ::= (- LUS LUS GAP -) BUC (- GAP -) tall5d
LuslusCell ::= (- LUS LUS GAP -) SYM4K (- GAP -) tall5d
LushepCell ::= (- LUS HEP GAP -) SYM4K (- GAP -) tall5d
LushepCell ::= (- LUS HEP GAP -) BUC (- GAP -) tall5d
LustisCell ::= (- LUS TIS GAP -) SYM4K (- GAP -) till5d

# 5d library: gash

gash5d ::= limp5d* separator=>FAS proper=>1
limp5d ::= (- optFasSeq -) gasp5d
optFasSeq ::= # empty
optFasSeq ::= FAS_SEQ
FAS_SEQ ~ fas4h+
gasp5d ::= tisSeq
tisSeq ~ tis4h+
optTisSeq ::= # empty
optTisSeq ::= TIS_SEQ
TIS_SEQ ~ tis4h+

# 5d library: gasp

gasp5d ::= (- optTisSeq -) hasp5d (- optTisSeq -)

# 5d library: hasp

hasp5d ::= (- SEL -) wide5d (- SER -)
hasp5d ::= (- PEL -) wide5dSeq (- PER -)
hasp5d ::= BUC4H
hasp5d ::= qut4k
hasp5d ::= nuck4l

# 5d library: lute

lute5d ::= (- SEL GAP -) tall5dSeq (- GAP SER -)

# 5d library: long

wideLong5d ::= scat5d rank=>80
wideLong5d ::= infixTis rank=>60
wideLong5d ::= infixCol rank=>50
wideLong5d ::= infixKet rank=>40
wideLong5d ::= infixFas rank=>30
wideLong5d ::= circumScatParen rank=>20

toga ::= rope5d
toga ::= togaSeq
togaSeq ::= (- SEL -) togaElements (- SER -)
togaElements ::= togaElement+ separator=>ACE proper=>1
togaElement ::= toga
togaElement ::= SIG

infixTis ::= toga (- TIS -) wide5d
infixCol ::= scat5d (- COL -) wide5d
infixKet ::= scat5d (- KET -) wide5d
infixFas ::= toga (- FAS -) wide5d
circumScatParen ::= scat5d (- PEL -) lobo5d (- PER -)

lobo5d ::= wide5dJogs
wide5dJogs ::= wide5dJog+ separator=>wide5dJoggingSeparator proper=>1
wide5dJog ::= rope5d (- ACE -) wide5d
wide5dJoggingSeparator ::= COM ACE

# 5d library: mota

# Lexemes cannot be empty so empty
# aura name must be special cased.
mota5d ::= # empty
mota5d ::= AURA_NAME
AURA_NAME ~ optLow4kSeq optHig4kSeq
optLow4kSeq ~ low4i*
optHig4kSeq ~ hig4k*

# 5d library: norm

# Mold runes

# ['_' (rune cab %bccb expa)]
# ++  expa  |.(loaf)                                  ::  one hoon
norm5dMold ::= tallBuccabMold
wideNorm5dMold ::= wideBuccabMold
tallBuccabMold ::= (- BUC CAB GAP -) tall5d
wideBuccabMold ::= (- BUC CAB PEL -) wide5d (- PER -)

# ['%' (rune cen %bccn exqs)]
# ++  exqs  |.((butt hunk))                           ::  closed gapped roots
norm5dMold ::= tallBuccenMold
wideNorm5dMold ::= wideBuccenMold
tallBuccenMold ::= (- BUC CEN GAP -) till5dSeq (- GAP TIS TIS -)
wideBuccenMold ::= (- BUC CEN PEL -) wyde5dSeq (- PER -)

# [':' (rune col %bccl exqs)]
# ++  exqs  |.((butt hunk))                           ::  closed gapped roots
# Running syntax
norm5dMold ::= tallBuccolMold
wideNorm5dMold ::= wideBuccolMold
tallBuccolMold ::= (- BUC COL GAP -) till5dSeq (- GAP TIS TIS -)
wideBuccolMold ::= (- BUC COL PEL -) wyde5dSeq (- PER -)

# ['-' (rune hep %bchp exqb)]
# ++  exqb  |.(;~(gunk loan loan))                    ::  two roots
norm5dMold ::= tallBuchepMold
wideNorm5dMold ::= wideBuchepMold
tallBuchepMold ::= (- BUC HEP GAP -) till5d (- GAP -) till5d
wideBuchepMold ::= (- BUC HEP PEL -) wyde5d (- ACE -) wyde5d (- PER -)

# ['^' (rune ket %bckt exqb)]
# ++  exqb  |.(;~(gunk loan loan))                    ::  two roots
norm5dMold ::= tallBucketMold
wideNorm5dMold ::= wideBucketMold
tallBucketMold ::= (- BUC KET GAP -) till5d (- GAP -) till5d
wideBucketMold ::= (- BUC KET PEL -) wyde5d (- ACE -) wyde5d (- PER -)

# ['@' (rune pat %bcpt exqb)]
# ++  exqb  |.(;~(gunk loan loan))                    ::  two roots
norm5dMold ::= tallBucpatMold
wideNorm5dMold ::= wideBucpatMold
tallBucpatMold ::= (- BUC PAT GAP -) till5d (- GAP -) till5d
wideBucpatMold ::= (- BUC PAT PEL -) wyde5d (- ACE -) wyde5d (- PER -)

# [';' (rune sem %bcsm expa)]
# ++  expa  |.(loaf)                                  ::  one hoon
norm5dMold ::= tallBucsemMold
wideNorm5dMold ::= wideBucsemMold
tallBucsemMold ::= (- BUC SEM GAP -) tall5d
wideBucsemMold ::= (- BUC SEM PEL -) wide5d (- PER -)

# ['=' (rune tis %bcts exqg)]
# ++  exqg  |.(;~(gunk sym loan))                     ::  term and root
norm5dMold ::= tallBuctisMold
wideNorm5dMold ::= wideBuctisMold
tallBuctisMold ::= (- BUC TIS GAP -) SYM4K (- GAP -) till5d
wideBuctisMold ::= (- BUC TIS PEL -) SYM4K (- ACE -) wyde5d (- PER -)

# ['?' (rune wut %bcwt exqs)]
# ++  exqs  |.((butt hunk))                           ::  closed gapped roots
norm5dMold ::= tallBucwutMold
wideNorm5dMold ::= wideBucwutMold
tallBucwutMold ::= (- BUC WUT GAP -) till5dSeq (- GAP TIS TIS -)
wideBucwutMold ::= (- BUC WUT PEL -) wyde5dSeq (- PER -)

# [':' (rune col %cnhp exqz)]
#    ++  exqz  |.(;~(gunk loaf (butt hunk)))             ::  hoon, n roots
norm5dMold ::= tallCencolMold
wideNorm5dMold ::= wideCencolMold
tallCencolMold ::= (- CEN COL GAP -) tall5d (- GAP -) till5dSeq (- GAP TIS TIS -)
wideCencolMold ::= (- CEN COL PEL -) wide5d (- ACE -) wyde5dSeq (- PER -)

# ['-' (rune hep %cnhp exqk)]
#    ++  exqk  |.(;~(gunk loaf ;~(plug loan (easy ~))))  ::  hoon with one root
norm5dMold ::= tallCenhepMold
wideNorm5dMold ::= wideCenhepMold
tallCenhepMold ::= (- CEN HEP GAP -) tall5d (- GAP -) till5d
wideCenhepMold ::= (- CEN HEP PEL -) wide5d (- ACE -) wyde5d (- PER -)

# :~  ['^' (rune ket %cnkt exqy)]
#    ++  exqy  |.(;~(gunk loaf loan loan loan))          ::  hoon, three roots
norm5dMold ::= tallCenketMold
wideNorm5dMold ::= wideCenketMold
tallCenketMold ::= (- CEN KET GAP -) tall5d (- GAP -) till5d (- GAP -) till5d (- GAP -) till5d
wideCenketMold ::= (- CEN KET PEL -) wide5d (- ACE -) wyde5d (- ACE -) wyde5d
  (- ACE -) wyde5d (- PER -)

# ['+' (rune lus %cnls exqx)]
#   ++  exqx  |.(;~(gunk loaf loan loan))               ::  hoon, two roots
norm5dMold ::= tallCenlusMold
wideNorm5dMold ::= wideCenlusMold
tallCenlusMold ::= (- CEN LUS GAP -) tall5d (- GAP -) till5d (- GAP -) till5d
wideCenlusMold ::= (- CEN LUS PEL -) wide5d (- ACE -) wyde5d (- ACE -) wyde5d (- PER -)

# 5d library: norm

# Hoon runes

# ['_' (runo cab %brcb [~ ~] exqr)]
# ++  exqr  |.(;~(gunk loan ;~(plug wasp wisp)))      ::  root/aliases?/tail
# wisp must be tall, therefore wasp and BARCAB must be tall
norm5d ::= tallBarcab
tallBarcab ::= (- BAR CAB GAP -) till5d (- GAP -) wasp5d wisp5d

# ['%' (runo cen %brcn [~ ~] expe)]
# ++  expe  |.(wisp)                                  ::  core tail
norm5d ::= tallBarcen
tallBarcen ::= (- BAR CEN GAP -) wisp5d

# [':' (runo col %brcl [~ ~] expb)]
# ++  expb  |.(;~(gunk loaf loaf))                    ::  two hoons
# FIXED: barcol tall5d tall5d

# ['.' (runo dot %brdt [~ ~] expa)]
# ++  expa  |.(loaf)                                  ::  one hoon
# FIXED: bardot tall5d

# ['-' (runo hep %brhp [~ ~] expa)]
# ++  expa  |.(loaf)                                  ::  one hoon
# FIXED: barhep tall5d

# ['^' (runo ket %brkt [~ ~] expx)]
# ++  expx  |.  ;~  gunk  loaf [...] wisp ::  hoon and core tail
norm5d ::= tallBarket
tallBarket ::= (- BAR KET GAP -) tall5d (- GAP -) wisp5d

# ['~' (runo sig %brsg [~ ~] exqc)]
#  ++  exqc  |.(;~(gunk loan loaf))                    ::  root then hoon
# FIXED: barsig till5d tall5d

# ['*' (runo tar %brtr [~ ~] exqc)]
#  ++  exqc  |.(;~(gunk loan loaf))                    ::  root then hoon
# FIXED: bartar till5d tall5d

# ['=' (runo tis %brts [~ ~] exqc)]
# ++  exqc  |.(;~(gunk loan loaf))                    ::  root then hoon
# FIXED: bartis till5d tall5d

# ['?' (runo wut %brwt [~ ~] expa)]
# ++  expa  |.(loaf)                                  ::  one hoon
# FIXED: barwut tall5d

# ['_' (rune cab %bccb expa)]
# ++  expa  |.(loaf)                                  ::  one hoon
# FIXED: buccab tall5d

# [':' (rune col %bccl exqs)]
# ++  exqs  |.((butt hunk))                           ::  closed gapped roots
norm5d ::= tallBuccol
tallBuccol ::= (- BUC COL GAP -) till5dSeq (- GAP TIS TIS -)
wideNorm5d ::= wideBuccol
wideBuccol ::= (- BUC COL PEL -) wyde5dSeq (- PER -)

# ['%' (rune cen %bccn exqs)]
# ++  exqs  |.((butt hunk))                           ::  closed gapped roots
# Running syntax
norm5d ::= tallBuccen
tallBuccen ::= (- BUC CEN GAP -) till5dSeq (- GAP TIS TIS -)
wideNorm5d ::= wideBuccen
wideBuccen ::= (- BUC CEN PEL -) wyde5dSeq (- PER -)

# ['-' (rune hep %bchp exqb)]
# ++  exqb  |.(;~(gunk loan loan))                    ::  two roots
# NOT FIXED: buchep till5d till5d
# No multi-character lexemes, to allow unary $-(...)
norm5d ::= tallBuchep
wideNorm5d ::= wideBuchep
tallBuchep ::= (- BUC HEP GAP -) till5d (- GAP -) till5d
wideBuchep ::= (- BUC HEP PEL -) till5d (- ACE -) till5d (- PER -)

# ['^' (rune ket %bckt exqb)]
# ++  exqb  |.(;~(gunk loan loan))                    ::  two roots
# FIXED: bucket till5d till5d

# ['@' (rune pat %bcpt exqb)]
# ++  exqb  |.(;~(gunk loan loan))                    ::  two roots
# FIXED: bucpat till5d till5d

# [';' (rune sem %bcsm exqa)]
# ++  exqa  |.(loan)                                  ::  one hoon
# Typo in hoon.hoon -- actually "loan" is a mold
# FIXED: bucsem till5d

# ['=' (rune tis %bcts exqg)]
# ++  exqg  |.(;~(gunk sym loan))                     ::  term and root
# FIXED: buctis SYM4K till5d

# ['?' (rune wut %bcwt exqs)]
# ++  exqs  |.((butt hunk))                           ::  closed gapped roots
norm5d ::= tallBucwut
tallBucwut ::= (- BUC WUT GAP -) till5dSeq (- GAP TIS TIS -)
wideNorm5d ::= wideBucwut
wideBucwut ::= (- BUC WUT PEL -) wyde5dSeq (- PER -)

# ['_' (rune cab %cncb exph)]
# ++  exph  |.((butt ;~(gunk rope rick)))             ::  wing, [tile hoon]s
norm5d ::= tallCencab
tallCencab ::= (- CEN CAB GAP -) rope5d (- GAP -) rick5d (- GAP TIS TIS -)
wideNorm5d ::= wideCencab
wideCencab ::= (- CEN CAB PEL -) rope5d (- ACE -) wideRick5d (- PAR -)

# ['.' (rune dot %cndt expb)]
# ++  expb  |.(;~(gunk loaf loaf))                    ::  two hoons
# FIXED: cendot tall5d tall5d

# ['-' (rune hep %cnhp expk)]
# ++  expk  |.(;~(gunk loaf ;~(plug loaf (easy ~))))  ::  list of two hoons
# FIXED: cenhep tall5d tall5d

# ['^' (rune ket %cnkt expd)]
# ++  expd  |.(;~(gunk loaf loaf loaf loaf))          ::  four hoons
# FIXED: cenket tall5d tall5d tall5d tall5d

# ['+' (rune lus %cnls expc)]
# ++  expc  |.(;~(gunk loaf loaf loaf))               ::  three hoons
# FIXED: cenlus tall5d tall5d tall5d

# ['~' (rune sig %cnsg expn)]
# ++  expn  |.  ;~  gunk  rope  loaf                  ::  wing, hoon,
# 		;~(plug loaf (easy ~))              ::  list of one hoon
# 	      ==
# FIXED: censig rope5d tall5d tall5d

# ['*' (rune tar %cntr expm)]
#  ++  expm  |.((butt ;~(gunk rope loaf rick)))        ::  several [tile hoon]s
norm5d ::= tallCentar
tallCentar ::= (- CEN TAR GAP -) rope5d (- GAP -) tall5d (- GAP -) rick5d (- GAP TIS TIS -)
wideNorm5d ::= wideCentar
wideCentar ::= (- CEN TAR PEL -) rope5d (- ACE -) wide5d (- ACE -) wideRick5d (- PAR -)

# ['=' (rune tis %cnts exph)]
# ++  exph  |.((butt ;~(gunk rope rick)))             ::  wing, [tile hoon]s
norm5d ::= tallCentis
tallCentis ::= (- CEN TIS GAP -) rope5d (- GAP -) rick5d (- GAP TIS TIS -)
wideNorm5d ::= wideCentis
wideCentis ::= (- CEN TIS PEL -) rope5d (- ACE -) wideRick5d (- PAR -)

# ['_' (rune cab %clcb expb)]
# ++  expb  |.(;~(gunk loaf loaf))                    ::  two hoons
# FIXED: colcab tall5d tall5d

# ['-' (rune hep %clhp expb)]
# ++  expb  |.(;~(gunk loaf loaf))                    ::  two hoons
# FIXED: colhep tall5d tall5d

# ['+' (rune lus %clls expc)]
# ++  expc  |.(;~(gunk loaf loaf loaf))               ::  three hoons
# FIXED: collus tall5d tall5d tall5d

# ['^' (rune ket %clkt expd)]
# ++  expd  |.(;~(gunk loaf loaf loaf loaf))          ::  four hoons
# FIXED: colket tall5d tall5d tall5d tall5d

# ['~' (rune sig %clsg exps)]
#  ++  exps  |.((butt hank))                           ::  closed gapped hoons
norm5d ::= tallColsig
tallColsig ::= (- COL SIG GAP -) tall5dSeq (- GAP TIS TIS -)
wideNorm5d ::= wideColsig
wideColsig ::= (- COL SIG PEL -) wide5dSeq (- PER -)

# ['*' (rune tar %cltr exps)]
#  ++  exps  |.((butt hank))                           ::  closed gapped hoons
norm5d ::= tallColtar
tallColtar ::= (- COL TAR GAP -) tall5dSeq (- GAP TIS TIS -)
wideNorm5d ::= wideColtar
wideColtar ::= (- COL TAR PEL -) wide5dSeq (PER)

# ['^' (rune ket %dtkt exqn)]
# ++  exqn  |.(;~(gunk loan (stag %cltr (butt hank))))::  autoconsed hoons
# I do not understand hoon.hoon comment ("autoconsed hoons"), but
# follow the code
norm5d ::= tallDotket
tallDotket ::= (- DOT KET GAP -) till5d (- GAP -) tall5dSeq (- GAP TIS TIS -)
wideNorm5d ::= wideDotket
wideDotket ::= (- DOT KET PEL -) wyde5d (- ACE -) wide5dSeq (- PER -)

# ['+' (rune lus %dtls expa)]
# :~  ['+' (rune lus %dtls expa)]
# ++  expa  |.(loaf)                                  ::  one hoon
# FIXED: dotlus tall5d

# ['*' (rune tar %dttr expb)]
# ++  expb  |.(;~(gunk loaf loaf))                    ::  two hoons
# FIXED: dottar tall5d tall5d

# ['=' (rune tis %dtts expb)]
# ++  expb  |.(;~(gunk loaf loaf))                    ::  two hoons
# FIXED: dottis tall5d tall5d

# ['?' (rune wut %dtwt expa)]
# ++  expa  |.(loaf)                                  ::  one hoon
# FIXED: dotwut tall5d

# ['|' (rune bar %ktbr expa)]
# ++  expa  |.(loaf)                                  ::  one hoon
# FIXED: ketbar tall5d

# ['%' (rune cen %ktcn expa)]
# ++  expa  |.(loaf)                                  ::  one hoon
# FIXED: ketcen tall5d

# ['.' (rune dot %ktdt expb)]
# ++  expb  |.(;~(gunk loaf loaf))                    ::  two hoons
# FIXED: ketdot tall5d tall5d

# ['-' (rune hep %kthp exqc)]
# ++  exqc  |.(;~(gunk loan loaf))                    ::  root then hoon
# FIXED: kethep till5d tall5d

# ['+' (rune lus %ktls expb)]
# ++  expb  |.(;~(gunk loaf loaf))                    ::  two hoons
# FIXED: ketlus tall5d tall5d

# ['&' (rune pam %ktpm expa)]
# ++  expa  |.(loaf)                                  ::  one hoon
# FIXED: ketpam tall5d

# ['~' (rune sig %ktsg expa)]
# ++  expa  |.(loaf)                                  ::  one hoon
# FIXED: ketsig tall5d

# ['=' (rune tis %ktts expg)]
# ++  expg  |.(;~(gunk sym loaf))                     ::  term and hoon
# FIXED: kettis SYM4K tall5d

# ['?' (rune wut %ktwt expa)]
# ++  expa  |.(loaf)                                  ::  one hoon
# FIXED: ketwut tall5d

# [':' (rune col %smcl expi)]
# ++  expi  |.((butt ;~(gunk loaf hank)))             ::  one or more hoons
norm5d ::= tallSemcol
tallSemcol ::= (- SEM COL GAP -) tall5d (- GAP -) tall5dSeq (- GAP TIS TIS -)
wideNorm5d ::= wideSemcol
wideSemcol ::= (- SEM COL PEL -) wide5d (- ACE -) wide5dSeq (- PER -)

# ['/' (rune fas %smfs expa)]
# ++  expa  |.(loaf)                                  ::  one hoon
# FIXED: semfas tall5d

# [';' (rune sem %smsm expb)]
# ++  expb  |.(;~(gunk loaf loaf))                    ::  two hoons
# FIXED: semsem tall5d tall5d

# ['~' (rune sig %smsg expi)]
# ++  expi  |.((butt ;~(gunk loaf hank)))             ::  one or more hoons
norm5d ::= tallSemsig
tallSemsig ::= (- SEM SIG GAP -) tall5d (- GAP -) tall5dSeq (- GAP TIS TIS -)
wideNorm5d ::= wideSemsig
wideSemsig ::= (- SEM SIG PEL -) wide5d (- ACE -) wide5dSeq (- PER -)

# ['|' (rune bar %sgbr expb)]
# FIXED: sigbar tall5d tall5d

# ['$' (rune buc %sgbc expf)]
# ++  expf  |.(;~(gunk ;~(pfix cen sym) loaf))        ::  %term and hoon
# FIXED: sigbuc CEN_SYM4K tall5d

# ['_' (rune cab %sgcb expb)]
# ++  expb  |.(;~(gunk loaf loaf))                    ::  two hoons
# FIXED: sigcab tall5d tall5d

# ['%' (rune cen %sgcn hind)]
# ++  hind  |.(;~(gunk bonk loaf bonz loaf))          ::  jet hoon "bon"s hoon
# FIXED: sigcen bonk5d tall5d bonz5d tall5d

# ['/' (rune fas %sgfs hine)]
# ++  hine  |.(;~(gunk bonk loaf))                    ::  jet-hint and hoon
# FIXED: sigfas bonk5d tall5d

# ['<' (rune gal %sggl hinb)]
#  ++  hinb  |.(;~(gunk bont loaf))                    ::  hint and hoon
# FIXED: siggal bont5d tall5d

# ['>' (rune gar %sggr hinb)]
#  ++  hinb  |.(;~(gunk bont loaf))                    ::  hint and hoon
# FIXED: siggar bont5d tall5d

# ['+' (rune lus %sgls hinc)]
# ++  hinc  |.                                        ::  optional =en, hoon
#           ;~(pose ;~(gunk bony loaf) (stag ~ loaf)) ::
norm5d ::= tallSiglus
tallSiglus ::= (- SIG LUS GAP -) bony5d (- GAP -) tall5d
tallSiglus ::= (- SIG LUS GAP -) tall5d
wideNorm5d ::= wideSiglus
wideSiglus ::= (- SIG LUS PEL -) bony5d (- ACE -) wide5d (- PER -)
wideSiglus ::= (- SIG LUS PEL -) wide5d (- PER -)

# ['&' (rune pam %sgpm hinf)]
# ++  hinf  |.                                        ::  0-3 >s, two hoons
#  ;~  pose
#    ;~(gunk (cook lent (stun [1 3] gar)) loaf loaf)
#    (stag 0 ;~(gunk loaf loaf))
#  ==
norm5d ::= tallSigpam
tallSigpam ::= (- SIG PAM GAP -) oneToThreeGars (- GAP -) tall5d (- GAP -) tall5d
tallSigpam ::= (- SIG PAM GAP -) tall5d (- GAP -) tall5d
wideNorm5d ::= wideSigpam
wideSigpam ::= (- SIG PAM PEL -) oneToThreeGars (- ACE -) wide5d (- ACE -) wide5d (- PER -)
wideSigpam ::= (- SIG PAM PEL -) wide5d (- ACE -) wide5d (- PER -)
oneToThreeGars ::= GAR | GAR GAR | GAR GAR GAR

# ['=' (rune tis %sgts expb)]
# ++  expb  |.(;~(gunk loaf loaf))                    ::  two hoons
# FIXED: sigtis tall5d tall5d

# ['?' (rune wut %sgwt hing)]
# ++  hing  |.                                        ::  0-3 >s, three hoons
#  ;~  pose
#    ;~(gunk (cook lent (stun [1 3] gar)) loaf loaf loaf)
#    (stag 0 ;~(gunk loaf loaf loaf))
#  ==
norm5d ::= tallSigwut
tallSigwut ::= (- SIG WUT GAP -) oneToThreeGars (- GAP -) tall5d (- GAP -) tall5d (- GAP -) tall5d
tallSigwut ::= (- SIG WUT GAP -) tall5d (- GAP -) tall5d (- GAP -) tall5d
wideNorm5d ::= wideSigwut
wideSigwut ::= (- SIG WUT PEL -) oneToThreeGars (- ACE -) wide5d (- ACE -) wide5d (- ACE -) wide5d (- PER -)
wideSigwut ::= (- SIG WUT PEL -) wide5d (- ACE -) wide5d (- ACE -) wide5d (- PER -)

# ['!' (rune zap %sgzp expb)]
# ++  expb  |.(;~(gunk loaf loaf))                    ::  two hoons
# FIXED: sigzap tall5d tall5d

# ['|' (rune bar %tsbr exqc)]
# ++  exqc  |.(;~(gunk loan loaf))                    ::  root then hoon
# FIXED: tisbar till5d tall5d

# [':' (rune col %tscl expp)]
# ++  expp  |.(;~(gunk (butt rick) loaf))             ::  [wing hoon]s, hoon
norm5d ::= tallTiscol
tallTiscol ::= (- TIS COL GAP -) rick5d (- GAP TIS TIS GAP -) tall5d
wideNorm5d ::= wideTiscol
wideTiscol ::= (- TIS COL PEL -) wideRick5d (- ACE -) wide5d (- PAR -)

# [',' (rune com %tscm expb)]
# ++  expb  |.(;~(gunk loaf loaf))                    ::  two hoons
# FIXED: tiscom tall5d tall5d

# ['.' (rune dot %tsdt expq)]
# ++  expq  |.(;~(gunk rope loaf loaf))               ::  wing and two hoons
# FIXED: tisdot rope5d tall5d tall5d

# ['-' (rune hep %tshp expb)]
# ++  expb  |.(;~(gunk loaf loaf))                    ::  two hoons
# FIXED: tishep tall5d tall5d

# ['/' (rune fas %tsfs expo)]
# ++  expo  |.(;~(gunk wise loaf loaf))               ::  =;
# FIXED: tisfas wise5d tall5d tall5d

# ['<' (rune gal %tsgl expb)]
# ++  expb  |.(;~(gunk loaf loaf))                    ::  two hoons
# FIXED: tisgal tall5d tall5d

# ['>' (rune gar %tsgr expb)]
# ++  expb  |.(;~(gunk loaf loaf))                    ::  two hoons
# FIXED: tisgar tall5d tall5d

# ['^' (rune ket %tskt expt)]
#     ++  expt  |.(;~(gunk wise rope loaf loaf))          ::  =^
# FIXED: tisket wise5d rope5d tall5d tall5d

# ['+' (rune lus %tsls expb)]
# ++  expb  |.(;~(gunk loaf loaf))                    ::  two hoons
# FIXED: tislus tall5d tall5d

# [';' (rune sem %tssm expo)]
# ++  expo  |.(;~(gunk wise loaf loaf))               ::  =;
# FIXED: tissem wise5d tall5d tall5d

# ['~' (rune sig %tssg expi)]
# ++  expi  |.((butt ;~(gunk loaf hank)))             ::  one or more hoons
norm5d ::= tallTissig
tallTissig ::= (- TIS SIG GAP -) tall5d (- GAP -) tall5dSeq (- GAP TIS TIS -)
wideNorm5d ::= wideTissig
wideTissig ::= (- TIS SIG PEL -) wide5d (- ACE -) wide5dSeq (- PER -)

# ['*' (rune tar %tstr expl)]
# ++  expl  |.(;~(gunk (stag ~ sym) loaf loaf))       ::  term, two hoons
# FIXED: tistar SYM4K tall5d tall5d

# ['?' (rune wut %tswt expw)]
#     ++  expw  |.(;~(gunk rope loaf loaf loaf))          ::  wing and three hoons
# FIXED: tiswut rope5d tall5d tall5d tall5d

# ['|' (rune bar %wtbr exps)]
#  ++  exps  |.((butt hank))                           ::  closed gapped hoons
norm5d ::= tallWutbar
tallWutbar ::= (- WUT BAR GAP -) tall5dSeq (- GAP TIS TIS -)
wideNorm5d ::= wideWutbar
wideWutbar ::= (- WUT BAR PEL -) wide5dSeq (- PER -)

# [':' (rune col %wtcl expc)]
# ++  expc  |.(;~(gunk loaf loaf loaf))               ::  three hoons
# FIXED: wutcol tall5d tall5d tall5d

# ['.' (rune dot %wtdt expc)]
# ++  expc  |.(;~(gunk loaf loaf loaf))               ::  three hoons
# FIXED: wutdot tall5d tall5d tall5d

# ['<' (rune gal %wtgl expb)]
# ++  expb  |.(;~(gunk loaf loaf))                    ::  two hoons
# FIXED: wutgal tall5d tall5d

# ['>' (rune gar %wtgr expb)]
# ++  expb  |.(;~(gunk loaf loaf))                    ::  two hoons
# FIXED: wutgar tall5d tall5d

# ['-' ;~(pfix hep (toad tkhp))]
# ++  tkhp  |.  %+  cook  |=  {a/tiki b/(list (pair root hoon))}
#			(~(wthp ah a) b)
#	      (butt ;~(gunk teak ruck))
norm5d ::= tallWuthep
tallWuthep ::= (- WUT HEP GAP -) teak5d (- GAP -) ruck5d (- GAP TIS TIS -)
wideNorm5d ::= wideWuthep
wideWuthep ::= (- WUT HEP PEL -) teak5d (- ACE -) wideRuck5d (- PER -)

# ['^' ;~(pfix ket (toad tkkt))]
# ++  tkkt  |.  %+  cook  |=  {a/tiki b/hoon c/hoon}
#			(~(wtkt ah a) b c)
#	      ;~(gunk teak loaf loaf)
# FIXED: wutket teak5d tall5d tall5d

# ['+' ;~(pfix lus (toad tkls))]
# ++  tkls  |.  %+  cook  |=  {a/tiki b/hoon c/(list (pair root hoon))}
# 			(~(wtls ah a) b c)
#	      (butt ;~(gunk teak loaf ruck))
norm5d ::= tallWutlus
tallWutlus ::= (- WUT LUS GAP -) teak5d (- GAP -) tall5d (- GAP -) ruck5d (- GAP TIS TIS -)
wideNorm5d ::= wideWutlus
wideWutlus ::= (- WUT LUS PEL -) teak5d (- ACE -) tall5d (- ACE -) wideRuck5d (- PAR -)

# ['&' (rune pam %wtpm exps)]
#  ++  exps  |.((butt hank))                           ::  closed gapped hoons
norm5d ::= tallWutpam
tallWutpam ::= (- WUT PAM GAP -) tall5dSeq (- GAP TIS TIS -)
wideNorm5d ::= wideWutpam
wideWutpam ::= (- WUT PAM PEL -) wide5dSeq (- PER -)

# ['@' ;~(pfix pat (toad tkpt))]
# ++  tkpt  |.  %+  cook  |=  {a/tiki b/hoon c/hoon}
#			(~(wtpt ah a) b c)
#	      ;~(gunk teak loaf loaf)
# FIXED: wutpat teak5d tall5d tall5d

# ['~' ;~(pfix sig (toad tksg))]
# ++  tksg  |.  %+  cook  |=  {a/tiki b/hoon c/hoon}
# 			  (~(wtsg ah a) b c)
# 		;~(gunk teak loaf loaf)
# FIXED: wutsig teak5d tall5d tall5d

# ['=' ;~(pfix tis (toad tkts))]
#    ++  tkts  |.  %+  cook  |=  {a/root b/tiki}
#                            (~(wtts ah b) a)
#                  ;~(gunk loan teak)
# FIXED: wuttis till5d teak5d

# ['!' (rune zap %wtzp expa)]
# ++  expa  |.(loaf)                                  ::  one hoon
# FIXED: wutzap tall5d

# [':' ;~(pfix col (toad expz))]
#    ++  expz  |.(loaf(bug &))                           ::  hoon with tracing
# FIXED: zapcol tall5d

# ['.' ;~(pfix dot (toad |.(loaf(bug |))))]
# FIXED: zapdot tall5d

# [',' (rune com %zpcm expb)]
# ++  expb  |.(;~(gunk loaf loaf))                    ::  two hoons
# FIXED: zapcom tall5d tall5d

# ['>' (rune gar %zpgr expa)]
# ++  expa  |.(loaf)                                  ::  one hoon
# FIXED: zapgar tall5d

# [';' (rune sem %zpsm expb)]
# ++  expb  |.(;~(gunk loaf loaf))                    ::  two hoons
# FIXED zapsem tall5d tall5d

# ['=' (rune tis %zpts expa)]
# ++  expa  |.(loaf)                                  ::  one hoon
# NOT FIXED: zaptis tall5d
# Write this out to allow for parsing binary !=(a b), which is different
norm5d ::= tallZaptis
wideNorm5d ::= wideZaptis
tallZaptis ::= (- ZAP TIS GAP -) tall5d
wideZaptis ::= (- ZAP TIS PEL -) wide5d (- PER -)

# ['?' (rune wut %zpwt hinh)]
# ++  hinh  |.                                        ::  1/2 numbers, hoon
#         ;~  gunk
#           ;~  pose
#             dem
#             (ifix [sel ser] ;~(plug dem ;~(pfix ace dem)))
#           ==
#           loaf
#         ==
norm5d ::= tallZapwut
wideNorm5d ::= wideZapwut
tallZapwut ::= (- ZAPWUTGAP -) dem4k (- GAP -) tall5d
tallZapwut ::= (- ZAPWUTGAP SEL -) dem4k (- ACE -) dem4k (- SER GAP -) tall5d
wideZapwut ::= (- ZAPWUTPEL -) dem4k (- ACE -) wide5d
wideZapwut ::= (- ZAPWUTPEL SEL -) dem4k (- ACE -) dem4k (- SER ACE -) wide5d


# Multi-character lexemes to allow zapwut rune to take
# priority over irregular unary zap, especially
# "!?", which is unary zap followed by wut
ZAPWUTGAP ~ zap4h wut4h gap4k
ZAPWUTPEL ~ zap4h wut4h gap4k

# zapzap (= crash) is implemented in scat5d

# 5d library: poor

poor5d ::= gash5d
poor5d ::= gash5d CEN4H porc5d

# 5d library: porc

porc5d ::= optCen4hSeq FAS gash5d
optCen4hSeq ::= # empty
optCen4hSeq ::= CEN4H_SEQ
CEN4H_SEQ ~ cen4h+

# 5d library: rood
# rood is the path parser

rood5d ::= FAS poor5d

# 5d library: rope

# the wing type is parsed by the rope(5d)
rope5d ::= limb+ separator=>DOT proper=>1
limb ::= COM
limb ::= optKets BUC
limb ::= optKets SYM4K
optKets ::= KET*
limb ::= BAR4H DIM4J
limb ::= LUS DIM4J
limb ::= PAM4H DIM4J
limb ::= VEN4K
limb ::= DOT

# 5d library: rick

rick5d ::= rick5dJog+ separator=>GAP proper=>1
rick5dJog ::= rope5d (- GAP -) tall5d

wideRick5d ::= wideRick5dJog+ separator=>commaAce proper=>1
wideRick5dJog ::= rope5d (- ACE -) wide5d

# 5d library: ruck

ruck5d ::= ruck5dJog+ separator=>GAP proper=>1
ruck5dJog ::= till5d (- GAP -) tall5d

wideRuck5d ::= wideRuck5dJog+ separator=>commaAce proper=>1
wideRuck5dJog ::= till5d (- ACE -) wide5d
commaAce ::= COM ACE

# 5d library: rump

rump5d ::= rope5d
rump5d ::= rope5d wede5d

# 5d library: rupl
# rupl(5d) seems to implement the hoon '[...]', ~[...], and [...]~
# syntaxes.

rupl5d ::= circumBracket
rupl5d ::= sigCircumBracket
rupl5d ::= circumBracketSig
rupl5d ::= sigCircumBracketSig

# Initial ACE of tall form is intended -- it
# distinguishes this from lute(5d)
circumBracket ::= (- SEL ACE -) tall5dSeq (- GAP SER -)
circumBracket ::= (- SEL -) wide5dSeq (- SER -)
sigCircumBracket ::= (- SIG SEL ACE -) tall5dSeq (- GAP SER -)
sigCircumBracket ::= (- SIG SEL -) wide5dSeq (- SER -)
circumBracketSig ::= (- SEL ACE -) tall5dSeq (- GAP SER SIG -)
circumBracketSig ::= (- SEL -) wide5dSeq (- SER SIG -)
sigCircumBracketSig ::= (- SIG SEL ACE -) tall5dSeq (- GAP SER SIG -)
sigCircumBracketSig ::= (- SIG SEL -) wide5dSeq (- SER SIG -)

# 5d library: sail

sailApex5d ::= (- SEM -) tallTopSail
wideSailApex5d ::= (- SEM -) wideTopSail

tallTopSail ::= ACES optWideQuoteInnards rank=>100
tallTopSail ::= scriptOrStyle scriptStyleTail rank=>80
tallTopSail ::= tallElem rank=>70
tallTopSail ::= wideQuote rank=>60
tallTopSail ::= (- TIS -) tallTailOfTop rank=>50
tallTopSail ::= (- GAR GAP -) CRAM rank=>40
tallTopSail ::= tunaMode (- GAP -) tall5d rank=>30
# TODO: can tallTopSail (= tall-top ) also be empty?

event '^CRAM' = predicted CRAM
CRAM ~ unicorn # supplied by a combinator

wideTopSail ::= wideQuote rank=>20
wideTopSail ::= wideParenElems rank=>10
wideTopSail ::= tagHead wideTail rank=>0

tallElem ::= tagHead optTallAttrs tallTailOfElem

tagHead ::= aMane optTagHeadInitial optTagHeadKernel optTagHeadFinal optWideAttrs
optTagHeadInitial ::= # empty
optTagHeadInitial ::= tagHeadInitial
tagHeadInitial ::= # empty
tagHeadInitial ::= HAX SYM4K
optTagHeadKernel ::= # empty
optTagHeadKernel ::= tagHeadKernel
tagHeadKernel ::= tagHeadKernelElements
tagHeadKernelElements ::= tagHeadKernelElement+
tagHeadKernelElement ::= DOT SYM4K
optTagHeadFinal ::= # empty
optTagHeadFinal ::= tagHeadFinal
tagHeadFinal ::= FAS soil5d
tagHeadFinal ::= PAT soil5d

optTallAttrs ::= # empty
optTallAttrs ::= tallAttributes
tallAttributes ::= tallAttribute+
tallAttribute ::= (- GAP TIS -) aMane (- GAP -) hopefullyQuote

tallTailCommon ::= # empty
tallTailCommon ::= SEM
tallTailCommon ::= COL wrappedElems
tallTailCommon ::= COL ACE optWideQuoteInnards

tallTailOfTop ::= tallTailCommon
tallTailOfTop ::= tallKidsOfTop (- GAP TIS TIS -)

tallTailOfElem ::= tallTailCommon
tallTailOfElem ::= tallKidsOfElem (- GAP TIS TIS -)

# hoon.hoon seems to allow "cram" items anywhere "tall-kids"
# occurs -- not just after SEMTIS (;=).  And it defines them
# as kids, so multiple "cram" items may occur after a SEMTIS.
# This would be hard to implement here, and I wonder if it does
# not cause problems in hoon.hoon.
#
# This implements what (I think) was the intent: "cram" items
# only after SEMTIS or SEMGAR (;>), and only one -- not a
# sequence of them.  This does pass the test.

# <tallKid> includes its preceding gap -kids to allow lookahead
# to differentiate among the <tallKid> choices.
#
# <GAP_SEM>, if a semi-colon is the next non-whitespace character,
# will beat <GAP> in LATM.
#
tallKidsOfTop  ::= (- GAP_SEM -) tallTopKidSeq rank=>20
tallKidsOfTop  ::= (- GAP -) CRAM rank=>0
tallTopKidSeq  ::= tallTopSail+ separator=>GAP_SEM proper=>1
GAP_SEM ~ gap4k sem4h

tallKidsOfElem ::= tallKidOfElem+
tallKidOfElem  ::= (- GAP_SEM -) tallTopSail

wideTail ::= # empty
wideTail ::= SEM
wideTail ::= COL wrappedElems

# wideParenElems are produced by <wideTopSail>
# wrappedElems ::= wideParenElems
wrappedElems ::= qut4k
wrappedElems ::= wideTopSail

wideParenElems ::= (- PEL -) (- PER -)
wideParenElems ::= (- PEL -) wideInnerTops (- PER -)

wideInnerTops ::= wideInnerTop+ separator=>ACE proper=>1
wideInnerTop  ::= wideTopSail
wideInnerTop  ::= tunaMode wide5d

tunaMode ::= HEP | LUS | TAR | CEN

scriptOrStyle ::= 'script' wideAttrs
scriptOrStyle ::= 'style' wideAttrs

optWideAttrs ::= # empty
optWideAttrs ::= wideAttrs
wideAttrs ::= (- PEL PER -)
wideAttrs ::= (- PEL -) wideAttrBody (- PER -)
wideAttrBody ::= wideAttribute+ separator=>commaAce proper=>1
wideAttribute ::= aMane (- ACE -) hopefullyQuote

aMane ::= SYM4K
aMane ::= SYM4K CAB SYM4K

# TODO: hoon.hoon comment expresses dissatisfaction at
# this solution
hopefullyQuote ::= wide5d

scriptStyleTail ::= (- GAP -) scriptStyleTailElements (- GAP TIS TIS -)
scriptStyleTailElements ::= scriptStyleTailElement+ separator=>GAP proper=>1
scriptStyleTailElement ::= (- SEM -) ACE PRN4I_SEQ
scriptStyleTailElement ::= (- SEM -)

wideQuote ::= (- DOQ -) optWideQuoteInnards (- DOQ -)
# TODO: Triple double quote form of wide-quote NYI

optWideQuoteInnards ::=
optWideQuoteInnards ::= optWideQuoteEmbedFreeStretch
optWideQuoteInnards ::= wideQuoteEmbedTerminatedStretches optWideQuoteEmbedFreeStretch
optWideQuoteEmbedFreeStretch ::=
optWideQuoteEmbedFreeStretch ::= wideQuoteEmbedFreeStretch
wideQuoteEmbedFreeStretch ::= wideQuoteEmbedFreeElement+
wideQuoteEmbedFreeElement ::= <ESCAPED_WIDE_INNARD_CHAR>
wideQuoteEmbedFreeElement ::= <NORMAL_WIDE_INNARD_CHARS>

<ESCAPED_WIDE_INNARD_CHAR> ~
  bas4h hep4h | bas4h lus4h | bas4h tar4h | bas4h cen4h |
  bas4h sem4h | bas4h kel4h |
  bas4h bas4h | bas4h doq4h | bas4h bix4j

# All the printable (non-control) characters except
# doq (x22), sem (x3b), bas (x5c) and kel (x7b)
# For efficiency we want to slurp in as many "normal"
# characters at once as we can.
<NORMAL_WIDE_INNARD_CHARS> ~ unescapedWideInnardsChar+
unescapedWideInnardsChar ~ [\x20-\x21\x23-\x3a\x3c-\x5b\x5d-\x7a\x7c-\x7e\x80-\xff]

wideQuoteEmbedTerminatedStretches ::= wideQuoteEmbedTerminatedStretch+
wideQuoteEmbedTerminatedStretch ::= optWideQuoteEmbedFreeStretch (- SEM -) wideBracketedElem rank=>30
wideQuoteEmbedTerminatedStretch ::= optWideQuoteEmbedFreeStretch tunaMode sump5d rank=>20
wideQuoteEmbedTerminatedStretch ::= optWideQuoteEmbedFreeStretch sump5d rank=>10

wideBracketedElem ::= (- KEL -) tagHead wideElems (- KER -)

wideElems ::=
wideElems ::= <sailWideElements>
<sailWideElements> ::= <sailWideElement>+
<sailWideElement> ::= (- ACE -) wideInnerTop

# 5d library: scad

# scad(5d) implements the irregular mold syntaxes

# Cases given in hoon.hoon order.  Unfortunately
# not the same as the order in scat(5d).

# '_'
# Same as scat(5d)
scad5d ::= moldPrefixCab
moldPrefixCab ::= (- CAB -) wide5d

# ','
# Differs from scat(5d)
scad5d ::= moldPrefixCom
moldPrefixCom ::= (- COM -) wide5d

# '$'
# Differs from scat(5d)
scad5d ::= moldBucbuc
moldBucbuc ::= (- BUC BUC -)

scad5d ::= moldBucpam
moldBucpam ::= (- BUC PAM -)

scad5d ::= moldBucbar
moldBucbar ::= (- BUC BAR -)

scad5d ::= moldBucSingleString
moldBucSingleString ::= (- BUC -) qut4k

scad5d ::= moldBucNuck4l
moldBucNuck4l ::= (- BUC -) nuck4l

scad5d ::= rump5d

# '%'
# Differs from scat(5d)
scad5d ::= moldCenbuc
moldCenbuc ::= CEN BUC

scad5d ::= moldCenpam
moldCenpam ::= CEN PAM

scad5d ::= moldCenbar
moldCenbar ::= CEN BAR

scad5d ::= moldCenSingleString
moldCenSingleString ::= (- CEN -) qut4k

scad5d ::= moldCenNuck4l
moldCenNuck4l ::= CEN nuck4l

# '('
# Differs from scat(5d)
scad5d ::= moldCircumParen
moldCircumParen ::= (- PEL -) wide5d (- ACE -) wyde5dSeq (- PER -)
moldCircumParen ::= (- PEL -) wide5d (- PER -)

# '{'
# Same as scat(5d)
scad5d ::= moldCircumBrace
moldCircumBrace ::= (- KEL -) wyde5dSeq (- KER -)

# '['
# Differs from scat(5d)
scad5d ::= moldCircumBracket
moldCircumBracket ::= (- SEL -) wyde5dSeq (- SER -)

# '*'
# Subset of scat(5d)
scad5d ::= moldTar
moldTar ::= TAR

# '@'
# Same as scat(5d)
scad5d ::= moldAura
moldAura ::= PAT mota5d

# '?'
# Same as scat(5d)
scad5d ::= moldPrefixWut
moldPrefixWut ::= (- WUT PEL -) wyde5dSeq (- PER -)

scad5d ::= moldWut
moldWut ::= WUT

# '~'
# Differs from scat(5d)
scad5d ::= moldSig
moldSig ::= SIG

# '^'
# Differs from scat(5d)
scad5d ::= moldKet
moldKet ::= KET

# <moldInfixCol> can start with either KET (^) or lowercase char
# This is scab(5d)
scad5d ::= moldInfixCol
moldInfixCol ::= rope5d (- COL -) moldInfixCol2
moldInfixCol2 ::= rope5d+ separator=>COL proper=>1

# '='
# Differs from scat(5d)
scad5d ::= moldPrefixTis
moldPrefixTis ::= (- TIS -) wyde5d (- PER -) action=>MarpaX::Hoonlint::YAHC::deprecated

# ['a' 'z']
# Differs from scat(5d)
# for scab(5d), see the KET subcase
scad5d ::= moldInfixFas rank=>1
scad5d ::= moldInfixTis rank=>1
moldInfixFas ::= SYM4K FAS wyde5d
moldInfixTis ::= SYM4K TIS wyde5d

# End of scad(5d)

# 5d library: scat
# scat(5d) implements the irregular hoon syntaxes

# For convenience in referring back
# to hoon.hoon, I use scat(5d)'s order, as is.
# Unfortunately this is not in the same
# order as in scad.

# ','
# Differs from scad(5)
# For rope(5d), see subcase ['a' 'z'] and rump(5d)
wideBuccol ::= (- COM SEL -) wyde5dSeq (- SER -)

# '!'
# Not in scad(5)
scat5d ::= prefixZap
prefixZap ::= (- ZAP -) wide5d
scat5d ::= wideZapzap
wideZapzap ~ zap4h zap4h

# '_'
# Same as scad(5)
scat5d ::= prefixCab
prefixCab ::= (- CAB -) wide5d

# '$'
# For rump, see subcase ['a' 'z']
# Differs from scad(5)
scat5d ::= bucBuc
scat5d ::= bucPam
scat5d ::= bucBar
scat5d ::= dollarTerm
bucBuc ::= BUC4H BUC4H
bucPam ::= BUC4H PAM4H
bucBar ::= BUC4H BAR4H
dollarTerm ::= BUC4H qut4k
dollarTerm ::= BUC4H nuck4l

# '%'
# Differs from scad(5)
scat5d ::= cenPath
scat5d ::= cenBuc
scat5d ::= cenPam
scat5d ::= cenBar
scat5d ::= cenTerm
scat5d ::= cenDirectories
cenPath ::= CEN4H porc5d
cenBuc ::= CEN4H BUC4H
cenPam ::= CEN4H PAM4H
cenBar ::= CEN4H BAR4H
cenTerm ::= CEN4H qut4k
cenTerm ::= CEN4H nuck4l
cenDirectories ::= CEN4H+

# '&'
# Not in scad(5)
# For rope(5d), see subcase ['a' 'z'] and rump(5d)
scat5d ::= prefixPam
scat5d ::= pamPlusPrefix
scat5d ::= soloPam
prefixPam ::= (- PAM4H PEL -) wide5dSeq (- PER -)
pamPlusPrefix ::= (- PAM4H -) wede5d
soloPam ::= PAM4H

# '\''
# Not in scad(5)
scat5d ::= qut4k

# '('
# Differs from scad(5)
# See https://raw.githubusercontent.com/urbit/old-urbit.org/master/doc/hoon/lan/irregular.markdown
# and cenhep in https://urbit.org/docs/hoon/irregular/
scat5d ::= circumParen1
scat5d ::= circumParen2
circumParen1 ::= (- PEL -) wide5d (- PER -)
circumParen2 ::= (- PEL -) wide5d (- ACE -) wide5dSeq (- PER -)

# '{'
# Same as scad(5)
scat5d ::= circumBraces
circumBraces ::= (- KEL -) wyde5dSeq (- KER -)

# '*'
# Superset of scad(5)
scat5d ::= prefixTar
scat5d ::= soloTar
prefixTar ::= TAR wyde5d
soloTar ::= TAR

# '@'
# Same as scad(5)
scat5d ::= aura
aura ::= PAT mota5d

# '+'
# Not in scad(5)
# For rope(5d) see ['a' 'z'] subcase and rump(5d)
scat5d ::= wideDotlus
scat5d ::= lusSoilSeq
wideDotlus ::= (- LUS PEL -) wide5d (- PER -)
lusSoilSeq ::= lusSolSeqItem+ separator=>DOG4I proper=>1
lusSolSeqItem ::= LUS soil5d

# '-'
# For rope(5d) see ['a' 'z'] subcase and rump(5d)
# Not in scad(5)
scat5d ::= tash4l
scat5d ::= hepSoilSeq
hepSoilSeq ::= hepSolSeqItem+ separator=>DOG4I proper=>1
hepSolSeqItem ::= HEP soil5d

# '.'
# For rope(5d) see ['a' 'z'] subcase and rump(5d)
# Not in scad(5)
scat5d ::= DOT perd4l

# ['0' '9']
# Not in scad(5)
# This subcase handles infix expressions
# starting with a digit.
scat5d ::= bisk4l
scat5d ::= bisk4l wede5d

# ':'
# Not in scad(5)
scat5d ::= circumColParen
scat5d ::= prefixColFas
circumColParen ::= (- COL PEL -) wide5dSeq (- PER -)
prefixColFas ::= (- COL FAS -) wide5d

# '='
# Differs from scad(5)
tallDottis ::= (- TIS GAP -) tall5d
scat5d ::= irrDottis
irrDottis ::= (- TIS PEL -) wide5d (- ACE -) wide5d (- PER -)
irrDottis ::= (- TIS PEL -) wide5d (- PER -)

# '?'
# Same as scad(5)
scat5d ::= circumWutParen
scat5d ::= soloWut
circumWutParen ::= (- WUT PEL -) wyde5dSeq (- PER -)
soloWut ::= WUT

# '['
# Differs from scad(5)
scat5d ::= rupl5d

# '^'
# Differs from scad(5)
# For rope(5d) see ['a' 'z'] subcase and rump(5d)
scat5d ::= soloKet
soloKet ::= KET

# '`'
# Not in scad(5)
scat5d ::= prefixTecChoices
prefixTecChoices ::= prefixTecAura rank=>5
prefixTecChoices ::= prefixTecTar rank=>4
prefixTecChoices ::= prefixTecMold rank=>3
prefixTecChoices ::= prefixTecHoon rank=>2
prefixTecChoices ::= prefixSoloTec rank=>1
prefixTecAura ::= (- TEC PAT -) mota5d (- TEC -) wide5d
prefixTecTar ::= (- TEC TAR TEC -) wide5d
prefixTecMold ::= (- TEC -) wyde5d (- TEC -) wide5d
prefixTecHoon ::= (- TEC LUS -) wide5d (- TEC -) wide5d
prefixSoloTec ::= (- TEC -) wide5d

# '"'
# Not in scad(5)
scat5d ::= infixDot
infixDot ::= soil5d+ separator=>DOG4I proper=>1

# ['a' 'z']
# Differs from scad(5)
scat5d ::= rump5d

# '|'
# Not in scad(5)
# For rope(5d) see ['a' 'z'] subcase and rump(5d)
scat5d ::= prefixBar rank=>1
scat5d ::= circumBarParen rank=>1
scat5d ::= soloBar
prefixBar ::= (- BAR4H -) wede5d
circumBarParen ::= (- BAR4H PEL -) wide5dSeq (- PER -)
soloBar ::= BAR4H

# '~'
# Differs from scad(5)
# See also rupl(5d) in the '[' subcase
scat5d ::= circumSigParen
scat5d ::= (- SIG -) twid4l
scat5d ::= (- SIG -) wede5d
scat5d ::= soloSig
circumSigParen ::= (- SIG PEL -) rope5d (- ACE -) wide5d (- ACE -) wide5dSeq (- PER -)
soloSig ::= SIG

# This seems to be redundant with rupl(5d)
# scat5d ::= circumSigBracket
# circumSigBracket ::= (- SIG SEL -) wide5dSeq (- SER -)

# '/'
# Not in scad(5)
scat5d ::= rood5d

# '<'
# Not in scad(5)
scat5d ::= circumGalgar
circumGalgar ::= (- GAL -) wide5dSeq (- GAR -)

# '>'
# Not in scad(5)
scat5d ::= circumGargal
circumGargal ::= (- GAR -) wide5dSeq (- GAL -)

# 5d library: soil

soil5d ::= doubleQuoteString
doubleQuoteString ::= (- DOQ -) <doubleQuoteCord> (- DOQ -)
<doubleQuoteCord> ::= <doubleQuoteElement>*
<doubleQuoteElement> ::= <UNESCAPED_DOUBLE_QUOTE_CHARS>
<doubleQuoteElement> ::= <ESCAPED_DOUBLE_QUOTE_CHAR>
<doubleQuoteElement> ::= sump5d

# All the printable (non-control) characters except
# bas (x5c) kel (x7b) and doq (x22)
<UNESCAPED_DOUBLE_QUOTE_CHARS> ~ unescapedDoubleQuoteChar+
unescapedDoubleQuoteChar ~ [\x20-\x21\x23-\x5b\x5d-\x7a\x7c-\x7e\x80-\xff]
<ESCAPED_DOUBLE_QUOTE_CHAR> ~ bas4h bas4h | bas4h doq4h | bas4h kel4h | bas4h bix4j

soil5d ::= <TRIPLE_DOUBLE_QUOTE_STRING>
soil5d ::= TRIPLE_DOUBLE_START
:lexeme ~ TRIPLE_DOUBLE_START event=>tripleDoubleQuote pause=>before
TRIPLE_DOUBLE_START ~ doq4h doq4h doq4h nl
<TRIPLE_DOUBLE_QUOTE_STRING> ~ unicorn

sump5d ::= KEL wide5dSeq KER

# 5d library: teak

# teak is
#
# 1) a mold, if possible, hoon otherwise,
#
# 2) an assignment to <SYM4K>, which is again, of a mold,
# if possible, of a hoon otherwise

teak5d ::= teakChoice
teakChoice ::= (- KET TIS GAP -) SYM4K (- GAP -) rope5d rank=>2
teakChoice ::= (- KET TIS GAP -) SYM4K (- GAP -) tall5d rank=>1
teakChoice ::= tall5d rank=>1
teakChoice ::= wideTeak5d rank=>0
wideTeak5d ::= wideTeakChoice
wideTeakChoice ::= SYM4K (- TIS -) rope5d rank=>2
wideTeakChoice ::= rope5d rank=>2
wideTeakChoice ::= SYM4K (- TIS -) wide5d rank=>1
wideTeakChoice ::= wide5d rank=>1

# 5d library: wasp
# Always occurs with wisp(5d), which must be tall,
# so wisp is always tall

wasp5d ::= # empty
wasp5d ::= (- LUS TAR GAP -) waspElements (- GAP -)
waspElements ::= waspElement+ separator=>GAP proper=>1
waspElement  ::= SYM4K (- GAP -) tall5d

# 5d library: wede

wede5d ::= (- FAS -) wide5d
wede5d ::= (- LUS -) wide5d

# 5d library: wise

wise5d ::= SYM4K
wise5d ::= (- TIS -) wyde5d
wise5d ::= SYM4K (- TIS -) wyde5d
wise5d ::= SYM4K (- FAS -) wyde5d

# 5d library: wisp

wisp5d ::= (- HEP HEP -)
wisp5d ::= whap5d GAP (- HEP HEP -)

# 5d library: whap
# Always tall

whap5d ::= boog5d+ separator=>GAP proper=>1

# End of 5d library

# === HOON FILE ===
:start ::= fordFile

# A hack to allow inaccessible symbols
fordFile ::= UNICORN inaccessible_ok

fordFile ::=
  (- optGay4i -)
  optFordFaswut
  optFordFashep
  optFordFaslus
  optHornSeq
  fordHoopSeq
  (- optGay4i -)

optGay4i ::= # empty
optGay4i ::= GAY4I

optHornSeq ::= # empty
optHornSeq ::= hornSeq
hornSeq ::= horn+ separator=>GAP proper=>1
wideHornSeq ::= wideHorn+ separator=>ACE proper=>1

fordHoopSeq ::= fordHoop+ separator=>GAP proper=>1

fordHoop ::= FAS FAS GAP fordHave rank=>60
fordHoop ::= hornRune rank=>40
fordHoop ::= tall5d rank=>0

fordHave ::= FAS fordHath
fordHath ::= poor5d

fordHive ::= (- FAS -) gash5d
fordHive ::= (- FAS -) gash5d CEN porc5d

# === WHITESPACE ===

optClassicWhitespace ::= # empty
optClassicWhitespace ::= classicWhitespace
classicWhitespace ::= GAP
classicWhitespace ::= ACE

optHorizontalWhitespace ~ horizontalWhitespaceElement*
horizontalWhitespaceElements ~ horizontalWhitespaceElement+
horizontalWhitespaceElement ~ ace

GAP ~ gap4k

gap4k ~ ace horizontalWhitespaceElements # a "wide" gap
gap4k ~ tallGapPrefix optGapLines optHorizontalWhitespace
# The prefix must contain an <NL> to ensure that this *is* a tall gap
tallGapPrefix ~ optHorizontalWhitespace nl
tallGapPrefix ~ optHorizontalWhitespace comment
optGapLines ~ gapLine*
gapLine ~ optHorizontalWhitespace comment
gapLine ~ optHorizontalWhitespace nl

ACES ~ ace+
ACE ~ ace
ace ~ ' '
comment ~ '::' optNonNLs nl

# TODO: Is this treatment of documentation runes OK?
# Documentation decorations treated as comments
comment ~ ':>' optNonNLs nl
comment ~ ':<' optNonNLs nl
comment ~ '+|' optNonNLs nl

inaccessible_ok ::= NL
NL ~ nl
nl ~ [\n]
optNonNLs ~ nonNL*
nonNL ~ [^\n]

wsChars ~ wsChar*
wsChar ~ [ \n]

# @ub   unsigned binary          0b10          (2)
NUMBER ~ binaryNumber
# syn match       hoonNumber        "0b[01]\{1,4\}\%(\.\_s*[01]\{4\}\)*"
binaryNumber ~ '0b' binaryPrefix binaryGroups
binaryPrefix ~ binaryDigit
binaryPrefix ~ binaryDigit binaryDigit
binaryPrefix ~ binaryDigit binaryDigit binaryDigit
binaryPrefix ~ binaryDigit binaryDigit binaryDigit binaryDigit
binaryDigit ~ [01]
binaryGroups ~ binaryGroup*
binaryGroup ~ [.] wsChars binaryDigit binaryDigit binaryDigit binaryDigit

# @uc   bitcoin address          0c1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa
# @ud   unsigned decimal         42            (42)
#                                1.420         (1420)
NUMBER ~ decimalNumber
# syn match       hoonNumber        "\d\{1,3\}\%(\.\_s\?\d\{3\}\)*"
decimalNumber ~ decimalPrefix decimalGroups
decimalPrefix ~ decimalDigit
decimalPrefix ~ decimalDigit decimalDigit
decimalPrefix ~ decimalDigit decimalDigit decimalDigit
decimalDigit ~ [0-9]
decimalGroups ~ decimalGroup*
decimalGroup ~ [.] wsChars decimalDigit decimalDigit decimalDigit

# @uv   unsigned base32          0v3ic5h.6urr6
NUMBER ~ vNumber
# syn match       hoonNumber        "0v[0-9a-v]\{1,5\}\%(\.\_s*[0-9a-v]\{5\}\)*"
vNumber ~ '0v' vNumPrefix vNumGroups
vNumPrefix ~ vNumDigit
vNumPrefix ~ vNumDigit vNumDigit
vNumPrefix ~ vNumDigit vNumDigit vNumDigit
vNumPrefix ~ vNumDigit vNumDigit vNumDigit vNumDigit
vNumPrefix ~ vNumDigit vNumDigit vNumDigit vNumDigit vNumDigit
vNumDigit ~ [0-9a-v]
vNumGroups ~ vNumGroup*
vNumGroup ~ [.] wsChars vNumDigit vNumDigit vNumDigit vNumDigit vNumDigit

# @uw   unsigned base64          0wsC5.yrSZC
NUMBER ~ wNumber
# syn match       hoonNumber        "0w[-~0-9a-zA-Z]\{1,5\}\%(\.\_s*[-~0-9a-zA-Z]\{5\}\)*"
wNumber ~ '0w' wNumPrefix wNumGroups
wNumPrefix ~ wNumDigit
wNumPrefix ~ wNumDigit wNumDigit
wNumPrefix ~ wNumDigit wNumDigit wNumDigit
wNumPrefix ~ wNumDigit wNumDigit wNumDigit wNumDigit
wNumPrefix ~ wNumDigit wNumDigit wNumDigit wNumDigit wNumDigit
wNumDigit ~ [-~0-9a-zA-Z]
wNumGroups ~ wNumGroup*
wNumGroup ~ [.] wsChars wNumDigit wNumDigit wNumDigit wNumDigit wNumDigit

# @ux   unsigned hexadecimal     0xcafe.babe
NUMBER ~ hexNumber
# syn match       hoonNumber        "0x\x\{1,4\}\%(\.\_s*\x\{4\}\)*"
hexNumber ~ '0x' hexPrefix hexGroups
hexPrefix ~ hexDigit
hexPrefix ~ hexDigit hexDigit
hexPrefix ~ hexDigit hexDigit hexDigit
hexPrefix ~ hexDigit hexDigit hexDigit hexDigit
hexDigit ~ [0-9a-fA-F]
hexGroups ~ hexGroup*
hexGroup ~ [.] wsChars hexDigit hexDigit hexDigit hexDigit

# === CELLS BY TYPE ==

tall5dSeq ::= tall5d+ separator=>GAP proper=>1
tall5d ::= norm5d rank=>30
tall5d ::= sailApex5d rank=>25
tall5d ::= wideNorm5d rank=>20
tall5d ::= wideLong5d rank=>18
tall5d ::= wideSailApex5d rank=>15
tall5d ::= lute5d rank=>10

# TODO: Precedence needs to be tested

wide5d ::= wide5dChoices
wide5dChoices ::= wideNorm5d rank=>10
wide5dChoices ::= wideLong5d rank=>8
wide5dChoices ::= wideSailApex5d

wide5dSeq ::= wide5d+ separator=>ACE proper=>1

# === FORD RUNES ===

horn ::= hornRune
wideHorn ::= wideHornRune

hornRune ::= wideHornRune

hornRune ::= fordFasbar
fordFasbar ::= (- FAS BAR GAP -) hornSeq (- GAP TIS TIS -)
wideHornRune ::= wideFordFasbar
wideFordFasbar ::= (- FAS BAR PEL -) wideHornSeq (- PER -)

hornRune ::= fordFasbuc
fordFasbuc ::= (- FAS BUC GAP -) tall5d
wideHornRune ::= wideFordFasbuc
wideFordFasbuc ::= (- FAS BUC SEL -) wide5dSeq (- SER -)

hornRune ::= fordFascab
fordFascab ::= (- FAS CAB GAP -) horn
wideHornRune ::= wideFordFascab
wideFordFascab ::= (- FAS CAB -) horn

hornRune ::= fordFascen
fordFascen ::= (- FAS CEN GAP -) horn
wideHornRune ::= wideFordFascen
wideFordFascen ::= (- FAS CEN -) horn

hornRune ::= fordFascol
fordFascol ::= (- FAS COL GAP -) fordHive (- GAP -) horn
wideHornRune ::= wideFordFascol
wideFordFascol ::= (- FAS COL -) fordHive (- COL -) horn

hornRune ::= fordFascom
fordFascom ::= (- FAS COM GAP -) fordFascomBody (- GAP TIS TIS -)
fordFascomBody ::= # empty
fordFascomBody ::= fordFascomElements
fordFascomElements ::= fordFascomElement+ separator=>GAP proper=>1
fordFascomElement ::= (- FAS -) fordHith (- GAP -) horn

hornRune ::= fordFasdot
fordFasdot ::= (- FAS DOT GAP -) optHornSeq (- GAP TIS TIS -)

hornRune ::= fordFashax
fordFashax ::= (- FAS HAX GAP -) horn
wideHornRune ::= wideFordFashax
wideFordFashax ::= (- FAS HAX -) horn

optFordFashep ::= # empty
optFordFashep ::= (- FAS HEP GAP -) fordHoofSeq (- GAP -)

hornRune ::= fordFasket
fordFasket ::= (- FAS KET GAP -) tall5d (- GAP -) horn
wideHornRune ::= wideFordFasket
wideFordFasket ::= (- FAS KET -) wide5d (- KET -) horn

optFordFaslus ::= # empty
optFordFaslus ::= (- FAS LUS GAP -) fordHoofSeq (- GAP -)

hornRune ::= fordFaspam
fordFaspam ::= (- FAS PAM GAP -) SYM4K (- GAP -) horn
wideHornRune ::= wideFordFaspam
wideFordFaspam ::= (- FAS PAM -) faspamSyms horn
faspamSyms ::= faspamSym+
faspamSym ::= SYM4K PAM

hornRune ::= fordFassem
fordFassem ::= (- FAS SEM GAP -) tall5d (- GAP -) horn
wideHornRune ::= wideFordFassem
wideFordFassem ::= (- FAS SEM -) wide5d (- SEM -) horn

hornRune ::= fordFassig
fordFassig ::= (- FAS SIG GAP -) tall5d
wideHornRune ::= wideFordFassig
wideFordFassig ::= (- FAS SIG SEL -) wide5dSeq (- SER -)

hornRune ::= fordFastis
fordFastis ::= (- FASTISGAP -) SYM4K (- GAP -) horn
wideHornRune ::= wideFordFastis
wideFordFastis ::= (- FAS TIS -) SYM4K '=' wideHorn
# Long lexeme to allow ford rune to take priority
# over /= path
FASTISGAP ~ fas4h tis4h gap4k

optFordFaswut ::= # empty
optFordFaswut ::= fordFaswut
fordFaswut ::= (- FAS WUT GAP -) DIT4K_SEQ (- GAP -)

wideHornRune ::= wideFaszap
wideFaszap ::= (- FAS ZAP -) SYM4K (- FAS -)

commaWS ::= COM
commaWS ::= COM optClassicWhitespace

fordHith ::= optFordHithElements
optFordHithElements ::= hasp5d* separator=>FAS proper=>1

fordHoofSeq ::= fordHoof+ separator=>commaWS proper=>1
fordHoof ::= TAR fordHoot
fordHoof ::= fordHoot

fordHoot ::= SYM4K
fordHoot ::= SYM4K (- FAS -) fordHoodCase (- FAS -) fordHoodShip

fordHoodCase ::= nuck4l

fordHoodShip ::= SIG fed4j

wideHornRune ::= wideCircumFas
wideCircumFas ::= (- FAS -) SYM4K (- FAS  -)

