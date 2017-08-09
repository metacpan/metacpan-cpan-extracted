# Copyright (c) 2012-2017 Martin Becker, Blaubeuren.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

package Math::Logic::Ternary::Calculator::Operator;

use 5.008;
use strict;
use warnings;
use Carp qw(croak);
use Math::Logic::Ternary::Trit;
use Math::Logic::Ternary::Word;
use Math::Logic::Ternary::Calculator::Mode;

our $VERSION = '0.004';

use constant TRIT => Math::Logic::Ternary::Trit::;
use constant WORD => Math::Logic::Ternary::Word::;
use constant MODE => Math::Logic::Ternary::Calculator::Mode::;

# indexes into object attributes
use constant _GEN_NAME => 0;
use constant _VAR_NAME => 1;
use constant _MIN_ARGS => 2;
use constant _VAR_ARGS => 3;
use constant _RET_VALS => 4;
use constant _OP_KIND  => 5;
use constant _IS_ARITH => 6;

use constant K_LOGICAL   => 0;
use constant K_TRITWISE  => 1;
use constant K_NUMERICAL => 2;
use constant K_VIEWING   => 3;
use constant KINDS       => 4;

use constant _OK_OPERATORS => 0;
use constant _OK_TITLE     => 1;

use constant MAX_COLUMNS => 70;

my %operators = ();
my @by_kind   = ();
my @op_kinds  = (
    'Logical Operators',
    'Tritwise Logical Operators',
    'Numerical Operators',
    'Viewing Functions',
);
my %glossary = (
    sn    => 'set to nil',
    st    => 'set to true',
    sf    => 'set to false',
    id    => 'identity',
    not   => 'not',
    up    => 'up one: increment modulo 3',
    nup   => 'not up: swap nil/false',
    dn    => 'down one: decrement modulo 3',
    ndn   => 'not down: swap nil/true',
    eqn   => 'equal to nil',
    eqt   => 'equal to true',
    eqf   => 'equal to false',
    nen   => 'not equal to nil',
    net   => 'not equal to true',
    nef   => 'not equal to false',
    hm    => 'hamlet: x or not x',
    uhm   => 'up & hamlet',
    dhm   => 'down & hamlet',
    orn   => 'or nil',
    uorn  => 'up & orn',
    dorn  => 'down & orn',
    qt    => 'quantum: x and not x',
    uqt   => 'up & quantum',
    dqt   => 'down & quantum',
    ann   => 'and nil',
    uann  => 'up & ann',
    dann  => 'down & ann',
    and   => 'and',
    or    => 'or',
    xor   => 'exclusive or',
    eqv   => 'equivalent',
    imp   => 'implication (x ==> y)',
    rep   => 'replication (x <== y)',
    nand  => 'not and',
    nor   => 'not or',
    cmp   => 'compare (false < nil < true)',
    asc   => 'ascending (false < nil < true)',
    tlr   => 'the lesser (false < nil < true)',
    tgr   => 'the greater (false < nil < true)',
    eq    => 'equal to',
    ne    => 'not equal to',
    lt    => 'less than (false < nil < true)',
    ge    => 'greater or equal (false < nil < true)',
    gt    => 'greater than (false < nil < true)',
    le    => 'less or equal (false < nil < true)',
    cmpu  => 'compare (unbalanced, nil < true < false)',
    ascu  => 'ascending (unbalanced, nil < true < false)',
    tlru  => 'the lesser (unbalanced, nil < true < false)',
    tgru  => 'the greater (unbalanced, nil < true < false)',
    ltu   => 'less than (unbalanced, nil < true < false)',
    geu   => 'greater or equal (unbalanced, nil < true < false)',
    gtu   => 'greater than (unbalanced, nil < true < false)',
    leu   => 'less or equal (unbalanced, nil < true < false)',
    incr  => 'increment',
    incc  => 'increment carry',
    inccu => 'increment carry (unbalanced)',
    inccv => 'increment carry (negative base)',
    decr  => 'decrement',
    decc  => 'decrement carry',
    deccu => 'decrement carry (unbalanced)',
    deccv => 'decrement carry (negative base)',
    pty   => 'parity',
    dpl   => 'duplicate',
    dplc  => 'duplication carry',
    dplcu => 'duplication carry (unbalanced)',
    dplcv => 'duplication carry (negative base)',
    hlv   => 'halve',
    hlvc  => 'halving carry',
    hlvs  => 'halving second carry',
    hlvcu => 'halving carry (unbalanced)',
    hlvsu => 'halving second carry (unbalanced)',
    negcv => 'negation carry (negative base)',
    mulcu => 'multiplication carry (unbalanced)',
    add   => 'addition',
    addc  => 'addition carry',
    addcu => 'addition carry (unbalanced)',
    addcv => 'addition carry (negative base)',
    addcx => 'addition carry (mixed base)',
    subt  => 'subtraction',
    subc  => 'subtraction carry',
    subcu => 'subtraction carry (unbalanced)',
    subcv => 'subtraction carry (negative base)',
    amn   => 'arithmetic mean',
    amnc  => 'arithmetic mean carry',
    amncu => 'arithmetic mean carry (unbalanced)',
    cmin  => 'ternary comparison to minimum',
    cmed  => 'ternary comparison to median',
    cmax  => 'ternary comparison to maximum',
    cvld  => 'ternary comparison validation',
    iplc  => 'interpolation linear coefficient',
    ipqc  => 'interpolation quadratic coefficient',
    lco   => 'linear combination',
    min   => 'minimum of three',
    med   => 'median of three',
    max   => 'maximum of three',
    minu  => 'minimum of three (unbalanced)',
    medu  => 'median of three (unbalanced)',
    maxu  => 'maximum of three (unbalanced)',
    sum   => 'summation',
    sumc  => 'summation carry',
    sumcu => 'summation carry (unbalanced)',
    mpx   => 'multiplex',
    Neg   => 'negate',
    Lshift=> 'left shift',
    Rshift=> 'right shift',
    Sign  => 'sign',
    Incr  => 'increment',
    Decr  => 'decrement',
    Dpl   => 'duplicate',
    Hlv   => 'halve',
    Cmp   => 'compare',
    Asc   => 'ascending',
    Gt    => 'greater than',
    Lt    => 'lesser than',
    Ge    => 'greater or equal',
    Le    => 'lesser or equal',
    Sort2 => 'sort two words',
    Tlr   => 'the lesser',
    Tgr   => 'the greater',
    Add   => 'add',
    Subt  => 'subtract',
    Amn   => 'arithmetic mean',
    Sort3 => 'sort three words',
    Min   => 'minimum',
    Med   => 'median',
    Max   => 'maximum',
    Mul   => 'multiply',
    Div   => 'divide',
    Ldiv  => 'long division',
    Sum   => 'summation',
    Mpx   => 'multiplex',
);
my @trit_l = (' nil   ', ' true  ', ' false ');
my @trit_s = map { /(\w)/ } @trit_l;
my @table_funcs = (
    \&_const,
    \&_unary,
    \&_binary,
    \&_ternary,
    \&_quaternary,
);

_initialize_operators();

sub _initialize_operators {
    my @modes = MODE->modes;
    foreach my $orec (TRIT->trit_operators) {
        my ($name, $min_args, $var_args, $ret_vals) = @{$orec};
        my $NAME = uc $name;
        $by_kind[K_LOGICAL ]->{$NAME} = $operators{$NAME} =
            bless [$NAME, $NAME, $min_args, $var_args, $ret_vals, K_LOGICAL];
        $by_kind[K_TRITWISE]->{$name} = $operators{$name} =
            bless [$name, $name, $min_args, $var_args, $ret_vals, K_TRITWISE];
        if (exists $glossary{$name}) {
            $glossary{$NAME} = $glossary{$name};
        }
    }
    foreach my $orec (WORD->word_operators) {
        my ($name, $min_args, $var_args, $ret_vals, $is_arith) = @{$orec};
        my $base = $is_arith? $modes[$is_arith]->unapply($name): $name;
        my $desc =
            bless [$base, $name, $min_args, $var_args, $ret_vals, K_NUMERICAL];
        if (defined $is_arith) {
            $desc->[_IS_ARITH] = $is_arith;
            (
                $by_kind[K_NUMERICAL]->{$base} = $operators{$base} ||= []
            )->[$is_arith] = $desc;
            if ($base ne $name) {
                ($operators{$name} = [])->[$is_arith] = $desc;
            }
            if (exists $glossary{$base} and !exists $glossary{$name}) {
                my $mode = $modes[$is_arith]->name;
                $glossary{$name} = $glossary{$base} . " ($mode)";
            }
        }
        else {
            $by_kind[K_NUMERICAL]->{$base} = $operators{$base} = $desc;
        }
    }
    foreach my $frec (WORD->word_formatters) {
        # not caring for variants: provide viewing functions in any mode
        my ($name) = @{$frec};
        $by_kind[K_VIEWING]->{$name} = $operators{$name} =
            bless [$name, $name, 1, 0, 0, K_VIEWING];
    }
}

sub _quantity {
    my ($min, $var, $item, $items) = @_;
    if (!defined $items) {
        $items = $item . 's';
    }
    if (!$min) {
        return
            !$var    ? "no $items"           :
            $var < 0 ? "any number of $items":
            1 == $var? "one optional $item"  : "$var optional $items";
    }
    if (!$var) {
        return 1 == $min? "one $item": "$min $items";
    }
    if ($var < 0) {
        return 1 == $min? "at least one $item": "at least $min $items";
    }
    my $max = $min + $var;
    return 1 == $var? "$min or $max $items": "$min to $max $items";
}

sub _fmt_word {
    my ($word) = @_;
    return join q[ ], map { /(\w)/g } $word->as_string;
}

sub _fmt_trits { "@trit_s[map { $_->res_mod3 } @_]" }

sub _iterate {
    my ($args, $balanced, $meth) = @_;
    my $carry = TRIT->nil;
    if (!$args) {
        return sub {
            if ($carry->is_nil) {
                $carry = TRIT->true;
                return $meth->();
            }
            return ();
        };
    }
    my $inc = $balanced? 'Incr': 'Incru';
    my $in = WORD->from_trits($args);
    $in = $in->sf if $balanced;
    return
        sub {
            if ($carry->is_nil) {
                my @trits = reverse $in->Trits;
                ($in, $carry) = $in->$inc;
                return $meth->(@trits);
            }
            return ();
        };
}

sub _iowrap {
    my ($meth) = @_;
    return
        sub {
            my @input = @_;
            return (\@input, $meth->(@input));
        };
}

sub _name {   $trit_l[  $_[0]->res_mod3    ]   }
sub _abbr { " @trit_s[map {$_->res_mod3} @_] " }

sub _const {
    my ($name, $balanced, $iterator) = @_;
    return
        join q[], map { "  $_\n" }
            $name,
            '+-------+',
            '|' . _name($iterator->()) . '|',
            '+-------+';
}

sub _unary {
    my ($name, $balanced, $iterator) = @_;
    my @idx  = $balanced? (2, 0, 1): (0 .. 2);
    my $desc = lc($name) . ' A';
    my $pw   = q[];
    my $pl   = q[];
    my $ld   = length $desc;
    if ($ld <= 5) {
        $desc .= q[ ] x (5 - $ld);
    }
    else {
        $pw = q[ ] x ($ld - 5);
        $pl = q[-] x ($ld - 5);
    }
    return
        join q[], map { "  $_\n" }
            "+-------+-------$pl+",
            "|   A   | $desc |",
            "+-------+-------$pl+",
            (map { "|$trit_l[$_]|" . _name($iterator->()) . "$pw|" } @idx),
            "+-------+-------$pl+";
}

sub _binary {
    my ($name, $balanced, $iterator) = @_;
    my @idx  = $balanced? (2, 0, 1): (0 .. 2);
    $name = lc $name;
    return
        join q[], map { "  $_\n" }
            "A $name B",
            '+---+---------------------------+',
            "| A | B  @trit_l[@idx]|",
            '|   +---+-----------------------+',
            (map {
                "|$trit_l[$_]|" .
                join(q[ ], map {_name($iterator->())} @idx) . '|'
            } @idx),
            '+-------+-----------------------+';
}

sub _ternary {
    my ($name, $balanced, $iterator) = @_;
    my @idx  = $balanced? (2, 0, 1): (0 .. 2);
    $name = lc $name;
    return
        join q[], map { "  $_\n" }
            "$name A, B, C",
            '+-------+---+---------------------------+',
            "|   A   | B | C  @trit_l[@idx]|",
            '|       |   +---+-----------------------+',
            (map {
                my $a = $_;
                $a == $idx[0]? (): '|       |       |                       |',
                (map {
                    "|$trit_l[$a]|$trit_l[$_]|" .
                    join(q[ ], map {_name($iterator->())} @idx) . '|'
                } @idx)
            } @idx),
            '+-------+-------+-----------------------+';
}

sub _quaternary {
    my ($name, $balanced, $iterator) = @_;
    my @idx  = $balanced? (2, 0, 1): (0 .. 2);
    $name = lc $name;
    return
        join q[], map { "  $_\n" }
            "$name A, B, C, D",
            '+-------+---+---------------------------+',
            '|   A   | B | C  ' .
            join(q[ ], map {" @trit_s[($_) x 3] "} @idx) . '|',
            '|       |   +---------------------------+',
            '|       |   | D  ' .
            join(q[ ], map {" @trit_s[@idx] "} @idx) . '|',
            '|       |   +---+-----------------------+',
            (map {
                my $a = $_;
                $a == $idx[0]? (): '|       |       |                       |',
                (map {
                    "|$trit_l[$a]|$trit_l[$_]|" .
                    join(q[ ],
                        map {_abbr(map {$iterator->()} @idx)} @idx
                    ) . '|'
                } @idx)
            } @idx),
            '+-------+-------+-----------------------+';
}

sub find {
    my ($class, $raw_name, $mode) = @_;
    return 'operator not defined' if !exists $operators{$raw_name};
    my $this = $operators{$raw_name};
    if ('ARRAY' eq ref $this) {
        $this = $this->[$mode->ordinal];
        if (!defined $this) {
            my $mname = $mode->name;
            return qq{operator not available in mode "$mname"};
        }
    }
    return $this;
}

sub operator_kinds { @op_kinds }

sub operator_list {
    my ($class, $mode, $kind) = @_;
    my $ops = defined($kind)? $by_kind[$kind]: \%operators;
    my $omode = $mode->ordinal;
    return
        map {
            my $orec = $ops->{$_};
            if ('ARRAY' eq ref $orec) {
                $orec = $orec->[$omode];
            }
            defined($orec)? $orec->name: ()
        } sort keys %{$ops};
}

sub signature {
    my ($this) = @_;
    return @{$this}[_MIN_ARGS, _VAR_ARGS, _RET_VALS];
}

sub generic_name  { $_[0]->[_GEN_NAME] }
sub name          { $_[0]->[_VAR_NAME] }
sub op_kind       { $_[0]->[_OP_KIND ] }
sub is_arithmetic { $_[0]->[_IS_ARITH] }

sub execute {
    my ($this, $first_arg, @more_args) = @_;
    my $name = $this->name;
    return $first_arg->$name(@more_args);
}

sub description {
    my ($this, $mode) = @_;
    my $name = $this->name;
    my ($min_args, $var_args, $ret_vals) = $this->signature;
    my $args = _quantity($min_args, $var_args, 'argument');
    my $vals = _quantity($ret_vals, undef, 'result value');
    my $kind = lc $op_kinds[$this->op_kind];
    $kind =~ s/s\z//;
    my $ari  = $this->is_arithmetic;
    if (defined $ari) {
        $kind .= q[, ] . (MODE->modes)[$ari]->name . q[ arithmetic];
    }
    $kind =~ s/s\z//;
    my $glos = exists($glossary{$name})? qq[ "$glossary{$name}"]: q[];
    my $desc = <<"EOT";
$name$glos
$args, $vals
($kind)
EOT
    if (K_LOGICAL == $this->op_kind || K_TRITWISE == $this->op_kind) {
        $desc .= $this->truth_table($mode->is_equal(MODE->balanced));
    }
    return $desc;
}

sub truth_table {
    my ($this, $balanced) = @_;
    my $name   = $this->name;
    my ($min_args, $var_args, $ret_vals) = $this->signature;
    my $max_args = 0 < $var_args? $min_args + $var_args: $min_args;
    my $result = q[];
    my $inc = $balanced? 'Incr': 'Incru';
    my $meth = TRIT->can(lc $name);
    return "(no truth table for $name)\n" if !$meth;
    foreach my $args ($min_args .. $max_args) {
        if ($result ne q[]) {
            $result .= "\n";
        }
        if (1 == $ret_vals && $args < @table_funcs) {
            my $it = _iterate($args, $balanced, $meth);
            $result .= $table_funcs[$args]->($name, $balanced, $it);
            next;
        }
        my $it = _iterate($args, $balanced, _iowrap($meth));
        while (my ($in, @out) = $it->()) {
            $result .=
                q[  ] . $name . q[ ] . _fmt_trits(@{$in}) .
                q[ => ] . _fmt_trits(@out) . "\n";
        }
    }
    return $result;
}

1;
__END__
=head1 NAME

Math::Logic::Ternary::Calculator::Operator - ternary calculator arithmetic unit

=head1 VERSION

This documentation refers to version 0.004 of
Math::Logic::Ternary::Calculator::Operator.

=head1 SYNOPSIS

  use Math::Logic::Ternary::Calculator::Operator;
  use Math::Logic::Ternary::Calculator::Mode;
  use Math::Logic::Ternary qw(nil true false word9);

  $mode = Math::Logic::Ternary::Calculator::Mode->balanced;
  $op = Math::Logic::Ternary::Calculator::Operator->find('Cmp', $mode);

  ($min_args, $var_args, $ret_vals) = $op->signature;
  @results = $op->execute(word9('1234'), word9('-5678'), nil);
  print scalar @results;                # prints 1
  print $results[0]->as_string;         # prints '$true'

=head1 DESCRIPTION

=over 4

=back

=head2 Exports

None.

=head1 SEE ALSO

=over 4

=item L<Math::Logic::Ternary::Calculator>

=back

=head1 AUTHOR

Martin Becker E<lt>becker-cpan-mpE<64>cozap.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2017 by Martin Becker, Blaubeuren.  All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
