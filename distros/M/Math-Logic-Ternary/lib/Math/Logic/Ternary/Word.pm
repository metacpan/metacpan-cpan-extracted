# Copyright (c) 2012-2017 Martin Becker, Blaubeuren.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

package Math::Logic::Ternary::Word;

use 5.008;
use strict;
use warnings;
use Carp qw(croak);
use Scalar::Util qw(blessed);
use Role::Basic qw(with);
use Math::BigInt;
use Math::Logic::Ternary::Trit;
with qw(Math::Logic::Ternary::Object);

# ----- static data -----

our $VERSION = '0.004';
our @CARP_NOT = qw(Math::Logic::Ternary);

use constant MAX_SIZE      => 19683;
use constant MAX_IV_SIZE   => 18;
use constant W_SIZE        => 0;
use constant W_TRITS       => 1;
use constant TRIT_PREFIX   => Math::Logic::Ternary::Trit::TRIT_PREFIX();
use constant BASE3_PREFIX  => '@';
use constant BASE27_PREFIX => '%';

my $zero = Math::Logic::Ternary::Trit->nil;
my $one  = Math::Logic::Ternary::Trit->true;
my $two  = Math::Logic::Ternary::Trit->false;
my @int_trits = ($zero, $one, $two);

my @base3_chars = qw(n t f);
my %base3_trits =
    map {
        my $ch = $base3_chars[$_->as_int_u];
        (lc $ch => $_, uc $ch => $_)
    } @int_trits;
my @base27_chars = qw(_ a b c d e f g h i j k l m N O P Q R S T U V W X Y Z);
my %base27_words =
    map {
        my $ch = $base27_chars[$_];
        my $w  = Math::Logic::Ternary::Word->from_int(3, $_);
        (lc $ch => $w, uc $ch => $w)
    } -13..13;
my @comparison_relations = (
    [gt => 'eqt'],
    [lt => 'eqf'],
    [ge => 'nef'],
    [le => 'net'],
);
my @suffixes  = ('',  'u',  'v');
my @_suffixes = ('', '_u', '_v');

my @word_operators = (
    ['Neg',    'W',  'W',  0],
    ['Negv',   'Wt', 'WT', 2],
    ['Lshift', 'Wt', 'WT'],
    ['Rshift', 'Wt', 'WT'],
    (
        map {
            my ($i, $sfx) = ($_, $suffixes[$_]);
            ["Sign$sfx",  'W',   'T',   $i],
            ["Incr$sfx",  'Wt',  'WT',  $i],
            ["Decr$sfx",  'Wt',  'WT',  $i],
            ["Dpl$sfx",   'Wt',  'WT',  $i],
            (
                map {
                    ["$_$sfx", 'WWt', 'T', $i]
                } qw(Cmp Asc Gt Lt Ge Le)
            ),
            ["Sort2$sfx", 'WW',  'WW',   $i],
            ["Tlr$sfx",   'WW',  'W',    $i],
            ["Tgr$sfx",   'WW',  'W',    $i],
            ["Add$sfx",   'WWt', 'WT',   $i],
            ["Subt$sfx",  'WWt', 'WT',   $i],
            ["Sort3$sfx", 'WWW', 'WWW',  $i],
            ["Min$sfx",   'WWW', 'W',    $i],
            ["Med$sfx",   'WWW', 'W',    $i],
            ["Max$sfx",   'WWW', 'W',    $i],
            ["Mul$sfx",   'WWw', 'WW' . ('v' eq $sfx && 'T'), $i],
            ["Div$sfx",   'WW',  'WWT',  $i],
            ["Ldiv$sfx",  'WWW', 'WWWT', $i],
        } 0 .. $#suffixes
    ),
    (
        map {
            my ($i, $sfx) = ($_, $suffixes[$_]);
#           ["Hlv$sfx",   'Wt',   'WT',  $i],
#           ["Amn$sfx",   'WWt',  'WT',  $i],
            ["Sum$sfx",   'WWWt', 'WT',  $i],
        } 0, 1
    ),
    ['Mpx',  'WWWW', 'W' ],
);
my @word_formatters = (
    ['as_string'],
    ['as_base27'],
    (
        map {
            my ($i, $_sfx) = ($_, $_suffixes[$_]);
            ["as_int$_sfx",    $i],
            ["as_modint$_sfx", $i],
        } 0 .. $#_suffixes
    ),
);

my $modint_loaded = 0;

# ----- other initializations -----

_load_generated_methods();

# ----- private subroutines -----

sub _declare {
    my ($name, $ref) = @_;
    my $fqname = __PACKAGE__ . '::' . $name;
    no strict 'refs';
    *{$fqname} = $ref;
}

sub _parse_int {
    my ($class, $size, $int, $tval, $base) = @_;
    croak 'missing size information'  if !$size;
    croak 'integer argument expected' if $int !~ /^[-+]?\d+\z/;
    if ($size > MAX_IV_SIZE && !ref $int) {
        $int = Math::BigInt->new($int);
    }
    my @trits = ();
    while ($int) {
        croak "number too large for word size $size" if $size <= @trits;
        my $trit = $int_trits[$int % 3];
        $int = ($int - $trit->$tval) / $base;
        push @trits, $trit;
    }
    return $class->from_trits($size, @trits);
}

sub _parse_base {
    my ($class, $size, $string, $base, $thash) = @_;
    my @words =
        map {
            exists($thash->{$_}) ? $thash->{$_} :
            q[ ] eq $_           ? ()           :
            croak qq{illegal base$base character "$_"}
        }
        split //, reverse $string;
    return $class->from_words($size, @words);
}

sub _as_int {
    my ($this, $tval, $base) = @_;
    my ($size, $trits) = @{$this}[W_SIZE, W_TRITS];
    my $int = $size <= MAX_IV_SIZE? 0: Math::BigInt->new(0);
    foreach my $trit (reverse @{$trits}) {
        $int = $int * $base + $trit->$tval;
    }
    return $int;
}

sub _modulus {
    my ($size) = @_;
    my $modulus = ($size <= MAX_IV_SIZE? 3: Math::BigInt->new(3)) ** $size;
    return $modulus;
}

sub _max_int_v {
    my ($size) = @_;
    my $max_int_v =  $size <= MAX_IV_SIZE? 0: Math::BigInt->new(0);
    for (my $exp = 0; $exp < $size; $exp += 2) {
        $max_int_v = $max_int_v * 9 + 2;
    }
    return $max_int_v;
}

sub _as_modint {
    my ($this, $residue) = @_;
    my $size = $this->Trits;
    if (!$modint_loaded) {
        require Math::ModInt;
        $modint_loaded = 1;
    }
    return Math::ModInt->new($residue, _modulus($size));
}

sub _check_modint_modulus {
    my ($size, $modint) = @_;
    my $given_mod = $modint->modulus;
    if ($size) {
        my ($wanted_mod) = _modulus($size);
        if ($given_mod != $wanted_mod) {
            croak qq{wrong modulus for this size, expected $wanted_mod};
        }
    }
    else {
        my $power = $given_mod;
        $size = 0;
        while (1) {
            croak qq{modulus is not a power of 3} if 0 != $power % 3;
            $power /= 3;
            ++$size;
            last if $power <= 1;
        }
    }
    return $size;
}

# ascending trits iterator factory
sub _trits_asc {
    my ($this) = @_;
    my $i = 0;
    return sub { $this->Trit($i++) };
}

# descending trits iterator factory, takes number of trits
sub _trits_desc {
    my ($this, $i) = @_;
    return sub { $this->Trit(--$i) };
}

# logical operator factory, takes number of operands and a name
sub _logical {
    my ($argc, $op) = @_;
    return sub {
        my $this = shift;
        my @args = map { $_->Sign } @_;
        return $this->Sign->$op(@args);
    };
}

# tritwise operator factory, takes number of operands and a name
sub _tritwise {
    my ($argc, $op) = @_;
    return sub {
        my $this = shift;
        my @args = map { _trits_asc($_) } @_;
        my @trits = map { $_->$op(map { $_->() } @args) } $this->Trits;
        return $this->convert_trits(@trits);
    };
}

# lower to higher significance cascading numerical operator factory
# takes argument count and names of principal and carry operator
# and optional default carry trit
# resulting op takes given number of numerical arguments and optional
# carry trit, by default 0, and returns numerical result and carry trit
sub _cascading {
    my ($arity, $op, $cop, $default_carry) = (@_, $zero);
    return sub {
        croak "missing arguments" if @_ < $arity;
        croak "array context expected" if !wantarray;
        my $this    = shift;
        my @those   = map { (shift)->_trits_asc } 2..$arity;
        my ($carry) = (@_, $default_carry);
        my @trits   = $this->Trits;
        foreach my $trit (@trits) {
            my @args = map { $_->() } @those;
            ($trit, $carry) =
                ($trit->$op(@args, $carry), $trit->$cop(@args, $carry));
        }
        return ($this->convert_trits(@trits), $carry);
    };
}

# # higher to lower significance extended cascading operator factory
# # takes names of three logical operators (result trit, carry trit, second
# # carry trit) and numeric addition operator
# # resulting op takes given number of numerical arguments and optional
# # carry trits and returns numerical result and carry trits
# sub _ext_casc {
#     my ($arity, $op, $cop, $sop, $Aop) = @_;
#     return sub {
#         croak "missing arguments" if @_ < $arity;
#         croak "array context expected" if !wantarray;
#         my $this    = shift;
#         my $wsiz    = $this->Trits;
#         my @those   = map { (shift)->_trits_dsc($wsiz) } 2..$arity;
#         my ($carry, $sec_carry) = (@_, $zero, $zero);
#         my @trits   = $this->Trits;
#         my @secs    = ();
#         croak 'NYI';
#     };
# }

# higher to lower significance cascading comparison operator factory
# takes name of logical comparison operator and optional name of
# result modifier function
# resulting op takes two numerical arguments and optional carry trit
# and returns result trit
sub _lexical {
    my ($cmp, $map) = @_;
    return sub {
        my ($this, $that, $carry) = @_;
        croak 'missing arguments' if @_ < 2;
        $carry = (2 == @_)? $zero: $carry->Sign;
        my $i  = $this->Trits;
        my $i1 = $this->_trits_desc($i);
        my $i2 = $that->_trits_desc($i);
        while ($carry->is_nil && $i--) {
            $carry = $i1->()->$cmp($i2->());
        }
        return $map? $carry->$map: $carry;
    };
}

# base-3 comparison operator factory
# takes optional name of result modifier function
# resulting op takes two numerical arguments and optional carry trit
# and returns result trit
sub _cmpv {
    my ($map) = @_;
    my @op  = ('cmpu', 'ascu');
    return sub {
        my ($this, $that, $carry) = @_;
        croak 'missing arguments' if @_ < 2;
        $carry = (2 == @_)? $zero: $carry->Sign;
        my $i  = $this->Trits;
        my $i1 = $this->_trits_desc($i);
        my $i2 = $that->_trits_desc($i);
        while ($carry->is_nil && $i--) {
            my $cmp = $op[$i & 1];
            $carry = $i1->()->$cmp($i2->());
        }
        return $map? $carry->$map: $carry;
    }
}

# binary sorting factory
# takes numerical comparison name and one or more rank numbers
# resulting op takes two numerical arguments
# and returns the selected item or items from those
sub _sort2 {
    my ($cmp, @sel) = @_;
    return sub {
        croak 'missing arguments' if @_ < 2;
        croak 'array context expected' if !wantarray;
        my ($this, $that) = @_;
        my $rel = $this->$cmp($that);
        my @items = $rel->is_true? ($that, $this): ($this, $that);
        return @items[@sel];
    };
}

# ternary sorting factory
# takes numerical comparison name and one or more rank numbers
# resulting op takes three numerical arguments
# and returns the selected item or items from those
sub _sort3 {
    my $cmp = shift;
    my @sel = qw(cmin cmed cmax)[@_];
    return sub {
        croak 'missing arguments' if @_ < 3;
        croak 'array context expected' if 1 < @sel && !wantarray;
        my $r01 = $_[0]->$cmp($_[1]);
        my $r02 = $_[0]->$cmp($_[2]);
        my $r12 = $_[1]->$cmp($_[2]);
        return map { $r01->$_($r02, $r12)->Mpx(@_) } @sel;
    };
}

sub _w2i2w {
    my ($sfx) = @_;
    if ('' ne $sfx) {
        $sfx = "_$sfx";
    }
    return ("as_int$sfx", "convert_int$sfx");
}

# create an object like left side holding least significant trits of right side
sub _truncate {
    my ($this, $that) = @_;
    my $size  = $this->Trits;
    my @trits = $that->Rtrits;
    if ($size < @trits) {
        splice @trits, $size;
        while (@trits && $trits[-1]->is_nil) {
            pop @trits;
        }
    }
    return bless [$size, \@trits], ref $this;
}

# COMING_UP (emulated with binary arithmetic for now)
sub _divmod {
    my ($sfx) = @_;
    my $ldiv = "Ldiv$sfx";
    return sub {
        croak 'missing arguments' if @_ < 2;
        croak 'array context expected' if !wantarray;
        my ($this, $that) = @_;
        my ($lsw, $msw, $rem, $err) = $this->$ldiv($zero, $that);
        if ($err->is_nil && $msw->Rtrits) {
            $err = $two;
        }
        return ($lsw, $rem, $err);
    };
}

# COMING_UP (emulated with binary arithmetic for now)
sub _long_divmod {
    my ($sfx) = @_;
    my ($as_int, $convert) = _w2i2w($sfx);
    return sub {
        croak 'missing arguments' if @_ < 3;
        croak 'array context expected' if !wantarray;
        my ($this, $over, $that) = @_;
        my $size = $this->Trits;
        $over = $this->_truncate($over);
        $that = $this->_truncate($that);
        my $acc = Math::Logic::Ternary::Word->from_words(
            $size * 2 + 1, $this, $over
        );
        my $num = $acc->$as_int;
        my $den = $that->$as_int;
        return ($this, $over, $that, $one) if 0 == $den;
        my $rem;
        if ($den < 0) {
            $rem = $num % -$den;
            if ($rem) {
                $rem += $den;
            }
        }
        else {
            $rem = $num % $den;
        }
        my $quot = ($num - $rem) / $den;
        my ($lsw, $msw, $xsw) = $acc->$convert($quot)->Words($size);
        return ($lsw, $msw, $this->$convert($rem), $xsw->Rtrits? $two: $zero);
    };
}

sub _load_generated_methods {
    my @ops = Math::Logic::Ternary::Trit->trit_operators;
    foreach my $opr (@ops) {
        my ($name, $argc) = @{$opr};
        _declare($name, _tritwise($argc, $name));
        _declare(uc($name), _logical($argc, $name));
    }
    *Neg = \&not;
    *Negv = _cascading(1, 'dpl', 'negcv');
    foreach my $sfx ('', 'u') {
        my $asc = "asc$sfx";
        my $cmp = "cmp$sfx";
        _declare(ucfirst($asc), _lexical($asc));
        _declare(ucfirst($cmp), _lexical($cmp));
        foreach my $cr (@comparison_relations) {
            my ($rel, $map) = @{$cr};
            _declare(ucfirst("$rel$sfx"), _lexical($cmp, $map));
        }
    }
    *Cmpv = _cmpv();
    *Ascv = _cmpv('not');
    foreach my $cr (@comparison_relations) {
        my ($rel, $map) = @{$cr};
        _declare(ucfirst($rel . 'v'), _cmpv($map));
    }
    foreach my $sfx ('', 'u', 'v') {
        my $Cmp = "Cmp$sfx";
        _declare("Sort2$sfx", _sort2($Cmp, 0..1));
        _declare(  "Tlr$sfx", _sort2($Cmp, 0));
        _declare(  "Tgr$sfx", _sort2($Cmp, 1));
        _declare("Sort3$sfx", _sort3($Cmp, 0..2));
        _declare(  "Min$sfx", _sort3($Cmp, 0));
        _declare(  "Med$sfx", _sort3($Cmp, 1));
        _declare(  "Max$sfx", _sort3($Cmp, 2));
        _declare( "Incr$sfx", _cascading(1, 'incr', "incc$sfx", $one));
        _declare( "Decr$sfx", _cascading(1, 'decr', "decc$sfx", $one));
        _declare(  "Dpl$sfx", _cascading(1, 'dpl',  "dplc$sfx"));
        _declare(  "Add$sfx", _cascading(2, 'add',  "addc$sfx"));
        _declare( "Subt$sfx", _cascading(2, 'subt', "subc$sfx"));
        _declare(  "Div$sfx", _divmod($sfx));
        _declare( "Ldiv$sfx", _long_divmod($sfx));
        next if 'v' eq $sfx;            # ops below are not not for base(-3)
#       _declare(  "Hlv$sfx",
#           _ext_casc(1, 'hlv', "hlvc$sfx", "hlvs$sfx", "Add$sfx"));
#       _declare(  "Amn$sfx",
#           _ext_casc(2, 'amn', "amnc$sfx", "amns$sfx", "Add$sfx"));
        _declare(  "Sum$sfx", _cascading(3, 'sum',  "sumc$sfx"));
    }
    return;
}

# ----- class methods -----

sub from_trits {
    my ($class, $size, @trits) = @_;
    if (!$size) {
        croak 'missing arguments' if !@trits;
        $size = @trits;
    }
    croak 'illegal size, use 1..' . MAX_SIZE if $size < 1 || MAX_SIZE < $size;
    while (@trits && $trits[-1]->is_nil) {
        pop @trits;
    }
    croak "too many trits for word size $size" if $size < @trits;
    return bless [$size, \@trits], $class;
}

sub from_words {
    my ($class, $size, @words) = @_;
    return $class->from_trits($size, map { $_->Trits } @words);
}

sub from_bools {
    my ($class, $size, @bools) = @_;
    my @trits = map { Math::Logic::Ternary::Trit->from_bool($_) } @bools;
    return $class->from_trits($size, @trits);
}

sub from_int {
    my ($class, $size, $int) = @_;
    return $class->_parse_int($size, $int, 'as_int', 3);
}

sub from_int_u {
    my ($class, $size, $int) = @_;
    croak 'negative number has no unbalanced representation' if $int < 0;
    return $class->_parse_int($size, $int, 'as_int_u', 3);
}

sub from_int_v {
    my ($class, $size, $int) = @_;
    return $class->_parse_int($size, $int, 'as_int_u', -3);
}

sub from_base27 {
    my ($class, $size, $string) = @_;
    if (BASE27_PREFIX eq substr $string, 0, 1) {
        $string = substr $string, 1;
    }
    return $class->_parse_base($size, $string, 27, \%base27_words);
}

sub from_string {
    my ($class, $size, $string) = @_;
    my $prefix = substr $string, 0, 1;
    if (BASE3_PREFIX eq $prefix) {
        $string = substr $string, 1;
        return $class->_parse_base($size, $string, 3, \%base3_trits);
    }
    if (BASE27_PREFIX eq $prefix) {
        $string = substr $string, 1;
        return $class->_parse_base($size, $string, 27, \%base27_words);
    }
    if (TRIT_PREFIX eq $prefix) {
        my $trit = Math::Logic::Ternary::Trit->from_string($string);
        return $size? $class->from_trits($size, $trit): $trit;
    }
    return $class->_parse_base($size, $string, 3, \%base3_trits);
}

sub from_modint {
    my ($class, $size, $modint) = @_;
    $size = _check_modint_modulus($size, $modint);
    return $class->from_int($size, $modint->signed_residue);
}

sub from_modint_u {
    my ($class, $size, $modint) = @_;
    $size = _check_modint_modulus($size, $modint);
    return $class->from_int_u($size, $modint->residue);
}

sub from_modint_v {
    my ($class, $size, $modint) = @_;
    $size = _check_modint_modulus($size, $modint);
    my $modulus   = _modulus($size);
    my $max_int_v = _max_int_v($size);
    my $residue   = $modint->residue;
    my $is_neg    = $max_int_v < $residue;
    $residue -= $modulus if $is_neg;
    return $class->from_int_v($size, $residue);
}

sub from_various {
    my ($class, $size, @args) = @_;
    return $class->from_trits($size) if !@args;
    my $arg  = $args[0];
    my $type = blessed $arg;
    if ($type) {
        return $class->from_words($size, @args)
            if eval { $type->DOES('Math::Logic::Ternary::Object') };
        croak qq{cannot convert multiple "$type" objects into ternary word}
            if 1 < @args;
        return $class->from_int($size, $arg)
            if eval { $type->isa('Math::BigInt') };
        return $class->from_modint($size, $arg)
            if eval { $type->isa('Math::ModInt') };
        croak qq{cannot convert "$type" object into ternary word};
    }
    $type = ref $arg;
    croak qq{cannot convert $type reference into ternary word} if $type;
    return $class->from_bools($size, @args) if 1 < @args;
    my $prefix = substr $arg, 0, 1;
    return $class->from_int($size, $arg) if $prefix =~ /^[\+\-\d]/;
    return $class->from_string($size, $arg);
}

sub word_operators {
    return map {
        my ($name, $sig, $rsig, @more) = @{$_};
        my $min_args = $sig  =~ tr/A-Z//;
        my $var_args = $sig  =~ tr/a-z//;
        my $ret_vals = $rsig =~ tr/A-Z//;
        [$name, $min_args, $var_args, $ret_vals, @more]
    } @word_operators;
}

sub word_formatters { map { [@{$_}] } @word_formatters }

# ----- object methods -----

sub convert_trits {
    my $this = shift;
    my $size = $this->Trits;
    return ref($this)->from_trits($size, @_);
}

sub convert_words {
    my $this = shift;
    my $size = $this->Trits;
    return ref($this)->from_words($size, @_);
}

sub convert_bools {
    my $this = shift;
    my $size = $this->Trits;
    return ref($this)->from_bools($size, @_);
}

sub convert_int {
    my ($this, $int) = @_;
    my $size = $this->Trits;
    return ref($this)->from_int($size, $int);
}

sub convert_int_u {
    my ($this, $int) = @_;
    my $size = $this->Trits;
    return ref($this)->from_int_u($size, $int);
}

sub convert_int_v {
    my ($this, $int) = @_;
    my $size = $this->Trits;
    return ref($this)->from_int_v($size, $int);
}

sub convert_modint {
    my ($this, $modint) = @_;
    my $size = $this->Trits;
    return ref($this)->from_modint($size, $modint);
}

sub convert_modint_u {
    my ($this, $modint) = @_;
    my $size = $this->Trits;
    return ref($this)->from_modint_u($size, $modint);
}

sub convert_modint_v {
    my ($this, $modint) = @_;
    my $size = $this->Trits;
    return ref($this)->from_modint_v($size, $modint);
}

sub convert_base27 {
    my ($this, $string) = @_;
    my $size = $this->Trits;
    return ref($this)->from_base27($size, $string);
}

sub convert_string {
    my ($this, $string) = @_;
    my $size = $this->Trits;
    return ref($this)->from_string($size, $string);
}

sub convert_various {
    my $this = shift;
    my $size = $this->Trits;
    return ref($this)->from_various($size, @_);
}

sub is_equal {
    my ($this, $that) = @_;
    my $rtrits = $this->[W_TRITS];
    return q[] if @{$rtrits} != $that->Rtrits;
    my $pos = @{$rtrits};
    while (--$pos >= 0) {
        return q[] if $rtrits->[$pos]->as_int != $that->Trit($pos)->as_int;
    }
    return 1;
}

sub Rtrits {
    my ($this) = @_;
    my $rtrits = $this->[W_TRITS];
    return @{$rtrits};
}

sub Sign {
    my ($this) = @_;
    my $rtrits = $this->[W_TRITS];
    return @{$rtrits}? $rtrits->[-1]: $zero;
}

sub Signu {
    my ($this) = @_;
    my $rtrits = $this->[W_TRITS];
    return @{$rtrits}? $one: $zero;
}

sub Signv {
    my ($this) = @_;
    my $rtrits = $this->[W_TRITS];
    return @{$rtrits} & 1? $one: @{$rtrits}? $two: $zero;
}

sub Trit {
    my ($this, $pos) = @_;
    my ($size, $trits) = @{$this}[W_SIZE, W_TRITS];
    if ($pos < 0) {
        $pos += $size;
        return $zero if $pos < 0;
    }
    return $pos < @{$trits}? $trits->[$pos]: $zero;
}

sub Trits {
    my ($this) = @_;
    my ($size, $trits) = @{$this}[W_SIZE, W_TRITS];
    return $size if !wantarray;
    return (@{$trits}, ($zero) x ($size - @{$trits}));
}

sub Words {
    my ($this, $size) = @_;
    my $class = ref $this;
    my @trits = $this->Trits;
    my @words = ();
    while (@trits) {
        push @words, $class->from_trits($size, splice @trits, 0, $size);
    }
    return @words;
}

sub as_int   { $_[0]->_as_int('as_int',    3) }
sub as_int_u { $_[0]->_as_int('as_int_u',  3) }
sub as_int_v { $_[0]->_as_int('as_int_u', -3) }
sub res_mod3 { $_[0]->Trit(0)->res_mod3       }

sub as_modint   { $_[0]->_as_modint($_[0]->as_int  ) }
sub as_modint_u { $_[0]->_as_modint($_[0]->as_int_u) }
sub as_modint_v { $_[0]->_as_modint($_[0]->as_int_v) }

sub as_base27 {
    my ($this) = @_;
    my @ints = map { $_->as_int } $this->Words(3);
    return scalar reverse @base27_chars[@ints], BASE27_PREFIX;
}

sub as_string {
    my ($this) = @_;
    my @ints = map { $_->as_int_u } $this->Trits;
    return scalar reverse @base3_chars[@ints], BASE3_PREFIX;
}

sub Mul {
    croak 'missing arguments' if @_ < 2;
    croak 'array context expected' if !wantarray;
    my ($this, $that, $over) = (@_, $zero);
    $that = $this->_truncate($that);
    $over = $this->_truncate($over);
    my $size = $this->Trits;
    my @trits = $over->Rtrits;
    my $i = 0;
    foreach my $a ($this->Rtrits) {
        my $j = $i;
        my $c = $zero;
        foreach my $b ($that->Rtrits) {
            my $p = $a->eqv($b);
            if ($j < @trits) {
                my $t      = $trits[$j];
                $trits[$j] = $p->add( $c, $t);
                $c         = $p->addc($c, $t);
            }
            else {
                $trits[$j] = $p->incr($c);
                $c         = $p->incc($c);
            }
            ++$j;
        }
        while (!$c->is_nil) {
            if ($j < @trits) {
                my $t      = $trits[$j];
                $trits[$j] = $t->incr($c);
                $c         = $t->incc($c);
            }
            else {
                $trits[$j] = $c;
                $c         = $zero;
            }
            ++$j;
        }
        ++$i;
    }
    my @lst = splice @trits, 0, $size;
    return ($this->convert_trits(@lst), $this->convert_trits(@trits));
}

sub Mulu {
    croak 'missing arguments' if @_ < 2;
    croak 'array context expected' if !wantarray;
    my ($this, $that, $over) = (@_, $zero);
    $that = $this->_truncate($that);
    $over = $this->_truncate($over);
    my $size = $this->Trits;
    my @trits = $over->Rtrits;
    my $i = 0;
    foreach my $a ($this->Rtrits) {
        my $j = $i;
        my $c = $zero;
        foreach my $b ($that->Rtrits) {
            my $p  = $a->eqv($b);
            my $pc = $a->mulcu($b);
            if ($j < @trits) {
                my $t      = $trits[$j];
                $trits[$j] = $p->add(  $c, $t);
                $c         = $p->addcu($c, $t)->incr($pc);
            }
            else {
                $trits[$j] = $p->incr( $c);
                $c         = $p->inccu($c)->incr($pc);
            }
            ++$j;
        }
        while (!$c->is_nil) {
            if ($j < @trits) {
                my $t      = $trits[$j];
                $trits[$j] = $t->incr( $c);
                $c         = $t->inccu($c);
            }
            else {
                $trits[$j] = $c;
                $c         = $zero;
            }
            ++$j;
        }
        ++$i;
    }
    my @lst = splice @trits, 0, $size;
    return ($this->convert_trits(@lst), $this->convert_trits(@trits));
}

sub Mulv {
    croak 'missing arguments' if @_ < 2;
    croak 'array context expected' if !wantarray;
    my ($this, $that, $over) = (@_, $zero);
    $that = $this->_truncate($that);
    $over = $this->_truncate($over);
    my $size = $this->Trits;
    my @trits = $over->Rtrits;
    my $i = 0;
    foreach my $a ($this->Rtrits) {
        my $j = $i;
        foreach my $b ($that->Rtrits) {
            my $p  = $a->eqv($b);
            my $pc = $a->mulcu($b)->not;
            my $t  = $j < @trits? $trits[$j]: $zero;
            $trits[$j] = $t->incr($p);
            my $c  = $t->inccu($p)->not;
            my $k  = $j;
            while (!$c->is_nil || !$pc->is_nil) {
                $t         = ++$k < @trits? $trits[$k]: $zero;
                $trits[$k] = $t->add($pc, $c);
                $c         = $t->addcx($pc, $c);
                $pc        = $zero;
            }
            ++$j;
        }
        ++$i;
    }
    my @lst = splice @trits, 0, $size;
    my @mst = splice @trits, 0, $size;
    my ($tt) = (@trits, $zero);
    return ($this->convert_trits(@lst), $this->convert_trits(@mst), $tt);
}

sub Mpx { (shift)->Sign->Mpx(@_) }

# generic logical operator
sub GENERIC {
    my ($this, $op, @args) = @_;
    return $this->Sign->generic($op, map { $_->Sign } @args);
}

# generic tritwise operator
sub generic {
    my ($this, $op, @argws) = @_;
    my $trit_op = Math::Logic::Ternary::Trit->make_generic($op);
    my @args    = map { _trits_asc($_) } @argws;
    my @trits   = map { $trit_op->($_, map { $_->() } @args) } $this->Trits;
    return $this->convert_trits(@trits);
}

sub Lshift {
    croak 'array context expected' if !wantarray;
    my ($this, $carry) = (@_, $zero);
    my @trits = ($carry, $this->Trits);
    $carry = pop @trits;
    return ($this->convert_trits(@trits), $carry);
}

sub Rshift {
    croak 'array context expected' if !wantarray;
    my $this = shift;
    my ($carry, @trits) = @_? ($this->Trits, shift): ($this->Rtrits, $zero);
    return ($this->convert_trits(@trits), $carry);
}

sub min_int   { $_[0]->sf }
sub max_int   { $_[0]->st }
sub min_int_u { $_[0]->sn }
sub max_int_u { $_[0]->sf }

sub min_int_v {
    my ($this) = @_;
    my @trits = map { ($zero, $two)[$_ & 1] } 0 .. $this->Trits - 1;
    return $this->convert_trits(@trits);
}

sub max_int_v {
    my ($this) = @_;
    my @trits = map { ($two, $zero)[$_ & 1] } 0 .. $this->Trits - 1;
    return $this->convert_trits(@trits);
}

1;
__END__
=head1 NAME

Math::Logic::Ternary::Word - fixed-size ternary information compound

=head1 VERSION

This documentation refers to version 0.004 of Math::Logic::Ternary::Word.

=head1 SYNOPSIS

  use Math::Logic::Ternary::Word;

  $a = Math::Logic::Ternary::Word->from_string(9, 'fnttffnnt');
  $a = Math::Logic::Ternary::Word->from_base27(9, 'sea');
  $a = Math::Logic::Ternary::Word->from_int   (9,  -5696);

  $b = $a->Neg;                         # word +5696
  $c = $a->Cmp($b);                     # trit -1
  ($d, $e) = $a->Add($b);               # word 0, carry trit 0
  ($f, $g) = $a->Mul($b);               # word -6832, word -1648
  ($h, $i, $e) = $f->Div($a);           # word +1, word -1136, trit 0
  ($j, $k, $l, $e) = $f->Ldiv($g, $b);  # word -5696, word 0, word 0, trit 0

  @m = $a->Trits;                       # (true, nil, nil, ..., false)
  $n = $a->Size;                        # 9

  print $a->as_int;                     # print -5696
  print $b->as_base27;                  # print '%hVZ'
  print $d->as_string;                  # print '@nnnnnnnnn'

=head1 DESCRIPTION

=head2 Nomenclature

Method naming conventions for Math::Logic::Ternary::Word are as follows:

=over 4

=item Logical operators

Elementary logical operators can be applied in two ways to word objects.
Words can be treated as single trits, so that only their truth values
(read: signs) are taken into account.  Operators with all uppercase
names will treat words in this way.

Logical operators spelled all lowercase, on the other hand, will
work tritwise on all trits of their operands in parallel.  The
least significant trit of the result will be the result of the
operation on the least significant trits of the operands, and
so on up to the most significant trit.

If words of different sizes are mixed in an operation, the leftmost
argument determines the word size in which the operation is carried
out.  Other operands will be padded with I<nil> trits or truncated
accordingly, aligned on their least significant end.

=item Numerical operators

Numerical operators treat their operands as numerical values, which
usually means that different trits in multi-trit-words interfere
with each other in the course of a computation.  Their names are
written in mixed case starting with an uppercase letter.

Most numerical and some logical functions have different variants
for balanced, unbalanced, and baseZ<>(-3) arithmetic, where unbalanced
also means unsigned.  Balanced ternary digits are -1, 0, and 1.
Unbalanced baseZ<>(3) and baseZ<>(-3) ternary digits are 0, 1, and
2.  As balanced ternary numbers are in many cases easier to deal
with than unbalanced or negative base numbers, our naming scheme
prefers the former, giving balanced arithmetic operators short
names, while their unbalanced counterparts get a suffix letter B<u>
or B<U>, and baseZ<>(-3) operators B<v> or B<V>.

=item Comparison functions

Comparisons are the ultimate challenge of standardizing ternary
logic, since there are six ways to assign comparison results to
trit values and six ways to order trit values.  For three-way
comparison results, we continue leaning towards balanced arithmetic
and assign -1 (false) to "less than", 0 (nil) to "equal to" and 1
(true) to "greater than".  We regard false E<lt> nil E<lt> true as
the "natural" trit order, and nil E<lt> true E<lt> false as the
"unbalanced" order.  Again, the latter is flagged with a B<u> or
B<U> suffix.

=item Conversions

Conversions from objects to other data have a name prefix B<to_> or B<To_>
depending on whether they convert a truth value or a word.  The prefix
is followed by a name for the data type they yield.  If there is an
unbalanced or baseZ<>(-3) variant the final suffix is B<_u> or B<_v>,
respectively.  Alien type names are always separated by underscores from
prefixes and suffixes (if there are any).

Conversions from other data to objects have a name prefix B<from_>
or B<From_> depending on whether they yield single trits or words,
followed by a name for the data type they accept.  Again, the
unbalanced and baseZ<>(-3) suffixes are B<_u> and B<_v>, respectively.
These constructors are class methods.

Conversions to and from floating point formats are not implemented
here.  A ternary floating point format with a whole bunch of
operations and conversions is defined in the separate module
Math::Logic::Ternary::TFP_81.

If an operand size does not match the word size of an operator, it is
silently truncated to its least significant trits or padded with leading
zeroes as appropriate.

=back

=head2 Exports

None.

=head2 Complete list of methods

=head3 Logical and tritwise operators

Operators on trits are carried over to word objects in two variants.

Spelled all uppercase they act as pure logical operators, using just
the truth values (read: signs) of their arguments and returning a trit.

Spelled all lowercase they act as tritwise operators, performing the
logical operation on each trit position of the arguments, and returning
a word.

The leftmost argument of a tritwise operator determines the word
size of the operation and thus the size of the result.  In tritwise
operations, all arguments are aligned at the least significant end.
Smaller arguments are padded with nil trits and larger arguments are
truncated at the other end.

Details about trit operators are documented in L<Math::Logic::Ternary::Trit>.

=over 4

=item B<NIL> B<nil>

Nil: Constant nil.
No arguments, one result value.

=item B<TRUE> B<true>

True: Constant true.
No arguments, one result value.

=item B<FALSE> B<false>

False: Constant false.
No arguments, one result value.

=item B<SN> B<sn>

Set to Nil: return nil.
One argument, one result value.

=item B<ST> B<st>

Set to True: return true.
One argument, one result value.

=item B<SF> B<sf>

Set to False: return false.
One argument, one result value.

=item B<ID> B<id>

Identity: return the argument.
One argument, one result value.

=item B<NOT> B<not>

Not.
One argument, one result value.

=item B<UP> B<up>

Up One: increment modulo 3.
One argument, one result value.

=item B<NUP> B<nup>

Not Up: swap nil/false.
One argument, one result value.

=item B<DN> B<dn>

Down One: decrement modulo 3.
One argument, one result value.

=item B<NDN> B<ndn>

Not Down: swap nil/true.
One argument, one result value.

=item B<EQN> B<eqn>

Equal to Nil.
One argument, one result value.

=item B<EQT> B<eqt>

Equal to True.
One argument, one result value.

=item B<EQF> B<eqf>

Equal to False.
One argument, one result value.

=item B<NEN> B<nen>

Not Equal to Nil.
One argument, one result value.

=item B<NET> B<net>

Not Equal to True.
One argument, one result value.

=item B<NEF> B<nef>

Not Equal to False.
One argument, one result value.

=item B<HM> B<hm>

Hamlet: x or not x.
One argument, one result value.

=item B<UHM> B<uhm>

Up & Hamlet.
One argument, one result value.

=item B<DHM> B<dhm>

Down & Hamlet.
One argument, one result value.

=item B<ORN> B<orn>

Or Nil.
One argument, one result value.

=item B<UORN> B<uorn>

Up & Or Nil.
One argument, one result value.

=item B<DORN> B<dorn>

Down & Or Nil.
One argument, one result value.

=item B<QT> B<qt>

Quantum: x and not x.
One argument, one result value.

=item B<UQT> B<uqt>

Up & Quantum.
One argument, one result value.

=item B<DQT> B<dqt>

Down & Quantum.
One argument, one result value.

=item B<ANN> B<ann>

And Nil.
One argument, one result value.

=item B<UANN> B<uann>

Up & And Nil.
One argument, one result value.

=item B<DANN> B<dann>

Down & And Nil.
One argument, one result value.

=item B<AND> B<and>

And.
2 arguments, one result value.

=item B<OR> B<or>

Or.
2 arguments, one result value.

=item B<XOR> B<xor>

Exclusive Or.
2 arguments, one result value.

=item B<EQV> B<eqv>

Equivalent.
2 arguments, one result value.

=item B<IMP> B<imp>

Implication (x ==> y).
2 arguments, one result value.

=item B<REP> B<rep>

Replication (x <== y).
2 arguments, one result value.

=item B<NAND> B<nand>

Not And.
2 arguments, one result value.

=item B<NOR> B<nor>

Not Or.
2 arguments, one result value.

=item B<CMP> B<cmp>

Compare (false < nil < true).
2 arguments, one result value.

=item B<ASC> B<asc>

Ascending (false < nil < true).
2 arguments, one result value.

=item B<TLR> B<tlr>

The Lesser (false < nil < true).
2 arguments, one result value.

=item B<TGR> B<tgr>

The Greater (false < nil < true).
2 arguments, one result value.

=item B<EQ> B<eq>

Equal to.
2 arguments, one result value.

=item B<NE> B<ne>

Not Equal to.
2 arguments, one result value.

=item B<LT> B<lt>

Less Than (false < nil < true).
2 arguments, one result value.

=item B<GE> B<ge>

Greater or Equal (false < nil < true).
2 arguments, one result value.

=item B<GT> B<gt>

Greater Than (false < nil < true).
2 arguments, one result value.

=item B<LE> B<le>

Less or Equal (false < nil < true).
2 arguments, one result value.

=item B<CMPU> B<cmpu>

Compare (unbalanced, nil < true < false).
2 arguments, one result value.

=item B<ASCU> B<ascu>

Ascending (unbalanced, nil < true < false).
2 arguments, one result value.

=item B<TLRU> B<tlru>

The Lesser (unbalanced, nil < true < false).
2 arguments, one result value.

=item B<TGRU> B<tgru>

The Greater (unbalanced, nil < true < false).
2 arguments, one result value.

=item B<LTU> B<ltu>

Less Than (unbalanced, nil < true < false).
2 arguments, one result value.

=item B<GEU> B<geu>

Greater or Equal (unbalanced, nil < true < false).
2 arguments, one result value.

=item B<GTU> B<gtu>

Greater Than (unbalanced, nil < true < false).
2 arguments, one result value.

=item B<LEU> B<leu>

Less or Equal (unbalanced, nil < true < false).
2 arguments, one result value.

=item B<INCR> B<incr>

Increment.
2 arguments, one result value.

=item B<INCC> B<incc>

Increment Carry.
2 arguments, one result value.

=item B<INCCU> B<inccu>

Increment Carry (unbalanced).
2 arguments, one result value.

=item B<INCCV> B<inccv>

Increment Carry (negative base).
2 arguments, one result value.

=item B<DECR> B<decr>

Decrement.
2 arguments, one result value.

=item B<DECC> B<decc>

Decrement Carry.
2 arguments, one result value.

=item B<DECCU> B<deccu>

Decrement Carry (unbalanced).
2 arguments, one result value.

=item B<DECCV> B<deccv>

Decrement Carry (negative base).
2 arguments, one result value.

=item B<PTY> B<pty>

Parity.
2 arguments, one result value.

=item B<DPL> B<dpl>

Duplicate.
2 arguments, one result value.

=item B<DPLC> B<dplc>

Duplication Carry.
2 arguments, one result value.

=item B<DPLCU> B<dplcu>

Duplication Carry (unbalanced).
2 arguments, one result value.

=item B<DPLCV> B<dplcv>

Duplication Carry (negative base).
2 arguments, one result value.

=item B<NEGCV> B<negcv>

Negation Carry (negative base).
2 arguments, one result value.

=item B<MULCU> B<mulcu>

Multiplication Carry (unbalanced).
2 arguments, one result value.

=item B<ADD> B<add>

Addition modulo 3.
3 arguments, one result value.

=item B<ADDC> B<addc>

Addition Carry.
3 arguments, one result value.

=item B<ADDCU> B<addcu>

Addition Carry (unbalanced).
3 arguments, one result value.

=item B<ADDCV> B<addcv>

Addition Carry (negative base).
3 arguments, one result value.

=item B<ADDCX> B<addcx>

Addition Carry (mixed base).
3 arguments, one result value.

=item B<SUBT> B<subt>

Subtraction.
3 arguments, one result value.

=item B<SUBC> B<subc>

Subtraction Carry.
3 arguments, one result value.

=item B<SUBCU> B<subcu>

Subtraction Carry (unbalanced).
3 arguments, one result value.

=item B<SUBCV> B<subcv>

Subtraction Carry (negative base).
3 arguments, one result value.

=item B<CMIN> B<cmin>

Ternary Comparison to Minimum.
3 arguments, one result value.

=item B<CMED> B<cmed>

Ternary Comparison to Median.
3 arguments, one result value.

=item B<CMAX> B<cmax>

Ternary Comparison to Maximum.
3 arguments, one result value.

=item B<CVLD> B<cvld>

Ternary Comparison Validation.
3 arguments, one result value.

=item B<IPLC> B<iplc>

Interpolation Linear Coefficient.
3 arguments, one result value.

=item B<IPQC> B<ipqc>

Interpolation Quadratic Coefficient.
3 arguments, one result value.

=item B<LCO> B<lco>

Linear Combination.
3 arguments, one result value.

=item B<MIN> B<min>

Minimum of Three Values.
3 arguments, one result value.

=item B<MED> B<med>

Median of Three Values.
3 arguments, one result value.

=item B<MAX> B<max>

Maximum of Three Values.
3 arguments, one result value.

=item B<MINU> B<minu>

Minimum of Three Values (unbalanced).
3 arguments, one result value.

=item B<MEDU> B<medu>

Median of Three Values (unbalanced).
3 arguments, one result value.

=item B<MAXU> B<maxu>

Maximum of Three Values (unbalanced).
3 arguments, one result value.

=item B<SUM> B<sum>

Summation.
4 arguments, one result value.

=item B<SUMC> B<sumc>

Summation Carry.
4 arguments, one result value.

=item B<SUMCU> B<sumcu>

Summation Carry (unbalanced).
4 arguments, one result value.

=item B<MPX> B<mpx>

Multiplex: first trit controls which of the other arguments is returned.
4 arguments, one result value.

=item B<GENERIC> B<generic>

Generic logical and tritwise operators, first argument acts as logical
operator name.

=back

=head3 Numerical operators

=over 4

=item B<Add>

=item B<Addu>

=item B<Addv>

Addition in balanced, unbalanced, or baseZ<>(-3) arithmetic.
Two operands with optional carry trit, returns value and carry trit.

=item B<Asc>

=item B<Ascu>

=item B<Ascv>

Ascending.
Comparison operator in balanced, unbalanced or baseZ<>(-3) arithmetic.
Two operands with optional carry trit, returns result trit.
If carry is not nil, result is carry.
Otherwise if first operand is less than second operand, result is true.
Otherwise if first operand is greater than second operand, result is false.
Otherwise result is nil.

=item B<Cmp>

=item B<Cmpu>

=item B<Cmpv>

Comparison operator in balanced, unbalanced or baseZ<>(-3) arithmetic.
Two operands with optional carry trit, returns result trit.
If carry is not zero, result is carry.
Otherwise if first operand is greater than second operand, result is +1.
Otherwise if first operand is less than second operand, result is -1.
Otherwise result is zero.

=item B<Decr>

=item B<Decru>

=item B<Decrv>

Decrement operator in balanced, unbalanced or baseZ<>(-3) arithmetic.
One operand with optional carry trit, returns value and carry trit.
Carry defaults to one if omitted.
The carry is subtracted from the value.

=item B<Div>

=item B<Divu>

=item B<Divv>

Short division operator in balanced, unbalanced or baseZ<>(-3) arithmetic.
Two operands, returns quotient and remainder values and error trit.
If the second operand is zero, the error trit is true, otherwise nil.

=item B<Dpl>

=item B<Dplu>

=item B<Dplv>

Duplication operator in balanced, unbalanced or baseZ<>(-3) arithmetic.
One operand with optional carry trit, returns value and carry trit.
The operand is multiplied by two.

=item B<Ge>

=item B<Geu>

=item B<Gev>

Greater or equal.
Comparison operator in balanced, unbalanced or baseZ<>(-3) arithmetic.
Two operands with optional carry trit, returns result trit.
If carry is not nil, result is carry.
Otherwise if first operand is not less than second operand, result is true.
Otherwise result is false.

=item B<Gt>

=item B<Gtu>

=item B<Gtv>

Greater than.
Comparison operator in balanced, unbalanced or baseZ<>(-3) arithmetic.
Two operands with optional carry trit, returns result trit.
If carry is not nil, result is carry.
Otherwise if first operand is greater than second operand, result is true.
Otherwise result is false.

=item B<Incr>

=item B<Incru>

=item B<Incrv>

Increment operator in balanced, unbalanced or baseZ<>(-3) arithmetic.
One operand with optional carry trit, returns value and carry trit.
Carry defaults to one if omitted.
The carry is added to the value.

=item B<Ldiv>

=item B<Ldivu>

=item B<Ldivv>

Long division operator in balanced, unbalanced or baseZ<>(-3) arithmetic.
Three operands: lower word of first operand, upper word of first operand,
second operand.  Returns lower and upper word of quotient value, remainder
value, and error trit.  If the second operand is zero, the error trit
is true, otherwise nil.

=item B<Le>

=item B<Leu>

=item B<Lev>

Less or equal.
Comparison operator in balanced, unbalanced or baseZ<>(-3) arithmetic.
Two operands with optional carry trit, returns result trit.
If carry is not nil, result is carry.
Otherwise if first operand is not greater than second operand, result is true.
Otherwise result is false.

=item B<Lshift>

Left shift operator.
One operand with optional carry trit, returns value and carry trit.
The operand is multiplied by the base and the carry is added.  The base
is 3 in balanced or unbalanced arithmetic, -3 in baseZ<>(-3) arithmetic.

=item B<Lt>

=item B<Ltu>

=item B<Ltv>

Less than.
Comparison operator in balanced, unbalanced or baseZ<>(-3) arithmetic.
Two operands with optional carry trit, returns result trit.
If carry is not nil, result is carry.
Otherwise if first operand is less than second operand, result is true.
Otherwise result is false.

=item B<Max>

=item B<Maxu>

=item B<Maxv>

Maximum.
Ternary comparison operator in balanced, unbalanced or baseZ<>(-3) arithmetic.
Three operands, returns the largest of these as result value.

=item B<Med>

=item B<Medu>

=item B<Medv>

Median.
Ternary comparison operator in balanced, unbalanced or baseZ<>(-3) arithmetic.
Three operands, returns the second largest of these as result value.

=item B<Min>

=item B<Minu>

=item B<Minv>

Minimum.
Ternary comparison operator in balanced, unbalanced or baseZ<>(-3) arithmetic.
Three operands, returns the smallest of these as result value.

=item B<Mul>

=item B<Mulu>

Multiplication in balanced or unbalanced arithmetic.  Two or three
operands, returns lower and upper part of the result value.
The optional third operand is added to the multiplication result.

=item B<Mulv>

Multiplication in baseZ<>(-3) arithmetic.  Two or three operands,
returns lower and upper part of the result value and a carry trit.
The optional third operand is added to the multiplication result.

=item B<Neg>

Negation in balanced arithmetic.
One operand, one result value.
In balanced arithmetic, negation is equivalent to bitwise not.

=item B<Negv>

Negation in unbalanced arithmetic.
One operand with optional carry trit, returns value and carry trit.
The operand is multiplied by -1.

=item B<Rshift>

Right shift operator.
One operand with optional carry trit, returns value and carry trit.
The operand is divided by the base and the most significant trit is set
to the carry.
The old least significant trit is returned as new carry.
The base is 3 in balanced or unbalanced arithmetic, -3 in baseZ<>(-3)
arithmetic.

=item B<Sign>

=item B<Signu>

=item B<Signv>

Sign operator in balanced, unbalanced or baseZ<>(-3) arithmetic.
One operand, returns sign trit.
Note that in unbalanced arithmetic the result can only be nil or true,
as all values are representing zero or positive numbers.

=item B<Sort2>

=item B<Sort2u>

=item B<Sort2v>

Binary Sorting operator in balanced, unbalanced or baseZ<>(-3) arithmetic.
Two operands, returns smaller and larger operand.

=item B<Sort3>

=item B<Sort3u>

=item B<Sort3v>

Ternary sorting operator in balanced, unbalanced or baseZ<>(-3) arithmetic.
Three operands, returns smallest, middle and largest operand.

=item B<Subt>

=item B<Subtu>

=item B<Subtv>

Subtraction in balanced, unbalanced, or baseZ<>(-3) arithmetic.
Two operands with optional carry trit, returns value and carry trit.

=item B<Sum>

=item B<Sumu>

Three-operand summation in balanced or unbalanced arithmetic.
Three operands with optional carry trit, returns value and carry trit.
Note that the baseZ<>(-3) variant is not implemented.

=item B<Tgr>

=item B<Tgru>

=item B<Tgrv>

The greater - binary comparison operator in balanced, unbalanced or
baseZ<>(-3) arithmetic.
Two operands, returns larger operand.

=item B<Tlr>

=item B<Tlru>

=item B<Tlrv>

The lesser - binary comparison operator in balanced, unbalanced or
baseZ<>(-3) arithmetic.
Two operands, returns smaller operand.

=back

=head3 Math::Logic::Ternary::Object Role Methods

=over 4

=item B<Trit>

Trit inspection:
C<$word-E<gt>Trit($n)> returns trit number C<$n>, 0 indexing the least
significant trit.

=item B<Trits>

Trit inspection:
C<$word-E<gt>Trits> returns a list of precisely I<n> trits for word size
I<n>, starting with the least significant trit.

=item B<Rtrits>

Trit inspection:
C<$word-E<gt>Trits> returns a list of zero up to I<n> trits for word
size I<n>, starting with the least significant trit, ending with the
most significant non-nil trit.

=item B<Sign>

=item B<Signu>

=item B<Signv>

Numeric sign operator in balanced, unbalanced or baseZ<>(-3) arithmetic,
returns a sign trit.
Note that in all variants a return value of true means positive, nil
zero and false negative.

=item B<as_int>

C<$word-E<gt>as_int> returns the integer number represented by the word
in balanced ternary arithmetic.
The result will either be a native integer or a Math::BigInt object
depending on the word size.

=item B<as_int_u>

C<$word-E<gt>as_int_u> returns the integer number represented by the
word in unsigned unbalanced ternary arithmetic.
The result will either be a native integer or a Math::BigInt object
depending on the word size.

=item B<as_int_v>

C<$word-E<gt>as_int_v> returns the integer number represented by the
word in baseZ<>(-3) arithmetic.
The result will either be a native integer or a Math::BigInt object
depending on the word size.

=item B<res_mod3>

C<$word-E<gt>res_mod3> returns the least significant trit of the word.

=item B<as_string>

C<$word-E<gt>as_string> returns a string of C<n> | C<t> | C<f> characters
for all trits in the word including leading zeroes, from most to least
significant trit, prepended by an C<@> sigil.

=item B<is_equal>

C<$word-E<gt>is_equal($obj)> returns true if C<$word-E<gt>Rtrits>
and C<$obj-E<gt>Rtrits> are identical lists, otherwise false.
This means that words of different sizes are regarded as equal if they
represent equal numeric values.

=back

=head3 Other Object Methods

=over 4

=item B<Mpx>

Multiplex.  C<$word-E<gt>Mpx($case_n, $case_t, $case_f)> with three
arbitrary arguments returns C<$case_n> if C<$word> is zero, C<$case_t>
if C<$word> is positive, or C<$case_f> if C<$word> is negative.  Thus it
is equivalent to C<$word-E<gt>Sign->Mpx($case_n, $case_t, $case_f)>.

=item B<as_base27>

C<$word-E<gt>as_base27> returns a string of baseZ<>(27) letters (C<_>,
lower case C<a> up to C<m>, upper case C<N> up to C<Z>) for all groups
of three trits in the word including leading zeroes, from most to least
significant triplet, prepended by a C<%> sigil.
The most significant triplet will be taken as zero padded if the word
size is not a multiple of three.

BaseZ<>(27) string representations of words of equal size will sort
lexically in the same order as their balanced ternary values sort numerically.
Zero values will yield a string of underscore characters, prepended
by C<%>.

=item B<as_modint>

=item B<as_modint_u>

=item B<as_modint_v>

C<$word-E<gt>as_modint> converts the numerical value of C<$word> to a
Math::ModInt object modulo 3 ** I<n> for words of size I<n>, using
balanced arithmetic.
The variants I<as_modint_u> and I<as_modint_v> do the same in unbalanced
and baseZ<>(-3) arithmetic.

The Perl extension Math::ModInt (available on CPAN) must be installed for
this to work, otherwise I<as_modint> etc. will raise a run-time exception.

=back

=head3 Constructor shortcuts

=over 4

=item B<convert_trits>

=item B<convert_words>

=item B<convert_bools>

=item B<convert_int>

=item B<convert_int_u>

=item B<convert_int_v>

=item B<convert_modint>

=item B<convert_modint_u>

=item B<convert_modint_v>

=item B<convert_base27>

=item B<convert_string>

=item B<convert_various>

Each of these object methods creates a new word of the same size as
its invocant.

C<$word-E<gt>convert_I<XXX>(@args)> is a shortcut for
C<Math::Logic::Ternary::Word-E<gt>from_I<XXX>($word-E<gt>Size, @args)> .
See L</Constructors>, below.

=back

=head3 Splitting

=over 4

=item B<Words>

C<$word-E<gt>Words($size)> returns a list of new word objects of the
given size, holding all the trits of the invocant, in lowest to highest
significance order.  This can be used to split a big word into smaller
words.

If the desired word size is not a divisor of the original size, some
padding nil trits are added at the (most significant) end so that the
words returned are all the same size.

=back

=head3 Other object methods

=over 4

=item B<min_int>

C<$word-E<gt>min_int> returns a word representing the smallest integer
of the same size as the invocant in balanced ternary arithmetic.
This is a word full of I<false> trits.

=item B<max_int>

C<$word-E<gt>max_int> returns a word representing the largest integer
of the same size as the invocant in balanced ternary arithmetic.
This is a word full of I<true> trits.

=item B<min_int_u>

C<$word-E<gt>min_int_u> returns a word representing the smallest integer
of the same size as the invocant in unbalanced ternary arithmetic.
This is a word full of I<nil> trits.

=item B<max_int_u>

C<$word-E<gt>max_int_u> returns a word representing the largest integer
of the same size as the invocant in unbalanced ternary arithmetic.
This is a word full of I<false> trits.

=item B<min_int_v>

C<$word-E<gt>min_int_v> returns a word representing the smallest integer
of the same size as the invocant in baseZ<>(-3) ternary arithmetic.
This is a word full of alternating I<nil> and I<false> trits, with the
least significant trit I<nil>.

=item B<max_int_v>

C<$word-E<gt>max_int_v> returns a word representing the largest integer
of the same size as the invocant in baseZ<>(-3) ternary arithmetic.
This is a word full of alternating I<nil> and I<false> trits, with the
least significant trit I<false>.

=back

=head2 Class methods

=head3 Constructors

Word objects are fixed size containers for trits.
All constructors take a size argument and additional information defining
those trit values.

The size must be a positive integer.
There may be an implementation-specific upper limit for the size.
Sizes up to C<3 ** 9> should always be valid, though.

=over 4

=item B<from_trits>

C<Math::Logic::Ternary::Word->from_trits($size, @trits)> creates a new
word object of given size from the given trit values.

Trits must be enumerated from lowest to highest significance, without gaps.
Trailing (i.e. highly significant) nil trits may be omitted.
Trailing superfluous nil trits will be ignored.
Non-nil trits beyond the given size will trigger an exception.

=item B<from_words>

C<Math::Logic::Ternary::Word-E<gt>from_words($size, @words)> creates
a new word object of given size from trit values taken from the given
list of words.

The words may be of any size and must be listed from lowest to highest
significance.
All of their trits are used.

=item B<from_bools>

C<Math::Logic::Ternary::Word-E<gt>from_bools($size, @bools)> creates a
new word object of given size from trit values given as booleans rather
than trit objects.
Boolean values are taken as I<nil> if undefined, I<false> if defined
but false, or I<true> if true.

=item B<from_int>

C<Math::Logic::Ternary::Word-E<gt>from_int($size, $int)> creates a new
word representing the given integer value in balanced arithmetic.
If the integer value exceeds the range of the given word size
an exception is raised.

=item B<from_int_u>

C<Math::Logic::Ternary::Word-E<gt>from_int_u($size, $int)> creates a new
word representing the given integer value in unbalanced unsigned arithmetic.
If the integer value is negative or exceeds the range of the given word
size an exception is raised.

=item B<from_int_v>

C<Math::Logic::Ternary::Word-E<gt>from_int_v($size, $int)> creates a new
word representing the given integer value in baseZ<>(-3) arithmetic.
If the integer value exceeds the range of the given word size an exception
is raised.

=item B<from_base27>

C<Math::Logic::Ternary::Word-E<gt>from_base27($size, $string)> creates
a new word from a string of baseZ<>(27) digits (underscore and letters,
case not important), given in highest to lowest significance order.
If the resulting value exceeds the range of the given word size an
exception is raised.  See also L</as_base27>.

=item B<from_string>

C<Math::Logic::Ternary::Word-E<gt>from_string($size, $string)> creates
a new word from a string of ternary digits (C<n>, C<t>, C<f>, case
not important), given in highest to lowest significance order.  If the
resulting value exceeds the range of the given word size an exception
is raised.

If the string begins with one of the sigils C<%>, C<@>, or C<$>, it is
interpreted as a baseZ<>(27) string, ternary digit string, or single
ternary digit name, respectively.

If the string is not syntactically correct, an exception is raised.

=item B<from_modint>

C<Math::Logic::Ternary::Word-E<gt>from_modint($size, $string)> creates a
new word from a Math::ModInt object (i.e. a modular integer) representing
the same value if interpreted as a balanced ternary number.  The modulus
must be a power of three.  Size can be zero or the base 3 logarithm of
the modulus, otherwise an exception will be raised.

=item B<from_modint_u>

C<Math::Logic::Ternary::Word-E<gt>from_modint_u($size, $string)> creates a
new word from a Math::ModInt object (i.e. a modular integer) representing
the same value if interpreted as an unsigned ternary number.  The modulus
must be a power of three.  Size can be zero or the base 3 logarithm of
the modulus, otherwise an exception will be raised.

=item B<from_modint_v>

C<Math::Logic::Ternary::Word-E<gt>from_modint_v($size, $string)> creates a
new word from a Math::ModInt object (i.e. a modular integer) representing
the same value if interpreted as a baseZ<>(-3) number.  The modulus
must be a power of three.  Size can be zero or the base 3 logarithm of
the modulus, otherwise an exception will be raised.

=item B<from_various>

C<Math::Logic::Ternary::Word-E<gt>from_various($size, @args)> creates
a new word from its arguments, guided by their type.  If the resulting
value exceeds the range of the given word size an exception is raised.

If the arguments are word or trit objects, they will be packed 
into a new word of the given size.

If the argument is a single string of decimal digits, optionally preceded
by plus or minus, or it is a single Math::BigInt object, it will be
converted as in L<from_int|/from_int>.

If the argument is a single Math::ModInt object, it will be converted
as in L<from_modint|/from_modint>.

If the arguments are plain perl scalars, they will be converted as in
L<from_bools|/from_bools>.

If the argument is a single string recognized by L<as_string|/as_string>,
it will be converted accordingly.

=back

=head3 Other class methods

=over 4

=item B<word_operators>

C<Math::Logic::Ternary::Word-E<gt>word_operators> returns a list of
arrayrefs, each holding an operator signature with five attributes:

=over 4

=item C<$name>

Operator method name.

=item C<$min_args>

Number of mandatory arguments.

=item C<$var_args>

Number of optional arguments.

=item C<$ret_vals>

Number of returned values.

=item C<$is_arith>

Arithmetic type:  I<undef> for general operators, 0 for balanced
arithmetic, 1 for unbalanced arithmetic, 2 for baseZ<>(-3) arithmetic.

=back

=item B<word_formatters>

C<Math::Logic::Ternary::Word-E<gt>word_formatters> returns a list of
arrayrefs, each holding a method signature.

These formatters all take no parameters and return a string value.
Hence only two attributes are needed to individually describe them:

=over 4

=item C<$name>

Formatter method name.

=item C<$is_arith>

Arithmetic type:  I<undef> for general formatters, 0 for balanced
arithmetic, 1 for unbalanced arithmetic, 2 for baseZ<>(-3) arithmetic.

=back

=back

=head1 AGENDA

The range of numeric operators is by no means complete.
In particular, conversions supporting input and output for binary
architectures will have to be added.

=head1 SEE ALSO

=over 4

=item L<Math::Logic::Ternary> - General Information

=item L<Math::Logic::Ternary::Trit> - Ternary Logical Information Unit

=item L<Math::Logic::Ternary::Object> - Role providing trit introspection

=item L<Math::Logic::Ternary::TFP_81> - 81-Trit Ternary Floating Point

=item L<Math::Logic::Ternary::Calculator> - Interactive Ternary Calculator

=back

=head1 AUTHOR

Martin Becker E<lt>becker-cpan-mpE<64>cozap.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2017 by Martin Becker, Blaubeuren.  All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
