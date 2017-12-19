package Math::Bacovia::Difference;

use 5.014;
use warnings;

use Class::Multimethods qw();
use parent qw(Math::Bacovia);

our $VERSION = $Math::Bacovia::VERSION;

my %cache;

sub new {
    my ($class, $minuend, $subtrahend) = @_;

    if (defined($minuend)) {
        Math::Bacovia::_check_type(\$minuend);
    }
    else {
        $minuend = $Math::Bacovia::ZERO;
    }

    if (defined($subtrahend)) {
        Math::Bacovia::_check_type(\$subtrahend);
    }
    else {
        $subtrahend = $Math::Bacovia::ZERO;
    }

    $cache{join(';', $minuend->stringify, $subtrahend->stringify)} //= bless {
                                                                              minuend    => $minuend,
                                                                              subtrahend => $subtrahend,
                                                                             }, $class;
}

sub inside {
    my ($x) = @_;
    ($x->{minuend}, $x->{subtrahend});
}

#
## Operations
#

#
## (a-b) + (x-y) = (a+x) - (b+y)
#

Class::Multimethods::multimethod add => (__PACKAGE__, __PACKAGE__) => sub {
    my ($x, $y) = @_;
#<<<
    __PACKAGE__->new(
        $x->{minuend}    + $y->{minuend},
        $x->{subtrahend} + $y->{subtrahend}
    );
#>>>
};

Class::Multimethods::multimethod add => (__PACKAGE__, 'Math::Bacovia::Number') => sub {
    my ($x, $y) = @_;
    __PACKAGE__->new($x->{minuend} + $y, $x->{subtrahend});
};

Class::Multimethods::multimethod add => (__PACKAGE__, 'Math::Bacovia::Fraction') => sub {
    my ($x, $y) = @_;
    __PACKAGE__->new($x->{minuend} + $y, $x->{subtrahend});
};

#
## (a-b) - (x-y) = (a+y) - (b+x)
#

Class::Multimethods::multimethod sub => (__PACKAGE__, __PACKAGE__) => sub {
    my ($x, $y) = @_;
#<<<
    __PACKAGE__->new(
        $x->{minuend}    + $y->{subtrahend},
        $x->{subtrahend} + $y->{minuend}
    );
#>>>
};

Class::Multimethods::multimethod sub => (__PACKAGE__, 'Math::Bacovia::Number') => sub {
    my ($x, $y) = @_;
    __PACKAGE__->new($x->{minuend}, $x->{subtrahend} + $y);
};

Class::Multimethods::multimethod sub => (__PACKAGE__, 'Math::Bacovia::Fraction') => sub {
    my ($x, $y) = @_;
    __PACKAGE__->new($x->{minuend}, $x->{subtrahend} + $y);
};

#
## (a-b) * (x-y) = (a*x + b*y) - (b*x + a*y)
#

Class::Multimethods::multimethod mul => (__PACKAGE__, __PACKAGE__) => sub {
    my ($x, $y) = @_;
#<<<
    __PACKAGE__->new(
        $x->{minuend}    * $y->{minuend} + $x->{subtrahend} * $y->{subtrahend},
        $x->{subtrahend} * $y->{minuend} + $x->{minuend}    * $y->{subtrahend}
    );
#>>>
};

Class::Multimethods::multimethod mul => (__PACKAGE__, 'Math::Bacovia::Number') => sub {
    my ($x, $y) = @_;
    __PACKAGE__->new($x->{minuend} * $y, $x->{subtrahend} * $y);
};

Class::Multimethods::multimethod mul => (__PACKAGE__, 'Math::Bacovia::Fraction') => sub {
    my ($x, $y) = @_;
    __PACKAGE__->new($x->{minuend} * $y, $x->{subtrahend} * $y);
};

#
## -(a-b) = b-a
#

sub neg {
    my ($x) = @_;
    $x->{_neg} //= __PACKAGE__->new($x->{subtrahend}, $x->{minuend});
}

#
## Equality
#

Class::Multimethods::multimethod eq => (__PACKAGE__, __PACKAGE__) => sub {
    my ($x, $y) = @_;

         (ref($x->{minuend}) eq ref($y->{minuend}))
      && (ref($x->{subtrahend}) eq ref($y->{subtrahend}))
      && ($x->{minuend}->eq($y->{minuend}))
      && ($x->{subtrahend}->eq($y->{subtrahend}));
};

Class::Multimethods::multimethod eq => (__PACKAGE__, '*') => sub {
    !1;
};

#
## Transformations
#

sub numeric {
    my ($x) = @_;
    $x->{_num} //= $x->{minuend}->numeric - $x->{subtrahend}->numeric;
}

sub pretty {
    my ($x) = @_;

    $x->{_pretty} //= do {
        my $minuend    = $x->{minuend}->pretty();
        my $subtrahend = $x->{subtrahend}->pretty();

        if ($minuend eq '0') {
            "(-$subtrahend)";
        }
        elsif ($subtrahend eq '0') {
            $minuend;
        }
        else {
            "($minuend - $subtrahend)";
        }
    };
}

sub stringify {
    my ($x) = @_;
    $x->{_str} //= "Difference(" . $x->{minuend}->stringify() . ', ' . $x->{subtrahend}->stringify() . ")";
}

#
## Alternatives
#

sub alternatives {
    my ($x, %opt) = @_;

    $x->{_alt} //= do {
        my @a_num = $x->{minuend}->alternatives(%opt);
        my @a_den = $x->{subtrahend}->alternatives(%opt);

        my @alt;
        foreach my $minuend (@a_num) {
            foreach my $subtrahend (@a_den) {

                if (ref($subtrahend) eq 'Math::Bacovia::Number' and $subtrahend->{value} == 0) {
                    push @alt, $minuend;
                }
                elsif (ref($minuend) eq 'Math::Bacovia::Number' and $minuend->{value} == 0) {
                    push @alt, $subtrahend->neg;
                }
                elsif (ref($minuend) eq ref($subtrahend) and $minuend->eq($subtrahend)) {
                    push @alt, $Math::Bacovia::ZERO;
                }
                else {

                    push @alt, __PACKAGE__->new($minuend, $subtrahend);

                    if ($opt{full}) {
                        push @alt, $minuend - $subtrahend;
                    }
                    elsif (    ref($minuend) eq 'Math::Bacovia::Number'
                           and ref($subtrahend) eq 'Math::Bacovia::Number') {
                        push @alt, $minuend - $subtrahend;
                    }
                }
            }
        }

        [List::UtilsBy::XS::uniq_by { $_->stringify } @alt];
    };

    @{$x->{_alt}};
}

1;
