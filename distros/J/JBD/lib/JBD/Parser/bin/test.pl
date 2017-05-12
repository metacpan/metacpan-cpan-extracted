
# Test parsing primitives.
# @author Joel Dalley
# @version 2014/Mar/13

use JBD::Parser::DSL;

# Short names for printing.
sub abbreviated($) {
    \join ':', map substr($_->type, 0, 2), @{$_[0]};
}

# Parse statement.
sub statement($$$) {
    my ($text, $types, $tokens) = @_;
    return "text[ $text ] : match{ $types }"
         . " --> ${abbreviated $tokens}\n";
}

# Prints.
sub printer($$$) {
    my ($text, $parser, $matchers) = @_;
    my $types  = join ', ', map ref $_, @$matchers;
    my $lexed  = tokens "$text", $matchers;
    my $state  = parser_state [@$lexed, token End_of_Input];
    my $tokens = ($parser ^ type End_of_Input)->($state)
                 or die $state->error_string;
    print "\t", statement $text, $types, $tokens;
        
}

# Named parsers.
my $Op       = type Op;
my $Num      = type Num;
my $Word     = type Word;
my $Float    = type Float;
my $Signed   = type Signed;
my $Unsigned = type Unsigned;
my $plus     = pair Op, '+';
my $o_paren  = pair Op, '(';
my $c_paren  = pair Op, ')';

STAR: {
    print "\nTest star():\n";

    printer '1 + 2 + -3 + -.42', (
        $Num ^ star($plus ^ $Num)
        ), [Num, Op];

    printer '1 * 1 1 + /', (
        $Num ^ $Op ^ star ($Num | $Op)
        ), [Num, Op];

    printer '0', (star $Num), [Num];
    printer '1', (star $Num), [Num];

    printer '1 2 3 foo bar baz', (
        star $Num ^ star $Word
        ), [Word, Num];

    printer '1 -2 foo 23.1 bar', (
        star($Signed | $Unsigned) ^ star($Word | $Unsigned)
        ), [Signed, Unsigned, Word];
}

CAT: {
    print "\nTest cat():\n";

    printer '1',   $Num,          [Num];
    printer '1 1', ($Num ^ $Num), [Num];

    printer '1 + 1', (
        $Num ^ $plus ^ $Num
        ), [Num, Op];

    printer '(1 + 1)', (
        $o_paren ^ $Num ^ $plus ^ $Num ^ $c_paren
        ), [Num, Op];

    printer 'foo 1 bar', (
        $Word ^ $Num ^ $Word
        ), [Num, Word];
}

ANY: {
    print "\nTest any():\n";
    printer 'foo',     ($Word | $Num), [Num, Word];
    printer '-113.24', ($Word | $Num), [Num, Word];
    printer '+',       ($Num | $plus), [Num, Op];

    printer '1 Word', (
        $Num ^ ($Num | $Word)
        ), [Num, Word];
}

TRANS: {
    print "\nTest trans(Everything -> OK Type):\n";
    
    my $trans = sub {
        [map token('OK', 'value'), @{$_[0]}];
    };

    printer '1', (trans $Num, $trans), [Num];
    printer '1.', (trans $Float, $trans), [Float];
}

print "\n";
