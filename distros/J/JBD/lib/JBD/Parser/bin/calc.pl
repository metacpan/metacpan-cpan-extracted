
# Test simple calculation parsers.
# @author Joel Dalley
# @version 2014/Mar/14

use JBD::Parser::DSL;
use JBD::Core::List 'pairsof';

sub test($$$)  { _test(@_) }
sub reduce($$) { trans shift, _reduce(shift) }

my $Op    = type Op;
my $add   = pair Op, '+';
my $mult  = pair Op, '*';
my $Num   = type Unsigned | type Signed;
my $match = [Unsigned, Signed, Op];

my $pairs = pairsof [
    '1 + 24.92 + -3 + -.42' 
        => $Num ^ star($add ^ $Num),
    '5 * -9.0 + -3' 
        => $Num ^ star(($add | $mult) ^ $Num),
    ];

while (my $pair = $pairs->()) {
    my ($text, $parser) = @$pair;
    test $text, reduce($parser, $match), $match;
}

print "\n";

###########

sub _test {
    my ($text, $parser, $matchers) = @_;
    my $copy   = "$text";
    my $lexed  = tokens $text, $matchers;
    my $state  = parser_state [@$lexed, token End_of_Input];
    my $tokens = ($parser ^ type End_of_Input)->($state)
                 or die $state->error_string;
    my $ans = shift(@$tokens)->value;
    $ans == eval $copy or die "Unexpected answer `$ans`";
    print "`$copy` --> $ans\n";
}

sub _reduce {
    my $matchers = shift;
    sub {
        my $tokens = shift;
        my $expr = join ' ', grep $_, map $_->value, @$tokens;
        my $val = eval $expr; die $@ if $@;
        tokens $val, $matchers;
    };
}
