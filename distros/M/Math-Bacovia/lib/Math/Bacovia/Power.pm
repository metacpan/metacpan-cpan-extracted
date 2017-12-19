package Math::Bacovia::Power;

use 5.014;
use warnings;

use Class::Multimethods qw();
use parent qw(Math::Bacovia);

our $VERSION = $Math::Bacovia::VERSION;

my %cache;

sub new {
    my ($class, $base, $power) = @_;

    Math::Bacovia::_check_type(\$base);

    if (defined($power)) {
        Math::Bacovia::_check_type(\$power);
    }
    else {
        $power = $Math::Bacovia::ONE;
    }

    $cache{join(';', $base->stringify, $power->stringify)} //= bless {
                                                                      base  => $base,
                                                                      power => $power,
                                                                     }, $class;
}

sub inside {
    my ($x) = @_;
    ($x->{base}, $x->{power});
}

#
## Operations
#

#~ Class::Multimethods::multimethod pow => (__PACKAGE__, 'Math::Bacovia') => sub {
#~ my ($x, $y) = @_;
#~ __PACKAGE__->new($x->{base}, $x->{power} * $y);
#~ };

sub inv {
    my ($x) = @_;
    $x->{_inv} //= __PACKAGE__->new($x->{base}, $x->{power}->neg);
}

Class::Multimethods::multimethod mul => (__PACKAGE__, __PACKAGE__) => sub {
    my ($x, $y) = @_;

    if (ref($x->{base}) eq ref($y->{base})
        and $x->{base}->eq($y->{base})) {
        __PACKAGE__->new($x->{base}, $x->{power} + $y->{power});
    }
    else {
        'Math::Bacovia::Product'->new($x, $y);
    }
};

Class::Multimethods::multimethod div => (__PACKAGE__, __PACKAGE__) => sub {
    my ($x, $y) = @_;

    if (ref($x->{base}) eq ref($y->{base})
        and $x->{base}->eq($y->{base})) {
        __PACKAGE__->new($x->{base}, $x->{power} - $y->{power});
    }
    else {
        'Math::Bacovia::Fraction'->new($x, $y);
    }
};

#
## Equality
#

Class::Multimethods::multimethod eq => (__PACKAGE__, __PACKAGE__) => sub {
    my ($x, $y) = @_;

         (ref($x->{base}) eq ref($y->{base}))
      && (ref($x->{power}) eq ref($y->{power}))
      && ($x->{base}->eq($y->{base}))
      && ($x->{power}->eq($y->{power}));
};

Class::Multimethods::multimethod eq => (__PACKAGE__, '*') => sub {
    !1;
};

#
## Transformations
#

sub numeric {
    my ($x) = @_;
    $x->{_num} //= ($x->{base}->numeric)**($x->{power}->numeric);
}

sub pretty {
    my ($x) = @_;

    $x->{_pretty} //= do {
        my $base = $x->{base}->pretty();
        my $pow  = $x->{power}->pretty();

        if (substr($base, 0, 1) eq '-'
            or ref($x->{base}) eq __PACKAGE__) {
            "($base)^$pow";
        }
        else {
            "$base^$pow";
        }
      }
}

sub stringify {
    my ($x) = @_;
    $x->{_str} //= "Power(" . $x->{base}->stringify() . ', ' . $x->{power}->stringify() . ")";
}

#
## Alternatives
#
sub alternatives {
    my ($self, %opt) = @_;

    $self->{_alt} //= do {
        my @a1 = $self->{base}->alternatives(%opt);
        my @a2 = $self->{power}->alternatives(%opt);

        my @alt;

        foreach my $x (@a1) {
            foreach my $y (@a2) {

                push @alt, $x**$y;

                if ($opt{full}) {
                    push @alt, __PACKAGE__->new($x, $y);
                }

                if ($opt{full} or $opt{log}) {
                    push @alt, 'Math::Bacovia::Exp'->new('Math::Bacovia::Log'->new($x) * $y);
                }

                # Identity: x^0 = 1
                if (ref($y) eq 'Math::Bacovia::Number' and $y->{value} == 0) {
                    push @alt, $Math::Bacovia::ONE;
                }

                # Identity: 1^x = 1
                if (ref($x) eq 'Math::Bacovia::Number' and $x->{value} == 1) {
                    push @alt, $x;
                }

                # Identity: x^1 = x
                if (ref($y) eq 'Math::Bacovia::Number' and $y->{value} == 1) {
                    push @alt, $x;
                }

                if (    ref($x) eq 'Math::Bacovia::Number'
                    and ref($y) eq 'Math::Bacovia::Number') {

                    # Integer or rational exponentation
                    if (ref(${$y->{value}}) eq 'Math::GMPz') {

                        my $ref_x = ref(${$x->{value}});

                        if ($ref_x eq 'Math::GMPz' or $ref_x eq 'Math::GMPq') {
                            push @alt, 'Math::Bacovia::Number'->new($x->{value}**$y->{value});
                        }
                    }
                }

                # Identity: (a/b)^x = a^x / b^x
                #~ if (ref($x) eq 'Math::Bacovia::Fraction') {
                #~ push @alt, $x->{num}**$y / $x->{den}**$y;
                #~ }

                # Identity: x^2 = x*x
                #~ if ($y == 2) {
                #~     push @alt, $x * $x;
                #~ }

                # Identity: x^log(y) = y^log(x)
                if (ref($y) eq 'Math::Bacovia::Log') {
                    push @alt, $y->{value}**('Math::Bacovia::Log'->new($x));
                }

                # Identity: exp(x)^log(y) = y^x
                if (    ref($x) eq 'Math::Bacovia::Exp'
                    and ref($y) eq 'Math::Bacovia::Exp') {
                    push @alt, ($y->{value}**$x->{value});
                }

                # Identity: exp(x)^y = exp(y*x)
                #~ if (ref($x) eq 'Math::Bacovia::Exp') {
                #~ push @alt, 'Math::Bacovia::Exp'->new($x->{value} * $y);
                #~ }

                # Identity: x^(y/log(x)) = exp(y)
                if (    ref($y) eq 'Math::Bacovia::Fraction'
                    and ref($y->{den}) eq 'Math::Bacovia::Log'
                    and ref($x) eq ref($y->{den}{value})
                    and $x->eq($y->{den}{value})) {
                    if (ref($y->{num}) eq 'Math::Bacovia::Log') {
                        push @alt, $y->{num}{value};
                    }
                    else {
                        push @alt, 'Math::Bacovia::Exp'->new($y->{num})->alternatives(%opt);
                    }
                }
            }
        }

        [List::UtilsBy::XS::uniq_by { $_->stringify } @alt];
    };

    @{$self->{_alt}};
}

1;
