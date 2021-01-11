package Math::Polynomial;

use 5.006;
use strict;
use warnings;
use Carp qw(croak);

require overload;

overload->import(
    q{neg}      => 'neg',
    q{+}        => _binary('add'),
    q{-}        => _binary('sub_'),
    q{*}        => _binary('mul'),
    q{/}        => _binary('div'),
    q{%}        => _binary('mod'),
    q{**}       => _lefty('pow'),
    q{<<}       => _lefty('shift_up'),
    q{>>}       => _lefty('shift_down'),
    q{!}        => 'is_zero',
    q{bool}     => 'is_nonzero',
    q{==}       => _binary('is_equal'),
    q{!=}       => _binary('is_unequal'),
    q{""}       => 'as_string',
    q{fallback} => undef,       # auto-generate trivial substitutions
);

# ----- object definition -----

# Math::Polynomial=ARRAY(...)

# .......... index ..........   # .......... value ..........
use constant _F_COEFF  => 0;    # coefficients arrayref, ascending degree
use constant _F_ZERO   => 1;    # zero element of coefficient space
use constant _F_ONE    => 2;    # unit element of coefficient space
use constant _F_CONFIG => 3;    # default stringification configuration
use constant _NFIELDS  => 4;

# ----- static data -----

our $VERSION      = '1.019';
our $max_degree   = 10_000;    # limit for power operator

# default values for as_string options
my @string_defaults = (
    ascending     => 0,
    with_variable => 1,
    fold_sign     => 0,
    fold_zero     => 1,
    fold_one      => 1,
    fold_exp_zero => 1,
    fold_exp_one  => 1,
    convert_coeff => sub { "$_[0]" },
    sign_of_coeff => undef,
    plus          => q{ + },
    minus         => q{ - },
    leading_plus  => q{},
    leading_minus => q{- },
    times         => q{ },
    power         => q{^},
    variable      => q{x},
    prefix        => q{(},
    suffix        => q{)},
    wrap          => sub { $_[1] },
);

my $global_string_config = {};

my @tree_defaults = (
    fold_sign     => 0,
    expand_power  => 0,
    group         => sub { $_[0] },
    sign_of_coeff => undef,
    wrap          => sub { $_[1] },
    map {
        my $key = $_;
        ($key => sub { croak "missing parameter: $key" })
    } qw(
        variable
        constant
        negation
        sum
        difference
        product
        power
    ),
);

# ----- private/protected subroutines -----

# binary operator wrapper generator
# generates functions to be called via overload:
# - upgrading a non-polynomial operand to a compatible polynomial
# - restoring the original operand order
sub _binary {
    my ($method) = @_;
    return sub {
        my ($this, $that, $reversed) = @_;
        if (!ref($that) || !eval { $that->isa('Math::Polynomial') }) {
            $that = $this->new($that);
        }
        if ($reversed) {
            ($this, $that) = ($that, $this);
        }
        return $this->$method($that);
    };
}

# asymmetrically prototyped binary operator wrapper generator
# generates functions to be called via overload:
# - disallowing reverse order of operands
sub _lefty {
    my ($method) = @_;
    return sub {
        my ($this, $that, $reversed) = @_;
        croak 'wrong operand type' if $reversed;
        return $this->$method($that);
    };
}

# integer argument checker
# - make sure arguments are non-negative integer numbers
sub _check_int {
    foreach my $arg (@_) {
        eval {
            use warnings FATAL => 'all';
            $arg == abs int $arg
        } or croak 'non-negative integer argument expected';
    }
    return;
}

# ----- methods -----

sub new {
    my ($this, @coeff) = @_;
    my $class = ref $this;
    my ($zero, $one, $config);
    if ($class) {
        (undef, $zero, $one, $config) = @{$this};
    }
    else {
        my $sample = @coeff? $coeff[-1]: 1;
        $zero   = $sample - $sample;
        $one    = $sample ** 0;
        $config = undef;
        $class  = $this;
    }
    while (@coeff && $zero == $coeff[-1]) {
        pop @coeff;
    }
    return bless [\@coeff, $zero, $one, $config], $class;
}

sub clone {
    my ($this) = @_;
    return bless [@{$this}], ref $this;
}

sub monomial {
    my ($this, $degree, $coeff) = @_;
    my $zero;
    _check_int($degree);
    croak 'exponent too large'
        if defined($max_degree) && $degree > $max_degree;
    if (ref $this) {
        if (!defined $coeff) {
            $coeff = $this->coeff_one;
        }
        $zero  = $this->coeff_zero;
    }
    else {
        if (!defined $coeff) {
            $coeff = 1;
        }
        $zero  = $coeff - $coeff;
    }
    return $this->new(($zero) x $degree, $coeff);
}

sub from_roots {
    my ($this, @roots) = @_;
    my $one = ref($this)? $this->coeff_one: @roots? $roots[-1] ** 0: 1;
    my $result = $this->new($one);
    foreach my $root (@roots) {
        $result = $result->mul_root($root);
    }
    return $result;
}

sub string_config {
    my ($this, $config) = @_;
    my $have_arg = 2 <= @_;
    if (ref $this) {
        if ($have_arg) {
            $this->[_F_CONFIG] = $config;
        }
        else {
            $config = $this->[_F_CONFIG];
        }
    }
    else {
        if ($have_arg) {
            # note: do not leave ultimate fallback configuration undefined
            $global_string_config = $config || {};
        }
        else {
            $config = $global_string_config;
        }
    }
    return $config;
}

sub interpolate {
    my ($this, $xvalues, $yvalues) = @_;
    if (
        !ref($xvalues) || !ref($yvalues) || @{$xvalues} != @{$yvalues}
    ) {
        croak 'usage: $q = $p->interpolate([$x1, $x2, ...], [$y1, $y2, ...])';
    }
    return $this->new if !@{$xvalues};
    my @alpha  = @{$yvalues};
    my $result = $this->new($alpha[0]);
    my $aux    = $result->monomial(0);
    my $zero   = $result->coeff_zero;
    for (my $k=1; $k<=$#alpha; ++$k) {
        for (my $j=$#alpha; $j>=$k; --$j) {
            my $dx = $xvalues->[$j] - $xvalues->[$j-$k];
            croak 'x values not disjoint' if $zero == $dx;
            $alpha[$j] = ($alpha[$j] - $alpha[$j-1]) / $dx;
        }
        $aux = $aux->mul_root($xvalues->[$k-1]);
        $result += $aux->mul_const($alpha[$k]);
    }
    return $result;
}

sub coeff {
    my ($this, $degree) = @_;
    if (defined $degree) {
        return
            0 <= $degree && $degree < @{$this->[_F_COEFF]}?
                $this->[_F_COEFF]->[$degree]:
                $this->[_F_ZERO];
    }
    croak 'array context required if called without argument' if !wantarray;
    return @{$this->[_F_COEFF]};
}

sub coefficients {
    my ($this) = @_;
    croak 'array context required' if !wantarray;
    return $this->is_zero? ($this->coeff_zero): $this->coeff;
}

sub degree     { return $#{ $_[0]->[_F_COEFF] }; }
sub coeff_zero { return $_[0]->[_F_ZERO]; }
sub coeff_one  { return $_[0]->[_F_ONE]; }

sub proper_degree {
    my ($this) = @_;
    my $degree = $this->degree;
    return 0 <= $degree? $degree: undef;
}

sub number_of_terms {
    my ($this) = @_;
    my $zero   = $this->coeff_zero;
    return scalar grep { $zero != $_ } $this->coeff;
}

sub evaluate {
    my ($this, $x) = @_;
    my $i = $this->degree;
    my $result = 0 <= $i? $this->coeff($i): $this->coeff_zero;
    while (0 <= --$i) {
        $result = $x * $result + $this->coeff($i);
    }
    return $result;
}

sub nest {
    my ($this, $that) = @_;
    my $i = $this->degree;
    my $result = $that->new(0 <= $i? $this->coeff($i): ());
    while (0 <= --$i) {
        $result = $result->mul($that)->add_const($this->coeff($i));
    }
    return $result;
}

sub unnest {
    my ($this, $that) = @_;
    return undef if $that->degree <= 0;
    my @coeff = ();
    my $q = $this;
    while ($q) {
        ($q, my $r) = $q->divmod($that);
        return undef if $r->degree > 0;
        push @coeff, $r->coeff(0);
    }
    return $this->new(@coeff);
}

sub mirror {
    my ($this) = @_;
    my $i = 0;
    return $this->new( map { $i++ & 1? -$_: $_ } $this->coeff );
}

sub is_zero {
    my ($this) = @_;
    return $this->degree < 0;
}

sub is_nonzero {
    my ($this) = @_;
    return $this->degree >= 0;
}

sub is_equal {
    my ($this, $that) = @_;
    my $i = $this->degree;
    my $eq = $i == $that->degree;
    while ($eq && 0 <= $i) {
        $eq = $this->coeff($i) == $that->coeff($i);
        --$i;
    }
    return $eq;
}

sub is_unequal {
    my ($this, $that) = @_;
    my $i = $this->degree;
    my $eq = $i == $that->degree;
    while ($eq && 0 <= $i) {
        $eq = $this->coeff($i) == $that->coeff($i);
        --$i;
    }
    return !$eq;
}

sub is_even {
    my ($this) = @_;
    return $this->is_equal($this->mirror);
}

sub is_odd {
    my ($this) = @_;
    return $this->is_equal($this->mirror->neg);
}

sub neg {
    my ($this) = @_;
    return $this if $this->degree < 0;
    return $this->new( map { -$_ } $this->coeff );
}

sub add {
    my ($this, $that) = @_;
    my $this_d = $this->degree;
    my $that_d = $that->degree;
    my $min_d  = $this_d <= $that_d? $this_d: $that_d;
    return $this->new(
        (map { $this->coeff($_) + $that->coeff($_) } 0..$min_d),
        (map { $this->coeff($_) } $that_d+1 .. $this_d),
        (map { $that->coeff($_) } $this_d+1 .. $that_d),
    );
}

sub sub_ {
    my ($this, $that) = @_;
    my $this_d = $this->degree;
    my $that_d = $that->degree;
    my $min_d  = $this_d <= $that_d? $this_d: $that_d;
    return $this->new(
        (map {  $this->coeff($_) - $that->coeff($_) } 0..$min_d),
        (map {  $this->coeff($_) } $that_d+1 .. $this_d),
        (map { -$that->coeff($_) } $this_d+1 .. $that_d),
    );
}

sub mul {
    my ($this, $that) = @_;
    my $this_d = $this->degree;
    return $this if $this_d < 0;
    my $that_d = $that->degree;
    return $this->new(
        map {
            my ($i, $j) = $_ <= $this_d? ($_, 0): ($this_d, $_-$this_d);
            my $sum = $this->coeff($i) * $that->coeff($j);
            while ($i > 0 && $j < $that_d) {
                $sum += $this->coeff(--$i) * $that->coeff(++$j);
            }
            $sum
        } $that_d < 0? (): (0 .. $this_d+$that_d)
    );
}

sub _divmod {
    my ($this, $that) = @_;
    my @den  = $that->coeff;
    @den or croak 'division by zero polynomial';
    my $hd   = pop @den;
    if ($that->is_monic) {
        undef $hd;
    }
    my @rem  = $this->coeff;
    my @quot = ();
    my $i    = $#rem - @den;
    while (0 <= $i) {
        my $q = pop @rem;
        if (defined $hd) {
            $q /= $hd;
        }
        $quot[$i] = $q;
        my $j = $i--;
        foreach my $d (@den) {
            $rem[$j++] -= $q * $d;
        }
    }
    return (\@quot, \@rem);
}

sub divmod {
    my ($this, $that) = @_;
    croak 'array context required' if !wantarray;
    my ($quot, $rem) = _divmod($this, $that);
    return ($this->new(@{$quot}), @{$quot}? $this->new(@{$rem}): $this);
}

sub div {
    my ($this, $that) = @_;
    my ($quot) = _divmod($this, $that);
    return $this->new(@{$quot});
}

sub mod {
    my ($this, $that) = @_;
    my ($quot, $rem) = _divmod($this, $that);
    return @{$quot}? $this->new(@{$rem}): $this;
}

sub mmod {
    my ($this, $that) = @_;
    my @den  = $that->coeff;
    @den or croak 'division by zero polynomial';
    my $hd   = pop @den;
    if ($that->is_monic) {
        undef $hd;
    }
    my @rem  = $this->coeff;
    my $i    = $#rem - @den;
    while (0 <= $i) {
        my $q = pop @rem;
        if (defined $hd) {
            foreach my $r (@rem) {
                $r *= $hd;
            }
        }
        my $j = $i--;
        foreach my $d (@den) {
            $rem[$j++] -= $q * $d;
        }
    }
    return $this->new(@rem);
}

sub add_const {
    my ($this, $const) = @_;
    return $this->new($const) if $this->is_zero;
    my $i = 0;
    return $this->new( map { $i++? $_: $_ + $const } $this->coeff );
}

sub sub_const {
    my ($this, $const) = @_;
    return $this->new(-$const) if $this->is_zero;
    my $i = 0;
    return $this->new( map { $i++? $_: $_ - $const } $this->coeff );
}

sub mul_const {
    my ($this, $factor) = @_;
    return $this->new( map { $_ * $factor } $this->coeff );
}

sub div_const {
    my ($this, $divisor) = @_;
    croak 'division by zero' if $this->coeff_zero == $divisor;
    return $this->new( map { $_ / $divisor } $this->coeff );
}

sub mul_root {
    my ($this, $root) = @_;
    return $this->shift_up(1)->sub_($this->mul_const($root));
}

sub _divmod_root {
    my ($this, $root) = @_;
    my $i   = $this->degree;
    my $rem = $this->coeff($i < 0? 0: $i);
    my @quot;
    while (0 <= --$i) {
        $quot[$i] = $rem;
        $rem = $root * $rem + $this->coeff($i);
    }
    return (\@quot, $rem);
}

sub divmod_root {
    my ($this, $root) = @_;
    croak 'array context required' if !wantarray;
    my ($quot, $rem) = _divmod_root($this, $root);
    return ($this->new(@{$quot}), $this->new($rem));
}

sub div_root {
    my ($this, $root, $check) = @_;
    my ($quot, $rem) = _divmod_root($this, $root);
    if ($check && $this->coeff_zero != $rem) {
        croak 'non-zero remainder';
    }
    return $this->new(@{$quot});
}

sub is_monic {
    my ($this) = @_;
    my $degree = $this->degree;
    return 0 <= $degree && $this->coeff_one == $this->coeff($degree);
}

sub monize {
    my ($this) = @_;
    return $this if $this->is_zero || $this->is_monic;
    return $this->div_const($this->coeff($this->degree));
}

sub pow {
    my ($this, $exp) = @_;
    _check_int($exp);
    my $degree = $this->degree;
    return $this->new($this->coeff_one)        if 0 == $exp;
    return $this                               if 0  > $degree;
    return $this->new($this->coeff(0) ** $exp) if 0 == $degree;
    croak 'exponent too large'
        if defined($max_degree) && $degree * $exp > $max_degree;
    my @binary = ();
    while ($exp > 1) {
        push @binary, 1 & $exp;
        $exp >>= 1;
    }
    my $result = $this;
    while (@binary) {
        $result *= $result;
        $result *= $this if pop @binary;
    }
    return $result;
}

sub pow_mod {
    my ($this, $exp, $that) = @_;
    _check_int($exp);
    $this = $this->mod($that);
    my $this_d = $this->degree;
    return $this->new                          if 0 == $that->degree;
    return $this->new($this->coeff_one)        if 0 == $exp;
    return $this                               if 0  > $this_d;
    return $this->new($this->coeff(0) ** $exp) if 0 == $this_d;
    my @binary = ();
    while ($exp > 1) {
        push @binary, 1 & $exp;
        $exp >>= 1;
    }
    my $result = $this;
    while (@binary) {
        $result *= $result;
        $result *= $this if pop @binary;
        $result %= $that;
    }
    return $result;
}

sub exp_mod {
    my ($this, $exp) = @_;
    _check_int($exp);
    return $this->new                   if 0 == $this->degree;
    return $this->new($this->coeff_one) if 0 == $exp;
    my @binary = ();
    while ($exp > 1) {
        push @binary, 1 & $exp;
        $exp >>= 1;
    }
    my $result = $this->new($this->coeff_zero, $this->coeff_one);
    while (@binary) {
        $result *= $result;
        if (pop @binary) {
            local $max_degree;
            $result <<= 1;
        }
        $result %= $this;
    }
    return $result;
}

sub shift_up {
    my ($this, $exp) = @_;
    _check_int($exp);
    croak 'exponent too large' if
        defined($max_degree) && $this->degree + $exp > $max_degree;
    return $this if !$exp;
    return $this->new(($this->coeff_zero) x $exp, $this->coeff);
}

sub shift_down {
    my ($this, $exp) = @_;
    _check_int($exp);
    return $this if !$exp;
    return $this->new( map { $this->coeff($_) } $exp .. $this->degree );
}

sub inflate {
    my ($this, $exp) = @_;
    my $degree = $this->degree;
    return $this if $degree <= 0;
    _check_int($exp);
    croak 'exponent too large' if
        defined($max_degree) && $degree * $exp > $max_degree;
    return $this->new($this->evaluate($this->coeff_one)) if !$exp;
    my @zeroes = ($this->coeff_zero) x ($exp - 1);
    return $this if !@zeroes;
    my ($const, @coeff) = $this->coeff;
    return $this->new($const, map {@zeroes, $_} @coeff);
}

sub deflate {
    my ($this, $exp) = @_;
    _check_int($exp);
    return undef if !$exp;
    return $this if $exp <= 1;
    my $degree = $this->degree;
    return $this if $degree <= 0;
    my @coeff =
        map {
            my $c = $this->coeff($_);
            !($_ % $exp)? $c: !$c? (): return undef
        } 0 .. $degree;
    return $this->new(@coeff);
}

sub slice {
    my ($this, $start, $count) = @_;
    _check_int($start, $count);
    my $degree = $this->degree;
    my $end = $start+$count-1;
    if ($degree <= $end) {
        return $this if 0 == $start;
        $end = $degree;
    }
    return $this->new( map { $this->coeff($_) } $start .. $end );
}

sub differentiate {
    my ($this) = @_;
    my $n   = $this->coeff_zero;
    my $one = $this->coeff_one;
    return $this->new(
        map { $this->coeff($_) * ($n += $one) } 1..$this->degree
    );
}

sub integrate {
    my ($this, $const) = @_;
    my $zero = $this->coeff_zero;
    my $one  = $this->coeff_one;
    my $n    = $zero;
    if (!defined $const) {
        $const = $zero;
    }
    return $this->new(
        $const,
        map {
            $n += $one;
            my $c = $this->coeff($_);
            $zero == $c? $c: $c / $n
        } 0..$this->degree
    );
}

sub definite_integral {
    my ($this, $lower, $upper) = @_;
    my $ad = $this->integrate;
    return $ad->evaluate($upper) - $ad->evaluate($lower);
}

sub _make_ltz {
    my ($config, $zero) = @_;
    return 0 if !$config->{'fold_sign'};
    my $sgn = $config->{'sign_of_coeff'};
    return
        defined($sgn)?
            sub { $sgn->($_[0]) < 0     }:
            sub {        $_[0]  < $zero };
}

sub as_string {
    my ($this, $params) = @_;
    my %config = (
        @string_defaults,
        %{$params || $this->string_config || (ref $this)->string_config},
    );
    my $max_exp = $this->degree;
    if ($max_exp < 0) {
        $max_exp = 0;
    }
    my $result = q{};
    my $zero = $this->coeff_zero;
    my $ltz  = _make_ltz(\%config, $zero);
    my $one  = $this->coeff_one;
    my $with_variable = $config{'with_variable'};
    foreach my $exp ($config{'ascending'}? 0..$max_exp: reverse 0..$max_exp) {
        my $coeff = $this->coeff($exp);

        # skip term?
        if (
            $with_variable &&
            $exp < $max_exp &&
            $config{'fold_zero'} &&
            $coeff == $zero
        ) {
            next;
        }

        # plus/minus
        if ($ltz && $ltz->($coeff)) {
            $coeff = -$coeff;
            $result .= $config{q[] eq $result? 'leading_minus': 'minus'};
        }
        else{
            $result .= $config{q[] eq $result? 'leading_plus': 'plus'};
        }

        # coefficient
        if (
            !$with_variable ||
            !$config{'fold_one'} ||
            0 == $exp && $config{'fold_exp_zero'} ||
            $one != $coeff
        ) {
            $result .= $config{'convert_coeff'}->($coeff);
            next if !$with_variable;
            if (0 != $exp || !$config{'fold_exp_zero'}) {
                $result .= $config{'times'};
            }
        }

        # variable and exponent
        if (0 != $exp || !$config{'fold_exp_zero'}) {
            $result .= $config{'variable'};
            if (1 != $exp || !$config{'fold_exp_one'}) {
                $result .= $config{'power'} . $exp;
            }
        }
    }
    return join q{},
        $config{'prefix'},
        $config{'wrap'}->($this, $result),
        $config{'suffix'};
}

sub as_horner_tree {
    my ($this, $params) = @_;
    my %config = (@tree_defaults, %{$params});
    my $exp = $this->degree;
    if ($exp < 0) {
        $exp = 0;
    }
    my $zero = $this->coeff_zero;
    my $ltz  = _make_ltz(\%config, $zero);
    my $coeff = $this->coeff($exp);
    my $first_is_neg = $ltz && $ltz->($coeff);
    if ($first_is_neg) {
        $coeff = -$coeff;
    }
    my $result =
        $exp && $this->coeff_one == $coeff? undef:
        $config{'constant'}->($coeff);
    my $is_sum = 0;
    my $var_is_dynamic = 'CODE' eq ref $config{'variable'};
    my $variable = $var_is_dynamic? undef: $config{'variable'};
    while (0 <= --$exp) {
        $coeff = $this->coeff($exp);
        if ($is_sum) {
            $result = $config{'group'}->($result);
        }
        if ($var_is_dynamic) {
            $variable = $config{'variable'}->();
        }
        my $power = $variable;
        if ($config{'expand_power'}) {
            $is_sum = $zero != $coeff;
        }
        else {
            my $skip = 0;
            while ($zero == $coeff) {
                ++$skip;
                last if $skip > $exp;
                $coeff =  $this->coeff($exp - $skip);
            }
            if ($skip) {
                $exp -= $skip;
                ++$skip if 0 <= $exp;
                $power = $config{'power'}->($variable, $skip) if 1 < $skip;
            }
            $is_sum = 0 <= $exp;
        }
        $result =
            defined($result)? $config{'product'}->($result, $power): $power;
        if ($first_is_neg) {
            $result = $config{'negation'}->($result);
            $first_is_neg = 0;
        }
        if ($is_sum) {
            my $is_neg = $ltz && $ltz->($coeff);
            if ($is_neg) {
                $coeff = -$coeff;
            }
            my $const = $config{'constant'}->($coeff);
            $result = $config{$is_neg? 'difference': 'sum'}->($result, $const);
        }
    }
    if ($first_is_neg) {
        $result = $config{'negation'}->($result);
    }
    return $result;
}

sub as_power_sum_tree {
    my ($this, $params) = @_;
    my %config = (@tree_defaults, %{$params});
    my $exp = $this->degree;
    if ($exp < 0) {
        $exp = 0;
    }
    my $zero = $this->coeff_zero;
    my $ltz  = _make_ltz(\%config, $zero);
    my $one  = $this->coeff_one;
    my $result = undef;
    my $var_is_dynamic = 'CODE' eq ref $config{'variable'};
    my $variable = $var_is_dynamic? undef: $config{'variable'};
    while (0 <= $exp) {
        my $coeff = $this->coeff($exp);

        # skip term?
        next if defined($result) && $zero == $coeff;

        # variable and exponent
        my $term = undef;
        if (0 != $exp) {
            if ($var_is_dynamic) {
                $variable = $config{'variable'}->();
            }
            $term = $variable;
            if (1 != $exp) {
                if ($config{'expand_power'}) {
                    my $todo = $exp-1;
                    for (my $tmp=$exp; $tmp>1; --$tmp) {
                        if ($var_is_dynamic) {
                            $variable = $config{'variable'}->();
                        }
                        $term = $config{'product'}->($term, $variable);
                    }
                }
                else {
                    $term = $config{'power'}->($term, $exp);
                }
            }
        }

        # sign and coefficient
        my $is_neg = $ltz && $ltz->($coeff);
        if ($is_neg) {
            $coeff = -$coeff;
        }
        if (0 == $exp || $one != $coeff) {
            my $const = $config{'constant'}->($coeff);
            $term = 0 == $exp? $const: $config{'product'}->($const, $term);
        }

        # summation
        if (defined $result) {
            $result = $config{$is_neg? 'difference': 'sum'}->($result, $term);
        }
        else {
            $result = $is_neg? $config{'negation'}->($term): $term;
        }
    }
    continue {
        --$exp;
    }
    return $result;
}

sub gcd {
    my ($this, $that, $mod) = @_;
    defined $mod or $mod = 'mod';
    my $mod_op = $this->can($mod);
    $mod_op or croak "no such method: $mod";
    my ($this_d, $that_d) = ($this->degree, $that->degree);
    if ($this_d < $that_d) {
        ($this, $that) = ($that, $this);
        ($this_d, $that_d) = ($that_d, $this_d);
    }
    while (0 <= $that_d) {
        ($this, $that) = ($that, $this->$mod_op($that));
        ($this_d, $that_d) = ($that_d, $that->degree);
        $this_d > $that_d or croak 'bad modulo operator';
    }
    return $this;
}

sub xgcd {
    my ($this, $that) = @_;
    croak 'array context required' if !wantarray;
    my ($d1, $d2) = ($this->new($this->coeff_one), $this->new);
    if ($this->degree < $that->degree) {
        ($this, $that) = ($that, $this);
        ($d1, $d2) = ($d2, $d1);
    }
    my ($m1, $m2) = ($d2, $d1);
    while (!$that->is_zero) {
        my ($div, $mod) = $this->divmod($that);
        ($this, $that) = ($that, $mod);
        ($d1, $d2, $m1, $m2) =
            ($m1, $m2, $d1->sub_($m1->mul($div)), $d2->sub_($m2->mul($div)));
    }
    return ($this, $d1, $d2, $m1, $m2);
}

sub lcm {
    my $result = shift;
    foreach my $that (@_) {
        my $gcd  = $result->gcd($that);
        $result *= $that->div($gcd) if !$that->is_equal($gcd);
    }
    return $result;
}

sub inv_mod {
    my ($this, $that) = @_;
    my ($d, $d2) = ($that->xgcd($this))[0, 2];
    croak 'division by zero polynomial' if $that->is_zero || $d2->is_zero;
    return $d2->div_const($d->coeff($d->degree));
}

1;
__END__

=head1 NAME

Math::Polynomial - Perl class for polynomials in one variable

=head1 VERSION

This documentation refers to version 1.019 of Math::Polynomial.

=head1 SYNOPSIS

  use Math::Polynomial 1.000;

  $p = Math::Polynomial->new(0, -2, 0, 1);    # x^3 - 2 x

  print "p = $p\n";                           # p = (x^3 + -2 x)

  $p->string_config({ fold_sign => 1 });
  print "p = $p\n";                           # p = (x^3 - 2 x)

  $q = $p->new(0, 3, 0, -4, 0, 1);            # x^5 - 4 x^3 + 3 x

  $r = $p ** 2 - $p * $q;                     # arithmetic expression
  $bool = $p == $q;                           # boolean expression

  ($s, $t) = $r->divmod($q);                  # q * s + t = r

  $u = $r->gcd($q);                        # greatest common divisor,
                                           # here: u = 3 x
  $v = $u->monize;                         # v = x

  $y = $p->evaluate(0.5);                     # y = p(0.5) = -0.875
  $d = $q->degree;                            # d = degree(q) = 5

  $w = $p->interpolate([0..2], [-1, 0, 3]);   # w(0) = -1, w(1) = 0,
                                              # w(2) = 3

  use Math::Complex;
  $p = Math::Polynomial->new(i, 1+i);         # p(x) = (1+i)*x + i

=head1 DESCRIPTION

Math::Polynomial objects represent polynomials in one variable,
i.e. expressions built with finitely many additions, subtractions
and multiplications of the variable and some constants.  A standard
way of writing down a polynomial in one variable is as a sum of
products of some constant and a power of x, ordered by powers of
x.  The constants in those terms are called coefficients.

The polynomial I<p(x) = 0> is called the zero polynomial.  For
polynomials other than the zero polynomial, the exponent of the
highest power of x with a nonzero coefficient is called the degree
of the polynomial.

New Math::Polynomial objects can be created using a variety of
constructors, or as results of expressions composed from existing objects.
Math::Polynomial objects are immutable with respect to mathematical
properties; all operations on polynomials create and return new objects
rather than modifying anything.

The module works with various types of coefficients, like ordinary
floating point numbers, complex numbers, arbitrary precision
rationals, matrices, elements of finite fields, and lots of others.
All that is required is that the coefficients are either Perl numbers
or objects with suitably overloaded arithmetic operators.  Operations
on polynomials are carried out by reducing them to basic operations
in the domain of their coefficients.

Math::Polynomial objects are implicitly bound to their coefficient
space, which will be inherited when new polynomials are derived
from existing ones, or determined from actual coefficients when
polynomials are created from scratch.  It is the responsibility of
the application not to mix coefficients that cannot be added to or
multiplied by each other.

Note that ordinary Perl numbers used as coefficients have the disadvantage
that rounding errors may lead to undesired effects, such as unexpectedly
non-zero division remainders or failing equality checks.

=head1 CLASS VARIABLES

=over 4

=item I<$VERSION>

C<$VERSION> contains the current version number of the module.  Its
most typical use is the statement:

  use Math::Polynomial 1.000;

This will make sure the module version used is at least 1.000, which
is recommended because previous versions had a different API.

=item I<$max_degree>

C<$max_degree> limits the arguments for the I<pow>, I<shift_up>, and
I<inflate> operators, and the I<monomial> constructor, see L</pow>.
Its default value is ten thousand.  It can be undefined to disable any
size checks.

=back

=head1 CLASS METHODS

=head2 Constructors

=over 4

=item I<new($coeff0, $coeff1, $coeff2, ...)>

C<Math::Polynomial-E<gt>new(@coeff)> creates a new polynomial with
the given coefficients for x to the power of zero, one, two, etc.
For example, C<Math::Polynomial-E<gt>new(7, 1)> creates an object
representing I<p(x) = 7+x>.

Note that coefficients are specified in ascending order of powers
of x.  The degree of the polynomial will be at most I<n-1> if I<n>
coefficients are given, less if one or more of the highest-order
coefficients are zero.

Specifying at least one coefficient (which may be zero) ensures
that the created polynomials use the desired coefficient space.
Without any parameters, I<new> creates a zero polynomial on Perl
numeric values.

=item I<monomial($degree)>

=item I<monomial($degree, $coeff)>

C<Math::Polynomial-E<gt>monomial($degree, $coeff)> creates a
polynomial with $coeff as the coefficient for x to the power of
$degree, and all other coefficients zero.  The degree must be a
non-negative integer number.  If $coeff is omitted, it defaults to
the Perl scalar B<1>.

To prevent accidential excessive memory consumption, C<$degree>
must be at most C<$Math::Polynomial::max_degree>.

=item I<interpolate([$x1, $x2, ...], [$y1, $y2, ...])>

C<Math::Polynomial-E<gt>interpolate(\@x_values, \@y_values)> creates
a Newton/Lagrange interpolation polynomial passing through support
points with the given x- and y-coordinates.  The x-values must be
mutually distinct.  The number of y-values must be equal to the
number of x-values.  For I<n> support points this takes I<O(n**2)>
additions, subtractions, multiplications, divisions and comparisons
each in the coefficient space.  The result will be a polynomial of
degree I<n-1> at most.

Note that with increasing numbers of support points, interpolation
tends to get inaccurate if carried out with limited numerical
precision.  Furthermore, high-degree interpolation polynomials can
oscillate wildly in the neighbourhood of the support points, let
alone elswhere, unless the support point x-values are carefully
chosen.  This is due to the nature of these functions and not a
fault of the module.  A script demonstrating this phenomenon can
be found in the Math-Polynomial examples directory.

=item I<from_roots($x1, $x2, ...)>

C<Math::Polynomial-E<gt>from_roots(@x_values)> creates the monic
polynomial with the given set of roots, i.e. for x-values
I<x1, x2, ..., xn> the product I<(x-x1)*(x-x2)*...*(x-xn)>.  This
is a Polynomial of degree I<n> if I<n> roots are given.  The x-values
can be given in any order and do not need to be distinct.  For I<n>
roots this takes I<O(n*n)> multiplications and subtractions in the
coefficient space.

=back

=head2 Other class methods

Some properties governing default behaviour can be accessed through the
class method I<string_config>.  See L</String Representation>.

=head1 OBJECT METHODS

=head2 Constructors

Each class-level constructor can be used as an object method, too,
i.e. be invoked from an object rather than a class name.  This way,
coefficient space properties are passed on from the invocant object
to the new object, saving some initial coefficient analysis.  Other
properties like per-object stringification settings (explained
below) are inherited likewise.

=over 4

=item I<new($coeff0, $coeff1, $coeff2, ...)>

If C<$p> refers to a Math::Polynomial object, the object method
C<$p-E<gt>new(@coeff)> creates and returns a new polynomial sharing
inheritable properties with C<$p>, but with its own list of coefficients
as specified in C<@coeff>.

=item I<monomial($degree)>

=item I<monomial($degree, $coeff)>

C<$p-E<gt>monomial($degree, $coeff)> creates a monomial like
C<Math::Polynomial-E<gt>monomial($degree, $coeff)>, but sharing
inheritable properties with C<$p>.  If C<$coeff> is omitted it
defaults to the multiplicative unit element of the coefficient space
of C<$p>.

To prevent accidential excessive memory consumption, C<$degree>
must be at most C<$Math::Polynomial::max_degree>.

=item I<interpolate([$x1, $x2, ...], [$y1, $y2, ...])>

C<$p-E<gt>interpolate(\@x_values, \@y_values)> is the object method
usage of the Newton/Lagrange interpolation polynomial constructor
(see above).  It creates a polynomial passing through support points
with the given x- and y-coordinates.  The x-values must be mutually
distinct.  The number of y-values must be equal to the number of
x-values.  All values must belong to the coefficient space of C<$p>.

=item I<from_roots($x1, $x2, ...)>

If C<$p> refers to a Math::Polynomial object, the object method
C<$p-E<gt>from_roots(@x_values)> creates the monic polynomial with
the given set of roots, i.e. for x-values I<x1, x2, ..., xn> the
product I<(x-x1)*(x-x2)*...*(x-xn)>, sharing inheritable properties
with C<$p>.  For I<n> roots this takes I<O(n*n)> multiplications
and subtractions in the coefficient space.

=item I<clone>

C<$p-E<gt>clone> returns a new object equal to C<$p>.  This method
will rarely be needed as Math::Polynomial objects are immutable
except for their stringification configuration (cf. L</string_config>).

=back

=head2 Property Accessors

=over 4

=item I<coefficients>

C<$p-E<gt>coefficients> returns the coefficients of C<$p> in ascending
order of exponents, including zeroes, up to the highest-order
non-zero coefficient.  The result will be a list of I<n+1> coefficients
for polynomials of degree I<n>, or a single zero coefficient for
zero polynomials.

=item I<coeff>

C<$p-E<gt>coeff> returns the coefficients of C<$p> much like
C<$p-E<gt>coefficients>, but for zero polynomials the result will
be an empty list.

(Mnemonic for I<coeff> versus I<coefficients>: Shorter name, shorter
list.)

=item I<coeff($exp)>

C<$p-E<gt>coeff($exp)> returns the coefficient of degree C<$exp>
of C<$p>.  If C<$exp> is less than zero or larger than the degree
of C<$p>, the zero element of the coefficient space is returned.

=item I<coeff_zero>

C<$p-E<gt>coeff_zero> returns the zero element of the coefficient
space of C<$p>, i.e. the neutral element with respect to addition.

=item I<coeff_one>

C<$p-E<gt>coeff_one> returns the multiplicative unit element of the
coefficient space of C<$p>, i.e. the neutral element with respect
to multiplication.

=item I<degree>

C<$p-E<gt>degree> returns B<-1> if C<$p> is a zero polynomial,
otherwise the degree of C<$p>.

=item I<proper_degree>

C<$p-E<gt>proper_degree> returns B<undef> if C<$p> is a zero
polynomial, otherwise the degree of C<$p>.  This can be useful in
order to catch incorrect numerical uses of degrees where zero
polynomials might be involved.

=item I<number_of_terms>

C<$p-E<gt>number_of_terms> returns the number of non-zero coefficients
of the polynomial C<$p>.

=item I<is_monic>

C<$p-E<gt>is_monic> returns a boolean value which is true if C<$p> is
monic, which means it is not the zero polynomial and its highest-degree
coefficient is equal to one.  Cf. L</monize>.

=item I<is_even>

C<$p-E<gt>is_even> returns a boolean value which is true if C<$p> is
an even function, which means it is identical to its reflection about
the axis I<x = 0>.

=item I<is_odd>

C<$p-E<gt>is_odd> returns a boolean value which is true if C<$p> is an
odd function, which means it is the negative of its reflection about
the axis I<x = 0>.

=back

=head2 Evaluation

=over 4

=item I<evaluate>

C<$p-E<gt>evaluate($x)> computes the value of the polynomial function
given by C<$p> at the position C<$x>.  For polynomials of degree
I<n>, this takes I<n> multiplications and I<n> additions in the
coefficient space.

=back

=head2 Comparison Operators

All comparison operators return boolean results.

Note that there are no order-checking comparisons (E<lt>, E<lt>=, E<gt>,
E<lt>=E<gt>, ...) as neither polynomial nor coefficient spaces in general
need to be ordered spaces.

=over 4

=item C<!>

=item I<is_zero>

C<$p-E<gt>is_zero> or short C<!$p> or C<not $p> checks whether C<$p>
is a zero polynomial.

=item I<is_nonzero>

C<$p-E<gt>is_nonzero> checks whether C<$p> is not a zero polynomial.
This method may be implicitly called if an object is used in boolean
context such as the condition of a while loop or in an expression
with boolean operators such as C<&&> or C<||>.

=item C<==>

=item I<is_equal>

C<$p-E<gt>is_equal($q)> or short C<$p == $q> checks whether C<$p> is
equivalent to C<$q>.  The result is true if both polynomials have the
same degree and the same coefficients.  For polynomials of equal degree
I<n>, this takes at most I<n+1> equality checks in the coefficient space.

Note that I<p == q> implies that I<p(x) == q(x)> for every I<x>,
but the converse implication is not true for some coefficient spaces.

=item C<!=>

=item I<is_unequal>

C<$p-E<gt>is_unequal($q)> or short C<$p != $q> checks whether C<$p>
is not equivalent to C<$q>.  The result is true if the polynomials
have different degree or at least one pair of coefficients of same
degree is different.  For polynomials of equal degree I<n>, this
takes at most I<n+1> equality checks in the coefficient space.

=back

=head2 Arithmetic Operators

=over 4

=item unary C<->

=item I<neg>

C<$p-E<gt>neg> or short C<-$p> calculates the negative of a polynomial.
For a polynomial of degree I<n>, this takes I<n+1> negations in the
coefficient space.

=item C<+>

=item I<add>

C<$p-E<gt>add($q)> or short C<$p + $q> calculates the sum of two polynomials.
For polynomials of degree I<m> and I<n>, this takes I<1+min(m, n)> additions
in the coefficient space.

=item C<->

=item I<sub_>

C<$p-E<gt>sub_($q)> or short C<$p - $q> calculates the difference
of two polynomials.  For polynomials of degree I<m> and I<n>, this
takes I<1+min(m, n)> subtractions in the coefficient space, plus
I<n-m> negations if I<n> is greater than I<m>.

The trailing underscore in the method name may look a bit odd but
will prevent primitive syntax-aware tools from stumbling over
"misplaced" I<sub> keywords.

=item C< *>

=item I<mul>

C<$p-E<gt>mul($q)> or short C<$p * $q> calculates the product of two
polynomials.  For polynomials of degree I<m> and I<n>, this takes
I<(m+1)*(n+1)> multiplications and I<m*n> additions in the coefficient
space.

=item I<divmod>

C<($q, $r) = $p1-E<gt>divmod($p2)> divides a polynomial by another
polynomial and returns the polynomial part of the quotient, and the
remainder.  The second polynomial must not be a zero polynomial.
The remainder is a polynomial of lesser degree than the second
polynomial and satisfies the equation I<$p1 == $p2*$q + $r>.  For
polynomials of degree I<m> and I<n>, I<mE<gt>=n>, this takes I<m+1-n>
divisions, I<(m+1-n)*n> multiplications and I<(m+1-n)*n> subtractions
in the coefficient space.

=item C</>

=item I<div>

C<$p-E<gt>div($q)> or short C<$p / $q> calculates the polynomial part
of the quotient of two polynomials.  This takes the same operations
in the coefficient space as I<divmod>.

=item C<%>

=item I<mod>

C<$p-E<gt>mod($q)> or short C<$p % $q> calculates the remainder from
dividing one polynomial by another.  This takes the same operations
in the coefficient space as I<divmod>.

=item I<mmod>

C<$p-E<gt>mmod($q)> (modified mod) calculates the remainder from
dividing one polynomial by another, multiplied by some constant.
The constant is I<a**d> where I<a> is the highest coefficient of
I<q> and I<d = degree(p) - degree(q) + 1>, if I<degree(p) E<gt> degree(q)>,
otherwise I<d = 0>.  This operation is suitable to substitute I<mod>
in the Euclidean algorithm and can be calculated without division
in the coefficient space.  For polynomials of degree I<m> and I<n>,
I<mE<gt>=n>, this takes I<(m+1-n)*(m+3*n)/2> multiplications and
I<(m+1-n)*n> subtractions in the coefficient space.

=item C< **>

=item I<pow>

C<$p-E<gt>pow($n)> or short C<$p ** $n> calculates a power of
a polynomial.  The exponent C<$n> must be a non-negative integer.
To prevent accidential excessive time and memory consumption, the
degree of the result must be at most C<$Math::Polynomial::max_degree>.
The degree limit can be configured, see L</$max_degree>.  Calculating
the I<n>-th power of a polynomial of degree I<m> takes I<O(m*m*n*n)>
multiplications and additions in the coefficient space.

=item I<pow_mod>

C<$p1-E<gt>pow_mod($n, $p2)> is equivalent to C<($p1 ** $n) % $p2>,
except that the modulo operation is repeatedly applied to intermediate
results in order to keep their degrees small.  The exponent C<$n>
must be a non-negative integer.

=item I<exp_mod>

C<$p-E<gt>exp_mod($n)> is equivalent to C<(x ** $n) % $p>.
The exponent C<$n> must be a non-negative integer.

=item I<add_const>

=item I<sub_const>

=item I<mul_const>

=item I<div_const>

The arithmetic operations C<add_const>, C<sub_const>, C<mul_const>
and C<div_const> can be used to efficiently add a constant to or
subtract a constant from a polynomial, or multiply or divide a
polynomial by a constant, respectively.

Overloaded arithmetic operators (I<+>, I<->, I<*>, ...) work
with constants in place of polynomial operands, too, by converting
non-polynomial arguments into constant polynomials first.  However,
this usage is both less efficient and less obvious, and therefore
not recommended.

Note that there is no use for a C<mod_const> method, as polynomial
division by a constant always yields a zero remainder.

=item C<E<lt>E<lt>>

=item I<shift_up>

C<$p-E<gt>shift_up($n)> or short C<$p E<lt>E<lt> $n> calculates the
product of a polynomial and a power of x.  The exponent C<$n> must
be a non-negative integer.  To prevent accidential excessive memory
consumption, the degree of the result must be at most
C<$Math::Polynomial::max_degree>.

=item C<E<gt>E<gt>>

=item I<shift_down>

C<$p-E<gt>shift_down($n)> or short C<$p E<gt>E<gt> $n> divides a
polynomial by a power of x and returns the polynomial part of the
result, i.e. discarding negative powers of x.  The exponent C<$n>
must be a non-negative integer.

Shifting up or down is more efficient than multiplication or division
as it does not take any operations in the coefficient space.

=item I<slice>

C<$p-E<gt>slice($m, $n)> is equivalent to:

  $xm = $p->monomial($m);
  $xn = $p->monomial($n);
  ($p / $xm) % $xn

I.e., it returns a polynomial built from a slice of the coefficients
of the original polynomial starting with degree C<$m>, and at most
C<$n> coefficients.  However, it is more efficient than division
and modulo as it does not perform any operations in the coefficient
space.  The indexes C<$m> and C<$n> must be non-negative integers.

=item I<inflate>

C<$p-E<gt>inflate($n)> is equivalent to
C<$p-E<gt>nest($p-E<gt>monomial($n))>, only more efficient, as it does
not perform any operations in the coefficient space.  It returns the
polynomial resulting from replacing the variable I<x> by the I<n>th
power of I<x> in the original polynomial.

The exponent C<$n> must be a non-negative integer.  To prevent accidential
excessive memory consumption, the degree of the result must be at most
C<$Math::Polynomial::max_degree> (if a maximal degreee is defined).

=item I<deflate>

C<$p = $q-E<gt>deflate($n)> is the inverse operation of
C<$q = $p-E<gt>inflate($n)>. C<$q> must be a polynomial with zero
coefficients except for exponents that are an integer multiple of C<$n>.
For other polynomials, an undefined value is returned.

As inflating by exponent zero is not a reversible operation, deflating
by zero is not defined and thus yields B<undef>, too.

For a polynomial of degree I<d>, deflating by exponent I<n> takes
I<d * (n - 1) / n> comparisons with zero in the coefficient space.

=item I<mul_root>

C<$p-E<gt>mul_root($c)> calculates the product of a polynomial I<p>
and the linear term I<(x - c)>.  The result is a polynomial that
evaluates to zero at the given root I<c>.  For polynomials of degree
I<n>, this takes I<n+1> multiplications and I<n+1> subtractions.

=item I<div_root>

C<$p-E<gt>div_root($c)> divides a polynomial I<p> by a linear factor
I<(x - c)>, discarding any remainder.  For polynomials of degree I<n>,
this takes I<n> multiplications and I<n> additions in the coefficient
space.

This method originally had an optional second argument C<$check>,
enabling a check to make sure the value of C<$c> is actually a root
of C<$p>, i.e. the discarded remainder is zero.  This usage is
deprecated, however, in favour of using C<divmod_root> and explicitly
checking the remainder.

=item I<divmod_root>

C<($q, $r) = $p-E<gt>divmod_root($c)> divides a polynomial I<p>
by a linear factor I<(x - c)> and returns the result and remainder.
The remainder will be a zero polynomial if I<c> is a root of I<p>,
otherwise a constant polynomial.  For polynomials of degree I<n>, this
takes I<n> multiplications and I<n> additions.

This method must be called in array context.

Note that there is no need for a I<mod_root> method, as that would
be equivalent to I<evaluate>.

=item I<monize>

C<$p-E<gt>monize> converts an arbitrary non-zero polynomial to a
monic polynomial via division by its highest-order coefficient.
The result will be monic, i.e. with a highest-order coefficient of
one, if the invocant was not the zero polynomial, otherwise the
zero polynomial.  Monization of a non-zero polynomial of degree I<n>
takes I<n> divisions in the coefficient space.

=back

=head2 Assignment Operators

=over 4

=item C<=>

=item C<+=>

=item C<-=>

=item C<*=>

=item C</=>

=item C<%=>

=item C<**=>

=item C<E<lt>E<lt>=>

=item C<E<gt>E<gt>=>

=item C<&&=>

=item C<||=>

As Math::Polynomial objects are immutable with respect to their
arithmetic properties, assignment operators like C<=>, C<+=>, C<-=>,
C<*=> etc. will always replace the object that is being assigned
to, rather than mutate it.  Thus polynomial objects can safely be
"modified" using assignment operators, without side effects on other
variables referencing the same objects.

Note that the short-circuit behaviour of C<&&> and C<||>, which
return the last expression evaluated, implies that C<&&=> and C<||=>
conditionally replace a polynomial by a given expression (another
polynomial, say), not just a boolean value.

=back

=head2 Miscellaneous Operators

=over 4

=item I<nest>

C<$p1-E<gt>nest($p2)> calculates the nested polynomial I<p1(p2(x))>
from two polynomials I<p1(x)> and I<p2(x)>.  For polynomials of
degree I<m> and I<n> this takes I<O(m*m*n*n)> multiplications and
additions in the coefficient space.  The result will be a polynomial
of degree I<m*n> if neither of the polynomials is a zero polynomial,
otherwise a constant or zero polynomial.

=item I<unnest>

C<$p1 = $q-E<gt>unnest($p2)> is the inverse operation of
C<$q_=_$p1-E<gt>nest($p2)>.  It checks whether the polynomial C<$q> can
in fact be derived from another polynomial C<$p1> with a substitution
of the variable by C<$p2>.  If so, it returns C<$p1>, otherwise B<undef>.

Nesting a constant polynomial within a polynomial is equivalent to
simply evaluating the latter, yielding a constant. As this operation
is not reversible, trying to unnest a constant from any polynomial also
yields B<undef>.

Unnesting a polynomial of degree I<d> from a polynomial with degree I<n*d>
takes I<n> polynomial divisions.

=item I<mirror>

C<$p-E<gt>mirror> gives the reflection of a polynomial about the axis
I<x = 0>.  This is equivalent to the substitution of I<x> by I<-x>,
or C<$p-E<gt>nest(- $p-E<gt>monomial(1))>, only more efficient.  For a
polynomial of degree I<n>, it takes I<floor( (n+1)/2 )> negations in
the coefficient space.

=item I<gcd>

C<$p1-E<gt>gcd($p2, $mod)> calculates a greatest common divisor of
two polynomials, using the Euclidean algorithm and the modulo
operator as specified by name.  The C<$mod> parameter is optional
and defaults to C<'mod'>.  With polynomials of degree I<m> and I<n>,
I<mE<gt>=n>, and the default modulo operator I<mod>, this takes
at most I<n> polynomial divisions of decreasing degrees or I<O(m+n)>
divisions and I<O(m*n)> multiplications and subtractions in the
coefficient space.  With the I<mmod> operator, this takes I<O(m*n)>
multiplications and subtractions in the coefficient space.

I<mmod> can have advantages over I<mod> in situations where division
in the coefficient space is much more expensive than multiplication.

Note that the coefficient space is treated as a field and thus no effort
is made to find common divisors of coefficients once the degree of the
result is determined.

=item I<xgcd>

C<($d, $d1, $d2, $m1, $m2) = $p1-E<gt>xgcd($p2)> calculates a
greatest common divisor I<d> and four polynomials I<d1>, I<d2>,
I<m1>, I<m2>, such that I<d = p1*d1 + p2*d2>, I<0 = p1*m1 + p2*m2>,
I<degree(m1*d) = degree(p2)>, I<degree(m2*d) = degree(p1)>, using
the extended Euclidean algorithm.  With polynomials of degree I<m>
and I<n>, I<mE<gt>=n>, this takes at most I<n> polynomial divisions
and I<2*n> polynomial multiplications and subtractions of decreasing
degrees, or, in the coefficient space: I<O(m+n)> divisions and
I<O(m*n)> multiplications and subtractions.

=item I<lcm>

C<$p1-E<gt>lcm($p2)> calculates a least common multiple of two
polynomials, using the identity I<p1 * p2 = lcm(p1, p2) * gcd(p1, p2)>.
This takes the same operations as I<gcd> plus two polynomial
multiplications and one polynomial division.

Optionally, I<lcm> may be called with an arbitrary number of other
operands and will return a least common multiple of all given polynomials.

Note that least means least degree here.
With non-monic operands, the result may also be not monic.

=item I<inv_mod>

C<$q = $p1-E<gt>inv_mod($p2)> calculates the multiplicative pseudo-inverse
I<q> of a polynomial I<p1> modulo another polynomial I<p2>.  I<p2>
must not be a zero polynomial, and I<p1> must not be equivalent to zero
modulo I<p2>.

If I<p1> and I<p2> are relatively prime, the result will be a true
modular inverse, i.e. I<q * p1 % p2> will be the same as I<p2 ** 0>.
In any case, I<q> will be chosen such that I<q * p1 % p2> is the
monic greatest common divisor of I<p1> and I<p2>.

I<inv_mod> takes the same operations in the coefficient space as I<xgcd>
plus I<monize>.

=back

=head2 Calculus Operators

Calculus operators as presented here are most meaningful on spaces
such rational or real or complex numbers.  Starting with version 1.005
of Math::Polynomial, calculus operators are no longer restricted to
coefficient spaces compatible with Perl integers.  This means these
operators do not mix coefficients and Perl integers any more, but does
not imply they are equally useful with every kind of coefficients.

=over 4

=item I<differentiate>

C<$p-E<gt>differentiate> calculates the first derivative of a
polynomial.  For a polynomial of degree I<n>, this takes I<n>
multiplications and I<n> additions in the coefficient space.

=item I<integrate>

C<$p-E<gt>integrate> calculates an antiderivative of a polynomial.
The coefficient of degree zero of the result will be zero.
C<$p-E<gt>integrate($c)> does the same but adds the constant C<$c>.
For a polynomial of degree I<n>, both forms of integration take I<n+1>
comparisons with zero, at most I<n+1> divisions, and I<n+1> additions
in the coefficient space.  Note that in coefficient spaces with zero
divisors this operation might fail due to division by zero.

=item I<definite_integral>

C<$p-E<gt>definite_integral($x1, $x2)> calculates the value of the
definite integral from C<$x1> to C<$x2> over the polynomial function
given by C<$p>.  For real numbers I<x1 E<lt> x2>, this can be
interpreted as the signed area bound by the lines I<x=x1>, I<y=0>,
I<x=x2> and the graph of I<p(x)>, where parts below the x-axis are
regarded as negative.

For a polynomial of degree I<n>, this takes the same operations
as I<integrate> plus twice I<evaluate> plus a subtraction in the
coefficient space.  If you need to calculate more than one definite
integral over the same polynomial function, it is more efficient
to store an antiderivative once (see L</integrate>) and evaluate it
at the different interval limits.  The statement...

  $a = $p->definite_integral($x1, $x2);

... is essentially equivalent to:

  $p_int = $p->integrate;
  $a     = $p_int->evaluate($x2) - $p_int->evaluate($x1);

=back

=head2 String Representation

=over 4

=item C<"">

=item I<as_string>

In string context, Math::Polynomial objects will automatically be
converted to a character string, which is the same as the result
of the I<as_string()> method when called without parameter.

An optional configuration hashref controls many layout aspects of the
string representation.  In the absence of an explicit configuration,
a per-object default configuration is used, and in the absence of that,
a per-class default configuration (see L</string_config>).

Each individual configuration setting has a default value as defined
in the next section.

=item I<string_config>

C<$p-E<gt>string_config($hashref)> sets the per-object default
stringification configuration to C<$hashref>.  C<$hashref> may
be B<undef> to remove a previously set configuration.

C<$p-E<gt>string_config> returns the per-object default stringification
configuration as a reference to a hash, if present, otherwise undef.

C<Math::Polynomial-E<gt>string_config($hashref)> sets the
per-class default stringification configuration to C<$hashref>.
C<Math::Polynomial-E<gt>string_config> returns that configuration.
It should always refer to an existing hash, which may be empty.

A per-object configuration will be propagated to any new objects created
from an object.  Thus it is easy to use consistent settings without
having to touch global parameters.

=back

=head2 Stringification Configuration Options

=over 4

=item ascending

True value: order coefficients from lowest to highest degree;
False value (default): from highest to lowest.

=item with_variable

True value (default): display coefficients together with powers of
the variable; false value: display coefficients alone.  False implies
that I<fold_zero>, I<times>, I<power> and I<variable> will have no
effect.

=item fold_sign

True value: contract the addition symbol and the sign of a negative
value to a single subtraction symbol; false value (default): do not
carry out this kind of replacement.  True is only allowed if the
coefficient space defines a native "less than" operator or the
configuration parameter I<sign_of_coeff> (see below) is set.

=item fold_zero

True value (default): suppress terms with coefficients equal to
zero; false value: do not suppress any terms.  Zero polynomials
are represented with a zero constant term in any case.

=item fold_one

True value (default): suppress coefficients equal to one when
multiplied by a variable power; false value: do not suppress factors
of one.  Note that coefficients very close but not quite equal to
one might be stringified to one without being caught by this rule.

=item fold_exp_zero

True value (default): suppress the variable and the zero exponent
in the constant term; false value: display even the constant term
with a variable power.

=item fold_exp_one

True value (default): suppress the exponent in the term of the
variable to the power of one; false value: display even the linear
term with an exponent.

=item convert_coeff

Code reference specifying a function that takes a coefficient value
and returns a string representing that value.  Default is ordinary
stringification.

=item sign_of_coeff

If defined, code reference specifying a function that takes a
coefficient value and returns a negative, zero, or positive integer
if the argument is negative, zero, or positive, respectively.
Default is B<undef>.

This parameter can be used to let stringification distinguish
"negative" from other values where the coefficient space is not an
ordered space, i.e. lacking operators like C<E<lt>> (less than).

=item plus

Addition symbol to put between terms.  Default is a plus character
surrounded by blanks.

=item minus

Subtraction symbol replacing a plus symbol and a negative sign, if
applicable (see I<fold_sign>).  Default is a minus character
surrounded by blanks.

=item leading_plus

Sign symbol to put before the first term unless I<fold_sign> is true
and the coefficient is negative.  Default is an empty string.

=item leading_minus

Sign symbol replacing a negative sign at the first term, if
I<fold_sign> is true.  Default is a minus followed by a blank.

=item times

Multiplication symbol to put between the coefficient and the variable
in each term.  Default is a blank.

=item power

Exponentiation symbol to put between the variable and the exponent
in each term.  Default is a caret (C<^>).

=item variable

Symbol representing the variable.  Default is a lower case x.

=item prefix

Prefix to prepend to the entire polynomial.  Default is a left
parenthesis.

=item suffix

Suffix to append to the entire polynomial.  Default is a right
parenthesis.

=item wrap

Wrapping or post-processing function: Coderef called with the
polynomial object and its raw stringification (without prefix and
suffix) to return a final stringification (still without prefix and
suffix).  Default is a function returning its second argument.

=back

=head2 Other Conversions

Tree conversions can be used to generate data structures such as
operand trees from polynomials.  There is a distinction between two
types of construction -- a power sum scheme essentially follows the
canonical way of describing polynomials as a sum of multiples of
powers of the variable, while a Horner scheme avoids repeated
exponentiation and uses just alternating additions of coefficients
and multiplications by the variable, describing a polynomial in a
way that can be more efficiently evaluated.

=over 4

=item I<as_horner_tree>

C<$p-E<gt>as_horner_tree($config)> can generate nested data structures
from a polynomial C<$p>, employing a Horner scheme.  A Horner scheme
evaluates a polynomial using alternating additions and multiplications.
For convenience, consecutive multiplications by the variable are
condensed to a single multiplication by a power of the variable.
In order to avoid exponentiation altogether, the configuration option
I<expand_power> can be set to a true value.

The C<$config> hashref is a mandatory parameter.  It defines what
functions are to be called at each step of the tree construction.
All configuration components are described in the next section.

=item I<as_power_sum_tree>

C<$p-E<gt>as_power_sum_tree($config)> can generate nested data
structures from a polynomial C<$p>, where the polynomial is built
as a sum of multiples of powers of a variable.

The C<$config> hashref is a mandatory parameter.  It defines what
functions are to be called at each step of the tree construction.
All configuration components are described in the next section.

=back

=head2 Tree Conversion Configuration Options

=over 4

=item fold_sign

Boolean, default false.  Defines whether I<negation> and I<difference>
operations should be employed in order to avoid negative constants.

A true value is only allowed if the coefficient space is an ordered
space and defines a C<E<lt>> comparison operator for coefficients,
or the configuration parameter I<sign_of_coeff> (see below) is set.

=item expand_power

Boolean, default false.  Defines whether the I<power> operation
should be avoided in favour of consecutive multiplications.  Presumably
more useful in horner trees than power sum trees.

=item variable

Node to insert for the variable.  If it is a coderef, the given
subroutine will be called every time a variable is inserted into
the tree and its return value will be used, otherwise the (same)
value will be used directly each time.

=item constant

Coderef, node factory for constants.  Called with a coefficient as
single parameter.  The result is used as a node representing that
coefficient as a constant.

=item negation

Coderef, node negation.  Called with a node as single parameter.
The result is used as negative of the original node.  Only used if
I<fold_sign> is true.

=item sum

Coderef, node summation.  Called with two node parameters, ordered
in decreasing complexity.  The result is propagated as sum of the
original nodes.

=item difference

Coderef, node subtraction.  Called with two node parameters, ordered
in decreasing complexity.  The result is propagated as difference
of the original nodes.  Only used if I<fold_sign> is true.

=item product

Coderef, node multiplication.  Called with two node parameters,
ordered like this: If one node is the variable or a power of the
variable, it will be the second parameter, while a constant or a
complex tree will be the first parameter.  The result is propagated
as product of the original nodes.

=item power

Coderef, exponentiation.  Called with a node representing the
variable and an integer number greater than one.  Used for both
power sum trees (where degree is at least two) and Horner trees
(where some terms other than the constant term are zero).  Note
that the second parameter is not a node but a plain number, in
order to support data structures allowing only integer exponentiation.
Not used if I<expand_power> is set to a true value (in either kind
of tree).

=item group

Coderef, grouping.  Only used with Horner trees, optional.
Called with a node representing a subexpression that would
have to be in parentheses to maintain operator precedence.

=item sign_of_coeff

If defined, code reference specifying a function that takes a
coefficient value and returns a negative, zero, or positive integer
if the argument is negative, zero, or positive, respectively.
Default is B<undef>.

This parameter can be used to let tree construction distinguish
"negative" from other values where the coefficient space is not an
ordered space, i.e. lacking operators like C<E<lt>> (less than).

=back

=head1 PROTECTED METHODS

=head2 Protected class method

=over 4

=item I<_NFIELDS>

C<Math::Polynomial::_NFIELDS> is the constant number of object attributes
in the Math::Polynomial base class.  Child classes may use it as an
offset into the underlying array from where attributes of extensions can
be stored.  Application code must not use it, nor rely on the internal
type of object instances.

=back

=head1 EXAMPLES

  use Math::Polynomial 1.000;

  # simple constructors:
  $p  = Math::Polynomial->new(0, -3, 0, 2);    # (2*x**3 - 3*x)
  $zp = Math::Polynomial->new(0);              # the zero polynomial
  $q  = Math::Polynomial->monomial(3, 2);      # (2*x**3)
  $q  = Math::Polynomial->from_roots(5, 6, 7); # (x-5)*(x-6)*(x-7)

  # Lagrange interpolation:
  $q = Math::Polynomial->interpolate([0..3], [0, -1, 10, 45]);
                                               # (2*x**3 - 3*x)

  # constructors used as object methods:
  $q = $p->new(0, -3, 0, 2);                   # (2*x**3 - 3*x)
  $q = $p->new;                                # the zero polynomial
  $q = $p->monomial(3, 2);                     # (2*x**3)
  $q = $p->monomial(3);                        # (x**3)
  $q = $p->interpolate([0..3], [0, -1, 10, 45]); # (2*x**3 - 3*x)
  $q = $p->from_roots(5, 6, 7);                # (x-5)*(x-6)*(x-7)
  $q = $p->clone;                              # q == p

  # properties
  @coeff = $p->coefficients;                   #    (0, -3, 0, 2)
  @coeff = $p->coeff;                          #    (0, -3, 0, 2)
  $coeff = $p->coeff(0);                       #     0
  $coeff = $p->coeff(1);                       #        -3
  $coeff = $p->coeff(2);                       #            0
  $coeff = $p->coeff(3);                       #               2
  $coeff = $p->coeff(4);                       # 0
  @coeff = $zp->coefficients;                  #    (0)
  @coeff = $zp->coeff;                         #    ()
  $const = $p->coeff_zero;                     # 0
  $const = $p->coeff_one;                      # 1
  $n = $p->degree;                             # 3
  $n = $zp->degree;                            # -1
  $n = $p->proper_degree;                      # 3
  $n = $zp->proper_degree;                     # undef

  # evaluation
  $y = $p->evaluate(4);                        # p(4) == 116

  # comparison
  $bool = !$p;         $bool = $p->is_zero;    # zero polynomial?
  if ($p) ...          if ($p->is_nonzero) ... # not zero polynomial?

  $bool = $p == $q;    $bool = $p->is_equal($q);      # equality
  $bool = $p != $q;    $bool = $p->is_unequal($q);    # inequality

  $p = $q && $r;       $p = $q->is_zero? $q: $r;      # choice
  $p = $q || $r;       $p = $q->is_zero? $r: $q;      # choice

  # arithmetic
  $q = -$p;            $q = $p->neg;           # q(x) == -p(x)
  $q = $p1 + $p2;      $q = $p1->add($p2);     # q(x) == p1(x) + p2(x)
  $q = $p1 - $p2;      $q = $p1->sub_($p2);    # q(x) == p1(x) - p2(x)
  $q = $p1 * $p2;      $q = $p1->mul($p2);     # q(x) == p1(x) * p2(x)
  $q = $p1 / $p2;      $q = $p1->div($p2);     # p1 == q * p2 + r,
                                               #   deg r < deg p2
  $r = $p1 % $p2;      $r = $p1->mod($p2);     # p1 == q * p2 + r,
                                               #   deg r < deg p2
  $q = $p + 3;         $q = $p->add_const(3);  # q(x) == p(x) + 3
  $q = $p - 3;         $q = $p->sub_const(3);  # q(x) == p(x) - 3
  $q = $p * 3;         $q = $p->mul_const(3);  # q(x) == p(x) * 3
  $q = $p / 3;         $q = $p->div_const(3);  # q(x) == p(x) / 3

  $q = $p ** 3;        $q = $p->pow(3);        # q(x) == p(x) ** 3
  $q = $p << 3;        $q = $p->shift_up(3);   # q(x) == p(x) * x**3
  $q = $p >> 3;        $q = $p->shift_down(3); # p == q * x**3 + r,
                                               #   deg r < 3

  $r = $p->inflate(3);                         # r(x) == p(x ** 3)
  $p = $r->deflate(3);                         # r(x) == p(x ** 3)

  $r = $p->slice(0, 3);              # p ==  q * x**3 + r, deg r < 3
  $r = $p->slice(2, 3);              # p == (q * x**3 + r) * x**2 + s,
                                     #   deg r < 3, deg s < 2

  ($q, $r) = $p1->divmod($p2);                 # p1 == q * p2 + r,
                                               #   deg r < deg p2

  $q = $p->mul_root(7);                        # q = p * (x-7)

  $q = $p->div_root(7);                        # p = q * (x-7) + c,
                                               #   c is some constant

  ($q, $r) = $p->divmod_root(7);               # p = q * (x-7) + r,
                                               #   deg r < 1

  $r = $p1->mmod($p2);                         # c * p1 == q * p2 + r,
                                               #   deg r < deg p2,
                                               #   c is a constant

  $q = $p1->nest($p2);                         # q(x) == p1(p2(x))
  $p1 = $q->unnest($p2);                       # q(x) == p1(p2(x))

  $q = $p->mirror;                             # q(x) == p(-x)

  $bool = $p->is_even;                         # whether p(-x) == p(x)

  $bool = $p->is_odd;                          # whether p(-x) == -p(x)

  $bool = $p->is_monic;                        # whether p is monic

  $q = $p->monize;                             # p(x) == q(x) * c,
                                               #   q is monic or zero

  $r = $p1->pow_mod(3, $p2);                   # p1**3 == q * p2 + r,
                                               #   deg r < deg p2

  $r = $p->exp_mod(3);                         # x**3 == q * p + r,
                                               #   deg r < deg p

  # greatest common divisor
  $d = $p1->gcd($p2);                          # p1 == q1 * d,
                                               # p2 == q2 * d,
                                               # deg d is maximal

  $d = $p1->gcd($p2, 'mmod');                  # like gcd, but with
                                               # modified modulo op

  # extended Euclidean algorithm
  ($d, $d1, $d2, $m1, $m2) = $p1->xgcd($p2);   # p1 == q1 * d,
                                               # p2 == q2 * d,
                                               # deg d is maximal,
                                               # d == p1*d1 + p2*d2,
                                               # 0 == p1*m1 + p2*m2

  $r = $p1->inv_mod($p2);                      # p1 * r == p2 * q + d,
                                               #   deg r < deg p2,
                                               #   d is monic gcd of
                                               #   p1 and p2

  $r = $p1->lcm($p2);                 # p1 * p2 == r * gcd(p1, p2)

  # calculus
  $q = $p->differentiate;             # q(x) == d/dx p(x)
  $q = $p->integrate;                 # d/dx q(x) == p(x), q(0) == 0
  $q = $p->integrate(10);             # d/dx q(x) == p(x), q(0) == 10
  $a = $p->definite_integral(1, 2);   # Integral from 1 to 2, p(x) dx

  # configurable string representation
  $config = {
    ascending     => 0,
    with_variable => 1,
    fold_sign     => 0,
    fold_zero     => 1,
    fold_one      => 1,
    fold_exp_zero => 1,
    fold_exp_one  => 1,
    convert_coeff => sub { "$_[0]" },
    sign_of_coeff => undef,
    plus          => q{ + },
    minus         => q{ - },
    leading_plus  => q{},
    leading_minus => q{- },
    times         => q{ },
    power         => q{^},
    variable      => q{x},
    prefix        => q{(},
    suffix        => q{)},
    wrap          => sub { $_[1] },
  };
  $str = "$p";                                 # '(2 x^3 + -3 x)'
  $str = $p->as_string();                      # '(2 x^3 + -3 x)'
  $str = $p->as_string($config);               # '(2 x^3 + -3 x)'

  $str = $p->as_string({fold_sign => 1});      # '(2 x^3 - 3 x)'

  $p->string_config({fold_sign => 1});
  $str = "$p";                                 # '(2 x^3 - 3 x)'
  $str = $p->as_string;                        # '(2 x^3 - 3 x)'

  $p->string_config(undef);
  $str = "$p";                                 # '(2 x^3 + -3 x)'

  Math::Polynomial->string_config({fold_sign => 1});
  $str = "$p";                                 # '(2 x^3 - 3 x)'

  $config = $p->string_config;                 # undef
  $config = Math::Polynomial->string_config;   # {fold_sign => 1}

  $config = {
    with_variable => 0,
    ascending     => 1,
    plus          => q{, },
  };
  $str = $p->as_string($config);               # '(0, -3, 0, 2)'

  # other conversions

  $config = {
    fold_sign  => 1,
    variable   => 'x',
    coeff      => sub { $[0] },
    negation   => sub { "- $_[0]" },
    sum        => sub { "$_[0] + $_[1]" },
    difference => sub { "$_[0] - $_[1]" },
    product    => sub { "$_[0]*$_[1]" },
    power      => sub { "$_[0]^$_[1]" },
    group      => sub { "($_[0])" },
  };
  $str = $p->as_horner_tree($config);          # '(2*x^2 - 3)*x'

  $config = {
    variable => sub { ['x'] },
    coeff    => sub { ['c', @_] },
    sum      => sub { ['+', @_] },
    product  => sub { ['*', @_] },
    power    => sub { ['^', @_] },
    group    => sub { $_[0] },
  };
  $listref = $p->as_horner_tree($config);
  # ['*', ['+', ['*', ['c', 2], ['^', ['x'], 2], ['c', -3]]], ['x']]

  $listref = $p->as_power_sum_tree($config);
  # ['+', ['*', ['c', 2], ['^', ['x'], 3]], ['*', ['c', -3], ['x']]]

  # other customizations

  $q = do {
    local Math::Polynomial::max_degree;        # override limitation
    $p->monomial(100_000)                      # x^100000
  };

  # examples of other coefficient spaces

  use Math::Complex;
  $c0 = Math::Complex->make(0, 3);
  $c1 = Math::Complex->make(2, 1);
  $p = Math::Polynomial->new($c0, $c1);        # p(x) == (2+i)*x + 3i
  $p->string_config({
    convert_coeff => sub {
      my $coeff = "$_[0]";
      if ($coeff =~ /[+-]/) {
        $coeff = "($coeff)";
      }
      return $coeff;
    },
  });
  print "$p\n";                                # prints ((2+i) x + 3i)

  use Math::AnyNum;
  $c0 = Math::AnyNum->new('-1/2');
  $c1 = Math::AnyNum->new('0');
  $c2 = Math::AnyNum->new('3/2');
  $p = Math::Polynomial->new($c0, $c1, $c2);  # p(x) == 3/2*x**2 - 1/2

  use Math::ModInt qw(mod);
  $c0 = mod(4, 5);
  $c1 = mod(2, 5);
  $p = Math::Polynomial->new($c0, $c1);      # p(x) == 2*x + 4 (mod 5)
  $p->string_config({
    convert_coeff => sub { $_[0]->signed_residue },
    sign_of_coeff => sub { $_[0]->signed_residue },
  });
  print "$p\n";                              # prints (2 x - 1)

=head1 EXPORT

Math::Polynomial does not export anything into the namespace of the
caller.

=head1 DIAGNOSTICS

Currently, Math::Polynomial does not thoroughly check coefficient
values for sanity.  Incompatible coefficients might trigger warnings
or error messages from the coefficient class implementation, blaming
Math::Polynomial to operate on incompatible operands.  Unwisely
chosen coefficient objects, lacking overrides for arithmetic
operations, might even silently be used with their memory address
acting as an integer value.

Some types of wrong usage, however, are diagnosed and will trigger
one of the error messages listed below.  All of them terminate
program execution unless they are trapped in an eval block.

=over 4

=item array context required

A method designed to return more than one value, like I<divmod> or
I<xgcd>, was not called in array context.  The results of these
methods have to be assigned to a list of values rather than a single
value.

=item array context required if called without argument

The I<coeff> method was called without arguments, so as to return
a list of coefficients, but not in array context.  The list of
coefficients should be assigned to an array.  To retrieve a single
coefficient, I<coeff> should be called with a degree argument.

=item bad modulo operator

A modulo operator was passed to I<gcd> and turned out to violate
rules required by such an operator, like constraints on the degree
of returned polynomials.

=item division by zero

The I<div_const> method was called with a zero argument.  Coefficient
spaces are supposed to not allow division by zero, therefore
Math::Polynomial tries to safeguard against it.

=item division by zero polynomial

Some kind of polynomial division, like I<div>, I<mod>, I<divmod>,
I<inv_mod> or an expression with C</> or C<%> was attempted with a
zero polynomial acting as denominator or modulus.  Division by a
zero polynomial is not defined.

=item exponent too large

One of the methods I<pow>, I<shift_up>, I<inflate>, or I<monomial> was
called with arguments that would lead to a result with an excessively
high degree.  You can tweak the class variable I<$max_degree> to
change the actual limit or disable the check altogether.  Calculations
involving large polynomials can consume a lot of memory and CPU time.
Exponent sanity checks help to avoid that from happening by accident.

=item missing parameter: %s

A method such as I<as_horner_tree> or I<as_power_sum_tree>, expecting
a parameter hashref, was called without the mandatory parameter
this message refers to.

=item no such method: %s

A modulo operator name was passed to I<gcd> which is not actually
the name of a method.

=item non-negative integer argument expected

One of the methods expecting non-negative integer arguments, like
I<pow>, I<pow_mod>, I<shift_up>, I<shift_down>, I<slice> or
I<monomial>, got something else instead.

=item non-zero remainder

The I<div_root> method was called with a first argument that was
not actually a root of the polynomial and a true value as second
argument, forcing a check for divisibility.

Note that the two-argument usage of I<div_root> and therefore this
diagnostic message is deprecated.

=item usage: %s

A method designed to be called in a certain manner with certain types
of arguments got not what it expected.

For example, I<interpolate> takes two references of arrays of equal
length.

Usage messages give an example of the expected calling syntax.

=item wrong operand type

An arithmetic expression used an operation not defined for polynomial
objects, such as a power with a polynomial exponent.

=item x values not disjoint

The I<interpolate> method was called with at least two equal x-values.
Support points for this kind of interpolation must have distinct x-values.

=back

=head1 EXTENSION GUIDELINES

Math::Polynomial can be extended in different ways.  Subclasses may
restrict coefficient spaces to facilitate certain application domains
such as numerical analysis or channel coding or symbolic algebra.

Special polynomials (such as Legendre, Chebyshev, Gegenbauer, Jacobi,
Hermite, Laguerre polynomials etc.) may be provided by modules
adding not much more than a bunch of funnily named constructors to
the base class.

Other modules may implement algorithms employing polynomials (such
as approximation techniques) or analyzing them (such as root-finding
techniques).

Yet another set of modules may provide alternative implementations
optimized for special cases such as sparse polynomials, or taking
benefit from specialized external math libraries.

Multivariate polynomials, finally, are now implemented in an
independent package, Math-Polynomial-Multivariate.

This list is not necessarily complete.

=head1 DEPENDENCIES

This version of Math::Polynomial requires these other modules and
libraries to run:

=over 4

=item *

perl version 5.6.0 or higher

=item *

overload (usually bundled with perl)

=item *

Carp (usually bundled with perl)

=back

Additional requirements to run the test suite are:

=over 4

=item *

Test (usually bundled with perl)

=back

Recommended modules for increased functionality are:

=over 4

=item *

Math::Complex (usually bundled with perl)

=item *

Math::BigInt (usually bundled with perl)

=item *

Math::AnyNum (available on CPAN)

=item *

Math::ModInt (available on CPAN)

=back

=head1 BUGS AND LIMITATIONS

At the time of release, there were no known unresolved issues with
this module.  Bug reports and suggestions are welcome -- please
submit them through the CPAN RT,
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Math-Polynomial>.

Our test suite checks for compatibility with several alien modules that
might be useful as coefficient spaces.  Issues with these modules are
reported only in skip messages, but not as hard failures, as in the past
usually the alien module was to blame.

=head1 SEE ALSO

Part of this distribution:

=over 4

=item *

Example scripts distributed with Math::Polynomial.

Scripts in the examples directory cover module version differences,
interpolation, rational coefficients, pretty-printing, and more.

Scripts in the test suite are less wordily documented, but should have at
least one usage example for each of even the most exotic features.

=item *

I<Math::Polynomial::Generic> (deprecated) -
an experimental interface extension with some syntactical sugar
coating Math::Polynomial.  It is no longer supported.

=back

Modules planned for release, in various states of completion:

=over 4

=item *

I<Math::Polynomial::Sparse> -
an alternative implementation optimized for polynomials with lots
of zero coefficients.

=item *

I<Math::Polynomial::Orthogonal> -
an extension providing constructors for many well-known kinds of
orthogonal polynomials.

=item *

I<Math::Polynomial::Roots::DurandKerner> -
an extension implementing the Weierstrass-(Durand-Kerner) numerical
root-finding algorithm.

=item *

I<Math::Polynomial::Parse> -
an extension providing methods to create polynomial objects from strings.

=back

Other Modules:

=over 4

=item *

I<Math::Polynomial::Multivariate> -
a module dealing with polynomials in more than one variable.

=item *

I<PDL> -
the Perl Data Language.

=item *

Math::GMPz, Math::GMPq, Math::GMPf -
interfaces to the GMP arbitrary precision integer math library.

=item *

Math::BigInt, Math::BigFloat, and Math::BigRat -
arbitrary precision math libraries.

=item *

Math::AnyNum -
another arbitrary precision library (using GMP).

=item *

Math::Pari -
interface to the Pari math library.

=back

General Information:

=over 4

=item *

Pages in category I<Polynomials> of Wikipedia.
L<http://en.wikipedia.org/wiki/Category%3APolynomials>

=item *

Weisstein, Eric W. "Polynomial."
From MathWorld--A Wolfram Web Resource.
L<http://mathworld.wolfram.com/Polynomial.html>

=item *

Knuth, Donald E. "The Art of Computer Programming, Volume 2:
Seminumerical Algorithms", 3rd ed., 1998, Addison-Wesley Professional.

=back

=head1 AUTHOR

Martin Becker, E<lt>becker-cpan-mp (at) cozap.comE<gt>

=head1 ACKNOWLEDGEMENTS

Math::Polynomial was inspired by a module of the same name written and
maintained by Mats Kindahl, E<lt>mats (at) kindahl.netE<gt>, 1997-2007,
who kindly passed it on to the author for maintenance and improvement.

Additional suggestions and bug reports came from Thorsten Dahlheimer
and Kevin Ryde.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2007-2021 by Martin Becker, Blaubeuren.

This library is free software; you can distribute it and/or modify it
under the terms of the Artistic License 2.0 (see the LICENSE file).

=head1 DISCLAIMER OF WARRANTY

This library is distributed in the hope that it will be useful,
but without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut
