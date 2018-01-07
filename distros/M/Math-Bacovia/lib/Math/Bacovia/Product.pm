package Math::Bacovia::Product;

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
               or $value->{value} != 1) {
            push @flat, $value;
        }
    }

    @flat || do {
        @flat = ($Math::Bacovia::ONE);
    };

    bless {values => \@flat}, $class;
}

sub get {
    my ($x) = @_;
    (@{$x->{values}});
}

#
## Operations
#

Class::Multimethods::multimethod mul => (__PACKAGE__, __PACKAGE__) => sub {
    my ($x, $y) = @_;
    __PACKAGE__->new(@{$x->{values}}, @{$y->{values}});
};

Class::Multimethods::multimethod mul => (__PACKAGE__, 'Math::Bacovia') => sub {
    my ($x, $y) = @_;
    __PACKAGE__->new(@{$x->{values}}, $y);
};

Class::Multimethods::multimethod div => (__PACKAGE__, __PACKAGE__) => sub {
    my ($x, $y) = @_;
    __PACKAGE__->new(@{$x->{values}}, map { $_->inv } @{$y->{values}});
};

Class::Multimethods::multimethod div => (__PACKAGE__, 'Math::Bacovia') => sub {
    my ($x, $y) = @_;
    __PACKAGE__->new(@{$x->{values}}, $y->inv);
};

#~ Class::Multimethods::multimethod pow => (__PACKAGE__, 'Math::Bacovia') => sub {
#~ my ($x, $y) = @_;
#~ __PACKAGE__->new(map { $_**$y } @{$x->{values}});
#~ };

sub inv {
    my ($x) = @_;
    $x->{_inv} //= __PACKAGE__->new(map { $_->inv } @{$x->{values}});
}

#
## Transformations
#

sub numeric {
    my ($x) = @_;

    my $prod = $Math::Bacovia::ONE->{value};

    foreach my $value (@{$x->{values}}) {
        $prod *= $value->numeric;
    }

    $prod;
}

sub pretty {
    my ($x) = @_;
    $x->{_pretty} //= do {
        my @pretty = map { $_->pretty } @{$x->{values}};
        @pretty ? ('(' . join(' * ', @pretty) . ')') : '1';
    };
}

sub stringify {
    my ($x) = @_;
    $x->{_str} //= 'Product(' . join(', ', map { $_->stringify } @{$x->{values}}) . ')';
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

                my $prod = shift(@$group);
                foreach my $v (@{$group}) {
                    $prod *= $v;
                }

                if (ref($prod) eq __PACKAGE__) {
                    push @partial, @{$prod->{values}};
                }
                else {
                    push @partial, $prod;
                }
            }

            foreach my $v (@partial) {
                if (ref($v) eq 'Math::Bacovia::Number' and $v->{value} == 0) {
                    push @alt, $Math::Bacovia::ZERO;
                    return;
                }
            }

#<<<
            @partial = (
                List::UtilsBy::XS::nsort_by { $Math::Bacovia::HIERARCHY{ref($_)} }
                grep { ref($_) ne 'Math::Bacovia::Number' or $_->{value} != 1 } @partial
            );
#>>>

            my $prod = shift(@partial) // $Math::Bacovia::ONE;

            foreach my $v (@partial) {
                $prod *= $v;
            }

            push @alt, $prod;
        }
        map { [$_->alternatives(%opt)] } @{$x->{values}};

        [List::UtilsBy::XS::uniq_by { $_->stringify } @alt];
    };

    @{$x->{_alt}};
}

1;
