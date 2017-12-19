package Math::Bacovia::Number;

use 5.014;
use warnings;

use Class::Multimethods qw();
use parent qw(Math::Bacovia);

our $VERSION = $Math::Bacovia::VERSION;

my %cache;

sub new {
    my ($class, $value) = @_;

    if (ref($value) && UNIVERSAL::isa($value, 'Math::Bacovia')) {
        return $value;
    }

    if (ref($value) ne 'Math::AnyNum') {
        $value = 'Math::AnyNum'->new($value);
    }

    $cache{$value->stringify} //= bless {value => $value}, $class;
}

sub inside {
    $_[0]->{value};
}

#
## Operations
#

Class::Multimethods::multimethod add => (__PACKAGE__, __PACKAGE__) => sub {
    my ($x, $y) = @_;
    __PACKAGE__->new($x->{value} + $y->{value});
};

Class::Multimethods::multimethod add => (__PACKAGE__, 'Math::Bacovia::Fraction') => sub {
    my ($x, $y) = @_;
    'Math::Bacovia::Fraction'->new($x)->add($y);
};

Class::Multimethods::multimethod add => (__PACKAGE__, 'Math::Bacovia::Difference') => sub {
    my ($x, $y) = @_;
    'Math::Bacovia::Difference'->new($x)->add($y);
};

Class::Multimethods::multimethod sub => (__PACKAGE__, __PACKAGE__) => sub {
    my ($x, $y) = @_;
    __PACKAGE__->new($x->{value} - $y->{value});
};

#~ Class::Multimethods::multimethod sub => (__PACKAGE__, 'Math::Bacovia::Fraction') => sub {
#~ my ($x, $y) = @_;
#~ 'Math::Bacovia::Fraction'->new($x)->sub($y);
#~ };

Class::Multimethods::multimethod sub => (__PACKAGE__, 'Math::Bacovia::Difference') => sub {
    my ($x, $y) = @_;
    'Math::Bacovia::Difference'->new($x)->sub($y);
};

Class::Multimethods::multimethod mul => (__PACKAGE__, __PACKAGE__) => sub {
    my ($x, $y) = @_;
    __PACKAGE__->new($x->{value} * $y->{value});
};

Class::Multimethods::multimethod mul => (__PACKAGE__, 'Math::Bacovia::Fraction') => sub {
    my ($x, $y) = @_;
    'Math::Bacovia::Fraction'->new($x)->mul($y);
};

Class::Multimethods::multimethod mul => (__PACKAGE__, 'Math::Bacovia::Difference') => sub {
    my ($x, $y) = @_;
    'Math::Bacovia::Difference'->new($x)->mul($y);
};

Class::Multimethods::multimethod div => (__PACKAGE__, __PACKAGE__) => sub {
    my ($x, $y) = @_;
    __PACKAGE__->new($x->{value} / $y->{value});
};

Class::Multimethods::multimethod div => (__PACKAGE__, 'Math::Bacovia::Fraction') => sub {
    my ($x, $y) = @_;
    'Math::Bacovia::Fraction'->new($x)->div($y);
};

#~ Class::Multimethods::multimethod pow => (__PACKAGE__, __PACKAGE__) => sub {
#~ my ($x, $y) = @_;
#~ __PACKAGE__->new($x->{value}**$y->{value});
#~ };

sub inv {
    my ($x) = @_;
    $x->{_inv} //= __PACKAGE__->new($x->{value}->inv);
}

sub neg {
    my ($x) = @_;
    $x->{_neg} //= __PACKAGE__->new($x->{value}->neg);
}

#
## Equality
#

Class::Multimethods::multimethod eq => (__PACKAGE__, __PACKAGE__) => sub {
    $_[0]->{value} == $_[1]->{value};
};

Class::Multimethods::multimethod eq => (__PACKAGE__, '*') => sub {
    !1;
};

#
## Transformations
#

sub numeric {
    $_[0]->{value};
}

sub pretty {
    my ($x) = @_;

    $x->{_pretty} //= do {
        my $str = "$x->{value}";

        if ((index($str, 'i') != -1 and $str ne 'i' and $str ne '-i')
            or index($str, '/') != -1) {
            "($str)";
        }
        else {
            $str;
        }
    };
}

sub stringify {
    my ($x) = @_;
    $x->{_str} //= $x->{value}->stringify;
}

1;
