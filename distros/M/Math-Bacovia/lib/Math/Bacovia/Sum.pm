package Math::Bacovia::Sum;

use 5.014;
use warnings;

use Set::Product::XS qw(product);
use Class::Multimethods qw();
use parent qw(Math::Bacovia);

our $VERSION = $Math::Bacovia::VERSION;

sub new {
    my ($class, @values) = @_;
    Math::Bacovia::_check_type(\$_) for @values;

    my @flat;
    foreach my $value (@values) {
        if (ref($value) eq __PACKAGE__) {
            push @values, @{$value->{values}};
        }
        elsif (ref($value) ne 'Math::Bacovia::Number'
               or $value->{value} != 0) {
            push @flat, $value;
        }
    }

    @flat || do {
        @flat = ($Math::Bacovia::ZERO);
    };

    bless {values => \@flat}, $class;
}

sub inside {
    my ($x) = @_;
    (@{$x->{values}});
}

#
## Operations
#

Class::Multimethods::multimethod add => (__PACKAGE__, __PACKAGE__) => sub {
    my ($x, $y) = @_;
    __PACKAGE__->new(@{$x->{values}}, @{$y->{values}});
};

Class::Multimethods::multimethod add => (__PACKAGE__, 'Math::Bacovia') => sub {
    my ($x, $y) = @_;
    __PACKAGE__->new(@{$x->{values}}, $y);
};

Class::Multimethods::multimethod sub => (__PACKAGE__, __PACKAGE__) => sub {
    my ($x, $y) = @_;
    __PACKAGE__->new(@{$x->{values}}, map { $_->neg } @{$y->{values}});
};

Class::Multimethods::multimethod sub => (__PACKAGE__, 'Math::Bacovia') => sub {
    my ($x, $y) = @_;
    __PACKAGE__->new(@{$x->{values}}, $y->neg);
};

Class::Multimethods::multimethod mul => (__PACKAGE__, 'Math::Bacovia') => sub {
    my ($x, $y) = @_;
    __PACKAGE__->new(map { $_->mul($y) } @{$x->{values}});
};

Class::Multimethods::multimethod div => (__PACKAGE__, 'Math::Bacovia') => sub {
    my ($x, $y) = @_;
    __PACKAGE__->new(map { $_->div($y) } @{$x->{values}});
};

sub neg {
    my ($x) = @_;
    $x->{_neg} //= __PACKAGE__->new(map { $_->neg } @{$x->{values}});
}

#
## Transformations
#

sub numeric {
    my ($x) = @_;
    $x->{_num} //= do {
        my $sum = $Math::Bacovia::ZERO->{value};
        foreach my $value (@{$x->{values}}) {
            $sum += $value->numeric;
        }
        $sum;
    };
}

sub pretty {
    my ($x) = @_;
    $x->{_pretty} //= do {
        my @pretty = map { $_->pretty } @{$x->{values}};
        @pretty ? ('(' . join(' + ', @pretty) . ')') : '0';
    };
}

sub stringify {
    my ($x) = @_;
    $x->{_str} //= 'Sum(' . join(', ', map { $_->stringify } @{$x->{values}}) . ')';
}

#
## Equality
#

Class::Multimethods::multimethod eq => (__PACKAGE__, __PACKAGE__) => sub {
    my ($x, $y) = @_;

    my @p1 = @{$x->{values}};
    my @p2 = @{$y->{values}};

    (@p1 == @p2) || return !1;

    while (@p1 && @p2) {

        my $first  = shift(@p1);
        my $second = shift(@p2);

        (ref($first) eq ref($second) and $first->eq($second))
          || return !1;
    }

    return 1;
};

Class::Multimethods::multimethod eq => (__PACKAGE__, '*') => sub {
    !1;
};

#
## Alternatives
#
sub alternatives {
    my ($x, %opt) = @_;

    $x->{_alt} //= do {
        my @alt;

        product {
            my (@c) = @_;

            my %table = ();
            foreach my $v (@c) {
                if (ref($v) eq __PACKAGE__) {
                    push @c, @{$v->{values}};
                }
                else {
                    push @{$table{ref($v)}}, $v;
                }
            }

            my @partial = ();
            foreach my $group (values(%table)) {
                my $sum = shift(@$group);
                foreach my $v (@{$group}) {
                    $sum += $v;
                }
                if (ref($sum) eq __PACKAGE__) {
                    push @partial, @{$sum->{values}};
                }
                else {
                    push @partial, $sum;
                }
            }

#<<<
            @partial = (
                List::UtilsBy::XS::nsort_by { $Math::Bacovia::HIERARCHY{ref($_)} }
                grep { ref($_) ne 'Math::Bacovia::Number' or $_->{value} != 0 } @partial
            );
#>>>

            my $sum = shift(@partial) // $Math::Bacovia::ZERO;

            foreach my $v (@partial) {
                $sum += $v;
            }

            push @alt, $sum;
        }
        map { [$_->alternatives(%opt)] } @{$x->{values}};

        [List::UtilsBy::XS::uniq_by { $_->stringify } @alt];
    };

    @{$x->{_alt}};
}

1;
