package Math::Bacovia::Exp;

use 5.014;
use warnings;

use Class::Multimethods qw();
use parent qw(Math::Bacovia);

our $VERSION = $Math::Bacovia::VERSION;

sub new {
    my ($class, $value) = @_;
    Math::Bacovia::_check_type(\$value);
    bless {value => $value}, $class;
}

sub get {
    $_[0]->{value};
}

#
## Operations
#

Class::Multimethods::multimethod mul => (__PACKAGE__, __PACKAGE__) => sub {
    my ($x, $y) = @_;
    __PACKAGE__->new($x->{value} + $y->{value});
};

Class::Multimethods::multimethod div => (__PACKAGE__, __PACKAGE__) => sub {
    my ($x, $y) = @_;
    __PACKAGE__->new($x->{value} - $y->{value});
};

#~ Class::Multimethods::multimethod pow => (__PACKAGE__, 'Math::Bacovia') => sub {
#~ my ($x, $y) = @_;
#~ __PACKAGE__->new($x->{value} * $y);
#~ };

sub inv {
    my ($x) = @_;
    $x->{_inv} //= __PACKAGE__->new($x->{value}->neg);
}

#
## Equality
#

Class::Multimethods::multimethod eq => (__PACKAGE__, __PACKAGE__) => sub {
    my ($x, $y) = @_;

    (ref($x->{value}) eq ref($y->{value}))
      && ($x->{value}->eq($y->{value}));
};

Class::Multimethods::multimethod eq => (__PACKAGE__, '*') => sub {
    !1;
};

#
## Transformations
#

sub numeric {
    my ($x) = @_;
    CORE::exp($x->{value}->numeric);
}

sub pretty {
    my ($x) = @_;
    $x->{_pretty} //= "exp(" . $x->{value}->pretty() . ")";
}

sub stringify {
    my ($x) = @_;
    $x->{_str} //= "Exp(" . $x->{value}->stringify() . ")";
}

#
## Alternatives
#
sub alternatives {
    my ($self, %opt) = @_;

    $self->{_alt} //= do {

        my @alt;
        foreach my $o ($self->{value}->alternatives(%opt)) {

            push @alt, __PACKAGE__->new($o);

            # Identity: exp(log(x) * y) = x^y
            if (ref($o) eq 'Math::Bacovia::Product' and @{$o->{values}} == 2) {
                my ($x, $y) = @{$o->{values}};

                if (ref($x) eq 'Math::Bacovia::Log') {
                    push @alt, 'Math::Bacovia::Power'->new($x->{value}, $y);
                }
                elsif (ref($y) eq 'Math::Bacovia::Log') {
                    push @alt, 'Math::Bacovia::Power'->new($y->{value}, $x);
                }
            }

            # Identity: exp(log(x)) = x
            elsif (ref($o) eq 'Math::Bacovia::Log') {
                push @alt, $o->{value};
            }

            if ($opt{full}) {

                # Identity: exp(a + b) = exp(a) * exp(b)
                if (ref($o) eq 'Math::Bacovia::Sum') {
                    push @alt, 'Math::Bacovia::Product'->new(map { __PACKAGE__->new($_) } @{$o->{values}});
                }

                # Identity: exp(a/b) = exp(a)^(1/b)
                #~ if (ref($o) eq 'Math::Bacovia::Fraction') {
                #~ push @alt, (__PACKAGE__->new($o->{num}) ** $o->{den}->inv)->alternatives(%opt);
                #~ }

#<<<
                # Identity: exp(a - b) = exp(a) / exp(b)
                if (ref($o) eq 'Math::Bacovia::Difference') {
                    push @alt, 'Math::Bacovia::Fraction'->new(__PACKAGE__->new($o->{minuend}), __PACKAGE__->new($o->{subtrahend}));
                }
#>>>
            }
        }

        [List::UtilsBy::XS::uniq_by { $_->stringify } @alt];
    };

    @{$self->{_alt}};
}

1;
