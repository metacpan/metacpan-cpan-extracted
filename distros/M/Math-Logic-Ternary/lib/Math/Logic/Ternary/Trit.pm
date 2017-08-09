# Copyright (c) 2012-2017 Martin Becker, Blaubeuren.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

package Math::Logic::Ternary::Trit;

use 5.008;
use strict;
use warnings;
use Carp qw(croak);
use Scalar::Util qw(blessed);
use Role::Basic qw(with);
with qw(Math::Logic::Ternary::Object);

our $VERSION  = '0.004';
our @CARP_NOT = qw(Math::Logic::Ternary Math::Logic::Ternary::Word);

# ----- auxiliary constants -----

use constant TRIT_PREFIX => '$';

use constant _UINT     => 0;
use constant _INT      => 1;
use constant _NAME     => 2;
use constant _PNAME    => 3;
use constant _IS_NIL   => 4;
use constant _IS_TRUE  => 5;
use constant _IS_FALSE => 6;
use constant _BOOL     => 7;
use constant _MODINT   => 8;

use constant _MAX_MEMOIZED_OPS => 364;

# class backing data type for logical values: singleton arrayref

my @trits =
my ($nil, $true, $false) = map { bless $_ } (
    [0,  0, 'nil'  ],
    [1,  1, 'true' ],
    [2, -1, 'false'],
);
foreach my $trit ($nil, $true, $false) {
    $trit->[_PNAME]    = TRIT_PREFIX . $trit->[_NAME];
    $trit->[_IS_NIL]   = $trit->[_UINT] == $nil->[_UINT];
    $trit->[_IS_TRUE]  = $trit->[_UINT] == $true->[_UINT];
    $trit->[_IS_FALSE] = $trit->[_UINT] == $false->[_UINT];
    $trit->[_BOOL]     = $trit->[_IS_NIL]? undef: $trit->[_IS_TRUE];
}

# return values for trit conversions
my %by_name =
    map {
        ($_->[_NAME] => $_, $_->[_PNAME] => $_)
    } @trits;

# tables for parameter to index mappings
my @arg3s = (
    [[0, 1, 2], [1, 3, 4], [2, 4, 5]],
    [[1, 3, 4], [3, 6, 7], [4, 7, 8]],
    [[2, 4, 5], [4, 7, 8], [5, 8, 9]],
);
my @arg4s = (
    \@arg3s,
    [
        [[1, 3, 4], [3,  6,  7], [4,  7,  8]],
        [[3, 6, 7], [6, 10, 11], [7, 11, 12]],
        [[4, 7, 8], [7, 11, 12], [8, 12, 13]],
    ],
    [
        [[2, 4, 5], [4,  7,  8], [5,  8,  9]],
        [[4, 7, 8], [7, 11, 12], [8, 12, 13]],
        [[5, 8, 9], [8, 12, 13], [9, 13, 14]],
    ],
);

# generic op prefixes
my %arity = (
    c => 0,
    u => 1,
    b => 2,
    s => 3,
    t => 3,
    q => 4,
    Q => 4,
);

# named operators
my @named_ops = (
    [sn    => 'u000'],          # Set to Nil
    [st    => 'u111'],          # Set to True
    [sf    => 'u222'],          # Set to False
    [id    => 'u012'],          # IDentity
    [not   => 'u021'],          # NOT
    [up    => 'u120'],          # increment modulo 3, UP one
    [nup   => 'u210'],          # swap nil/false, Not(UP(x))
    [dn    => 'u201'],          # decrement modulo 3, DowN one
    [ndn   => 'u102'],          # swap nil/true, Not(DowN(x))
    [eqn   => 'u122'],          # EQual to Nil
    [eqt   => 'u212'],          # EQual to True
    [eqf   => 'u221'],          # EQual to False
    [nen   => 'u211'],          # Not Equal to Nil
    [net   => 'u121'],          # Not Equal to True
    [nef   => 'u112'],          # Not Equal to False
    [hm    => 'u011'],          # HaMlet (x or not x)
    [uhm   => 'u110'],          # Up & HaMlet
    [dhm   => 'u101'],          # Down & HaMlet
    [orn   => 'u010'],          # OR Nil
    [uorn  => 'u100'],          # Up & OR Nil
    [dorn  => 'u001'],          # Down & OR Nil
    [qt    => 'u022'],          # QuanTum (x and not x)
    [uqt   => 'u220'],          # Up & QuanTum
    [dqt   => 'u202'],          # Down & QuanTum
    [ann   => 'u002'],          # ANd Nil
    [uann  => 'u020'],          # Up & ANd Nil
    [dann  => 'u200'],          # Down & ANd Nil
    [and   => 'b002012222'],    # AND
    [or    => 'b010111012'],    # OR
    [xor   => 'b000021012'],    # eXclusive OR
    [eqv   => 'b000012021'],    # EQuiValent
    [imp   => 'b010012111'],    # IMPlication (x ==> y)
    [rep   => 'b001111021'],    # REPlication (x <== y)
    [nand  => 'b001021111'],    # Not AND
    [nor   => 'b020222021'],    # Not OR
    [cmp   => 'b021101220'],    # CoMPare,              false < nil < true
    [asc   => 'b012202110'],    # ASCending
    [tlr   => 'b002012222'],    # The LesseR
    [tgr   => 'b010111012'],    # The GreateR
    [eq    => 'b122212221'],    # EQual to
    [ne    => 'b211121112'],    # Not Equal to
    [lt    => 'b212222112'],    # Less Than
    [ge    => 'b121111221'],    # Greater or Equal
    [gt    => 'b221121222'],    # Greater Than
    [le    => 'b112212111'],    # Less or Equal
    [cmpu  => 'b022102110'],    # CoMPare (Unbalanced), nil < true < false
    [ascu  => 'b011201220'],    # ASCending (Unbalanced)
    [tlru  => 'b000011012'],    # The LesseR (Unbalanced)
    [tgru  => 'b012112222'],    # The GreateR (Unbalanced)
    [ltu   => 'b211221222'],    # Less Than (Unbalanced)
    [geu   => 'b122112111'],    # Greater or Equal (Unbalanced)
    [gtu   => 'b222122112'],    # Greater Than (Unbalanced)
    [leu   => 'b111211221'],    # Less or Equal (Unbalanced)
    [incr  => 'b012120201'],    # INCRement
    [incc  => 'b000010002'],    # INCrement Carry
    [inccu => 'b000001011'],    # INCrement Carry (Unbalanced)
    [inccv => 'b001000020'],    # INCrement Carry (negatiVe base)
    [decr  => 'b021102210'],    # DECRement
    [decc  => 'b000002010'],    # DECrement Carry
    [deccu => 'b011001000'],    # DECrement Carry (Unbalanced)
    [deccv => 'b020000001'],    # DECrement Carry (negatiVe base)
    [pty   => 'b021210102'],    # PariTY
    [dpl   => 'b012201120'],    # DuPLicate
    [dplc  => 'b000110202'],    # DuPLication Carry
    [dplcu => 'b000011112'],    # DuPLication Carry (Unbalanced)
    [dplcv => 'b001020222'],    # DuPLication Carry (negatiVe base)
#   [hlv   => 'b011022211'],    # HaLVe
#   [hlvc  => 'b011100100'],    # HaLVing Carry
#   [hlvs  => 'b002010002'],    # HaLVing Second carry
#   [hlvu  => 'b000000000'],    # HaLVe (Unbalanced)
#   [hlvcu => 'b000000000'],    # HaLVing Carry (Unbalanced)
#   [hlvsu => 'b000000000'],    # HaLVing Second carry (Unbalanced)
    [negcv => 'b000100110'],    # NEGation Carry (negatiVe base)
    [mulcu => 'b000000001'],    # MULtiplication Carry (Unbalanced)
    [add   => 's0122010120'],   # ADDition
    [addc  => 's0001021002'],   # ADDition Carry
    [addcu => 's0000111112'],   # ADDition Carry (Unbalanced)
    [addcv => 't001000020000020220020220222'], # ADDition Carry (negatiVe base)
    [addcx => 't001000101000020001020220000'], # ADDition Carry (miXed base)
    [subt  => 't021210102102021210210102021'], # SUBTraction
    [subc  => 't000010002002000202010110000'], # SUBTraction Carry
    [subcu => 't011111112001011111000001011'], # SUBTraction Carry (Unbal.)
    [subcv => 't020220222000020220001000020'], # SUBTraction Carry (nV.b.)
#   [amn   => 't000000000000000000000000000'], # Arithmetic MeaN
#   [amnc  => 't000000000000000000000000000'], # Arithmetic MeaN Carry
#   [amncu => 't000000000000000000000000000'], # Arithmetic MeaN Carry (Unbal.)
    [ipqc  => 's0211020210'],   # InterPolation Quadratic Coeff
    [cmin  => 't000221000121121121000220000'], # ternary Comparison to MINimum
    [cmed  => 't121102121010212010121001121'], # ternary Comparison to MEDian
    [cmax  => 't212010212202000202212112212'], # ternary Comparison to MAXimum
    [cvld  => 't100010001001111021010012111'], # ternary Comparison VaLiDation
    [min   => 's0020221222'],   # MINimum of three
    [med   => 's0001021122'],   # MEDian of three
    [max   => 's0101101112'],   # MAXimum of three
    [minu  => 's0000001112'],   # MINimum of three (Unbalanced)
    [medu  => 's0001121122'],   # MEDian of three (Unbalanced)
    [maxu  => 's0121221222'],   # MAXimum of three (Unbalanced)
    [sum   => 'q012201012012012'], # SUMmation
    [sumc  => 'q000102100211022'], # SUMmation Carry
    [sumcu => 'q000011111211222'], # SUMmation Carry (Unbalanced)
);
# names of arithmetic operators with mode-dependent variants
my %is_ar = map {($_ => 0, $_ . 'u' => 1, $_ . 'v' => 2)} qw(
    asc cmp ge gt le lt max med min tgr tlr
    addc decc dplc incc negc subc sumc
);

# ----- private variables -----

# operator memoizer
# initialized with some special cases
# maps name to [argc, sub]
my %OP = (
    'c0'   => [0, sub { 0 }],
    'c1'   => [0, sub { 1 }],
    'c2'   => [0, sub { 2 }],
    'u012' => [1, sub { $_[0] }],
);

# ----- other initializations -----

_load_generated_methods();

# ----- private subroutines -----

# raw unary op factory, takes 3 values
sub _unary {
    my @val = @_;
    return sub { $val[$_[0]] };
}

# argument shifter, takes 1 operator, yields 1 operator
sub _shiftarg {
    my $op = $_[0];
    return sub { shift; $op->(@_) };
}

# argument chooser, takes 3 operators, yields 1 operator with extra parameter
sub _mpx {
    my @op = @_;
    return sub { my $i = shift; $op[$i]->(@_) };
}

# symmetric ternary op factory, takes 10 values
sub _symmetric_3adic {
    my @val = @_;
    return sub { $val[$arg3s[$_[0]]->[$_[1]]->[$_[2]]] };
}

# symmetric quaternary op factory, takes 15 values
sub _symmetric_4adic {
    my @val = @_;
    return sub { $val[$arg4s[$_[0]]->[$_[1]]->[$_[2]]->[$_[3]]] };
}

# raw operator factory, takes a name
sub _OP {
    my ($name) = @_;
    return $OP{$name} if exists $OP{$name};
    my $op;
    if ($name =~ /^u([012])([012])([012])\z/) {
        if ($1 eq $2 && $1 eq $3) {
            return $OP{"c$1"};
        }
        $op = [1, _unary($1, $2, $3)];
    }
    elsif ($name =~ /^b([012]{3})([012]{3})([012]{3})\z/) {
        if ($1 eq $2 && $1 eq $3) {
            return $OP{$name} = [2, _shiftarg(_unary(split //, $1))];
        }
        $op = [2, _mpx(map {_OP($_)->[1]} "u$1", "u$2", "u$3")];
    }
    elsif ($name =~ /^s([012]{10})\z/) {
        $op = [3, _symmetric_3adic(split //, $1)];
    }
    elsif ($name =~ /^t([012]{9})([012]{9})([012]{9})\z/) {
        $op = [3, _mpx(map {_OP($_)->[1]} "b$1", "b$2", "b$3")];
    }
    elsif ($name =~ /^q([012]{15})\z/) {
        $op = [4, _symmetric_4adic(split //, $1)];
    }
    elsif ($name =~ /^Q([012]{27})([012]{27})([012]{27})\z/) {
        $op = [4, _mpx(map {_OP($_)->[1]} "t$1", "t$2", "t$3")];
    }
    else {
        croak qq{unknown operator name "$name"};
    }
    if (keys(%OP) < _MAX_MEMOIZED_OPS) {
        $OP{$name} = $op;
    }
    return $op;
}

sub _generic {
    my ($argc, $op) = @{_OP($_[0])};
    return sub {
        if (@_ < $argc) {
            my $missing = $argc - @_;
            croak "too few arguments, expected $missing more";
        }
        my @args = map { $_->res_mod3 } @_[0..$argc-1];
        return $trits[ $op->(@args) ];
    };
}

sub _load_generated_methods {
    foreach my $arec (@named_ops) {
        my ($method, $gen_method) = @{$arec};
        # use fully qualified method names to avoid clashes with builtins
        my $tm = __PACKAGE__ . '::' . $method;
        no strict 'refs';
        *$tm = _generic($gen_method);
    }
}

# ----- class methods -----

sub nil   { $nil   }
sub true  { $true  }
sub false { $false }

sub from_bool {
    my $bool = $_[1];
    return $true  if $bool;
    return $false if defined $bool;
    return $nil;
}

sub from_sign      { $trits[$_[1] <=> 0] }
sub from_remainder { $trits[$_[1]  %  3] }

sub from_int {
    my $int = $_[1];
    croak qq{integer "$int" out of range -1..1} if $int < -1 || 1 < $int;
    return $trits[$int];
}

sub from_int_u {
    my $int = $_[1];
    croak qq{integer "$int" out of range 0..2} if $int < 0 || 2 < $int;
    return $trits[$int];
}

sub from_string {
    my $name = lc $_[1];
    croak qq{unknown trit name "$_[1]"} if !exists $by_name{$name};
    return $by_name{$name};
}

sub from_modint {
    my $mi = $_[1];
    my ($mod, $res) = eval { $mi->modulus, $mi->residue };
    croak qq{modular integer with modulus 3 expected} if !$mod || 3 != $mod;
    return $trits[$res];
}

sub from_various {
    my ($class, $item) = @_;
    my $type = blessed $item;
    if ($type) {
        if (eval { $item->DOES('Math::Logic::Ternary::Object') }) {
            return $class->from_int($item->as_int);
        }
        if (eval { $item->isa('Math::BigInt') }) {
            my $is_two = 2 == $item;            # for Devel::Cover
            return $is_two? $false: $class->from_int($item);
        }
        if (eval { $item->isa('Math::ModInt') }) {
            return $class->from_modint($item);
        }
        croak qq{cannot convert "$type" object to a trit};
    }
    $type = ref $item;
    if ($type) {
        croak qq{cannot convert $type reference to a trit};
    }
    if (!defined $item) {
        return $nil;
    }
    if ($item =~ /^[\+\-]?\d+\z/) {
        return 2 == $item? $false: $class->from_int($item);
    }
    return $class->from_string($item);
}

sub make_generic { _generic($_[1]) }

sub trit_operators {
    return (
        [nil   => 0, 0, 1],
        [true  => 0, 0, 1],
        [false => 0, 0, 1],
        (
            map {
                my ($name, $gname) = @{$_};
                [
                    $name,
                    $arity{substr $gname, 0, 1},
                    0,
                    1,
                    exists($is_ar{$name})? $is_ar{$name}: ()
                ]
            }
            @named_ops
        ),
        [mpx   => 4, 0, 1],
    );
}

# ----- object methods -----

sub Mpx {
    if (@_ < 4) {
        my $missing = 4 - @_;
        croak "too few arguments, expected $missing more";
    }
    my ($this, $case_n, $case_t, $case_f) = @_;
    return ($case_n, $case_t, $case_f)[$this->res_mod3];
}

sub mpx { $trits[shift->Mpx(@_)->res_mod3] }

sub generic {
    my ($this, $method, @params) = @_;
    return _generic($method)->($this, @params);
}

sub is_nil    { $_[0]->[_IS_NIL]    }
sub is_true   { $_[0]->[_IS_TRUE]   }
sub is_false  { $_[0]->[_IS_FALSE]  }
sub as_bool   { $_[0]->[_BOOL]      }

sub as_modint {
    my ($this) = @_;
    my $mi = $this->[_MODINT];
    if (!defined $mi) {
        eval { require Math::ModInt }
            or croak 'perl extension Math::ModInt is not available';
        $mi = $this->[_MODINT] = Math::ModInt->new($this->[_UINT], 3);
    }
    return $mi;
}

# role: ternary object

sub is_equal  { $_[1]->Rtrits <= 1 && $_[0]->as_int == $_[1]->Trit(0)->as_int }
sub Rtrits    { $_[0]->[_IS_NIL]? (wantarray? (): 0): (wantarray? $_[0]: 1) }

sub Sign      { $_[0]                  }
sub Trit      { ($_[0])[$_[1]] || $nil }
sub Trits     { wantarray? $_[0]: 1    }
sub as_int    { $_[0]->[_INT]          }
sub as_int_u  { $_[0]->[_UINT]         }
sub as_int_v  { $_[0]->[_UINT]         }
sub res_mod3  { $_[0]->[_UINT]         }
sub as_string { $_[0]->[_PNAME]        }

1;

__END__
=head1 NAME

Math::Logic::Ternary::Trit - ternary logical information unit

=head1 VERSION

This documentation refers to version 0.004 of Math::Logic::Ternary::Trit.

=head1 SYNOPSIS

  use Math::Logic::Ternary::Trit;

  $a = Math::Logic::Ternary::Trit->true;
  $a = Math::Logic::Ternary::Trit->from_string('true'); # same as above
  $a = Math::Logic::Ternary::Trit->from_int(1);         # same as above
  $a = Math::Logic::Ternary::Trit->from_bool(1 == 1);   # same as above

  $b = Math::Logic::Ternary::Trit->false;
  $b = Math::Logic::Ternary::Trit->from_string('false'); # same as above
  $b = Math::Logic::Ternary::Trit->from_int(-1);         # same as above
  $b = Math::Logic::Ternary::Trit->from_bool(0 == 1);    # same as above

  $c = Math::Logic::Ternary::Trit->nil;
  $c = Math::Logic::Ternary::Trit->from_string('nil');  # same as above
  $c = Math::Logic::Ternary::Trit->from_int(0);         # same as above
  $c = Math::Logic::Ternary::Trit->from_bool(undef);    # same as above

  $d = $a->and($b)->or($a->not->and($c));

  print $d->as_string;                                  # print '$false'
  print $d->as_int;                                     # print -1

=head1 DESCRIPTION

Math::Logic::Ternary::Trit is the class for ternary logical values
aka trits.  This class has only three instances, representing
ternary truth values: I<true>, I<false>, and I<nil>.  It also
implements logical operators, conversions and the role defined by
Math::Logic::Ternary::Object.

=head2 Exports

None.

=head2 Constants

=over 4

=item nil

The I<nil> trit.

=item true

The I<true> trit.

=item false

The I<false> trit.

=back

=head2 Unary Operators

=over 4

=item sn

B<S>et to B<n>il.

  +-------+-------+
  |   A   | sn A  |
  +-------+-------+
  | false | nil   |
  | nil   | nil   |
  | true  | nil   |
  +-------+-------+

=item st

B<S>et to B<t>rue.

  +-------+-------+
  |   A   | st A  |
  +-------+-------+
  | false | true  |
  | nil   | true  |
  | true  | true  |
  +-------+-------+

=item sf

B<S>et to B<f>alse.

  +-------+-------+
  |   A   | sf A  |
  +-------+-------+
  | false | false |
  | nil   | false |
  | true  | false |
  +-------+-------+

=item id

B<Id>entity.

  +-------+-------+
  |   A   | id A  |
  +-------+-------+
  | false | false |
  | nil   | nil   |
  | true  | true  |
  +-------+-------+

=item not

B<Not>.

  +-------+-------+
  |   A   | not A |
  +-------+-------+
  | false | true  |
  | nil   | nil   |
  | true  | false |
  +-------+-------+

=item up

B<Up> one: increment modulo 3.

  +-------+-------+
  |   A   | up A  |
  +-------+-------+
  | false | nil   |
  | nil   | true  |
  | true  | false |
  +-------+-------+

=item nup

B<N>ot B<up>: swap nil/false.

  +-------+-------+
  |   A   | nup A |
  +-------+-------+
  | false | nil   |
  | nil   | false |
  | true  | true  |
  +-------+-------+

=item dn

B<D>owB<n> one: decrement modulo 3.

  +-------+-------+
  |   A   | dn A  |
  +-------+-------+
  | false | true  |
  | nil   | false |
  | true  | nil   |
  +-------+-------+

=item ndn

B<N>ot B<d>owB<n>: swap nil/true.

  +-------+-------+
  |   A   | ndn A |
  +-------+-------+
  | false | false |
  | nil   | true  |
  | true  | nil   |
  +-------+-------+

=item eqn

B<Eq>ual to B<n>il.

  +-------+-------+
  |   A   | eqn A |
  +-------+-------+
  | false | false |
  | nil   | true  |
  | true  | false |
  +-------+-------+

=item eqt

B<Eq>ual to B<t>rue.

  +-------+-------+
  |   A   | eqt A |
  +-------+-------+
  | false | false |
  | nil   | false |
  | true  | true  |
  +-------+-------+

=item eqf

B<Eq>ual to B<f>alse.

  +-------+-------+
  |   A   | eqf A |
  +-------+-------+
  | false | true  |
  | nil   | false |
  | true  | false |
  +-------+-------+

=item nen

B<N>ot B<e>qual to B<n>il.

  +-------+-------+
  |   A   | nen A |
  +-------+-------+
  | false | true  |
  | nil   | false |
  | true  | true  |
  +-------+-------+

=item net

B<N>ot B<e>qual to B<t>rue.

  +-------+-------+
  |   A   | net A |
  +-------+-------+
  | false | true  |
  | nil   | true  |
  | true  | false |
  +-------+-------+

=item nef

B<N>ot B<e>qual to B<f>alse.

  +-------+-------+
  |   A   | nef A |
  +-------+-------+
  | false | false |
  | nil   | true  |
  | true  | true  |
  +-------+-------+

=item hm

B<H>aB<m>let: x or not x.

  +-------+-------+
  |   A   | hm A  |
  +-------+-------+
  | false | true  |
  | nil   | nil   |
  | true  | true  |
  +-------+-------+

=item uhm

B<U>p & B<h>aB<m>let.

  +-------+-------+
  |   A   | uhm A |
  +-------+-------+
  | false | nil   |
  | nil   | true  |
  | true  | true  |
  +-------+-------+

=item dhm

B<D>own & B<h>aB<m>let.

  +-------+-------+
  |   A   | dhm A |
  +-------+-------+
  | false | true  |
  | nil   | true  |
  | true  | nil   |
  +-------+-------+

=item orn

B<Or> B<n>il.

  +-------+-------+
  |   A   | orn A |
  +-------+-------+
  | false | nil   |
  | nil   | nil   |
  | true  | true  |
  +-------+-------+

=item uorn

B<U>p & B<or> B<n>il.

  +-------+--------+
  |   A   | uorn A |
  +-------+--------+
  | false | nil    |
  | nil   | true   |
  | true  | nil    |
  +-------+--------+

=item dorn

B<D>own & B<or> B<n>il.

  +-------+--------+
  |   A   | dorn A |
  +-------+--------+
  | false | true   |
  | nil   | nil    |
  | true  | nil    |
  +-------+--------+

=item qt

B<Q>uanB<t>um: x and not x.

  +-------+-------+
  |   A   | qt A  |
  +-------+-------+
  | false | false |
  | nil   | nil   |
  | true  | false |
  +-------+-------+

=item uqt

B<U>p & B<q>uanB<t>um.

  +-------+-------+
  |   A   | uqt A |
  +-------+-------+
  | false | nil   |
  | nil   | false |
  | true  | false |
  +-------+-------+

=item dqt

B<D>own & B<q>uanB<t>um.

  +-------+-------+
  |   A   | dqt A |
  +-------+-------+
  | false | false |
  | nil   | false |
  | true  | nil   |
  +-------+-------+

=item ann

B<An>d B<n>il.

  +-------+-------+
  |   A   | ann A |
  +-------+-------+
  | false | false |
  | nil   | nil   |
  | true  | nil   |
  +-------+-------+

=item uann

B<U>p & B<ann>.

  +-------+--------+
  |   A   | uann A |
  +-------+--------+
  | false | nil    |
  | nil   | nil    |
  | true  | false  |
  +-------+--------+

=item dann

B<D>own & B<ann>.

  +-------+--------+
  |   A   | dann A |
  +-------+--------+
  | false | nil    |
  | nil   | false  |
  | true  | nil    |
  +-------+--------+

=back

=head2 Binary Operators

=over 4

=item and

B<And>.

  A and B
  +---+---------------------------+
  | A | B   false   nil     true  |
  |   +---+-----------------------+
  | false | false   false   false |
  | nil   | false   nil     nil   |
  | true  | false   nil     true  |
  +-------+-----------------------+

=item or

B<Or>.

  A or B
  +---+---------------------------+
  | A | B   false   nil     true  |
  |   +---+-----------------------+
  | false | false   nil     true  |
  | nil   | nil     nil     true  |
  | true  | true    true    true  |
  +-------+-----------------------+

=item xor

EB<x>clusive B<or>.

  A xor B
  +---+---------------------------+
  | A | B   false   nil     true  |
  |   +---+-----------------------+
  | false | false   nil     true  |
  | nil   | nil     nil     nil   |
  | true  | true    nil     false |
  +-------+-----------------------+

=item eqv

B<Eq>uiB<v>alent.

  A eqv B
  +---+---------------------------+
  | A | B   false   nil     true  |
  |   +---+-----------------------+
  | false | true    nil     false |
  | nil   | nil     nil     nil   |
  | true  | false   nil     true  |
  +-------+-----------------------+

=item imp

B<Imp>lication (x ==> y).

  A imp B
  +---+---------------------------+
  | A | B   false   nil     true  |
  |   +---+-----------------------+
  | false | true    true    true  |
  | nil   | nil     nil     true  |
  | true  | false   nil     true  |
  +-------+-----------------------+

=item rep

B<Rep>lication (x <== y).

  A rep B
  +---+---------------------------+
  | A | B   false   nil     true  |
  |   +---+-----------------------+
  | false | true    nil     false |
  | nil   | true    nil     nil   |
  | true  | true    true    true  |
  +-------+-----------------------+

=item nand

B<N>ot B<and>.

  A nand B
  +---+---------------------------+
  | A | B   false   nil     true  |
  |   +---+-----------------------+
  | false | true    true    true  |
  | nil   | true    nil     nil   |
  | true  | true    nil     false |
  +-------+-----------------------+

=item nor

B<N>ot B<or>.

  A nor B
  +---+---------------------------+
  | A | B   false   nil     true  |
  |   +---+-----------------------+
  | false | true    nil     false |
  | nil   | nil     nil     false |
  | true  | false   false   false |
  +-------+-----------------------+

=item cmp

B<C>oB<mp>are (false E<lt> nil E<lt> true).

  A cmp B
  +---+---------------------------+
  | A | B   false   nil     true  |
  |   +---+-----------------------+
  | false | nil     false   false |
  | nil   | true    nil     false |
  | true  | true    true    nil   |
  +-------+-----------------------+

=item asc

B<Asc>ending (false E<lt> nil E<lt> true).

  A asc B
  +---+---------------------------+
  | A | B   false   nil     true  |
  |   +---+-----------------------+
  | false | nil     true    true  |
  | nil   | false   nil     true  |
  | true  | false   false   nil   |
  +-------+-----------------------+

=item tlr

B<T>he B<l>esseB<r> (false E<lt> nil E<lt> true).
Logically equivalent to L<and>.

  A tlr B
  +---+---------------------------+
  | A | B   false   nil     true  |
  |   +---+-----------------------+
  | false | false   false   false |
  | nil   | false   nil     nil   |
  | true  | false   nil     true  |
  +-------+-----------------------+

=item tgr

B<T>he B<gr>eater (false E<lt> nil E<lt> true).
Logically equivalent to L<or>.

  A tgr B
  +---+---------------------------+
  | A | B   false   nil     true  |
  |   +---+-----------------------+
  | false | false   nil     true  |
  | nil   | nil     nil     true  |
  | true  | true    true    true  |
  +-------+-----------------------+

=item eq

B<Eq>ual to.

  A eq B
  +---+---------------------------+
  | A | B   false   nil     true  |
  |   +---+-----------------------+
  | false | true    false   false |
  | nil   | false   true    false |
  | true  | false   false   true  |
  +-------+-----------------------+

=item ne

B<N>ot B<e>qual to.

  A ne B
  +---+---------------------------+
  | A | B   false   nil     true  |
  |   +---+-----------------------+
  | false | false   true    true  |
  | nil   | true    false   true  |
  | true  | true    true    false |
  +-------+-----------------------+

=item lt

B<L>ess B<t>han (false E<lt> nil E<lt> true)

  A lt B
  +---+---------------------------+
  | A | B   false   nil     true  |
  |   +---+-----------------------+
  | false | false   true    true  |
  | nil   | false   false   true  |
  | true  | false   false   false |
  +-------+-----------------------+

=item ge

B<G>reater or B<e>qual (false E<lt> nil E<lt> true).

  A ge B
  +---+---------------------------+
  | A | B   false   nil     true  |
  |   +---+-----------------------+
  | false | true    false   false |
  | nil   | true    true    false |
  | true  | true    true    true  |
  +-------+-----------------------+

=item gt

B<G>reater B<t>han (false E<lt> nil E<lt> true).

  A gt B
  +---+---------------------------+
  | A | B   false   nil     true  |
  |   +---+-----------------------+
  | false | false   false   false |
  | nil   | true    false   false |
  | true  | true    true    false |
  +-------+-----------------------+

=item le

B<L>ess or B<e>qual (false E<lt> nil E<lt> true).

  A le B
  +---+---------------------------+
  | A | B   false   nil     true  |
  |   +---+-----------------------+
  | false | true    true    true  |
  | nil   | false   true    true  |
  | true  | false   false   true  |
  +-------+-----------------------+

=item cmpu

B<C>oB<mp>are (B<u>nbalanced, nil E<lt> true E<lt> false).

  A cmpu B
  +---+---------------------------+
  | A | B   nil     true    false |
  |   +---+-----------------------+
  | nil   | nil     false   false |
  | true  | true    nil     false |
  | false | true    true    nil   |
  +-------+-----------------------+

=item ascu

B<Asc>ending (B<u>nbalanced, nil E<lt> true E<lt> false).

  A ascu B
  +---+---------------------------+
  | A | B   nil     true    false |
  |   +---+-----------------------+
  | nil   | nil     true    true  |
  | true  | false   nil     true  |
  | false | false   false   nil   |
  +-------+-----------------------+

=item tlru

B<T>he B<l>esseB<r> (B<u>nbalanced, nil E<lt> true E<lt> false).

  A tlru B
  +---+---------------------------+
  | A | B   nil     true    false |
  |   +---+-----------------------+
  | nil   | nil     nil     nil   |
  | true  | nil     true    true  |
  | false | nil     true    false |
  +-------+-----------------------+

=item tgru

B<T>he B<gr>eater (B<u>nbalanced, nil E<lt> true E<lt> false).

  A tgru B
  +---+---------------------------+
  | A | B   nil     true    false |
  |   +---+-----------------------+
  | nil   | nil     true    false |
  | true  | true    true    false |
  | false | false   false   false |
  +-------+-----------------------+

=item ltu

B<L>ess B<t>han (B<u>nbalanced, nil E<lt> true E<lt> false).

  A ltu B
  +---+---------------------------+
  | A | B   nil     true    false |
  |   +---+-----------------------+
  | nil   | false   true    true  |
  | true  | false   false   true  |
  | false | false   false   false |
  +-------+-----------------------+

=item geu

B<G>reater or B<e>qual (B<u>nbalanced, nil E<lt> true E<lt> false).

  A geu B
  +---+---------------------------+
  | A | B   nil     true    false |
  |   +---+-----------------------+
  | nil   | true    false   false |
  | true  | true    true    false |
  | false | true    true    true  |
  +-------+-----------------------+

=item gtu

B<G>reater B<t>han (B<u>nbalanced, nil E<lt> true E<lt> false).

  A gtu B
  +---+---------------------------+
  | A | B   nil     true    false |
  |   +---+-----------------------+
  | nil   | false   false   false |
  | true  | true    false   false |
  | false | true    true    false |
  +-------+-----------------------+

=item leu

B<L>ess or B<e>qual (B<u>nbalanced, nil E<lt> true E<lt> false).

  A gtu B
  +---+---------------------------+
  | A | B   nil     true    false |
  |   +---+-----------------------+
  | nil   | true    true    true  |
  | true  | false   true    true  |
  | false | false   false   true  |
  +-------+-----------------------+

=item incr

B<Incr>ement.

  A incr B
  +---+---------------------------+
  | A | B   false   nil     true  |
  |   +---+-----------------------+
  | false | true    false   nil   |
  | nil   | false   nil     true  |
  | true  | nil     true    false |
  +-------+-----------------------+

=item incc

B<Inc>rement B<c>arry.

  A incc B
  +---+---------------------------+
  | A | B   false   nil     true  |
  |   +---+-----------------------+
  | false | false   nil     nil   |
  | nil   | nil     nil     nil   |
  | true  | nil     nil     true  |
  +-------+-----------------------+

=item inccu

B<Inc>rement B<c>arry (B<u>nbalanced).

  A inccu B
  +---+---------------------------+
  | A | B   nil     true    false |
  |   +---+-----------------------+
  | nil   | nil     nil     nil   |
  | true  | nil     nil     true  |
  | false | nil     true    true  |
  +-------+-----------------------+

=item inccv

B<Inc>rement B<c>arry (negatiB<v>e base).

  A inccv B
  +---+---------------------------+
  | A | B   nil     true    false |
  |   +---+-----------------------+
  | nil   | nil     nil     true  |
  | true  | nil     nil     nil   |
  | false | nil     false   nil   |
  +-------+-----------------------+

=item decr

B<Decr>ement.

  A decr B
  +---+---------------------------+
  | A | B   false   nil     true  |
  |   +---+-----------------------+
  | false | nil     false   true  |
  | nil   | true    nil     false |
  | true  | false   true    nil   |
  +-------+-----------------------+

=item decc

B<Dec>rement B<c>arry.

  A decc B
  +---+---------------------------+
  | A | B   false   nil     true  |
  |   +---+-----------------------+
  | false | nil     nil     true  |
  | nil   | nil     nil     nil   |
  | true  | false   nil     nil   |
  +-------+-----------------------+

=item deccu

B<Dec>rement B<c>arry (B<u>nbalanced).

  A deccu B
  +---+---------------------------+
  | A | B   nil     true    false |
  |   +---+-----------------------+
  | nil   | nil     true    true  |
  | true  | nil     nil     true  |
  | false | nil     nil     nil   |
  +-------+-----------------------+

=item deccv

B<Dec>rement B<c>arry (negatiB<v>e base)

  A deccv B
  +---+---------------------------+
  | A | B   nil     true    false |
  |   +---+-----------------------+
  | nil   | nil     false   nil   |
  | true  | nil     nil     nil   |
  | false | nil     nil     true  |
  +-------+-----------------------+

=item pty

B<P>ariB<ty>.

  A pty B
  +---+---------------------------+
  | A | B   false   nil     true  |
  |   +---+-----------------------+
  | false | false   true    nil   |
  | nil   | true    nil     false |
  | true  | nil     false   true  |
  +-------+-----------------------+

=item dpl

B<D>uB<pl>icate.

  A dpl B
  +---+---------------------------+
  | A | B   false   nil     true  |
  |   +---+-----------------------+
  | false | nil     true    false |
  | nil   | false   nil     true  |
  | true  | true    false   nil   |
  +-------+-----------------------+

=item dplc

B<D>uB<pl>ication B<c>arry.

  A dplc B
  +---+---------------------------+
  | A | B   false   nil     true  |
  |   +---+-----------------------+
  | false | false   false   nil   |
  | nil   | nil     nil     nil   |
  | true  | nil     true    true  |
  +-------+-----------------------+

=item dplcu

B<D>uB<pl>ication B<c>arry (B<u>nbalanced).

  A dplcu B
  +---+---------------------------+
  | A | B   nil     true    false |
  |   +---+-----------------------+
  | nil   | nil     nil     nil   |
  | true  | nil     true    true  |
  | false | true    true    false |
  +-------+-----------------------+

=item dplcv

B<D>uB<pl>ication B<c>arry (negatiB<v>e base).

  A dplcv B
  +---+---------------------------+
  | A | B   nil     true    false |
  |   +---+-----------------------+
  | nil   | nil     nil     true  |
  | true  | nil     false   nil   |
  | false | false   false   false |
  +-------+-----------------------+

=begin COMING_UP

=item hlv

=item hlvc

=item hlvs

=item hlvu

=item hlvcu

=item hlvsu

Division-by-two helper operators.

=end COMING_UP

=item negcv

B<Neg>ation B<c>arry (negatiB<v>e base).

  A negcv B
  +---+---------------------------+
  | A | B   nil     true    false |
  |   +---+-----------------------+
  | nil   | nil     nil     nil   |
  | true  | true    nil     nil   |
  | false | true    true    nil   |
  +-------+-----------------------+

=item mulcu

B<Mul>tiplication B<c>arry (B<u>nbalanced).

  A mulcu B
  +---+---------------------------+
  | A | B   nil     true    false |
  |   +---+-----------------------+
  | nil   | nil     nil     nil   |
  | true  | nil     nil     nil   |
  | false | nil     nil     true  |
  +-------+-----------------------+

=back

=head2 Ternary Operators

=over 4

=item add

B<Add>ition.

  add A, B, C
  +-------+---+---------------------------+
  |   A   | B | C   false   nil     true  |
  |       |   +---+-----------------------+
  | false | false | nil     true    false |
  | false | nil   | true    false   nil   |
  | false | true  | false   nil     true  |
  |       |       |                       |
  | nil   | false | true    false   nil   |
  | nil   | nil   | false   nil     true  |
  | nil   | true  | nil     true    false |
  |       |       |                       |
  | true  | false | false   nil     true  |
  | true  | nil   | nil     true    false |
  | true  | true  | true    false   nil   |
  +-------+-------+-----------------------+

=item addc

B<Add>ition B<c>arry.

  addc A, B, C
  +-------+---+---------------------------+
  |   A   | B | C   false   nil     true  |
  |       |   +---+-----------------------+
  | false | false | false   false   nil   |
  | false | nil   | false   nil     nil   |
  | false | true  | nil     nil     nil   |
  |       |       |                       |
  | nil   | false | false   nil     nil   |
  | nil   | nil   | nil     nil     nil   |
  | nil   | true  | nil     nil     true  |
  |       |       |                       |
  | true  | false | nil     nil     nil   |
  | true  | nil   | nil     nil     true  |
  | true  | true  | nil     true    true  |
  +-------+-------+-----------------------+

=item addcu

B<Add>ition B<c>arry (B<u>nbalanced).

  addcu A, B, C
  +-------+---+---------------------------+
  |   A   | B | C   nil     true    false |
  |       |   +---+-----------------------+
  | nil   | nil   | nil     nil     nil   |
  | nil   | true  | nil     nil     true  |
  | nil   | false | nil     true    true  |
  |       |       |                       |
  | true  | nil   | nil     nil     true  |
  | true  | true  | nil     true    true  |
  | true  | false | true    true    true  |
  |       |       |                       |
  | false | nil   | nil     true    true  |
  | false | true  | true    true    true  |
  | false | false | true    true    false |
  +-------+-------+-----------------------+

=item addcv

B<Add>ition B<c>arry (negatiB<v>e base).

  addcv A, B, C
  +-------+---+---------------------------+
  |   A   | B | C   nil     true    false |
  |       |   +---+-----------------------+
  | nil   | nil   | nil     nil     true  |
  | nil   | true  | nil     nil     nil   |
  | nil   | false | nil     false   nil   |
  |       |       |                       |
  | true  | nil   | nil     nil     nil   |
  | true  | true  | nil     false   nil   |
  | true  | false | false   false   nil   |
  |       |       |                       |
  | false | nil   | nil     false   nil   |
  | false | true  | false   false   nil   |
  | false | false | false   false   false |
  +-------+-------+-----------------------+

=item addcx

B<Add>ition B<c>arry (miB<x>ed base).

For multiplication in base(-3), an addition of two trits 0..2 and one
trit -1..1 can be useful.  Addcx computes a signed carry trit for this
kind of addition.

  addcx A, B, C
  +-------+---+---------------------------+
  |   A   | B | C   nil     true    false |
  |       |   +---+-----------------------+
  | nil   | nil   | nil     nil     true  |
  | nil   | true  | nil     nil     nil   |
  | nil   | false | true    nil     true  |
  |       |       |                       |
  | true  | nil   | nil     nil     nil   |
  | true  | true  | nil     false   nil   |
  | true  | false | nil     nil     true  |
  |       |       |                       |
  | false | nil   | nil     false   nil   |
  | false | true  | false   false   nil   |
  | false | false | nil     nil     nil   |
  +-------+-------+-----------------------+

=item subt

B<Subt>raction.

  subt A, B, C
  +-------+---+---------------------------+
  |   A   | B | C   false   nil     true  |
  |       |   +---+-----------------------+
  | false | false | true    nil     false |
  | false | nil   | nil     false   true  |
  | false | true  | false   true    nil   |
  |       |       |                       |
  | nil   | false | false   true    nil   |
  | nil   | nil   | true    nil     false |
  | nil   | true  | nil     false   true  |
  |       |       |                       |
  | true  | false | nil     false   true  |
  | true  | nil   | false   true    nil   |
  | true  | true  | true    nil     false |
  +-------+-------+-----------------------+

=item subc

B<Sub>traction B<c>arry.

  subc A, B, C
  +-------+---+---------------------------+
  |   A   | B | C   false   nil     true  |
  |       |   +---+-----------------------+
  | false | false | nil     nil     nil   |
  | false | nil   | nil     nil     true  |
  | false | true  | nil     true    true  |
  |       |       |                       |
  | nil   | false | false   nil     nil   |
  | nil   | nil   | nil     nil     nil   |
  | nil   | true  | nil     nil     true  |
  |       |       |                       |
  | true  | false | false   false   nil   |
  | true  | nil   | false   nil     nil   |
  | true  | true  | nil     nil     nil   |
  +-------+-------+-----------------------+

=item subcu

B<Sub>traction B<c>arry (B<u>nbalanced).

  subcu A, B, C
  +-------+---+---------------------------+
  |   A   | B | C   nil     true    false |
  |       |   +---+-----------------------+
  | nil   | nil   | nil     true    true  |
  | nil   | true  | true    true    true  |
  | nil   | false | true    true    false |
  |       |       |                       |
  | true  | nil   | nil     nil     true  |
  | true  | true  | nil     true    true  |
  | true  | false | true    true    true  |
  |       |       |                       |
  | false | nil   | nil     nil     nil   |
  | false | true  | nil     nil     true  |
  | false | false | nil     true    true  |
  +-------+-------+-----------------------+

=item subcv

B<Sub>traction B<c>arry (negatiB<v>e base).

  subcv A, B, C
  +-------+---+---------------------------+
  |   A   | B | C   nil     true    false |
  |       |   +---+-----------------------+
  | nil   | nil   | nil     false   nil   |
  | nil   | true  | false   false   nil   |
  | nil   | false | false   false   false |
  |       |       |                       |
  | true  | nil   | nil     nil     nil   |
  | true  | true  | nil     false   nil   |
  | true  | false | false   false   nil   |
  |       |       |                       |
  | false | nil   | nil     nil     true  |
  | false | true  | nil     nil     nil   |
  | false | false | nil     false   nil   |
  +-------+-------+-----------------------+

=item cmin

Ternary B<c>omparison to B<min>imum.

  cmin A, B, C
  +-------+---+---------------------------+
  |   A   | B | C   false   nil     true  |
  |       |   +---+-----------------------+
  | false | false | nil     nil     nil   |
  | false | nil   | nil     nil     nil   |
  | false | true  | nil     false   false |
  |       |       |                       |
  | nil   | false | nil     nil     nil   |
  | nil   | nil   | nil     nil     nil   |
  | nil   | true  | true    false   false |
  |       |       |                       |
  | true  | false | true    true    false |
  | true  | nil   | true    true    false |
  | true  | true  | true    true    false |
  +-------+-------+-----------------------+

=item cmed

Ternary B<c>omparison to B<med>ian.

  cmed A, B, C
  +-------+---+---------------------------+
  |   A   | B | C   false   nil     true  |
  |       |   +---+-----------------------+
  | false | false | true    true    false |
  | false | nil   | true    true    false |
  | false | true  | true    nil     nil   |
  |       |       |                       |
  | nil   | false | true    true    false |
  | nil   | nil   | true    true    false |
  | nil   | true  | false   true    nil   |
  |       |       |                       |
  | true  | false | nil     nil     true  |
  | true  | nil   | nil     nil     true  |
  | true  | true  | false   false   true  |
  +-------+-------+-----------------------+

=item cmax

Ternary B<c>omparison to B<max>imum.

  cmax A, B, C
  +-------+---+---------------------------+
  |   A   | B | C   false   nil     true  |
  |       |   +---+-----------------------+
  | false | false | false   false   true  |
  | false | nil   | false   false   true  |
  | false | true  | false   true    true  |
  |       |       |                       |
  | nil   | false | false   false   true  |
  | nil   | nil   | false   false   true  |
  | nil   | true  | nil     nil     true  |
  |       |       |                       |
  | true  | false | false   false   nil   |
  | true  | nil   | false   false   nil   |
  | true  | true  | nil     nil     nil   |
  +-------+-------+-----------------------+

=item cvld

Ternary B<c>omparison B<v>aB<l>iB<d>ation.

  +-------+---+---------------------------+
  |   A   | B | C   false   nil     true  |
  |       |   +---+-----------------------+
  | false | false | true    true    true  |
  | false | nil   | nil     nil     true  |
  | false | true  | false   nil     true  |
  |       |       |                       |
  | nil   | false | true    nil     nil   |
  | nil   | nil   | nil     true    nil   |
  | nil   | true  | nil     nil     true  |
  |       |       |                       |
  | true  | false | true    nil     false |
  | true  | nil   | true    nil     nil   |
  | true  | true  | true    true    true  |
  +-------+-------+-----------------------+

=item min

B<Min>imum of three.

  min A, B, C
  +-------+---+---------------------------+
  |   A   | B | C   false   nil     true  |
  |       |   +---+-----------------------+
  | false | false | false   false   false |
  | false | nil   | false   false   false |
  | false | true  | false   false   false |
  |       |       |                       |
  | nil   | false | false   false   false |
  | nil   | nil   | false   nil     nil   |
  | nil   | true  | false   nil     nil   |
  |       |       |                       |
  | true  | false | false   false   false |
  | true  | nil   | false   nil     nil   |
  | true  | true  | false   nil     true  |
  +-------+-------+-----------------------+

=item med

B<Med>ian of three.

  med A, B, C
  +-------+---+---------------------------+
  |   A   | B | C   false   nil     true  |
  |       |   +---+-----------------------+
  | false | false | false   false   false |
  | false | nil   | false   nil     nil   |
  | false | true  | false   nil     true  |
  |       |       |                       |
  | nil   | false | false   nil     nil   |
  | nil   | nil   | nil     nil     nil   |
  | nil   | true  | nil     nil     true  |
  |       |       |                       |
  | true  | false | false   nil     true  |
  | true  | nil   | nil     nil     true  |
  | true  | true  | true    true    true  |
  +-------+-------+-----------------------+

=item max

B<Max>imum of three.

  max A, B, C
  +-------+---+---------------------------+
  |   A   | B | C   false   nil     true  |
  |       |   +---+-----------------------+
  | false | false | false   nil     true  |
  | false | nil   | nil     nil     true  |
  | false | true  | true    true    true  |
  |       |       |                       |
  | nil   | false | nil     nil     true  |
  | nil   | nil   | nil     nil     true  |
  | nil   | true  | true    true    true  |
  |       |       |                       |
  | true  | false | true    true    true  |
  | true  | nil   | true    true    true  |
  | true  | true  | true    true    true  |
  +-------+-------+-----------------------+

=item minu

B<Min>imum of three (B<u>nbalanced).

  minu A, B, C
  +-------+---+---------------------------+
  |   A   | B | C   nil     true    false |
  |       |   +---+-----------------------+
  | nil   | nil   | nil     nil     nil   |
  | nil   | true  | nil     nil     nil   |
  | nil   | false | nil     nil     nil   |
  |       |       |                       |
  | true  | nil   | nil     nil     nil   |
  | true  | true  | nil     true    true  |
  | true  | false | nil     true    true  |
  |       |       |                       |
  | false | nil   | nil     nil     nil   |
  | false | true  | nil     true    true  |
  | false | false | nil     true    false |
  +-------+-------+-----------------------+

=item medu

B<Med>ian of three (B<u>nbalanced).

  medu A, B, C
  +-------+---+---------------------------+
  |   A   | B | C   nil     true    false |
  |       |   +---+-----------------------+
  | nil   | nil   | nil     nil     nil   |
  | nil   | true  | nil     true    true  |
  | nil   | false | nil     true    false |
  |       |       |                       |
  | true  | nil   | nil     true    true  |
  | true  | true  | true    true    true  |
  | true  | false | true    true    false |
  |       |       |                       |
  | false | nil   | nil     true    false |
  | false | true  | true    true    false |
  | false | false | false   false   false |
  +-------+-------+-----------------------+

=item maxu

B<Max>imum of three (B<u>nbalanced).

  maxu A, B, C
  +-------+---+---------------------------+
  |   A   | B | C   nil     true    false |
  |       |   +---+-----------------------+
  | nil   | nil   | nil     true    false |
  | nil   | true  | true    true    false |
  | nil   | false | false   false   false |
  |       |       |                       |
  | true  | nil   | true    true    false |
  | true  | true  | true    true    false |
  | true  | false | false   false   false |
  |       |       |                       |
  | false | nil   | false   false   false |
  | false | true  | false   false   false |
  | false | false | false   false   false |
  +-------+-------+-----------------------+

=item ipqc

B<I>nterB<p>olation B<q>uadratic B<c>oefficient.

In modulo 3 arithmetic, a polynomial with values I<A, B, C> at positions
I<0, 1, 2> can be computed as I<-(A + B + C) * x * x + (C - B) * x + A>.
For that reason, the negated sum of three trits modulo 3 has got the
funny name ipqc.

  ipqc A, B, C
  +-------+---+---------------------------+
  |   A   | B | C   false   nil     true  |
  |       |   +---+-----------------------+
  | false | false | nil     false   true  |
  | false | nil   | false   true    nil   |
  | false | true  | true    nil     false |
  |       |       |                       |
  | nil   | false | false   true    nil   |
  | nil   | nil   | true    nil     false |
  | nil   | true  | nil     false   true  |
  |       |       |                       |
  | true  | false | true    nil     false |
  | true  | nil   | nil     false   true  |
  | true  | true  | false   true    nil   |
  +-------+-------+-----------------------+

=back

=head2 Quarternary Operators

=over 4

=item sum

B<Sum>mation.

A result trit and a carry trit can hold the sum of three operand trits and
a carry trit.  Thus, addition of three numerical values can be implemented
efficiently in ternary arithmetic based on this super addition operator
with four trit arguments.

  sum A, B, C, D
  +-------+---+---------------------------+
  |   A   | B | C   f f f   n n n   t t t |
  |       |   +---------------------------+
  |       |   | D   f n t   f n t   f n t |
  |       |   +---+-----------------------+
  | false | false | f n t   n t f   t f n |
  | false | nil   | n t f   t f n   f n t |
  | false | true  | t f n   f n t   n t f |
  |       |       |                       |
  | nil   | false | n t f   t f n   f n t |
  | nil   | nil   | t f n   f n t   n t f |
  | nil   | true  | f n t   n t f   t f n |
  |       |       |                       |
  | true  | false | t f n   f n t   n t f |
  | true  | nil   | f n t   n t f   t f n |
  | true  | true  | n t f   t f n   f n t |
  +-------+-------+-----------------------+

=item sumc

B<Sum>mation B<c>arry.

  sumc A, B, C, D
  +-------+---+---------------------------+
  |   A   | B | C   f f f   n n n   t t t |
  |       |   +---------------------------+
  |       |   | D   f n t   f n t   f n t |
  |       |   +---+-----------------------+
  | false | false | f f f   f f n   f n n |
  | false | nil   | f f n   f n n   n n n |
  | false | true  | f n n   n n n   n n t |
  |       |       |                       |
  | nil   | false | f f n   f n n   n n n |
  | nil   | nil   | f n n   n n n   n n t |
  | nil   | true  | n n n   n n t   n t t |
  |       |       |                       |
  | true  | false | f n n   n n n   n n t |
  | true  | nil   | n n n   n n t   n t t |
  | true  | true  | n n t   n t t   t t t |
  +-------+-------+-----------------------+

=item sumcu

B<Sum>mation B<c>arry (B<u>nbalanced).

  sumcu A, B, C, D
  +-------+---+---------------------------+
  |   A   | B | C   n n n   t t t   f f f |
  |       |   +---------------------------+
  |       |   | D   n t f   n t f   n t f |
  |       |   +---+-----------------------+
  | nil   | nil   | n n n   n n t   n t t |
  | nil   | true  | n n t   n t t   t t t |
  | nil   | false | n t t   t t t   t t f |
  |       |       |                       |
  | true  | nil   | n n t   n t t   t t t |
  | true  | true  | n t t   t t t   t t f |
  | true  | false | t t t   t t f   t f f |
  |       |       |                       |
  | false | nil   | n t t   t t t   t t f |
  | false | true  | t t t   t t f   t f f |
  | false | false | t t f   t f f   f f f |
  +-------+-------+-----------------------+

=item mpx

B<M>ultiB<p>leB<x>.  The first argument determines which one of the
other arguments to return.

  mpx A, B, C, D
  +-------+---+---------------------------+
  |   A   | B | C   n n n   t t t   f f f |
  |       |   +---------------------------+
  |       |   | D   n t f   n t f   n t f |
  |       |   +---+-----------------------+
  | nil   | nil   | n n n   n n n   n n n |
  | nil   | true  | t t t   t t t   t t t |
  | nil   | false | f f f   f f f   f f f |
  |       |       |                       |
  | true  | nil   | n n n   t t t   f f f |
  | true  | true  | n n n   t t t   f f f |
  | true  | false | n n n   t t t   f f f |
  |       |       |                       |
  | false | nil   | n t f   n t f   n t f |
  | false | true  | n t f   n t f   n t f |
  | false | false | n t f   n t f   n t f |
  +-------+-------+-----------------------+

=item generic

C<$trit-E<gt>generic($op_name, @args)> evaluates a generic operator with
the given arguments.

Generic operator names consist of a letter and a number of digits from
0 to 2.  Each letter stands for an operator signature and determines
the number of digits completely describing the operator.  The digits
are mapped to trits I<nil>, I<true>, I<false>, as with L<from_int_u>.

B<c> - constant, 1 digit designating the constant.
Example: B<c1> is equivalent to B<true>.

B<u> - unary operator, 3 digits designating the result from I<nil>,
I<true>, I<false>.  Example: B<u021> is equivalent to B<not>.

B<b> - binary operator, 9 digits designating the result from 9 possible
pairs of input trits.  Example: B<b000021012> is equivalent to B<xor>.

B<s> - symmetric ternary operator, 10 digits designating the result from
10 possible combinations of input trits (only enumerating the lexically
first instance of permutations).  Example: B<s0122010120> is equivalent
to B<add>.

B<t> - ternary operator, 27 digits designating the result from
27 possible triples of input trits (lexically sorted).  Example:
B<t000010002002000202010110000> is equivalent to B<subc>.

B<q> - symmetric quaternary operator, 15 digits designating the result
from 15  possible combinations of input trits (only enumerating the
lexically first instance of permutations).  Example: B<q000102100211022>
is equivalent to B<sumc>.

B<Q> - quaternary operator, 81 digits designating the result from 81
possible quadruples of input trits (lexically sorted).

=back

=head2 Math::Logic::Ternary::Object Role Methods

=over 4

=item Trit

Trit inspection:
C<$trit-E<gt>Trit($n)> returns C<$trit> if C<$n> is 0, otherwise I<nil>.

=item Trits

Trit inspection:
C<$trit-E<gt>Trits> returns C<($trit)>, a list with one element.

=item Rtrits

C<$trit-E<gt>Rtrits> returns an empty list if C<$trit> is I<nil>,
otherwise C<($trit)>, a list with one element.

=item Sign

C<$trit-E<gt>Sign> returns C<$trit>.

=item as_int

C<$trit-E<gt>as_int> returns an integer number, 0 for I<nil>, 1 for
I<true>, and -1 for I<false>.

=item as_int_u

=item as_int_v

=item res_mod3

C<$trit-E<gt>as_int_u> returns an integer number, 0 for I<nil>, 1 for I<true>,
and 2 for I<false>.
C<$trit-E<gt>as_int_v> does the same.
C<$trit-E<gt>res_mod3> does the same.

=item as_string

C<$trit-E<gt>as_string> returns a string, C<'$nil'> for I<nil>,
C<'$true'> for I<true>, and C<'$false'> for I<false>.

=item is_equal

C<$trit-E<gt>is_equal($obj)> returns true if C<$trit-E<gt>Rtrits>
and C<$obj-E<gt>Rtrits> are identical lists, otherwise false.
This means a single trit is regarded as equal to itself and any
word with the same least significant trit and no other non-I<nil> trits.

=back

=head2 Other Object Methods

=over 4

=item Mpx

Multiplex.  C<$trit-E<gt>Mpx($case_n, $case_t, $case_f)> with three
arbitrary arguments returns C<$case_n> if C<$trit> is nil, C<$case_t>
if C<$trit> is true, or C<$case_f> if C<$trit> is false.

=item is_nil

C<$trit-E<gt>is_nil> returns boolean true if C<$trit> is nil, otherwise
false.

=item is_true

C<$trit-E<gt>is_true> returns boolean true if C<$trit> is true,
otherwise false.

=item is_false

C<$trit-E<gt>is_false> returns boolean true if C<$trit> is false,
otherwise false.

=item as_bool

C<$trit-E<gt>as_bool> returns I<undef> if C<$trit> is I<nil>, C<1>
(boolean true) if $trit is I<true>, or an empty string (boolean false)
if C<$trit> is I<false>.

=item as_modint

C<$trit-E<gt>as_modint> converts C<$trit> to a Math::ModInt object,
mapping I<nil> to I<mod(0, 3)>, I<true> to I<mod(1, 3)>, and I<false>
to I<mod(2, 3)>.

The Perl extension Math::ModInt (available on CPAN) must be installed
for this to work, otherwise I<as_modint> will raise a run-time exception.

=back

=head2 Constructors

All constructors are class methods.  They may raise an exception when
called with unexpected arguments.

=over 4

=item from_bool

C<Math::Logic::Ternary-E<gt>from_bool($arg)> returns I<nil> if C<$arg>
is undefined, I<false> if C<$arg> is defined but false, or I<true>
if C<$arg> is true.

=item from_sign

C<Math::Logic::Ternary-E<gt>from_sign($int)> returns I<nil> if C<$int> is
zero, I<true> if C<$int> is positive, or I<false> if C<$int> is negative.

=item from_remainder

C<Math::Logic::Ternary-E<gt>from_remainder($int)> returns I<nil> if
C<$int> is equivalent to 0 (modulo 3), I<true> if C<$int> is equivalent
to 1 (modulo 3), or I<false> if C<$int> is equivalent to 2 (modulo 3).

=item from_int

C<Math::Logic::Ternary-E<gt>from_int($int)> returns I<nil> if C<$int>
is 0, I<true> if C<$int> is 1, or I<false> if C<$int> is -1.

=item from_int_u

C<Math::Logic::Ternary-E<gt>from_int_u($int)> returns I<nil> if C<$int>
is 0, I<true> if C<$int> is 1, or I<false> if C<$int> is 2.

=item from_string

C<Math::Logic::Ternary-E<gt>from_string($str)> returns I<nil> if C<$str>
is C<'nil'> or C<'$nil'>, I<true> if C<$str> is C<'true'> or C<'$true'>,
and I<false> if C<$str> is C<'false'> or C<'$false'>.

=item from_modint

C<Math::Logic::Ternary-E<gt>from_modint($obj)> returns I<nil> or I<true>
or I<false> if C<$obj> is a Math::ModInt object and C<$obj-E<gt>modulus>
is 3.  A residue of 0, 1, or 2 maps to I<nil>, I<true>, or I<false>,
respectively.

=item from_various

C<Math::Logic::Ternary-E<gt>from_various($arg)> guesses the type of
its argument and calls one of the more specific constructors (but not
from_remainder).

=back

=head2 Other Class Methods

=over 4

=item make_generic

C<Math::Logic::Ternary-E<gt>make_generic($op_name)> returns an operator
coderef defined by a generic operator name.  It can subsequently be
called as a method on trits.

Example:

  $foo = Math::Logic::Ternary::Trit->make_generic('b021210102');
  $bar = true->$foo(false);     # $bar = nil
  $bar = $foo->(true, false);   # $bar = nil

On the syntax of generic operator names, see L</generic>.

=item trit_operators

C<Math::Logic::Ternary-E<gt>trit_operators> returns a list of listrefs
with all currently implemented named trit operators with these contents:

  [$name, $min_args, $var_args, $ret_vals, $arithmetic]

C<$name> is the name of the operator, C<$min_args> is the minimum
number of arguments, C<$var_args> is the number of optional arguments,
C<$ret_vals> is the number of return values, C<$arithmetic> is undefined
unless the operator is an arithmetic operator belonging to balanced
(= 0), unbalanced (= 1), or negative base (= 2) arithmetic.

Currently, C<$var_args> will be 0 and C<$ret_vals> will be 1 for all
list entries.  This may change in future releases.

=back

=head1 DIAGNOSTICS

=over 4

=item unknown operator name "%s"

L</generic> or L</make_generic> was called with an invalid operator name.

=item too few arguments, expected %d more

An operator was called with too few operands.

=item integer "%d" out of range %d..%d

A constructor taking an integer argument was called with an argument
outside its defined range.

=item unknown trit name "%s"

L</from_string> was called with an invalid trit name.

=item modular integer with modulus 3 expected

L</from_modint> was called with an invalid argument, either a modular
integer with a modulus other than 3 or not a Math::ModInt object at all.

=item cannot convert %s to a trit

L</from_various> was called with an invalid argument.

=item perl extension Math::ModInt is not available

L</as_modint> was called on a platform where Math::ModInt can not be loaded.
Installing L<Math::ModInt> from CPAN should resolve this problem.

=back

=head1 SEE ALSO

=over 4

=item L<Math::Logic::Ternary>

=item L<Math::Logic::Ternary::Object>

=item L<Math::Logic::Ternary::Word>

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
