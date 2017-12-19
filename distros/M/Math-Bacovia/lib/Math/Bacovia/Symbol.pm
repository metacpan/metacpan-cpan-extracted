package Math::Bacovia::Symbol;

use 5.014;
use warnings;

use Class::Multimethods qw();
use parent qw(Math::Bacovia);

our $VERSION = $Math::Bacovia::VERSION;

sub new {
    my ($class, $name, $value) = @_;

    if (defined($value)) {
        Math::Bacovia::_check_type(\$value);
    }

    bless {
           name  => "$name",
           value => $value,
          }, $class;
}

sub inside {
    my ($x) = @_;
    defined($x->{value})
      ? ($x->{name}, $x->{value})
      : $x->{name};
}

#
## Equality
#

Class::Multimethods::multimethod eq => (__PACKAGE__, __PACKAGE__) => sub {
    my ($x, $y) = @_;
    $x->{name} eq $y->{name};
};

Class::Multimethods::multimethod eq => (__PACKAGE__, '*') => sub {
    !1;
};

#
## Transformations
#

sub numeric {
    my ($x) = @_;
    my $v = $x->{value};
    defined($v) ? $v->numeric : undef;
}

sub pretty {
    $_[0]->{name};
}

sub stringify {
    my ($x) = @_;

    $x->{_str} //= do {
        defined($x->{value})
          ? ("Symbol(\"\Q$x->{name}\E\", " . $x->{value}->stringify() . ")")
          : ("Symbol(\"\Q$x->{name}\E\")");
    };
}

1;
