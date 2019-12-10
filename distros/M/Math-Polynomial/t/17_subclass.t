# Copyright (c) 2019 by Martin Becker, Blaubeuren.
# This package is free software; you can distribute it and/or modify it
# under the terms of the Artistic License 2.0 (see LICENSE file).

# Checking features supporting subclassing of Math::Polynomial.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/17_subclass.t'

use strict;
use warnings;
use Test;

BEGIN { plan tests => 10; }

package Math::Polynomial::Univariate;

use strict;
use warnings;
use Math::Polynomial 1.015;

# ----- object definition -----

use constant _OFFSET => Math::Polynomial::_NFIELDS;

# Math::Polynomial::Univariate=ARRAY(...)
# ............... index ...............   # ........ value ........
use constant _F_VARIABLE => _OFFSET;      # (string) the variable
use constant _NFIELDS    => _OFFSET + 1;

# ----- class data -----

BEGIN {
    our @ISA     = (Math::Polynomial::);
    our $VERSION = '0.001';
}

my $global_variable = 'x';

# ----- object methods -----

sub variable {
    my ($this, $variable) = @_;
    if (@_ > 1) {
        if (ref $this) {
            $this->[_F_VARIABLE] = $variable;
        }
        elsif (defined $variable) {
            $global_variable = $variable;
        }
    }
    elsif (ref $this) {
        $variable = $this->[_F_VARIABLE];
    }
    return defined($variable)? $variable: $global_variable;
}

sub string_config {
    my $this = shift;
    return $this->SUPER::string_config(@_) if @_;
    my $config = $this->SUPER::string_config;
    return {
        $config? %{ $config }: (),
        variable => $this->variable,
    };
}

# ----- end of subclass -----

package main;

ok(1);  # modules loaded

my $p = Math::Polynomial::Univariate->monomial(1);
ok($p->isa('Math::Polynomial::Univariate'));
ok($p->variable, 'x');
ok($p->as_string, '(x)');

$p->variable('y');
ok($p->variable, 'y');
ok($p->as_string, '(y)');

$p->string_config({ fold_sign => 1 });
ok($p->variable, 'y');
ok($p->as_string, '(y)');

$p->variable('z');
ok($p->variable, 'z');
ok($p->as_string, '(z)');

__END__
