package Math::Bacovia::Fraction;

use 5.014;
use warnings;

use Class::Multimethods qw();
use parent qw(Math::Bacovia);

our $VERSION = $Math::Bacovia::VERSION;

my %cache;

sub new {
    my ($class, $numerator, $denominator) = @_;

    if (defined($numerator)) {
        Math::Bacovia::_check_type(\$numerator);
    }
    else {
        $numerator = $Math::Bacovia::ZERO;
    }

    if (defined($denominator)) {
        Math::Bacovia::_check_type(\$denominator);
    }
    else {
        $denominator = $Math::Bacovia::ONE;
    }

    $cache{join(';', $numerator->stringify, $denominator->stringify)} //= bless {
                                                                                 num => $numerator,
                                                                                 den => $denominator,
                                                                                }, $class;
}

sub inside {
    my ($x) = @_;
    ($x->{num}, $x->{den});
}

#
## Operations
#

Class::Multimethods::multimethod add => (__PACKAGE__, __PACKAGE__) => sub {
    my ($x, $y) = @_;
#<<<
    __PACKAGE__->new(
        $x->{num} * $y->{den} + $y->{num} * $x->{den},
        $x->{den} * $y->{den}
    );
#>>>
};

Class::Multimethods::multimethod add => (__PACKAGE__, 'Math::Bacovia::Number') => sub {
    my ($x, $y) = @_;
#<<<
    __PACKAGE__->new(
        $x->{num} + $x->{den} * $y,
        $x->{den}
    );
#>>>
};

Class::Multimethods::multimethod add => (__PACKAGE__, 'Math::Bacovia::Difference') => sub {
    my ($x, $y) = @_;
#<<<
    __PACKAGE__->new(
        $x->{num} + $x->{den} * $y,
        $x->{den}
    );
#>>>
};

Class::Multimethods::multimethod sub => (__PACKAGE__, __PACKAGE__) => sub {
    my ($x, $y) = @_;
#<<<
    __PACKAGE__->new(
        $x->{num} * $y->{den} - $y->{num} * $x->{den},
        $x->{den} * $y->{den}
    );
#>>>
};

Class::Multimethods::multimethod sub => (__PACKAGE__, 'Math::Bacovia::Number') => sub {
    my ($x, $y) = @_;
#<<<
    __PACKAGE__->new(
        $x->{num} - $x->{den} * $y,
        $x->{den}
    );
#>>>
};

Class::Multimethods::multimethod sub => (__PACKAGE__, 'Math::Bacovia::Difference') => sub {
    my ($x, $y) = @_;
#<<<
    __PACKAGE__->new(
        $x->{num} - $x->{den} * $y,
        $x->{den}
    );
#>>>
};

Class::Multimethods::multimethod mul => (__PACKAGE__, __PACKAGE__) => sub {
    my ($x, $y) = @_;
    __PACKAGE__->new($x->{num} * $y->{num}, $x->{den} * $y->{den});
};

Class::Multimethods::multimethod mul => (__PACKAGE__, 'Math::Bacovia::Number') => sub {
    my ($x, $y) = @_;
    __PACKAGE__->new($x->{num} * $y, $x->{den});
};

Class::Multimethods::multimethod mul => (__PACKAGE__, 'Math::Bacovia::Difference') => sub {
    my ($x, $y) = @_;
    __PACKAGE__->new($x->{num} * $y, $x->{den});
};

Class::Multimethods::multimethod div => (__PACKAGE__, __PACKAGE__) => sub {
    my ($x, $y) = @_;
    __PACKAGE__->new($x->{num} * $y->{den}, $x->{den} * $y->{num});
};

Class::Multimethods::multimethod div => (__PACKAGE__, 'Math::Bacovia::Number') => sub {
    my ($x, $y) = @_;
    __PACKAGE__->new($x->{num}, $x->{den} * $y);
};

Class::Multimethods::multimethod div => (__PACKAGE__, 'Math::Bacovia::Difference') => sub {
    my ($x, $y) = @_;
    __PACKAGE__->new($x->{num}, $x->{den} * $y);
};

sub inv {
    my ($x) = @_;
    $x->{_inv} //= __PACKAGE__->new($x->{den}, $x->{num});
}

#
## Equality
#

Class::Multimethods::multimethod eq => (__PACKAGE__, __PACKAGE__) => sub {
    my ($x, $y) = @_;

         (ref($x->{num}) eq ref($y->{num}))
      && (ref($x->{den}) eq ref($y->{den}))
      && ($x->{num}->eq($y->{num}))
      && ($x->{den}->eq($y->{den}));
};

Class::Multimethods::multimethod eq => (__PACKAGE__, '*') => sub {
    !1;
};

#
## Transformations
#

sub numeric {
    my ($x) = @_;
    $x->{_num} //= $x->{num}->numeric / $x->{den}->numeric;
}

sub pretty {
    my ($x) = @_;

    $x->{_pretty} //= do {
        my $num = $x->{num}->pretty();
        my $den = $x->{den}->pretty();

        if ($den eq '1') {
            $num;
        }
        else {
            "($num/$den)";
        }
    };
}

sub stringify {
    my ($x) = @_;
    $x->{_str} //= "Fraction(" . $x->{num}->stringify() . ', ' . $x->{den}->stringify() . ")";
}

#
## Alternatives
#

sub alternatives {
    my ($x, %opt) = @_;

    $x->{_alt} //= do {
        my @a_num = $x->{num}->alternatives(%opt);
        my @a_den = $x->{den}->alternatives(%opt);

        my @alt;
        foreach my $num (@a_num) {
            foreach my $den (@a_den) {

                # Identity: x/1 = x
                if (ref($den) eq 'Math::Bacovia::Number' and $den->{value} == 1) {
                    push @alt, $num;
                }

                # Identity: x/x = 1
                if (ref($num) eq ref($den) and $num->eq($den)) {
                    push @alt, $Math::Bacovia::ONE;
                }

                push @alt, __PACKAGE__->new($num, $den);

                # Identity: 1/x = inv(x)
                if (ref($num) eq 'Math::Bacovia::Number' and $num->{value} == 1) {
                    push @alt, $den->inv;
                }

                # Identity: a^x / b^x = (a/b)^x
                #~ if (    ref($num) eq 'Math::Bacovia::Power'
                #~ and ref($den) eq 'Math::Bacovia::Power'
                #~ and ref($num->{power}) eq ref($den->{power})
                #~ and $num->{power}->eq($den->{power})) {
                #~ push @alt, 'Math::Bacovia::Power'->new($num->{base} / $den->{base}, $num->{power});
                #~ }

                # Identity: a^x / a = a^(x-1)
                if (    ref($num) eq 'Math::Bacovia::Power'
                    and ref($num->{base}) eq ref($den)
                    and $num->{base}->eq($den)) {
                    push @alt, 'Math::Bacovia::Power'->new($num->{base}, $num->{power} - $Math::Bacovia::ONE);
                }

                if ($opt{full}) {
                    push @alt, $den->inv * $num;
                    push @alt, $num * $den->inv;
                    push @alt, $num / $den;

                    # Identity: (a + b) / c = a/c + b/c
                    if (ref($num) eq 'Math::Bacovia::Sum') {
                        push @alt, 'Math::Bacovia::Sum'->new(map { $_ / $den } @{$num->{values}});
                    }

                    # Identity: (a * b) / c = (a * b * 1/c)
                    if (ref($num) eq 'Math::Bacovia::Product') {
                        push @alt, $num * $den->inv;
                    }
                }
                elsif (    ref($num) eq 'Math::Bacovia::Number'
                       and ref($den) eq 'Math::Bacovia::Number') {
                    push @alt, $num / $den;
                }
            }
        }

        [List::UtilsBy::XS::uniq_by { $_->stringify } @alt];
    };

    @{$x->{_alt}};
}

1;
