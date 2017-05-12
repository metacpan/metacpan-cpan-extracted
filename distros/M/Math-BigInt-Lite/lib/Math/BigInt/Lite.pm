# For speed and simplicity, Lite objects are a reference to a scalar. When
# something more complex needs to happen (like +inf,-inf, NaN or rounding),
# they will upgrade themselves to Math::BigInt.

package Math::BigInt::Lite;

require 5.006002;
use strict;

require Exporter;
use Math::BigInt 1.999801;

our ($_trap_inf, $_trap_nan);

our @ISA = qw(Math::BigInt);
our @EXPORT_OK = qw/objectify/;
my $class = 'Math::BigInt::Lite';

our $VERSION = '0.17';

##############################################################################
# global constants, flags and accessory

our $accuracy   = undef;
our $precision  = undef;
our $round_mode = 'even';
our $div_scale  = 40;
our $upgrade    = 'Math::BigInt';
our $downgrade  = undef;

my $nan = 'NaN';

my $MAX_NEW_LEN;
my $MAX_MUL;
my $MAX_ADD;

my $MAX_BIN_LEN = 31;
my $MAX_OCT_LEN = 10;
my $MAX_HEX_LEN =  7;

BEGIN {
    my $e0 = 1;
    my $e1 = $e0 + 1;
    my $num;
    {
        $num = '9' x $e1;       # maximum value in base 10**$e1
        $num = $num * $num      # multiply by itself
               + ($num - 1);    # largest possible carry
        last if $num !~ /^9{$e0}89{$e1}$/;      # check digit pattern
        $e0 = $e1;
        $e1++;
        redo;
    }
    my $e = $e0;                # $e1 is one too large

    # the limits below brush the problems with the test above under the rug:

    # the test should be able to find the proper $e automatically
    $e = 5 if $^O =~ /^uts/;    # UTS get's some special treatment
    $e = 5 if $^O =~ /^unicos/; # unicos is also problematic (6 seems to work
                                # there, but we play safe)
    $e = 8 if $e > 8;           # cap, for VMS, OS/390 and other 64 bit systems

    my $bi = $e;

    #  # determine how many digits fit into an integer and can be safely added
    #  # together plus carry w/o causing an overflow
    #
    #  # this below detects 15 on a 64 bit system, because after that it becomes
    #  # 1e16  and not 1000000 :/ I can make it detect 18, but then I get a lot of
    #  # test failures. Ugh! (Tomake detect 18: uncomment lines marked with *)
    #  use integer;
    #  my $bi = 5;                   # approx. 16 bit
    #  $num = int('9' x $bi);
    #  # $num = 99999; # *
    #  # while ( ($num+$num+1) eq '1' . '9' x $bi)   # *
    #  while ( int($num+$num+1) eq '1' . '9' x $bi)
    #    {
    #    $bi++; $num = int('9' x $bi);
    #    # $bi++; $num *= 10; $num += 9;     # *
    #    }
    #  $bi--;                                # back off one step

    # we ensure that every number created is below the length for the add, so
    # that it is always safe to add two objects together
    $MAX_NEW_LEN = $bi;
    # The constant below is used to check the result of any add, if above, we
    # need to upgrade.
    $MAX_ADD = int("1E$bi");
    # For mul, we need to check *before* the operation that both operands are
    # below the number benlow, since otherwise it could overflow.
    $MAX_MUL = int("1E$e");

    # print "MAX_NEW_LEN $MAX_NEW_LEN MAX_ADD $MAX_ADD MAX_MUL $MAX_MUL\n\n";
}

##############################################################################
# we tie our accuracy/precision/round_mode to BigInt, so that setting it here
# will do it in BigInt, too. You can't use Lite w/o BigInt, anyway.

sub round_mode {
    no strict 'refs';
    # make Class->round_mode() work
    my $self = shift;
    my $class = ref($self) || $self || __PACKAGE__;
    if (defined $_[0]) {
        my $m = shift;
        die "Unknown round mode $m"
          if $m !~ /^(even|odd|\+inf|\-inf|zero|trunc|common)$/;
        # set in BigInt, too
        Math::BigInt->round_mode($m);
        return ${"${class}::round_mode"} = $m;
    }
    return ${"${class}::round_mode"};
}

sub accuracy {
    # $x->accuracy($a);           ref($x) $a
    # $x->accuracy();             ref($x)
    # Class->accuracy();          class
    # Class->accuracy($a);        class $a

    my $x = shift;
    my $class = ref($x) || $x || __PACKAGE__;

    no strict 'refs';
    # need to set new value?
    if (@_ > 0) {
        my $a = shift;
        die ('accuracy must not be zero') if defined $a && $a == 0;
        if (ref($x)) {
            # $object->accuracy() or fallback to global
            $x->bround($a) if defined $a;
            $x->{_a} = $a;      # set/overwrite, even if not rounded
            $x->{_p} = undef;   # clear P
        } else {
            # set global
            Math::BigInt->accuracy($a);
            # and locally here
            $accuracy = $a;
            $precision = undef; # clear P
        }
        return $a;              # shortcut
    }

    if (ref($x)) {
        # $object->accuracy() or fallback to global
        return $x->{_a} || ${"${class}::accuracy"};
    }
    return ${"${class}::accuracy"};
}

sub precision {
    # $x->precision($p);          ref($x) $p
    # $x->precision();            ref($x)
    # Class->precision();         class
    # Class->precision($p);       class $p

    my $x = shift;
    my $class = ref($x) || $x || __PACKAGE__;

    no strict 'refs';
    # need to set new value?
    if (@_ > 0) {
        my $p = shift;
        if (ref($x)) {
            # $object->precision() or fallback to global
            $x->bfround($p) if defined $p;
            $x->{_p} = $p;      # set/overwrite, even if not rounded
            $x->{_a} = undef;   # clear A
        } else {
            Math::BigInt->precision($p);
            # and locally here
            $accuracy = undef;  # clear A
            $precision = $p;
        }
        return $p;              # shortcut
    }

    if (ref($x)) {
        # $object->precision() or fallback to global
        return $x->{_p} || ${"${class}::precision"};
    }
    return ${"${class}::precision"};
}

use overload
  '+'     => sub {
                 my $x = $_[0];
                 my $s = $_[1];
                 $s = $class->new($s) unless ref($s);
                 if ($s->isa($class)) {
                     $x = \($$x + $$s);
                     bless $x, $class;     # inline copy
                     $upgrade->new($$x) if abs($$x) >= $MAX_ADD;
                 } else {
                     $x = $upgrade->new($$x)->badd($s);
                 }
                 $x;
             },

  '*'     => sub {
                 my $x = $_[0];
                 my $s = $_[1];
                 $s = $class->new($s) unless ref($s);
                 if ($s->isa($class)) {
                     $x = \($$x * $$s);
                     $$x = 0 if $$x eq '-0';      # correct 5.x.x bug
                     bless $x, $class;            # inline copy
                 } else {
                     $x = $upgrade->new(${$_[0]})->bmul($s);
                 }
             },

  # some shortcuts for speed (assumes that reversed order of arguments is routed
  # to normal '+' and we thus can always modify first arg. If this is changed,
  # this breaks and must be adjusted.)
  #'/='    =>      sub { scalar $_[0]->bdiv($_[1]); },
  #'*='    =>      sub { $_[0]->bmul($_[1]); },
  #'+='    =>      sub { $_[0]->badd($_[1]); },
  #'-='    =>      sub { $_[0]->bsub($_[1]); },
  #'%='    =>      sub { $_[0]->bmod($_[1]); },
  #'&='    =>      sub { $_[0]->band($_[1]); },
  #'^='    =>      sub { $_[0]->bxor($_[1]); },
  #'|='    =>      sub { $_[0]->bior($_[1]); },
  #'**='   =>      sub { $upgrade->bpow($_[0], $_[1]); },

  '<=>'   => sub { $_[2] ? bcmp($_[1], $_[0]) : bcmp($_[0], $_[1]); },

  '""'    => sub { ${$_[0]}; },

  '0+'    => sub { ${$_[0]}; },

  '++'    => sub {
                 ${$_[0]}++;
                 return $upgrade->new(${$_[0]}) if ${$_[0]} >= $MAX_ADD;
                 $_[0];
             },

  '--'    => sub {
                 ${$_[0]}--;
                 return $upgrade->new(${$_[0]}) if ${$_[0]} <= -$MAX_ADD;
                 $_[0];
             },
  # fake HASH reference, so that Math::BigInt::Lite->new(123)->{sign} works
  '%{}'   => sub {
                 {
                     sign => ($_[0] < 0) ? '-' : '+',
                 };
             },
    ;

BEGIN {
    *objectify = \&Math::BigInt::objectify;
}

sub config {
    my $cfg = Math::BigInt -> config();
    $cfg->{version_lite} = $VERSION;
    $cfg;
}

sub bgcd {
    if (@_ == 1) {              # bgcd (8) == bgcd(8, 0) == 8
        my $x = shift;
        $x = $class->new($x) unless ref($x);
        return $x;
    }

    my @a = ();
    foreach (@_) {
        my $x = $_;
        $x = $upgrade->new($x) unless ref ($x);
        $x = $upgrade->new($$x) if $x->isa($class);
        push @a, $x;
    }
    Math::BigInt::bgcd(@a);
}

sub blcm {
    my @a = ();
    foreach (@_) {
        my $x = $_;
        $x = $upgrade->new($x) unless ref ($x);
        $x = $upgrade->new($$x) if $x->isa($class);
        push @a, $x;
    }
    Math::BigInt::blcm(@a);
}

sub isa {
    # we aren't a BigInt nor BigRat/BigFloat
    $_[1] =~ /^Math::BigInt::Lite/ ? 1 : 0;
}

sub new {
    my ($class, $wanted, @r) = @_;

    return $upgrade->new($wanted) if !defined $wanted;

    # 1e12, NaN, inf, 0x12, 0b11, 1.2e2, "12345678901234567890" etc all upgrade
    if (!ref($wanted)) {
        if ((length($wanted) <= $MAX_NEW_LEN) &&
            ($wanted =~ /^[+-]?[0-9]{1,$MAX_NEW_LEN}(\.0*)?\z/)) {
            my $a = \($wanted+0); # +0 to make a copy and force it numeric
            return bless $a, $class;
        }
        # TODO: 1e10 style constants that are still below MAX_NEW
        if ($wanted =~ /^([+-])?([0-9]+)[eE][+]?([0-9]+)$/) {
            if ((length($2) + $3) < $MAX_NEW_LEN) {
                my $a = \($wanted+0); # +0 to make a copy and force it numeric
                return bless $a, $class;
            }
        }
        #    print "new '$$a' $BASE_LEN ($wanted)\n";
    }
    $upgrade->new($wanted, @r);
}

sub bstr {
    my ($class, $x) = ref($_[0]) ? (ref($_[0]), $_[0]) : objectify(1, @_);

    return $x->bstr() unless $x->isa($class);
    $$x;
}

sub bsstr {
    my ($class, $x) = ref($_[0]) ? (ref($_[0]), $_[0]) : objectify(1, @_);

    $upgrade->new($$x)->bsstr();
}

sub bnorm {
    # no-op
    my $x = ref($_[0]) ? $_[0] : $_[0]->new($_[1]);

    $x;
}

sub _upgrade_2 {
    # This takes the two possible arguments, and checks them. It uses new() to
    # convert literals to objects first. Then it upgrades the operation
    # when it detects that:
    # * one or both of the argument(s) is/are BigInt,
    # * global A or P are set
    # Input arguments: x, y, a, p, r
    # Output: flag (1: need to upgrade, 0: need not), x, y, $a, $p, $r

    # Math::BigInt::Lite->badd(1, 2) style calls
    shift if !ref($_[0]) && $_[0] =~ /^Math::BigInt::Lite/;

    my ($x, $y, $a, $p, $r) = @_;

    my $up = 0;                 # default: don't upgrade

    $up = 1
      if (defined $a || defined $p || defined $accuracy || defined $precision);
    $x = __PACKAGE__->new($x) unless ref $x; # upgrade literals
    $y = __PACKAGE__->new($y) unless ref $y; # upgrade literals
    $up = 1 unless $x->isa($class) && $y->isa($class);
    # no need to check for overflow for add/sub/div/mod math
    if ($up == 1) {
        $x = $upgrade->new($$x) if $x->isa($class);
        $y = $upgrade->new($$y) if $y->isa($class);
    }

    ($up, $x, $y, $a, $p, $r);
}

sub _upgrade_2_mul {
    # This takes the two possible arguments, and checks them. It uses new() to
    # convert literals to objects first. Then it upgrades the operation
    # when it detects that:
    # * one or both of the argument(s) is/are BigInt,
    # * global A or P are set
    # * One of the arguments is too large for the operation
    # Input arguments: x, y, a, p, r
    # Output: flag (1: need to upgrade, 0: need not), x, y, $a, $p, $r

    # Math::BigInt::Lite->badd(1, 2) style calls
    shift if !ref($_[0]) && $_[0] =~ /^Math::BigInt::Lite/;

    my ($x, $y, $a, $p, $r) = @_;

    my $up = 0;                 # default: don't upgrade

    $up = 1
      if (defined $a || defined $p || defined $accuracy || defined $precision);
    $x = __PACKAGE__->new($x) unless ref $x; # upgrade literals
    $y = __PACKAGE__->new($y) unless ref $y; # upgrade literals
    $up = 1 unless $x->isa($class) && $y->isa($class);
    $up = 1 if ($up == 0 && (abs($$x) >= $MAX_MUL || abs($$y) >= $MAX_MUL) );
    if ($up == 1) {
        $x = $upgrade->new($$x) if $x->isa($class);
        $y = $upgrade->new($$y) if $y->isa($class);
    }
    ($up, $x, $y, $a, $p, $r);
}

sub _upgrade_1 {
    # This takes the one possible argument, and checks it. It uses new() to
    # convert a literal to an object first. Then it checks for a necc. upgrade:
    # * the argument is a BigInt
    # * global A or P are set
    # Input arguments: x, a, p, r
    # Output: flag (1: need to upgrade, 0: need not), x, $a, $p, $r
    my ($x, $a, $p, $r) = @_;

    my $up = 0;                 # default: don't upgrade

    $up = 1
      if (defined $a || defined $p || defined $accuracy || defined $precision);
    $x = __PACKAGE__->new($x) unless ref $x; # upgrade literals
    $up = 1 unless $x->isa($class);
    if ($up == 1) {
        $x = $upgrade->new($$x) if $x->isa($class);
    }
    ($up, $x, $a, $p, $r);
}

##############################################################################
# rounding functions

sub bround {
    my ($self, $x, $a, $m) = ref($_[0]) ? (ref($_[0]), @_) :
      ($class, $class->new($_[0]), $_[1], $_[2]);

    #$m = $self->round_mode() if !defined $m;
    #$a = $self->accuracy() if !defined $a;

    $x = $upgrade->new($$x) if $x->isa($class);
    $x->bround($a, $m);
}

sub bfround {
    my ($self, $x, $p, $m) = ref($_[0]) ? (ref($_[0]), @_) :
      ($class, $class->new($_[0]), $_[1], $_[2]);

    #$m = $self->round_mode() if !defined $m;
    #$p = $self->precision() if !defined $p;

    $x = $upgrade->new($$x) if $x->isa($class);
    $x->bfround($p, $m);

}

sub round {
    my ($self, $x, $a, $p, $r) = ref($_[0]) ? (ref($_[0]), @_) :
      ($class, $class->new(@_), $_[0], $_[1], $_[2]);

    $x = $upgrade->new($$x) if $x->isa($class);
    $x->round($a, $p, $r);
}

##############################################################################
# special values

sub bnan {
    # return a bnan or set object to NaN
    my $x = shift;

    $upgrade->bnan();
}

sub binf {
    # return a binf
    my $x = shift;

    #  return $upgrade->new($$x)->binf(@_) if ref $x;
    $upgrade->binf(@_);         # binf(1, '-') form
}

sub bone {
    # return a one
    my $x = shift;

    my $num = ($_[0] || '') eq '-' ? -1 : 1;
    return $x->new($num) unless ref $x; # Class->bone();
    $$x = $num;
    $x;
}

sub bzero {
    # return a one
    my $x = shift;

    return $x->new(0) unless ref $x; # Class->bone();
    $$x = 0;
    $x;
}

sub bcmp {
    # compare two objects
    my ($x, $y) = @_;

    $x = $class->new($x) unless ref $x;
    $y = $class->new($y) unless ref $y;

    return $$x <=> $$y if $x->isa($class) && $y->isa($class);
    my $x1 = $x;
    my $y1 = $y;
    $x1 = $upgrade->new($$x) if $x->isa($class);
    $y1 = $upgrade->new($$y) if $y->isa($class);
    $x1->bcmp($y1);             # one of them other class
}

sub bacmp {
    # compare two objects
    my ($x, $y) = @_;

    #  print "bacmp $x $y\n";
    $x = $class->new($x) unless ref $x;
    $y = $class->new($y) unless ref $y;
    return (abs($$x) <=> abs($$y))
      if $x->isa($class) && $y->isa($class);
    my $x1 = $x;
    my $y1 = $y;
    $x1 = $upgrade->new($$x) if $x->isa($class);
    $y1 = $upgrade->new($$y) if $y->isa($class);
    $x1->bacmp($y1);            # one of them other class
}

##############################################################################
# copy/conversion

sub copy {
    my $x = shift;
    return $class->new($x) if !ref $x;

    my $a = $$x;
    my $t = \$a;
    bless $t, $class;
}

sub as_number {
    my ($x) = shift;

    return $upgrade->new($x) unless ref($x);
    # as_number needs to return a BigInt
    return $upgrade->new($$x) if $x->isa($class);
    $x->copy();
}

sub numify {
    my ($self, $x) = ref($_[0]) ? (ref($_[0]), $_[0])
                                : ($class, $class->new(@_));

    return $$x if $x->isa($class);
    $x->numify();
}

sub as_hex {
    my ($self, $x) = ref($_[0]) ? (ref($_[0]), $_[0])
                                : ($class, $class->new(@_));

    return $upgrade->new($$x)->as_hex() if $x->isa($class);
    $x->as_hex();
}

sub as_oct {
    my ($self, $x) = ref($_[0]) ? (ref($_[0]), $_[0])
                                : ($class, $class->new(@_));

    return $upgrade->new($$x)->as_oct() if $x->isa($class);
    $x->as_hex();
}

sub as_bin {
    my ($self, $x) = ref($_[0]) ? (ref($_[0]), $_[0])
                                : ($class, $class->new(@_));

    return $upgrade->new($$x)->as_bin() if $x->isa($class);
    $x->as_bin();
}

sub from_hex {
    my $self    = shift;
    my $selfref = ref $self;
    my $class   = $selfref || $self;

    my $str = shift;

    # If called as a class method, initialize a new object.

    $self = $class -> bzero() unless $selfref;

    if ($str =~ s/
                     ^
                     ( [+-]? )
                     (0?x)?
                     (
                         [0-9a-fA-F]*
                         ( _ [0-9a-fA-F]+ )*
                     )
                     $
                 //x)
    {
        # Get a "clean" version of the string, i.e., non-emtpy and with no
        # underscores or invalid characters.

        my $sign = $1;
        my $chrs = $3;
        $chrs =~ tr/_//d;
        $chrs = '0' unless CORE::length $chrs;

        return $upgrade -> from_hex($sign . $chrs)
          if length($chrs) > $MAX_HEX_LEN;

        $$self = oct('0x' . $chrs);
        $$self = -$$self if $sign eq '-';

        return $self;
    }

    # For consistency with from_hex() and from_oct(), we return NaN when the
    # input is invalid.

    return $self->bnan();
}

sub from_oct {
    my $self    = shift;
    my $selfref = ref $self;
    my $class   = $selfref || $self;

    my $str = shift;

    # If called as a class method, initialize a new object.

    $self = $class -> bzero() unless $selfref;

    if ($str =~ s/
                     ^
                     ( [+-]? )
                     (
                         [0-7]*
                         ( _ [0-7]+ )*
                     )
                     $
                 //x)
    {
        # Get a "clean" version of the string, i.e., non-emtpy and with no
        # underscores or invalid characters.

        my $sign = $1;
        my $chrs = $2;
        $chrs =~ tr/_//d;
        $chrs = '0' unless CORE::length $chrs;

        return $upgrade -> from_oct($sign . $chrs)
          if length($chrs) > $MAX_OCT_LEN;

        $$self = oct($chrs);
        $$self = -$$self if $sign eq '-';

        return $self;
    }

    # For consistency with from_hex() and from_oct(), we return NaN when the
    # input is invalid.

    return $self->bnan();
}

sub from_bin {
    my $self    = shift;
    my $selfref = ref $self;
    my $class   = $selfref || $self;

    my $str = shift;

    # If called as a class method, initialize a new object.

    $self = $class -> bzero() unless $selfref;

    if ($str =~ s/
                     ^
                     ( [+-]? )
                     (0?b)?
                     (
                         [01]*
                         ( _ [01]+ )*
                     )
                     $
                 //x)
    {
        # Get a "clean" version of the string, i.e., non-emtpy and with no
        # underscores or invalid characters.

        my $sign = $1;
        my $chrs = $3;
        $chrs =~ tr/_//d;
        $chrs = '0' unless CORE::length $chrs;

        return $upgrade -> from_bin($sign . $chrs)
          if length($chrs) > $MAX_BIN_LEN;

        $$self = oct('0b' . $chrs);
        $$self = -$$self if $sign eq '-';

        return $self;
    }

    # For consistency with from_hex() and from_oct(), we return NaN when the
    # input is invalid.

    return $self->bnan();
}

##############################################################################
# binc/bdec

sub binc {
    # increment by one
    my ($up, $x, $y, $a, $p, $r) = _upgrade_1(@_);

    return $x->binc($a, $p, $r) if $up;
    $$x++;
    return $upgrade->new($$x) if abs($$x) > $MAX_ADD;
    $x;
}

sub bdec {
    # decrement by one
    my ($up, $x, $y, $a, $p, $r) = _upgrade_1(@_);

    return $x->bdec($a, $p, $r) if $up;
    $$x--;
    return $upgrade->new($$x) if abs($$x) > $MAX_ADD;
    $x;
}

##############################################################################
# shifting

sub brsft {
    # shift right
    my ($class, $x, $y, $b, @r) = objectify(2, @_);

    $x = $class->new($x) unless ref($x);
    $y = $class->new($y) unless ref($y);
    $b = $$b if ref $b && $b->isa($class);

    if (!$x->isa($class)) {
        $y = $upgrade->new($$y) if $y->isa($class);
        return $x->brsft($y, $b, @r);
    }
    return $upgrade->new($$x)->brsft($y, $b, @r)
      unless $y->isa($class);

    $b = 2 if !defined $b;
    # can't do this
    return $upgrade->new($$x)->brsft($upgrade->new($$y), $b, @r)
      if $b != 2 || $$y < 0;
    use integer;
    $$x >>= $$y;                # only base 2 for now
    $x;
}

sub blsft {
    # shift left
    my ($class, $x, $y, $b, @r) = objectify(2, @_);

    $x = $class->new($x) unless ref($x);
    $y = $class->new($x) unless ref($y);

    return $x->blsft($upgrade->new($$y), $b, @r) unless $x->isa($class);
    return $upgrade->new($$x)->blsft($y, $b, @r)
      unless $y->isa($class);

    # overflow: can't do this
    return $upgrade->new($$x)->blsft($upgrade->new($$y), $b, @r)
      if $$y > 31;
    $b = 2 if !defined $b;
    # can't do this
    return $upgrade->new($$x)->blsft($upgrade->new($$y), $b, @r)
      if $b != 2 || $$y < 0;
    use integer;
    $$x <<= $$y;                # only base 2 for now
    $x;
}

##############################################################################
# bitwise logical operators

sub band {
    # AND two objects
    my ($x, $y, $a, $p, $r) = @_;   #objectify(2, @_);

    $x = $class->new($x) unless ref($x);
    $y = $class->new($x) unless ref($y);

    return $x->band($y, $a, $p, $r) unless $x->isa($class);
    return $upgrade->band($x, $y, $a, $p, $r) unless $y->isa($class);
    use integer;
    $$x = ($$x+0) & ($$y+0);    # +0 to avoid string-context
    $x;
}

sub bxor {
    # XOR two objects
    my ($x, $y, $a, $p, $r) = @_;   #objectify(2, @_);

    $x = $class->new($x) unless ref($x);
    $y = $class->new($x) unless ref($y);

    return $x->bxor($y, $a, $p, $r) unless $x->isa($class);
    return $upgrade->bxor($x, $y, $a, $p, $r) unless $y->isa($class);
    use integer;
    $$x = ($$x+0) ^ ($$y+0);    # +0 to avoid string-context
    $x;
}

sub bior {
    # OR two objects
    my ($x, $y, $a, $p, $r) = @_;   #objectify(2, @_);

    $x = $class->new($x) unless ref($x);
    $y = $class->new($x) unless ref($y);

    return $x->bior($y, $a, $p, $r) unless $x->isa($class);
    return $upgrade->bior($x, $y, $a, $p, $r) unless $y->isa($class);
    use integer;
    $$x = ($$x+0) | ($$y+0);    # +0 to avoid string-context
    $x;
}

##############################################################################
# mul/add/div etc

sub badd {
    # add two objects
    my ($up, $x, $y, $a, $p, $r) = _upgrade_2(@_);

    return $x->badd($y, $a, $p, $r) if $up;

    $$x = $$x + $$y;
    return $upgrade->new($$x) if abs($$x) > $MAX_ADD;
    $x;
}

sub bsub {
    # subtract two objects
    my ($up, $x, $y, $a, $p, $r) = _upgrade_2(@_);
    return $x->bsub($y, $a, $p, $r) if $up;
    $$x = $$x - $$y;
    return $upgrade->new($$x) if abs($$x) > $MAX_ADD;
    $x;
}

sub bmul {
    # multiply two objects
    my ($up, $x, $y, $a, $p, $r) = _upgrade_2_mul(@_);
    return $x->bmul($y, $a, $p, $r) if $up;
    $$x = $$x * $$y;
    $$x = 0 if $$x eq '-0';  # for some Perls leave '-0' here
    #return $upgrade->new($$x) if abs($$x) > $MAX_ADD;
    $x;
}

sub bmod {
    # remainder of div
    my ($up, $x, $y, $a, $p, $r) = _upgrade_2(@_);
    return $x->bmod($y, $a, $p, $r) if $up;
    return $upgrade->new($$x)->bmod($y, $a, $p, $r) if $$y == 0;
    $$x = $$x % $$y;
    $x;
}

sub bdiv {
    # divide two objects
    my ($up, $x, $y, $a, $p, $r) = _upgrade_2(@_);

    return $x->bdiv($y, $a, $p, $r) if $up;

    return $upgrade->new($$x)->bdiv($$y, $a, $p, $r) if $$y == 0;

    # need to give Math::BigInt a chance to upgrade further
    return $upgrade->new($$x)->bdiv($$y, $a, $p, $r)
      if defined $Math::BigInt::upgrade;

    my ($quo, $rem);

    $rem = \($$x % $$y);
    $quo = int($$x / $$y);
    $quo-- if $$rem != 0 && ($$x <=> 0) != ($$y <=> 0);

    $$x = $quo;

    if (wantarray) {
        bless $rem, $class;
        return $x, $rem;
    }

    return $x;
}

sub btdiv {
    # divide two objects
    my ($up, $x, $y, $a, $p, $r) = _upgrade_2(@_);

    return $x->btdiv($y, $a, $p, $r) if $up;

    return $upgrade->new($$x)->btdiv($$y, $a, $p, $r) if $$y == 0;

    # need to give Math::BigInt a chance to upgrade further
    return $upgrade->new($$x)->btdiv($$y, $a, $p, $r)
      if defined $Math::BigInt::upgrade;

    my ($quo, $rem);

    if (wantarray) {
        $rem = \($$x % $$y);
        $$rem -= $$y if $$rem != 0 && ($$x <=> 0) != ($$y <=> 0);
        bless $rem, $class;
    }

    $quo = int($$x / $$y);

    $$x = $quo;
    return $x, $rem if wantarray;
    return $x;
}

##############################################################################
# is_foo methods (the rest is inherited)

sub is_int {
    # return true if arg (BLite or num_str) is an integer
    my ($class, $x) = ref($_[0]) ? (ref($_[0]), $_[0]) : objectify(1, @_);

    return 1 if $x->isa($class); # Lite objects are always int
    $x->is_int();
}

sub is_inf {
    # return true if arg (BLite or num_str) is an infinity
    my ($class, $x) = ref($_[0]) ? (ref($_[0]), $_[0]) : objectify(1, @_);

    return 0 if $x->isa($class); # Lite objects are never inf
    $x->is_inf();
}

sub is_nan {
    # return true if arg (BLite or num_str) is an NaN
    my ($class, $x) = ref($_[0]) ? (ref($_[0]), $_[0]) : objectify(1, @_);

    return 0 if $x->isa($class); # Lite objects are never NaN
    $x->is_nan();
}

sub is_zero {
    # return true if arg (BLite or num_str) is zero
    my ($class, $x) = ref($_[0]) ? (ref($_[0]), $_[0]) : objectify(1, @_);

    return ($$x == 0) <=> 0 if $x->isa($class);
    $x->is_zero();
}

sub is_positive {
    # return true if arg (BLite or num_str) is positive
    my ($class, $x) = ref($_[0]) ? (ref($_[0]), $_[0]) : objectify(1, @_);

    return ($$x > 0) <=> 0 if $x->isa($class);
    $x->is_positive();
}

sub is_negative {
    # return true if arg (BLite or num_str) is negative
    my ($class, $x) = ref($_[0]) ? (ref($_[0]), $_[0]) : objectify(1, @_);

    return ($$x < 0) <=> 0 if $x->isa($class);
    $x->is_positive();
}

sub is_one {
    # return true if arg (BLite or num_str) is one
    my ($class, $x, $s) = ref($_[0]) ? (ref($_[0]), @_) : objectify(1, @_);

    my $one = 1;
    $one = -1 if ($s || '+') eq '-';
    return ($$x == $one) <=> 0 if $x->isa($class);
    $x->is_one();
}

sub is_odd {
    # return true if arg (BLite or num_str) is odd
    my ($class, $x) = ref($_[0]) ? (ref($_[0]), $_[0]) : objectify(1, @_);

    return $x->is_odd() unless $x->isa($class);
    $$x & 1 == 1 ? 1 : 0;
}

sub is_even {
    # return true if arg (BLite or num_str) is even
    my ($class, $x) = ref($_[0]) ? (ref($_[0]), $_[0]) : objectify(1, @_);

    return $x->is_even() unless $x->isa($class);
    $$x & 1 == 1 ? 0 : 1;
}

##############################################################################
# parts() and friends

sub parts {
    my ($self, $x) = ref($_[0]) ? (ref($_[0]), $_[0]) :
      ($class, $class->new($_[0]));

    $x = $upgrade->new("$x") if $x->isa($class);
    return $x->parts();
}

sub sign {
    my ($self, $x) = ref($_[0]) ? (ref($_[0]), $_[0]) :
      ($class, $class->new($_[0]));

    $$x >= 0 ? '+' : '-';
}

sub exponent {
    my ($self, $x) = ref($_[0]) ? (ref($_[0]), $_[0]) :
      ($class, $class->new($_[0]));

    return $upgrade->new($$x)->exponent() if $x->isa($class);
    $x->exponent();
}

sub mantissa {
    my ($self, $x) = ref($_[0]) ? (ref($_[0]), $_[0]) :
      ($class, $class->new($_[0]));

    return $upgrade->new($$x)->mantissa() if $x->isa($class);
    $x->mantissa();
}

sub digit {
    my ($class, $x, $n) = ref($_[0]) ? (ref($_[0]), @_) : objectify(1, @_);

    return $x->digit($n) unless $x->isa($class);

    $n = 0 if !defined $n;
    my $len = length("$$x");

    $n = $len+$n if $n < 0;     # -1 last, -2 second-to-last
    $n = abs($n);               # if negative was too big
    $len--;
    $n = $len if $n > $len;     # n to big?

    substr($$x, -$n-1, 1);
}

sub length {
    my ($class, $x) = ref($_[0]) ? (ref($_[0]), $_[0]) : objectify(1, @_);

    return $x->length() unless $x->isa($class);
    my $l = length($$x);
    $l-- if $$x < 0;            # -123 => 123
    $l;
}

##############################################################################
# sign based methods

sub babs {
    my ($class, $x) = ref($_[0]) ? (undef, $_[0]) : objectify(1, @_);

    $$x = abs($$x);
    $x;
}

sub bneg {
    my ($class, $x) = ref($_[0]) ? (undef, $_[0]) : objectify(1, @_);

    $$x = -$$x if $$x != 0;
    $x;
}

sub bnot {
    my ($class, $x) = ref($_[0]) ? (undef, $_[0]) : objectify(1, @_);

    $$x = -$$x - 1;
    $x;
}

##############################################################################
# special calc routines

sub bceil {
    my ($class, $x) = ref($_[0]) ? (undef, $_[0]) : objectify(1, @_);
    $x;                         # no-op
}

sub bfloor {
    my ($class, $x) = ref($_[0]) ? (undef, $_[0]) : objectify(1, @_);
    $x;                         # no-op
}

sub bfac {
    my ($self, $x, $a, $p, $r) = ref($_[0]) ? (ref($_[0]), @_) :
      ($class, $class->new($_[0]), $_[1], $_[2], $_[3], $_[4]);

    $x = $upgrade->new($$x) if $x->isa($class);
    $upgrade->bfac($x, $a, $p, $r);
}

sub bpow {
    my ($class, $x, $y, @r) = objectify(2, @_);

    $x = $upgrade->new($$x) if $x->isa($class);
    $y = $upgrade->new($$y) if $y->isa($class);

    $x->bpow($y, @r);
}

sub blog {
    my ($class, $x, $base, @r);

    # Don't objectify the base, since an undefined base, as in $x->blog() or
    # $x->blog(undef) signals that the base is Euler's number.

    if (!ref($_[0]) && $_[0] =~ /^[A-Za-z]|::/) {
        # E.g., Math::BigInt::Lite->blog(256, 2)
        ($class, $x, $base, @r) =
          defined $_[2] ? objectify(2, @_) : objectify(1, @_);
    } else {
        # E.g., Math::BigInt::Lite::blog(256, 2) or $x->blog(2)
        ($class, $x, $base, @r) =
          defined $_[1] ? objectify(2, @_) : objectify(1, @_);
    }

    $x = $upgrade->new($$x) if $x->isa($class);
    $base = $upgrade->new($$base) if defined $base && $base->isa($class);

    $x->blog($base, @r);
}

sub bexp {
    my ($class, $x, @r) = objectify(1, @_);

    $x = $upgrade->new($$x) if $x->isa($class);

    $x->bexp(@r);
}

sub batan2 {
    my ($class, $x, @r) = objectify(2, @_);

    $x = $upgrade->new($$x) if $x->isa($class);

    $x->batan2(@r);
}

sub bnok {
    my ($class, $x, $y, @r) = objectify(2, @_);

    $x = $upgrade->new($$x) if $x->isa($class);
    $y = $upgrade->new($$y) if $y->isa($class);

    $x->bnok($y, @r);
}

sub broot {
    my ($class, $x, $base, @r) = objectify(2, @_);

    $x = $upgrade->new($$x) if $x->isa($class);
    $base = $upgrade->new($$base) if defined $base && $base->isa($class);

    $x->broot($base, @r);
}

sub bmuladd {
    my ($class, $x, $y, $z, @r) = objectify(2, @_);

    $x = $upgrade->new($$x) if $x->isa($class);
    $y = $upgrade->new($$y) if defined $y && $y->isa($class);
    $z = $upgrade->new($$z) if defined $z && $z->isa($class);

    $x->bmuladd($y, $z, @r);
}

sub bmodpow {
    my ($class, $x, $y, @r) = objectify(2, @_);

    $x = $upgrade->new($$x) if $x->isa($class);
    $y = $upgrade->new($$y) if defined $y && $y->isa($class);

    $x->bmodpow($y, @r);
}

sub bmodinv {
    my ($class, $x, $y, @r) = objectify(2, @_);

    $x = $upgrade->new($$x) if $x->isa($class);
    $y = $upgrade->new($$y) if defined $y && $y->isa($class);

    $x->bmodinv($y, @r);
}

sub bsqrt {
    my ($class, $x, @r) =
      ref($_[0]) ? (ref($_[0]), @_)
                 : ($class, $class->new($_[0]), $_[1], $_[2], $_[3]);

    return $x->bsqrt(@r) unless $x->isa($class);

    return $upgrade->new($$x)->bsqrt() if $$x < 0; # NaN
    my $s = sqrt($$x);
    # If MBI's upgrade is defined, and result is non-integer, we need to hand
    # up. If upgrade is undef, result would be the same, anyway
    if (int($s) != $s) {
        return $upgrade->new($$x)->bsqrt();
    }
    $$x = $s;
    $x;
}

##############################################################################

sub import {
    my $self = shift;

    my @a = @_;
    my $l = scalar @_;
    my $j = 0;
    my $lib = '';
    for (my $i = 0; $i < $l ; $i++, $j++) {
        if ($_[$i] eq ':constant') {
            # this causes overlord er load to step in
            overload::constant integer => sub { $self->new(shift) };
            splice @a, $j, 1;
            $j --;
        } elsif ($_[$i] eq 'upgrade') {
            # this causes upgrading
            $upgrade = $_[$i+1]; # or undef to disable
            my $s = 2;
            $s = 1 if @a-$j < 2; # no "can not modify non-existant..."
            splice @a, $j, $s;
            $j -= $s;
        } elsif ($_[$i] eq 'lib') {
            $lib = $_[$i+1];    # or undef to disable
            my $s = 2;
            $s = 1 if @a-$j < 2; # no "can not modify non-existant..."
            splice @a, $j, $s;
            $j -= $s;
        }
    }
    # any non :constant stuff is handled by our parent, Math::BigInt or Exporter
    # even if @_ is empty, to give it a chance
    $self->SUPER::import(@a);           # need it for subclasses
    $self->export_to_level(1, $self, @a); # need it for MBF
}

1;

__END__

=pod

=head1 NAME

Math::BigInt::Lite - What Math::BigInts are before they become big

=head1 SYNOPSIS

    use Math::BigInt::Lite;

    $x = Math::BigInt::Lite->new(1);

    print $x->bstr(), "\n";                     # 1
    $x = Math::BigInt::Lite->new('1e1234');
    print $x->bsstr(), "\n";                    # 1e1234 (silently upgrades to
                                                # Math::BigInt)

=head1 DESCRIPTION

Math::BigInt is not very good suited to work with small (read: typical
less than 10 digits) numbers, since it has a quite high per-operation overhead
and is thus much slower than normal Perl for operations like:

    my $x = 1 + 2;                          # fast and correct
    my $x = 2 ** 256;                       # fast, but wrong

    my $x = Math::BigInt->new(1) + 2;       # slow, but correct
    my $x = Math::BigInt->new(2) ** 256;    # slow, and still correct

But for some applications, you want fast speed for small numbers without
the risk of overflowing.

This is were C<Math::BigInt::Lite> comes into play.

Math::BigInt::Lite objects should behave in every way like Math::BigInt
objects, that is apart from the different label, you should not be able
to tell the difference. Since Math::BigInt::Lite is designed with speed in
mind, there are certain limitations build-in. In praxis, however, you will
not feel them, because everytime something gets to big to pass as Lite
(literally), it will upgrade the objects and operation in question to
Math::BigInt.

=head2 Math library

Math with the numbers is done (by default) by a module called
Math::BigInt::Calc. This is equivalent to saying:

    use Math::BigInt::Lite lib => 'Calc';

You can change this by using:

    use Math::BigInt::Lite lib => 'GMP';

The following would first try to find Math::BigInt::Foo, then
Math::BigInt::Bar, and when this also fails, revert to Math::BigInt::Calc:

    use Math::BigInt::Lite lib => 'Foo,Math::BigInt::Bar';

See the respective low-level math library documentation for further
details.

Please note that Math::BigInt::Lite does B<not> use the denoted library itself,
but it merely passes the lib argument to Math::BigInt. So, instead of the need
to do:

    use Math::BigInt lib => 'GMP';
    use Math::BigInt::Lite;

you can roll it all into one line:

    use Math::BigInt::Lite lib => 'GMP';

Use the lib, Luke!

=head2 Using Lite as substitute for Math::BigInt

The pragmas L<bigrat>, L<bignum> and L<bigint> will automatically use
Math::BigInt::Lite whenever possible.

=head1 METHODS

=head2 new

    $x = Math::BigInt::Lite->new('1');

Create a new Math::BigInt:Lite object. When the input is not of an suitable
simple and small form, an object of the class of C<$upgrade> (typically
Math::BigInt) will be returned.

All other methods from BigInt and BigFloat should work as expected.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-math-bigint at rt.cpan.org>, or through the web interface at
L<https://rt.cpan.org/Ticket/Create.html?Queue=Math-BigInt-Lite> (requires login).
We will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Math::BigInt::Lite

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Math-BigInt-Lite>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Math-BigInt-Lite>

=item * CPAN Ratings

L<http://cpanratings.perl.org/dist/Math-BigInt-Lite>

=item * Search CPAN

L<http://search.cpan.org/dist/Math-BigInt-Lite/>

=item * CPAN Testers Matrix

L<http://matrix.cpantesters.org/?dist=Math-BigInt-Lite>

=back

=head1 LICENSE

This program is free software; you may redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

L<Math::BigFloat> and L<Math::Big> as well as
L<Math::BigInt::Pari> and L<Math::BigInt::GMP>.

The L<bignum|bignum> module.

=head1 AUTHORS

=over 4

=item *

Copyright 2002-2007 Tels, L<http://bloodgate.com>.

=item *

Copyright 2010 Florian Ragwitz L<flora@cpan.org>.

=item *

Copyright 2016- Peter John Acklam L<pjacklam@online.no>.

=back

=cut
