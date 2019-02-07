package Math::GComplex;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.13';

use overload
  '""' => \&stringify,
  '0+' => \&numify,
  bool => \&boolify,

  '+' => \&add,
  '*' => \&mul,

  '==' => \&eq,
  '!=' => \&ne,

  '~' => \&conj,
  '&' => \&and,
  '|' => \&or,
  '^' => \&xor,

  '>>' => \&rsft,
  '<<' => \&lsft,

  '>'  => sub { $_[2] ? (goto &lt) : (goto &gt) },
  '>=' => sub { $_[2] ? (goto &le) : (goto &ge) },
  '<'  => sub { $_[2] ? (goto &gt) : (goto &lt) },
  '<=' => sub { $_[2] ? (goto &ge) : (goto &le) },

  '<=>' => sub { $_[2] ? -(&cmp($_[0], $_[1]) // return undef) : &cmp($_[0], $_[1]) },

  '/' => sub { @_ = ($_[1], $_[0]) if $_[2]; goto &div },
  '-' => sub { @_ = ($_[1], $_[0]) if $_[2]; goto &sub },

  '**' => sub { @_ = $_[2] ? @_[1, 0] : @_[0, 1]; goto &pow },
  '%'  => sub { @_ = $_[2] ? @_[1, 0] : @_[0, 1]; goto &mod },

  atan2 => sub { @_ = $_[2] ? @_[1, 0] : @_[0, 1]; goto &atan2 },

  eq => sub { "$_[0]" eq "$_[1]" },
  ne => sub { "$_[0]" ne "$_[1]" },

  cmp => sub { $_[2] ? ("$_[1]" cmp $_[0]->stringify) : ($_[0]->stringify cmp "$_[1]") },

  neg  => \&neg,
  sin  => \&sin,
  cos  => \&cos,
  exp  => \&exp,
  log  => \&log,
  int  => \&int,
  abs  => \&abs,
  sqrt => \&sqrt;

{

    my %const = (    # prototypes are assigned in import()
                  i => \&i,
                );

    my %trig = (
        sin   => sub (_) { goto &sin },    # built-in function
        sinh  => \&sinh,
        asin  => \&asin,
        asinh => \&asinh,

        cos   => sub (_) { goto &cos },    # built-in function
        cosh  => \&cosh,
        acos  => \&acos,
        acosh => \&acosh,

        tan   => \&tan,
        tanh  => \&tanh,
        atan  => \&atan,
        atanh => \&atanh,

        cot   => \&cot,
        coth  => \&coth,
        acot  => \&acot,
        acoth => \&acoth,

        sec   => \&sec,
        sech  => \&sech,
        asec  => \&asec,
        asech => \&asech,

        csc   => \&csc,
        csch  => \&csch,
        acsc  => \&acsc,
        acsch => \&acsch,

        atan2 => sub ($$) { goto &atan2 },    # built-in function

        deg2rad => \&deg2rad,
        rad2deg => \&rad2deg,
               );

    my %special = (

        exp  => sub (_) { goto &exp },        # built-in function
        log  => sub (_) { goto &log },        # built-in function
        sqrt => sub (_) { goto &sqrt },       # built-in function

        cbrt => \&cbrt,
        logn => \&logn,
        root => \&root,
        pow  => \&pow,
        pown => \&pown,

        gcd    => \&gcd,
        invmod => \&invmod,
        powmod => \&powmod,
    );

    my %misc = (

        acmp  => \&acmp,
        cplx  => \&cplx,
        polar => \&polar,

        abs => sub (_) { goto &abs },    # built-in function

        inv  => \&inv,
        sgn  => \&sgn,
        conj => \&conj,
        norm => \&norm,

        real => \&real,
        imag => \&imag,

        floor => \&floor,
        ceil  => \&ceil,
        round => \&round,

        reals => \&reals,
    );

    sub import {
        shift;

        my $caller = caller(0);

        while (@_) {
            my $name = shift(@_);

            if ($name eq ':overload') {
                overload::constant
                  integer => sub { __PACKAGE__->new($_[0], 0) },
                  float   => sub { __PACKAGE__->new($_[0], 0) };

                # Export the 'i' constant
                foreach my $pair (['i', i()]) {
                    my $sub = $caller . '::' . $pair->[0];
                    no strict 'refs';
                    no warnings 'redefine';
                    my $value = $pair->[1];
                    *$sub = sub () { $value };
                }
            }
            elsif (exists $const{$name}) {
                no strict 'refs';
                no warnings 'redefine';
                my $caller_sub = $caller . '::' . $name;
                my $sub        = $const{$name};
                my $value      = $sub->();
                *$caller_sub = sub() { $value }
            }
            elsif (   exists($trig{$name})
                   or exists($special{$name})
                   or exists($misc{$name})) {
                no strict 'refs';
                no warnings 'redefine';
                my $caller_sub = $caller . '::' . $name;
                *$caller_sub = $trig{$name} // $misc{$name} // $special{$name};
            }
            elsif ($name eq ':trig') {
                push @_, keys(%trig);
            }
            elsif ($name eq ':misc') {
                push @_, keys(%misc);
            }
            elsif ($name eq ':special') {
                push @_, keys(%special);
            }
            elsif ($name eq ':all') {
                push @_, keys(%const), keys(%trig), keys(%special), keys(%misc);
            }
            else {
                die "unknown import: <<$name>>";
            }
        }
        return;
    }

    sub unimport {
        overload::remove_constant(float   => '',
                                  integer => '',);
    }
}

#
## Be somewhat compatible with Math::Complex
#

sub _cartesian {
    my ($self) = @_;
    $self->{cartesian} //= [$self->{a}, $self->{b}];
}

sub _polar {
    my ($self) = @_;
    $self->{polar} //= [CORE::sqrt($self->{a} * $self->{a} + $self->{b} * $self->{b}), CORE::atan2($self->{b}, $self->{a})];
}

#
## Return the polar form
#

sub polar {
    my ($self) = @_;
    @{$self->_polar};
}

#
## Create a new Math::GComplex object
#

sub new {
    my ($class, $x, $y) = @_;

    bless {
           a => $x // 0,
           b => $y // 0,
          }, $class;
}

*make = \&new;

#
## cplx(a, b) = a + b*i
#

sub cplx {
    my ($x, $y) = @_;

    bless {
           a => $x // 0,
           b => $y // 0,
          },
      __PACKAGE__;
}

sub emake {
    my ($class, $r, $theta) = @_;

    bless {
           a => ($r // 0) * CORE::cos($theta // 0),
           b => ($r // 0) * CORE::sin($theta // 0),
          }, $class;
}

#
## cplxe(r, theta) = r*cos(theta) + r*sin(theta)*i
#

sub cplxe {
    my ($r, $theta) = @_;

    bless {
           a => ($r // 0) * CORE::cos($theta // 0),
           b => ($r // 0) * CORE::sin($theta // 0),
          },
      __PACKAGE__;
}

#
## i = sqrt(-1)
#

sub i {
    __PACKAGE__->new(0, 1);
}

#
## (a + b*i) + (x + y*i) = (a + x) + (b + y)*i
#

sub add {
    my ($x, $y) = @_;

    $x = __PACKAGE__->new($x) if ref($x) ne __PACKAGE__;
    $y = __PACKAGE__->new($y) if ref($y) ne __PACKAGE__;

    __PACKAGE__->new($x->{a} + $y->{a}, $x->{b} + $y->{b});
}

#
## (a + b*i) - (x + y*i) = (a - x) + (b - y)*i
#

sub sub {
    my ($x, $y) = @_;

    $x = __PACKAGE__->new($x) if ref($x) ne __PACKAGE__;
    $y = __PACKAGE__->new($y) if ref($y) ne __PACKAGE__;

    __PACKAGE__->new($x->{a} - $y->{a}, $x->{b} - $y->{b});
}

#
## (a + b*i) * (x + y*i) = i*(a*y + b*x) + a*x - b*y
#

sub mul {
    my ($x, $y) = @_;

    $x = __PACKAGE__->new($x) if ref($x) ne __PACKAGE__;
    $y = __PACKAGE__->new($y) if ref($y) ne __PACKAGE__;

    __PACKAGE__->new($x->{a} * $y->{a} - $x->{b} * $y->{b}, $x->{a} * $y->{b} + $x->{b} * $y->{a});
}

#
## (a + b*i) / (x + y*i) = (a*x + b*y)/(x*x + y*y) + (b*x - a*y)/(x*x + y*y) * i
#

sub div {
    my ($x, $y) = @_;

    $x = __PACKAGE__->new($x) if ref($x) ne __PACKAGE__;
    $y = __PACKAGE__->new($y) if ref($y) ne __PACKAGE__;

    my $d = $y->{a} * $y->{a} + $y->{b} * $y->{b};

    if ($d == 0) {
        return $x->log->sub($y->log)->exp;
    }

    __PACKAGE__->new(($x->{a} * $y->{a} + $x->{b} * $y->{b}) / $d, ($x->{b} * $y->{a} - $x->{a} * $y->{b}) / $d);
}

#
## mod(x, y) = x - y*floor(x/y)
#

sub mod {
    my ($x, $y) = @_;

    $x = __PACKAGE__->new($x) if ref($x) ne __PACKAGE__;
    $y = __PACKAGE__->new($y) if ref($y) ne __PACKAGE__;

    $x->sub($x->div($y)->floor->mul($y));
}

#
## inv(x) = 1/x
#

sub inv ($) {
    my ($x) = @_;

    state $one = __PACKAGE__->new(1, 0);

    $one->div($x);
}

#
## abs(a + b*i) = sqrt(a^2 + b^2)
#

sub abs {
    my ($x) = @_;

    $x = __PACKAGE__->new($x) if ref($x) ne __PACKAGE__;

    CORE::sqrt($x->{a} * $x->{a} + $x->{b} * $x->{b});
}

#
## sgn(a + b*i) = (a + b*i) / abs(a + b*i)
#

sub sgn ($) {
    my ($x) = @_;

    $x = __PACKAGE__->new($x) if ref($x) ne __PACKAGE__;

    if ($x->{a} == 0 and $x->{b} == 0) {
        return __PACKAGE__->new(0, 0);
    }

    $x->div($x->abs);
}

#
## neg(a + b*i) = -a - b*i
#

sub neg {
    my ($x) = @_;

    $x = __PACKAGE__->new($x) if ref($x) ne __PACKAGE__;

    __PACKAGE__->new(-$x->{a}, -$x->{b});
}

#
## conj(a + b*i) = a - b*i
#

sub conj ($) {
    my ($x) = @_;

    $x = __PACKAGE__->new($x) if ref($x) ne __PACKAGE__;

    __PACKAGE__->new($x->{a}, -$x->{b});
}

#
## norm(a + b*i) = a**2 + b**2
#

sub norm ($) {
    my ($x) = @_;

    $x = __PACKAGE__->new($x) if ref($x) ne __PACKAGE__;

    $x->{a} * $x->{a} + $x->{b} * $x->{b};
}

#
## (a+b*i) AND (x+y*i) = (a AND x) + (b AND y)*i
#

sub and {
    my ($x, $y) = @_;

    $x = __PACKAGE__->new($x) if ref($x) ne __PACKAGE__;
    $y = __PACKAGE__->new($y) if ref($y) ne __PACKAGE__;

    __PACKAGE__->new($x->{a} & $y->{a}, $x->{b} & $y->{b});
}

#
## (a+b*i) OR (x+y*i) = (a OR x) + (b OR y)*i
#

sub or {
    my ($x, $y) = @_;

    $x = __PACKAGE__->new($x) if ref($x) ne __PACKAGE__;
    $y = __PACKAGE__->new($y) if ref($y) ne __PACKAGE__;

    __PACKAGE__->new($x->{a} | $y->{a}, $x->{b} | $y->{b});
}

#
## (a+b*i) XOR (x+y*i) = (a XOR x) + (b XOR y)*i
#

sub xor {
    my ($x, $y) = @_;

    $x = __PACKAGE__->new($x) if ref($x) ne __PACKAGE__;
    $y = __PACKAGE__->new($y) if ref($y) ne __PACKAGE__;

    __PACKAGE__->new($x->{a} ^ $y->{a}, $x->{b} ^ $y->{b});
}

#
## (a+b*i) << n       = (a << n) + (b << n)*i
## (a+b*i) << (x+y*i) = int((a+b*i) * 2^(x+y*i))
#

sub lsft {
    my ($x, $y) = @_;

    $x = __PACKAGE__->new($x) if ref($x) ne __PACKAGE__;
    $y = __PACKAGE__->new($y) if ref($y) ne __PACKAGE__;

    if ($y->{b} == 0) {
        return __PACKAGE__->new($x->{a} << $y->{a}, $x->{b} << $y->{a});
    }

    state $two = __PACKAGE__->new(2, 0);
    $x->mul($two->pow($y))->int;
}

#
## (a+b*i) >> n       = (a >> n) + (b >> n)*i
## (a+b*i) >> (x+y*i) = int((a+b*i) / 2^(x+y*i))
#

sub rsft {
    my ($x, $y) = @_;

    $x = __PACKAGE__->new($x) if ref($x) ne __PACKAGE__;
    $y = __PACKAGE__->new($y) if ref($y) ne __PACKAGE__;

    if ($y->{b} == 0) {
        return __PACKAGE__->new($x->{a} >> $y->{a}, $x->{b} >> $y->{a});
    }

    state $two = __PACKAGE__->new(2, 0);
    $x->div($two->pow($y))->int;
}

#
## log(a + b*i) = log(a^2 + b^2)/2 + atan2(b, a)*i    -- where a,b are real
#

sub log {
    my ($x) = @_;

    $x = __PACKAGE__->new($x) if ref($x) ne __PACKAGE__;

    my $t = $x->{a} * $x->{a} + $x->{b} * $x->{b};

    if (!ref($t) and $t == 0) {
        return __PACKAGE__->new(0 + '-Inf', 0);
    }

    __PACKAGE__->new(CORE::log($t) / 2, CORE::atan2($x->{b}, $x->{a}));
}

#
## logn(x, n) = log(x) / log(n)
#

sub logn ($$) {
    my ($x, $n) = @_;

    $x = __PACKAGE__->new($x) if ref($x) ne __PACKAGE__;
    $n = __PACKAGE__->new($n) if ref($n) ne __PACKAGE__;

    $x->log->div($n->log);
}

#
## exp(a + b*i) = exp(a)*cos(b) + exp(a)*sin(b)*i
#

sub exp {
    my ($x) = @_;

    $x = __PACKAGE__->new($x) if ref($x) ne __PACKAGE__;

    my $exp = CORE::exp($x->{a});

    __PACKAGE__->new($exp * CORE::cos($x->{b}), $exp * CORE::sin($x->{b}));
}

#
## x^y = exp(log(x) * y)
#

sub pow ($$) {
    my ($x, $y) = @_;

    $x = __PACKAGE__->new($x) if ref($x) ne __PACKAGE__;
    $y = __PACKAGE__->new($y) if ref($y) ne __PACKAGE__;

    if ($x->{a} == 0 and $x->{b} == 0) {

        if ($y->{a} < 0) {
            return $x->inv;
        }

        if ($y->{a} == 0 and $y->{b} == 0) {
            return __PACKAGE__->new($x->{a} + 1, $x->{b});
        }

        return $x;
    }

    $x->log->mul($y)->exp;
}

#
## x^n using the exponentiation by squaring method
#

sub pown ($$) {
    my ($x, $y) = @_;

    $x = __PACKAGE__->new($x) if ref($x) ne __PACKAGE__;

    $y = CORE::int($y);
    my $neg = $y < 0;
    $y = CORE::int(CORE::abs($y));

    if ($x->{a} == 0 and $x->{b} == 0) {

        if ($neg) {
            return $x->inv;
        }

        if ($y == 0) {
            return __PACKAGE__->new($x->{a} + 1, $x->{b});
        }

        return $x;
    }

    my ($rx, $ry) = (1, 0);
    my ($ax, $bx) = (@{$x}{qw(a b)});

    while (1) {
        ($rx, $ry) = ($rx * $ax - $ry * $bx, $rx * $bx + $ry * $ax) if ($y & 1);
        ($y >>= 1) or last;
        ($ax, $bx) = ($ax * $ax - $bx * $bx, $ax * $bx + $bx * $ax);
    }

    $neg ? __PACKAGE__->new($rx, $ry)->inv : __PACKAGE__->new($rx, $ry);
}

#
## Greatest common divisor
#

sub gcd ($$) {
    my ($n, $k) = @_;

    $n = __PACKAGE__->new($n) if ref($n) ne __PACKAGE__;
    $k = __PACKAGE__->new($k) if ref($k) ne __PACKAGE__;

    my $norm_n = $n->{a} * $n->{a} + $n->{b} * $n->{b};
    my $norm_k = $k->{a} * $k->{a} + $k->{b} * $k->{b};

    if ($norm_n > $norm_k) {
        ($n, $k) = ($k, $n);
    }

    while (!($k->{a} == 0 and $k->{b} == 0)) {

        my $q = $n->div($k)->round;
        my $r = $n->sub($q->mul($k));

        ($n, $k) = ($k, $r);
    }

    $n;
}

#
## Modular multiplicative inverse: 1/x (mod m)
#

sub invmod ($$) {
    my ($x, $m) = @_;

    $x = __PACKAGE__->new($x) if ref($x) ne __PACKAGE__;
    $m = __PACKAGE__->new($m) if ref($m) ne __PACKAGE__;

    my $g = $x->gcd($m);

    $g->abs == 1 or return undef;

    state $zero = __PACKAGE__->new(0, 0);

    my $inverse = sub {
        my ($x, $m, $k) = @_;

        my ($u, $w) = ($k, $zero);
        my ($q, $r);

        my $c = $m;

        while (!($c->{a} == 0 and $c->{b} == 0)) {

            $q = $x->div($c)->round;
            $r = $x->sub($q->mul($c));

            ($x, $c) = ($c, $r);
            ($u, $w) = ($w, $u->sub($q->mul($w)));
        }

        return $u;
    };

    state $one  = __PACKAGE__->new(1,  0);
    state $mone = __PACKAGE__->new(-1, 0);

    state $i  = __PACKAGE__->new(0, 1);
    state $mi = __PACKAGE__->new(0, -1);

    foreach my $k ($g->conj, $one, $mone, $i, $mi) {

        my $inv = $inverse->($x, $m, $k);
        my $t   = $x->mul($inv)->mod($m);

        if ($t->{a} == 1 and $t->{b} == 0) {
            return $inv->mod($m);
        }
    }

    return undef;
}

#
## x^n mod m using the exponentiation by squaring method
#

sub powmod ($$$) {
    my ($x, $y, $m) = @_;

    $x = __PACKAGE__->new($x) if ref($x) ne __PACKAGE__;
    $m = __PACKAGE__->new($m) if ref($m) ne __PACKAGE__;

    $y = CORE::int($y);
    my $neg = $y < 0;
    $y = CORE::int(CORE::abs($y));

    if ($x->{a} == 0 and $x->{b} == 0) {

        if ($neg) {
            return $x->invmod($m);
        }

        if ($y == 0) {
            return __PACKAGE__->new($x->{a} + 1, $x->{b})->mod($m);
        }

        return $x->mod($m);
    }

    $x = $x->invmod($m) if $neg;
    $x // return undef;

    my $r = __PACKAGE__->new(1, 0);

    while (1) {
        $r = $r->mul($x)->mod($m) if ($y & 1);
        ($y >>= 1) or last;
        $x = $x->mul($x)->mod($m);
    }

    $r->mod($m);
}

#
## root(x, y) = exp(log(x) / y)
#

sub root ($$) {
    my ($x, $y) = @_;

    $x = __PACKAGE__->new($x) if ref($x) ne __PACKAGE__;
    $y = __PACKAGE__->new($y) if ref($y) ne __PACKAGE__;

    $x->pow($y->inv);
}

#
## sqrt(a + b*i) = exp(log(a + b*i) / 2)
#

sub sqrt {
    my ($x) = @_;

    $x = __PACKAGE__->new($x) if ref($x) ne __PACKAGE__;

    my $r = $x->log;

    $r->{a} /= 2;
    $r->{b} /= 2;

    $r->exp;
}

#
## cbrt(a + b*i) = exp(log(a + b*i) / 3)
#

sub cbrt ($) {
    my ($x) = @_;

    $x = __PACKAGE__->new($x) if ref($x) ne __PACKAGE__;

    if ($x->{a} == 0 and $x->{b} == 0) {
        return __PACKAGE__->new(0, 0);
    }

    my $r = $x->log;

    $r->{a} /= 3;
    $r->{b} /= 3;

    $r->exp;
}

#
## int(a + b*i) = int(a) + int(b)*i
#

sub int {
    my ($x) = @_;

    $x = __PACKAGE__->new($x) if ref($x) ne __PACKAGE__;

    my $t1 = CORE::int($x->{a});
    my $t2 = CORE::int($x->{b});

    __PACKAGE__->new($t1, $t2);
}

#
## round to the nearest Gaussian integer
#

sub _round ($) {
    my ($n) = @_;
    CORE::int(($n + $n + (($n < 0) ? -1 : 1)) / 2);
}

sub round ($) {
    my ($x) = @_;
    $x = __PACKAGE__->new($x) if ref($x) ne __PACKAGE__;
    __PACKAGE__->new(_round($x->{a}), _round($x->{b}));
}

#
## floor(a + b*i) = floor(a) + floor(b)*i
#

sub floor ($) {
    my ($x) = @_;

    $x = __PACKAGE__->new($x) if ref($x) ne __PACKAGE__;

    my $t1 = CORE::int($x->{a});
    $t1 -= 1 if ($x->{a} != $t1 and $x->{a} < 0);

    my $t2 = CORE::int($x->{b});
    $t2 -= 1 if ($x->{b} != $t2 and $x->{b} < 0);

    __PACKAGE__->new($t1, $t2);
}

#
## ceil(a + b*i) = -floor(-(a + b*i))
#

sub ceil ($) {
    my ($x) = @_;

    $x = __PACKAGE__->new($x) if ref($x) ne __PACKAGE__;

    my $t = $x->neg->floor;

    $t->{a} = -$t->{a};
    $t->{b} = -$t->{b};

    $t;
}

########################################################################
#               SIN / SINH / ASIN / ASINH
########################################################################

#
## sin(a + b*i) = i*(exp(b - i*a) - exp(-b + i*a))/2
#

sub sin {
    my ($x) = @_;

    $x = __PACKAGE__->new($x) if ref($x) ne __PACKAGE__;

    my $t1 = __PACKAGE__->new(+$x->{b}, -$x->{a})->exp;
    my $t2 = __PACKAGE__->new(-$x->{b}, +$x->{a})->exp;

    $t1->{a} -= $t2->{a};
    $t1->{b} -= $t2->{b};

    $t1->{a} /= 2;
    $t1->{b} /= 2;

    @{$t1}{qw(a b)} = (-$t1->{b}, $t1->{a});

    $t1;
}

#
## sinh(a + b*i) = (exp(2 * (a + b*i)) - 1) / (2*exp(a + b*i))
#

sub sinh ($) {
    my ($x) = @_;

    $x = __PACKAGE__->new($x) if ref($x) ne __PACKAGE__;

    my $t1 = __PACKAGE__->new($x->{a} * 2, $x->{b} * 2)->exp;

    $t1->{a} -= 1;

    my $t2 = $x->exp;

    $t2->{a} *= 2;
    $t2->{b} *= 2;

    $t1->div($t2);
}

#
## asin(a + b*i) = -i*log(sqrt(1 - (a + b*i)^2) + i*a - b)
#

sub asin ($) {
    my ($x) = @_;

    $x = __PACKAGE__->new($x) if ref($x) ne __PACKAGE__;

    my $r = __PACKAGE__->new(1 - ($x->{a} * $x->{a} - $x->{b} * $x->{b}), -($x->{a} * $x->{b} + $x->{b} * $x->{a}))->sqrt;

    $r->{a} -= $x->{b};
    $r->{b} += $x->{a};

    $r = $r->log;
    @{$r}{qw(a b)} = ($r->{b}, -$r->{a});
    $r;
}

#
## asinh(a + b*i) = log(sqrt((a + b*i)^2 + 1) + (a + b*i))
#

sub asinh ($) {
    my ($x) = @_;

    $x = __PACKAGE__->new($x) if ref($x) ne __PACKAGE__;

    my $r = __PACKAGE__->new($x->{a} * $x->{a} - $x->{b} * $x->{b} + 1, $x->{a} * $x->{b} + $x->{b} * $x->{a})->sqrt;

    $r->{a} += $x->{a};
    $r->{b} += $x->{b};

    $r->log;
}

########################################################################
#               COS / COSH / ACOS / ACOSH
########################################################################

#
## cos(a + b*i) = (exp(-b + i*a) + exp(b - i*a))/2
#

sub cos {
    my ($x) = @_;

    $x = __PACKAGE__->new($x) if ref($x) ne __PACKAGE__;

    my $t1 = __PACKAGE__->new(-$x->{b}, +$x->{a})->exp;
    my $t2 = __PACKAGE__->new(+$x->{b}, -$x->{a})->exp;

    $t1->{a} += $t2->{a};
    $t1->{b} += $t2->{b};

    $t1->{a} /= 2;
    $t1->{b} /= 2;

    $t1;
}

#
## cosh(a + b*i) = (exp(2 * (a + b*i)) + 1) / (2*exp(a + b*i))
#

sub cosh ($) {
    my ($x) = @_;

    $x = __PACKAGE__->new($x) if ref($x) ne __PACKAGE__;

    my $t1 = __PACKAGE__->new($x->{a} * 2, $x->{b} * 2)->exp;

    $t1->{a} += 1;

    my $t2 = $x->exp;

    $t2->{a} *= 2;
    $t2->{b} *= 2;

    $t1->div($t2);
}

#
## acos(a + b*i) = -2*i*log(i*sqrt((1 - (a + b*i))/2) + sqrt((1 + (a + b*i))/2))
#

sub acos ($) {
    my ($x) = @_;

    $x = __PACKAGE__->new($x) if ref($x) ne __PACKAGE__;

    my $t1 = __PACKAGE__->new((1 - $x->{a}) / 2, $x->{b} / -2)->sqrt;
    my $t2 = __PACKAGE__->new((1 + $x->{a}) / 2, $x->{b} / +2)->sqrt;

    @{$t1}{qw(a b)} = (-$t1->{b}, $t1->{a});

    $t1->{a} += $t2->{a};
    $t1->{b} += $t2->{b};

    my $r = $t1->log;

    $r->{a} *= -2;
    $r->{b} *= -2;

    @{$r}{qw(a b)} = (-$r->{b}, $r->{a});

    $r;
}

#
## acosh(a + b*i) = log((a + b*i) + sqrt((a + b*i) - 1) * sqrt((a + b*i) + 1))
#

sub acosh ($) {
    my ($x) = @_;

    $x = __PACKAGE__->new($x) if ref($x) ne __PACKAGE__;

    my $t1 = __PACKAGE__->new($x->{a} - 1, $x->{b})->sqrt;
    my $t2 = __PACKAGE__->new($x->{a} + 1, $x->{b})->sqrt;

    my $t3 = $t1->mul($t2);

    $t3->{a} += $x->{a};
    $t3->{b} += $x->{b};

    $t3->log;
}

########################################################################
#               TAN / TANH / ATAN / ATANH
########################################################################

#
## tan(a + b*i) = (2*i)/(exp(2*i*(a + b*i)) + 1) - i
#

sub tan ($) {
    my ($x) = @_;

    $x = __PACKAGE__->new($x) if ref($x) ne __PACKAGE__;

    my $r = __PACKAGE__->new(-2 * $x->{b}, 2 * $x->{a})->exp;

    $r->{a} += 1;

    my $den = $r->{a} * $r->{a} + $r->{b} * $r->{b};

    $r->{a} *= 2;
    $r->{b} *= 2;

    if (!ref($den) and $den == 0) {
        $r = $r->div($den);
    }
    else {
        $r->{a} /= $den;
        $r->{b} /= $den;
    }

    $r->{a} -= 1;

    @{$r}{qw(a b)} = ($r->{b}, $r->{a});

    $r;
}

#
## tanh(a + b*i) = (exp(2 * (a + b*i)) - 1) / (exp(2 * (a + b*i)) + 1)
#

sub tanh ($) {
    my ($x) = @_;

    $x = __PACKAGE__->new($x) if ref($x) ne __PACKAGE__;

    my $t1 = __PACKAGE__->new($x->{a} * 2, $x->{b} * 2)->exp;

    my $t2 = __PACKAGE__->new($t1->{a} - 1, $t1->{b});
    my $t3 = __PACKAGE__->new($t1->{a} + 1, $t1->{b});

    $t2->div($t3);
}

#
## atan(a + b*i) = i * (log(1 - i*(a + b*i)) - log(1 + i*(a + b*i))) / 2
#

sub atan ($) {
    my ($x) = @_;

    $x = __PACKAGE__->new($x) if ref($x) ne __PACKAGE__;

    my $t1 = __PACKAGE__->new(+$x->{b} + 1, -$x->{a})->log;
    my $t2 = __PACKAGE__->new(-$x->{b} + 1, +$x->{a})->log;

    $t1->{a} -= $t2->{a};
    $t1->{b} -= $t2->{b};

    $t1->{a} /= 2;
    $t1->{b} /= 2;

    @{$t1}{qw(a b)} = (-$t1->{b}, $t1->{a});

    $t1;
}

#
## atan2(a, b) = -i * log((b + a*i) / sqrt(a^2 + b^2))
#

sub atan2 {
    my ($x, $y) = @_;

    $x = __PACKAGE__->new($x) if ref($x) ne __PACKAGE__;
    $y = __PACKAGE__->new($y) if ref($y) ne __PACKAGE__;

    my $t = __PACKAGE__->new($y->{a} - $x->{b}, $x->{a} + $y->{b});

    $t = $t->div($x->mul($x)->add($y->mul($y))->sqrt)->log;

    @{$t}{qw(a b)} = ($t->{b}, -$t->{a});

    $t;
}

#
## atanh(a + b*i) = (log(1 + (a + b*i)) - log(1 - (a + b*i))) / 2
#

sub atanh ($) {
    my ($x) = @_;

    $x = __PACKAGE__->new($x) if ref($x) ne __PACKAGE__;

    my $t1 = __PACKAGE__->new(1 + $x->{a}, +$x->{b})->log;
    my $t2 = __PACKAGE__->new(1 - $x->{a}, -$x->{b})->log;

    $t1->{a} -= $t2->{a};
    $t1->{b} -= $t2->{b};

    $t1->{a} /= 2;
    $t1->{b} /= 2;

    $t1;
}

########################################################################
#               COT / COTH / ACOT / ACOTH
########################################################################

#
## cot(a + b*i) = (2*i)/(exp(2*i*(a + b*i)) - 1) + i
#

sub cot ($) {
    my ($x) = @_;

    $x = __PACKAGE__->new($x) if ref($x) ne __PACKAGE__;

    my $r = __PACKAGE__->new(-2 * $x->{b}, 2 * $x->{a})->exp;

    $r->{a} -= 1;

    my $den = $r->{a} * $r->{a} + $r->{b} * $r->{b};

    $r->{a} *= 2;
    $r->{b} *= 2;

    if (!ref($den) and $den == 0) {
        $r = $r->div($den);
    }
    else {
        $r->{a} /= $den;
        $r->{b} /= $den;
    }

    $r->{a} += 1;

    @{$r}{qw(a b)} = ($r->{b}, $r->{a});

    $r;
}

#
## coth(a + b*i) = (exp(2 * (a + b*i)) + 1) / (exp(2 * (a + b*i)) - 1)
#

sub coth ($) {
    my ($x) = @_;

    $x = __PACKAGE__->new($x) if ref($x) ne __PACKAGE__;

    my $t1 = __PACKAGE__->new($x->{a} * 2, $x->{b} * 2)->exp;

    my $t2 = __PACKAGE__->new($t1->{a} + 1, $t1->{b});
    my $t3 = __PACKAGE__->new($t1->{a} - 1, $t1->{b});

    $t2->div($t3);
}

#
## acot(a + b*i) = atan(1/(a + b*i))
#

sub acot ($) {
    my ($x) = @_;

    $x = __PACKAGE__->new($x) if ref($x) ne __PACKAGE__;

    $x->inv->atan;
}

#
## acoth(a + b*i) = atanh(1 / (a + b*i))
#

sub acoth ($) {
    my ($x) = @_;

    $x = __PACKAGE__->new($x) if ref($x) ne __PACKAGE__;

    $x->inv->atanh;
}

########################################################################
#               SEC / SECH / ASEC / ASECH
########################################################################

#
## sec(a + b*i) = 2/(exp(-i*(a + b*i)) + exp(i*(a + b*i)))
#

sub sec ($) {
    my ($x) = @_;

    $x = __PACKAGE__->new($x) if ref($x) ne __PACKAGE__;

    my $t1 = __PACKAGE__->new(+$x->{b}, -$x->{a})->exp;
    my $t2 = __PACKAGE__->new(-$x->{b}, +$x->{a})->exp;

    $t1->{a} += $t2->{a};
    $t1->{b} += $t2->{b};

    my $den = $t1->{a} * $t1->{a} + $t1->{b} * $t1->{b};

    $t1->{a} *= +2;
    $t1->{b} *= -2;

    if (!ref($den) and $den == 0) {
        $t1 = $t1->div($den);
    }
    else {
        $t1->{a} /= $den;
        $t1->{b} /= $den;
    }

    $t1;
}

#
## sech(a + b*i) = (2 * exp(a + b*i)) / (exp(2 * (a + b*i)) + 1)
#

sub sech ($) {
    my ($x) = @_;

    $x = __PACKAGE__->new($x) if ref($x) ne __PACKAGE__;

    my $t1 = $x->exp;
    my $t2 = __PACKAGE__->new($x->{a} * 2, $x->{b} * 2)->exp;

    $t1->{a} *= 2;
    $t1->{b} *= 2;

    $t2->{a} += 1;

    $t1->div($t2);
}

#
## asec(a + b*i) = acos(1/(a + b*i))
#

sub asec ($) {
    my ($x) = @_;

    $x = __PACKAGE__->new($x) if ref($x) ne __PACKAGE__;

    $x->inv->acos;
}

#
## asech(a + b*i) = acosh(1/(a + b*i))
#

sub asech ($) {
    my ($x) = @_;

    $x = __PACKAGE__->new($x) if ref($x) ne __PACKAGE__;

    $x->inv->acosh;
}

########################################################################
#               CSC / CSCH / ACSC / ACSCH
########################################################################

#
## csc(a + b*i) = -(2*i)/(exp(-i * (a + b*i)) - exp(i * (a + b*i)))
#

sub csc ($) {
    my ($x) = @_;

    $x = __PACKAGE__->new($x) if ref($x) ne __PACKAGE__;

    my $t1 = __PACKAGE__->new(+$x->{b}, -$x->{a})->exp;
    my $t2 = __PACKAGE__->new(-$x->{b}, +$x->{a})->exp;

    $t1->{a} -= $t2->{a};
    $t1->{b} -= $t2->{b};

    my $den = $t1->{a} * $t1->{a} + $t1->{b} * $t1->{b};

    $t1->{a} *= -2;
    $t1->{b} *= -2;

    if (!ref($den) and $den == 0) {
        $t1 = $t1->div($den);
    }
    else {
        $t1->{a} /= $den;
        $t1->{b} /= $den;
    }

    @{$t1}{qw(a b)} = ($t1->{b}, $t1->{a});

    $t1;
}

#
## csch(a + b*i) = (2*exp(a + b*i)) / (exp(2 * (a + b*i)) - 1)
#

sub csch ($) {
    my ($x) = @_;

    $x = __PACKAGE__->new($x) if ref($x) ne __PACKAGE__;

    my $t1 = $x->exp;
    my $t2 = __PACKAGE__->new($x->{a} * 2, $x->{b} * 2)->exp;

    $t1->{a} *= 2;
    $t1->{b} *= 2;

    $t2->{a} -= 1;

    $t1->div($t2);
}

#
## acsc(a + b*i) = asin(1/(a + b*i))
#

sub acsc ($) {
    my ($x) = @_;

    $x = __PACKAGE__->new($x) if ref($x) ne __PACKAGE__;

    $x->inv->asin;
}

#
## acsch(a + b*i) = asinh(1/(a + b*i))
#

sub acsch ($) {
    my ($x) = @_;

    $x = __PACKAGE__->new($x) if ref($x) ne __PACKAGE__;

    $x->inv->asinh;
}

#
## deg2rad(x) = x / 180 * atan2(0, -abs(x))
#

sub deg2rad ($) {
    my ($x) = @_;

    $x = __PACKAGE__->new($x) if ref($x) ne __PACKAGE__;

    my $t  = __PACKAGE__->new($x->{a} / 180, $x->{b} / 180);
    my $pi = CORE::atan2(0, -($x->{a} * $x->{a} + $x->{b} * $x->{b}));

    if (!ref($pi)) {
        $t->{a} *= $pi;
        $t->{b} *= $pi;
        return $t;
    }

    $t->mul($pi);
}

#
## rad2deg(x) = x * 180 / atan2(0, -abs(x))
#

sub rad2deg ($) {
    my ($x) = @_;

    $x = __PACKAGE__->new($x) if ref($x) ne __PACKAGE__;

    my $r = __PACKAGE__->new($x->{a} * 180, $x->{b} * 180);
    my $t = $x->{a} * $x->{a} + $x->{b} * $x->{b};

    if ($t == 0) {
        return $r;
    }

    my $pi = CORE::atan2(0, -$t);

    if (!ref($pi) and $pi != 0) {
        $r->{a} /= $pi;
        $r->{b} /= $pi;
        return $r;
    }

    $r->div($pi);
}

########################### MISC FUNCTIONS ###########################

#
## real(a + b*i) = a
#

sub real ($) {
    my ($x) = @_;

    $x = __PACKAGE__->new($x) if ref($x) ne __PACKAGE__;

    $x->{a};
}

#
## imag(a + b*i) = b
#

sub imag ($) {
    my ($x) = @_;

    $x = __PACKAGE__->new($x) if ref($x) ne __PACKAGE__;

    $x->{b};
}

#
## reals(a + b*i) = (a, b)
#

sub reals ($) {
    my ($x) = @_;

    $x = __PACKAGE__->new($x) if ref($x) ne __PACKAGE__;

    ($x->{a}, $x->{b});
}

#
## Equality
#

sub eq {
    my ($x, $y) = @_;

    $x = __PACKAGE__->new($x) if ref($x) ne __PACKAGE__;
    $y = __PACKAGE__->new($y) if ref($y) ne __PACKAGE__;

    $x->{a} == $y->{a}
      and $x->{b} == $y->{b};
}

#
## Inequality
#

sub ne {
    my ($x, $y) = @_;

    $x = __PACKAGE__->new($x) if ref($x) ne __PACKAGE__;
    $y = __PACKAGE__->new($y) if ref($y) ne __PACKAGE__;

    $x->{a} != $y->{a}
      or $x->{b} != $y->{b};
}

#
## Comparisons
#

sub cmp {
    my ($x, $y) = @_;

    $x = __PACKAGE__->new($x) if ref($x) ne __PACKAGE__;
    $y = __PACKAGE__->new($y) if ref($y) ne __PACKAGE__;

    (($x->{a} <=> $y->{a}) // return undef)
      or (($x->{b} <=> $y->{b}) // return undef);
}

sub acmp ($$) {
    my ($x, $y) = @_;

    $x = __PACKAGE__->new($x) if ref($x) ne __PACKAGE__;
    $y = __PACKAGE__->new($y) if ref($y) ne __PACKAGE__;

    $x->abs <=> $y->abs;
}

sub lt {
    my ($x, $y) = @_;

    $x = __PACKAGE__->new($x) if ref($x) ne __PACKAGE__;
    $y = __PACKAGE__->new($y) if ref($y) ne __PACKAGE__;

    ($x->cmp($y) // return undef) < 0;
}

sub le {
    my ($x, $y) = @_;

    $x = __PACKAGE__->new($x) if ref($x) ne __PACKAGE__;
    $y = __PACKAGE__->new($y) if ref($y) ne __PACKAGE__;

    ($x->cmp($y) // return undef) <= 0;
}

sub gt {
    my ($x, $y) = @_;

    $x = __PACKAGE__->new($x) if ref($x) ne __PACKAGE__;
    $y = __PACKAGE__->new($y) if ref($y) ne __PACKAGE__;

    ($x->cmp($y) // return undef) > 0;
}

sub ge {
    my ($x, $y) = @_;

    $x = __PACKAGE__->new($x) if ref($x) ne __PACKAGE__;
    $y = __PACKAGE__->new($y) if ref($y) ne __PACKAGE__;

    ($x->cmp($y) // return undef) >= 0;
}

sub stringify {
    my ($x) = @_;

    $x = __PACKAGE__->new($x) if ref($x) ne __PACKAGE__;

    "($x->{a} $x->{b})";
}

sub boolify {
    my ($x) = @_;

    $x = __PACKAGE__->new($x) if ref($x) ne __PACKAGE__;

    !!$x->{a} or !!$x->{b};
}

sub numify {
    my ($x) = @_;

    $x = __PACKAGE__->new($x) if ref($x) ne __PACKAGE__;

    $x->{a};
}

1;    # End of Math::GComplex
