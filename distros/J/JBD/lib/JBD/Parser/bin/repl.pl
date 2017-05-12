
# Lexer / Parser REPL.
# Allows quick exploration of parsers on input texts.
# @author Joel Dalley
# @version 2014/Mar/09

use JBD::Parser::DSL;

my @hist;
my @stack;

my @symbols = qw(Signed Unsigned Num Int Float Word Space Op);
print "LOAD Lexer Symbols: @symbols\n";

my $lextypes; set_lextypes(shift);
my $parser;   set_parser(shift);

sub set_lextypes {
    my $in = shift;
    defined $in or return;
    my $val = eval "[$in]";
    return if $@ || !@$val;
    my $have_all = 1;
    M: for my $m (@$val) {
        next M if grep ref $m eq $_, @symbols;
        $have_all = 0;
        last M;
    }
    $lextypes = $val if !$@ && $have_all;
}

sub set_parser {
    my $in = shift;
    defined $in or return;
    my $ans = eval $in;
    return if $@ || ref $ans ne 'JBD::Parser';
    $parser = $ans;
    print " : > Enter one or more strings to parse.\n",
          " : > Enter 'END' to parse strings.\n";
    push @hist, $in;
}

while (1) {
    if    (!$lextypes) { print " : > Lex for types: \n : > " }
    elsif (!$parser)   { print " : > Enter a parser:\n : > " }
    else               { print " : > "                       }

    chomp(my $in = <STDIN>);
    last if $in =~ /^q(uit)?;$/io;

    if ($in =~ /^END;?$/) {
        print " : >\n";
        while (defined(my $text = shift @stack)) {
            print " : > Parse $text\n";
            my $pst = parser_state tokens $text, $lextypes;
            my $tokens = $parser->($pst);
            print $tokens
                ? join("\n", map(" : > \ttoken[$_]", @$tokens))
                : " : > \tUndefined";
            print "\n : > \n";
        }
        $parser = undef;
    }
    elsif ($in =~ /^h(ist(ory)?)?\s*(\d+)?;?$/) {
        my $hist_in = $3;

        if (!defined $hist_in) {
            for (my $i = 0; $i < @hist; $i++) {
                print " History: > [$i] $hist[$i]\n";
            }
            print " Enter a number: > ";
            chomp($hist_in = <STDIN>);
        }

        if (defined $hist_in && 
            $hist_in eq int($hist_in) &&
            $hist[$hist_in]) {
            my $ans = eval $hist[$hist_in];
            $parser = $ans if !$@;
        }
    }
    elsif (!$lextypes) { set_lextypes($in) }
    elsif (!$parser)   { set_parser($in)   }
    else               { push @stack, $in  }
}
