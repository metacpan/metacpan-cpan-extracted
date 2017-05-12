use strict;
use warnings FATAL => 'all';

package MarpaX::Database::Terminfo::String::Grammar::Actions;
use Carp qw/croak/;
use Log::Any qw/$log/;

# ABSTRACT: Terminfo grammar actions

our $VERSION = '0.012'; # VERSION



sub new {
    my $class = shift;
    my $self = {_level => 0};
    bless($self, $class);
    return $self;
}

sub _doPushLevel {
    my ($self) = @_;

    $self->{_level}++;
    return "my \$rc = '';";
}

sub _doEndLevel {
    my ($self) = @_;

    $self->{_level}--;
    return "\$rc;";
}


sub addEscapedCharacterToRc {
    my ($self, $c) = @_;

    if ($log->is_trace) {
        $log->tracef('addEscapedCharacterToRc(c="%s")', $c);
    }

    return "\$rc .= " . $self->_escapedCharacter($c) . "; # $c";
}

sub _escapedCharacter {
    my ($self, $c) = @_;

    if ($log->is_trace) {
        $log->tracef('_escapedCharacter(c="%s")', $c);
    }

    if    ($c eq '\\E' || $c eq '\\e') { return "\"\\e\"";  }
    elsif ($c eq '\\a'               ) { return "\"\\a\"";  }
    elsif ($c eq '\\n'               ) { return "\"\\n\"";  }
    elsif ($c eq '\\l'               ) { return "\"\\n\"";  }
    elsif ($c eq '\\r'               ) { return "\"\\r\"";  }
    elsif ($c eq '\\b'               ) { return "\"\\b\"";  }
    elsif ($c eq '\\f'               ) { return "\"\\f\"";  }
    elsif ($c eq '\\t'               ) { return "\"\\t\"";  }
    elsif ($c eq '\\s'               ) { return "' '";      }
    elsif ($c eq '\\^'               ) { return "'^'";      }
    elsif ($c eq '\\\\'              ) { return "'\\\\'";   }
    elsif ($c eq '\\,'               ) { return "','";      }
    elsif ($c eq '\\:'               ) { return "':'";      }
    # In perl \0 is not the end of a string
    elsif ($c eq '\\0'               ) { return "\"\\0\""; }

    elsif (substr($c, 0, 1) eq '^') {
        #
        # In perl, control-X is \cX, we support the ASCII C0 set + DEL.
        # i.e. the range [@A-Z[\]^_?] (c.f. Marpa grammar).
        # They can ALL be translated litteraly except \c\ that has to be
        # writen as \c\X in perl. Then we remove the last X.
        #
        my $this = $c;
        substr($this, 0, 1, '');
        if ($this eq '\\') {
            return "\"\\c\\X\"; substr(\$rc, -1, 1, '')";
        } else {
            return "\"\\c$this\"";
        }
    }
    elsif (substr($c, 0, 1) eq '\\') {
        #
        # Spec says this must be octal digits
        #
        my $oct = $c;
        substr($oct, 0, 1, '');
        $oct =~ s/^0*//;          # Take care... oct(012) == oct(12) = 10 ...
        # Note: in perl \0 is NOT the end of a string
        return "chr(oct($oct))";
    }
    else {
        croak "Unhandled escape sequence $c\n";
    }
}


sub addCharacterToRc {
    my ($self, $c) = @_;

    if ($log->is_trace) {
        $log->tracef('addCharacterToRc(c="%s")', $c);
    }
    #
    # If we quotemeta, then we have to use double quotes
    #
    return "\$rc .= \"" . quotemeta($c) . "\"; # $c";
}


sub addPercentToRc {
    my ($self, $c) = @_;

    if ($log->is_trace) {
        $log->tracef('addPercentToRc(c="%s")', $c);
    }

    return "\$rc .= '%'; # $c";
}


sub addPrintPopToRc {
    my ($self, $c) = @_;

    if ($log->is_trace) {
        $log->tracef('addPrintPopToRc(c="%s")', $c);
    }

    return "\$rc .= sprintf('%c', pop(\@iparam)); # $c";
}


sub addPrintToRc {
    my ($self, $format) = @_;

    if ($log->is_trace) {
        $log->tracef('addPrintToRc(format="%s")', $format);
    }

    #
    # print has the following format:
    # %[[:]flags][width[.precision]][doxXs]
    # => we remove the eventual ':' after the '%'
    # the rest is totally functional within perl
    #
    $format =~ s/^%:/%/;

    return "\$rc .= sprintf('$format', pop(\@iparam)); # $format";
}


sub addPushToRc {
    my ($self, $push) = @_;
    # %p[1-9]

    if ($log->is_trace) {
        $log->tracef('addpushToRc(push="%s")', $push);
    }

    my $indice = ord(substr($push, -1, 1)) - ord('0') - 1;
    return "push(\@iparam, \$param[$indice]); # $push";
}


sub addDynPop {
    my ($self, $dynpop) = @_;
    # %P[a-z]

    if ($log->is_trace) {
        $log->tracef('addDynPop(dynpop="%s")', $dynpop);
    }

    my $indice = ord(substr($dynpop, -1, 1)) - ord('a');
    return "\$dynamicp->[$indice] = pop(\@iparam); # $dynpop";
}


sub addDynPush {
    my ($self, $dynpush) = @_;
    # %g[a-z]

    if ($log->is_trace) {
        $log->tracef('addDynPush(dynpush="%s")', $dynpush);
    }

    my $indice = ord(substr($dynpush, -1, 1)) - ord('a');
    return "push(\@iparam, \$dynamicp->[$indice]); # $dynpush";
}


sub addStaticPop {
    my ($self, $staticpop) = @_;
    # %P[A-Z]

    if ($log->is_trace) {
        $log->tracef('addStaticPop(staticpop="%s")', $staticpop);
    }

    my $indice = ord(substr($staticpop, -1, 1)) - ord('A');
    return "\$staticp->[$indice] = pop(\@iparam); # $staticpop";
}


sub addStaticPush {
    my ($self, $staticpush) = @_;
    # %g[A-Z]

    if ($log->is_trace) {
        $log->tracef('addStaticPush(staticpush="%s")', $staticpush);
    }

    my $indice = ord(substr($staticpush, -1, 1)) - ord('A');
    return "push(\@iparam, \$staticp->[$indice]); # $staticpush";
}


sub addL {
    my ($self, $l) = @_;
    # %l

    if ($log->is_trace) {
        $log->tracef('addL(l="%s")', $l);
    }

    return "push(\@iparam, strlen(pop(\@iparam)); # $l";
}


sub addPushConst {
    my ($self, $const) = @_;
    # %'c'

    if ($log->is_trace) {
        $log->tracef('addPushConst(const="%s")', $const);
    }

    #
    # Either this is an escaped number \ddd, or anything but a quote
    #
    my $inside = $const;
    substr($inside, 0, 2, '');   # Remove %' at the beginning
    substr($inside, -1, 1, '');  # Remove ' at the end

    if (substr($inside, 0, 1) eq '\\') {
        return "push(\@iparam, " . $self->_escapedCharacter($inside) . "); # $const";
    } else {
        return "push(\@iparam, \"" . quotemeta($inside) . "\"); # $const";
    }
}


sub addPushInt {
    my ($self, $int) = @_;
    # %{nn}

    if ($log->is_trace) {
        $log->tracef('addPushInt(int="%s")', $int);
    }

    my $value = $int;
    substr($value, 0, 2, '');
    substr($value, -1, 1, '');

    return "push(\@iparam, $value); # $int";
}


sub addPlus {
    my ($self, $plus) = @_;
    # %+

    if ($log->is_trace) {
        $log->tracef('addPlus(plus="%s")', $plus);
    }

    return "push(\@iparam, pop(\@iparam) + pop(\@iparam)); # $plus";
}


sub addMinus {
    my ($self, $minus) = @_;
    # %+

    if ($log->is_trace) {
        $log->tracef('addMinus(minus="%s")', $minus);
    }

    return "{ my \$y = pop(\@iparam); my \$x = pop(\@iparam); push(\@iparam, \$x - \$y); } # $minus";
}


sub addStar {
    my ($self, $star) = @_;
    # %+

    if ($log->is_trace) {
        $log->tracef('addStar(star="%s")', $star);
    }

    return "push(\@iparam, pop(\@iparam) * pop(\@iparam)); # $star";
}


sub addDiv {
    my ($self, $div) = @_;
    # %+

    if ($log->is_trace) {
        $log->tracef('addDiv(div="%s")', $div);
    }

    return "{ my \$y = pop(\@iparam); my \$x = pop(\@iparam); push(\@iparam, \$y ? int(\$x / \$y) : 0); } # $div";
}


sub addMod {
    my ($self, $mod) = @_;
    # %+

    if ($log->is_trace) {
        $log->tracef('addMod(mod="%s")', $mod);
    }

    return "{ my \$y = pop(\@iparam); my \$x = pop(\@iparam); push(\@iparam, \$y ? int(\$x % \$y) : 0); } # $mod";
}


sub addBitAnd {
    my ($self, $bitAnd) = @_;
    # %&

    if ($log->is_trace) {
        $log->tracef('addBitAnd(bitAnd="%s")', $bitAnd);
    }

    return "push(\@iparam, pop(\@iparam) & pop(\@iparam)); # $bitAnd";
}


sub addBitOr {
    my ($self, $bitOr) = @_;
    # %|

    if ($log->is_trace) {
        $log->tracef('addBitOr(bitOr="%s")', $bitOr);
    }

    return "push(\@iparam, pop(\@iparam) | pop(\@iparam)); # $bitOr";
}


sub addBitXor {
    my ($self, $bitXor) = @_;
    # %^

    if ($log->is_trace) {
        $log->tracef('addBitXor(bitXor="%s")', $bitXor);
    }

    return "push(\@iparam, pop(\@iparam) ^ pop(\@iparam)); # $bitXor";
}


sub addEqual {
    my ($self, $equal) = @_;
    # %=

    if ($log->is_trace) {
        $log->tracef('addEqual(equal="%s")', $equal);
    }

    return "{ my \$y = pop(\@iparam); my \$x = pop(\@iparam); push(\@iparam, \$x == \$y); } # $equal";
}


sub addGreater {
    my ($self, $greater) = @_;
    # %>

    if ($log->is_trace) {
        $log->tracef('addGreater(greater="%s")', $greater);
    }

    return "{ my \$y = pop(\@iparam); my \$x = pop(\@iparam); push(\@iparam, \$x > \$y); } # $greater";
}


sub addLower {
    my ($self, $lower) = @_;
    # %<

    if ($log->is_trace) {
        $log->tracef('addLower(lower="%s")', $lower);
    }

    return "{ my \$y = pop(\@iparam); my \$x = pop(\@iparam); push(\@iparam, \$x < \$y); } # $lower";
}


sub addLogicalAnd {
    my ($self, $logicalAnd) = @_;
    # %A

    if ($log->is_trace) {
        $log->tracef('addLogicalAnd(logicalAnd="%s")', $logicalAnd);
    }

    return "push(\@iparam, pop(\@iparam) && pop(\@iparam)); # $logicalAnd";
}


sub addLogicalOr {
    my ($self, $logicalOr) = @_;
    # %O

    if ($log->is_trace) {
        $log->tracef('addLogicalOr(logicalOr="%s")', $logicalOr);
    }

    return "push(\@iparam, pop(\@iparam) || pop(\@iparam)); # $logicalOr";
}


sub addNot {
    my ($self, $not) = @_;
    # %!

    if ($log->is_trace) {
        $log->tracef('addNot(not="%s")', $not);
    }

    return "push(\@iparam, ! pop(\@iparam)); # $not";
}


sub addComplement {
    my ($self, $complement) = @_;
    # %!

    if ($log->is_trace) {
        $log->tracef('addComplement(complement="%s")', $complement);
    }

    return "push(\@iparam, ~ pop(\@iparam)); # $complement";
}


sub addOneToParams {
    my ($self, $one) = @_;
    # %i

    if ($log->is_trace) {
        $log->tracef('addOneToParams(one="%s")', $one);
    }

    return "map {\$param[\$_]++} (0..\$#param); # $one";
}


sub addIfThenElse {
    my ($self, $if, $units1p, $then, $units2p, $elsifUnitsp, $else, $units3p, $endif) = @_;

    if ($log->is_trace) {
        $log->tracef('addIfThenElse($if="%s", $units1p="%s", $then="%s", $units2p="%s", $elsifUnitsp="%s", $else="%s", $units3p="%s", $endif="%s")', $if, $units1p, $then, $units2p, $elsifUnitsp, $else, $units3p, $endif);
    }

    my $units1     = join("\n", @{$units1p});
    my $units2     = join("\n", @{$units2p});
    my $elsifUnits = join("\n", @{$elsifUnitsp});
    my $units3     = join("\n", @{$units3p});
    #
    # We increase indentation of units
    #
    $units1     =~ s/^/         /smg;
    $units2     =~ s/^/  /smg;
    $units3     =~ s/^/  /smg;
    #
    # $endif can be the EOF
    #
    $endif ||= 'implicit by eof';

    my $rc = "if (do { # $if
$units1
         pop(\@iparam);
       }) { # $then
$units2
}";
    if ($elsifUnits) {
        $rc .= "\n$elsifUnits";
    }
    $rc .= "
else { # $else
$units3
} # $endif";

    return $rc;
}


sub addIfThen {
    my ($self, $if, $units1p, $then, $units2p, $elsifUnitsp, $endif) = @_;

    if ($log->is_trace) {
        $log->tracef('addIfThen($if="%s", $units1p="%s", $then="%s", $units2p="%s", $elsifUnitsp="%s", $endif="%s")', $if, $units1p, $then, $units2p, $elsifUnitsp, $endif);
    }

    my $units1     = join("\n", @{$units1p});
    my $units2     = join("\n", @{$units2p});
    my $elsifUnits = join("\n", @{$elsifUnitsp});
    #
    # We increase indentation of units
    #
    $units1     =~ s/^/         /smg;
    $units2     =~ s/^/  /smg;
    #
    # $endif can be the EOF
    #
    $endif ||= 'implicit by eof';

    my $rc = "if (do { # $if
$units1
         pop(\@iparam);
       }) { # $then
$units2
} # $endif";
    if ($elsifUnits) {
        $rc .= "\n$elsifUnits";
    }

    return $rc;
}


sub elifUnit {
    my ($self, $else, $units1p, $then, $units2p) = @_;

    if ($log->is_trace) {
        $log->tracef('elifUnit($else="%s", $units1p="%s", $then="%s", $units2p="%s")', $else, $units1p, $then, $units2p);
    }
    my $units1     = join("\n", @{$units1p});
    my $units2     = join("\n", @{$units2p});
    #
    # We increase indentation of units
    #
    $units1     =~ s/^/            /smg;
    $units2     =~ s/^/  /smg;

    my $rc = "elsif (do { # $else
$units1
            pop(\@iparam);
       }) { # $then
$units2
}";

    return $rc;
}


sub eof {
    my ($self, @args) = @_;

    return '';
}


sub ifEndif {
    my ($self, @args) = @_;

    return '# IF/ENDIF ignored';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Database::Terminfo::String::Grammar::Actions - Terminfo grammar actions

=head1 VERSION

version 0.012

=head1 DESCRIPTION

This modules give the actions associated to terminfo grammar. The value will be an anonymous stub that will accept $self, a reference to static_vars array, and a reference to dynamic_vars array in input, and tparm() arguments. The output will be the parameterized string.

=head2 new($class)

Instance a new object.

=head2 addEscapedCharacterToRc($self, $c)

Generates code that appends escaped character $c to the output of generated code.

=head2 addCharacterToRc($self, $c)

Generates code that appends character $c to the output of generated code.

=head2 addPercentToRc($self, $c)

Generates code that appends character '%' to the output of generated code.

=head2 addPrintPopToRc($self, $c)

Generates code that appends a print of pop() like %c in printf().

=head2 addPrintToRc($self, $format)

Generates code that appends a print of pop() using the $format string in the terminfo database.

=head2 addPushToRc($self, $push)

Generates code that appends a push().

=head2 addDynPop($self, $dynpop)

Generates code that appends a pop() into a dynamic variable.

=head2 addDynPush($self, $dynpush)

Generates code that appends a push() of a dynamic variable.

=head2 addStaticPop($self, $staticpop)

Generates code that appends a pop() into a static variable.

=head2 addStaticPush($self, $staticpush)

Generates code that appends a push() of a static variable.

=head2 addL($self, $l)

Generates code that appends a push() of strlen(pop()).

=head2 addPushConst($self, $const)

Generates code that appends a push() of char constant $const.

=head2 addPushInt($self, $int)

Generates code that appends a push() of integer constant $const.

=head2 addPlus($self, $plus)

Generates code that appends a push() of pop()+pop()

=head2 addMinus($self, $minus)

Generates code that appends a push() of second pop() - first pop()

=head2 addStar($self, $star)

Generates code that appends a push() of pop() * pop()

=head2 addDiv($self, $div)

Generates code that appends a push() of second pop() / first pop()

=head2 addMod($self, $mod)

Generates code that appends a push() of second pop() % first pop()

=head2 addBitAnd($self, $bitAnd)

Generates code that appends a push() of pop() & pop()

=head2 addBitOr($self, $bitOr)

Generates code that appends a push() of pop() | pop()

=head2 addBitXor($self, $bitXor)

Generates code that appends a push() of pop() ^ pop()

=head2 addEqual($self)

Generates code that appends a push() of second pop() == first pop()

=head2 addGreater($self)

Generates code that appends a push() of second pop() > first pop()

=head2 addLower($self)

Generates code that appends a push() of second pop() < first pop()

=head2 addLogicalAnd($self, $logicalAnd)

Generates code that appends a push() of pop() && pop()

=head2 addLogicalOr($self, $logicalOr)

Generates code that appends a push() of pop() && pop()

=head2 addNot($self, $not)

Generates code that appends a push() of pop() && pop()

=head2 addComplement($self, $complement)

Generates code that appends a push() of pop() && pop()

=head2 addOneToParams($self, $one)

Generates code that adds 1 to all parameters (in practice not more than two)

=head2 addIfThenElse($self, $if, $units1p, $then, $units2p, $elsifUnitsp, $else, $unitsp, $endif)

Generates code that adds generated if {} $elsifUnits else {}.

=head2 addIfThen($self, $if, $units1p, $then, $units2p, $elsifUnits, $endif)

Generates code that adds generated if {} $elsifUnits.

=head2 elifUnit($self, $else, $units1p, $then, $units2p)

Generates code that adds generated elsif {}.

=head2 eof($self, ...)

Routine executed at EOF. It is also preventing undef to be pass through the parse tree value.

=head2 ifEndif($self, ...)

Routine executed to empty IF/ENDIF. It is also preventing undef to be pass through the parse tree value.

=head1 AUTHOR

jddurand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
