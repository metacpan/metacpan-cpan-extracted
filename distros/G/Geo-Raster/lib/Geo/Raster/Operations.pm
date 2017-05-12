## @class Geo::Raster::Operations
# @brief Adds operations into Geo::Raster and overloads them to operators.
# @note Many methods may convert an integer raster into a floating
# point raster if the operation requires.
# @note All operations, which involve more than one raster, require
# that the rasters are overlayable.
package Geo::Raster;

use strict;
use overload (
	      'fallback' => undef,
              # not having "" overloaded makes print "$raster" to print "1"
	      '""'       => 'as_string', 
	      'bool'     => 'bool',
              '='        => 'shallow_copy',
	      'neg'      => 'neg',
	      '+'        => 'plus',
	      '-'        => 'minus',	      
	      '*'        => 'times',
	      '/'        => 'over',
	      '%'        => 'modulo',
	      '**'       => 'power',
	      '+='       => 'add',
	      '-='       => 'subtract',
	      '*='       => 'multiply_by',
	      '/='       => 'divide_by',
	      '%='       => 'modulus_with',
	      '**='      => 'to_power_of',
	      '<'        => 'lt',
	      '>'        => 'gt',
	      '<='       => 'le',
	      '>='       => 'ge',
	      '=='       => 'eq',
	      '!='       => 'ne',
	      '<=>'      => 'cmp',
	      'atan2'    => 'atan2',
	      'cos'      => 'cos',
	      'sin'      => 'sin',
	      'exp'      => 'exp',
	      'abs'      => 'abs',
	      'log'      => 'log',
	      'sqrt'     => 'sqrt',
	      );
use Scalar::Util 'blessed';

## @ignore
sub as_string {
    my $self = shift;
    return $self;
}

## @ignore
sub bool {
    return 1;
}

## @ignore
sub shallow_copy {
    my $self = shift;
    return $self;
}

## @method Geo::Raster neg()
#
# @brief Unary minus. Multiplies this raster with -1.
#
# @return A negated (multiplied by -1) raster.
sub neg {
    my $self = shift;
    my $copy = Geo::Raster->new($self);
    ral_grid_mult_integer($copy->{GRID}, -1);
    return $copy;
}

## @ignore
sub _typeconversion {
    my($self,$other) = @_;
    my $type = ral_grid_get_datatype($self->{GRID});
    if (ref($other)) {
	if (blessed($other) and $other->isa('Geo::Raster')) {
	    return $Geo::Raster::REAL_GRID if 
		ral_grid_get_datatype($other->{GRID}) == $Geo::Raster::REAL_GRID or 
		$type == $Geo::Raster::REAL_GRID;
	    return $Geo::Raster::INTEGER_GRID;
	} else {
	    croak "$other is not a grid\n";
	}
    } else {
	# perlfaq4: is scalar an integer ?
	return $type if $other =~ /^-?\d+$/;
	
	# perlfaq4: is scalar a C float ?
	if ($other =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/) {
	    return $Geo::Raster::REAL_GRID if $type == $Geo::Raster::INTEGER_GRID;
	    return $type;
	}
	croak "$other is not numeric\n";
    }
}


## @method Geo::Raster plus($value)
#
# @brief Adds a number globally to the raster.
#
# Example:
# @code
# $b = $a + 3.14159;
# @endcode
# is the same as
# @code
# $b = $a->plus(3.14159); 
# @endcode
#
# @param[in] value An integer or a floating point number to add to the
# cell values of this raster.
# @return the resulting raster.

## @method Geo::Raster plus(Geo::Raster second)
#
# @brief Adds a raster to this raster.
#
# Example:
# @code
# $c = $a + $b;
# @endcode
# is the same as
# @code
# $c = $a->plus($b); 
# @endcode
#
# @param[in] second A raster.
# @return the resulting raster.
sub plus {
    my($self, $second) = @_;
    my $datatype = $self->_typeconversion($second);
    my $copy = Geo::Raster->new(datatype=>$datatype, copy=>$self);
    if (ref($second)) {
	ral_grid_add_grid($copy->{GRID}, $second->{GRID});
    } else {
	my $dt = ral_grid_get_datatype($copy->{GRID});
	if ($dt == $Geo::Raster::INTEGER_GRID and $second =~ /^-?\d+$/) {
	    ral_grid_add_integer($copy->{GRID}, $second);
	} else {
	    ral_grid_add_real($copy->{GRID}, $second);
	}
    }
    return $copy;
}

## @method Geo::Raster minus($value, $reversed)
#
# @brief Subtracts a value globally from this raster.
#
# Example:
# @code
# $b = $a - 3.14159;
# @endcode
# is the same as
# @code
# $b = -1*(3.14159 - $a);
# @endcode
#
# @param[in] value A value to subtract 
# @param[in] reversed (optional) Whether to perform value - raster
# computation instead of raster - value. When operator '-' is used,
# this value is automatically set by Perl when appropriate.
# @return the resulting raster.

## @method Geo::Raster minus(Geo::Raster second, $reversed)
#
# @brief Subtracts a raster from this raster.
#
# Example:
# @code
# $c = $b - $a;
# @endcode
# is the same as
# @code
# $c = $a->minus($b, 1); 
# @endcode
#
# @param[in] second A raster to be subtracted.
# @param[in] reversed (optional) Whether to perform value - raster
# computation instead of raster - value. When operator '-' is used,
# this value is automatically set by Perl when appropriate.
# @return the resulting raster.
sub minus {
    my($self, $second, $reversed) = @_;
    my $datatype = $self->_typeconversion($second);
    my $copy = Geo::Raster->new(datatype=>$datatype, copy=>$self);
    if (ref($second)) {
	($copy, $second) = ($second, $copy) if $reversed;
	ral_grid_sub_grid($copy->{GRID}, $second->{GRID});
    } else {
	if ($reversed) {
	    ral_grid_mult_integer($copy->{GRID}, -1);
	} else {
	    $second *= -1;
	}
	
	if (ral_grid_get_datatype($copy->{GRID}) == $Geo::Raster::INTEGER_GRID and $second =~ /^-?\d+$/) {
	    # Second parameter is an integer.
	    ral_grid_add_integer($copy->{GRID}, $second);
	} else {
	    # Second parameter is a real.
	    ral_grid_add_real($copy->{GRID}, $second);
	}
    }
    return $copy;
}

## @method Geo::Raster times($value)
#
# @brief Multiplies the cells of this raster with a value.
#
# Example:
# @code
# $b = $a * 3.14159;
# @endcode
# is the same as
# @code
# $b = $a->times(3.14159);
# @endcode
#
# @param[in] value The multiplier.
# @return a new raster.

## @method Geo::Raster times(Geo::Raster second)
#
# @brief Multiplies the cell values of this raster with the cell values of another raster.
#
# Example:
# @code
# $c = $a * $b;
# @endcode
# is the same as
# @code
# $c = $a->times($b); 
# @endcode
#
# The effect of raster multiplication is
# @code
# for all cells: c[cell] = a[cell]*b[cell]
# @endcode
#
# @param[in] second The multiplier raster.
# @return a new raster.
sub times {
    my($self, $second) = @_;
    my $datatype = $self->_typeconversion($second);
    my $copy = Geo::Raster->new(datatype=>$datatype, copy=>$self);
    if (ref($second)) {
	ral_grid_mult_grid($copy->{GRID}, $second->{GRID});
    } else {
	if (ral_grid_get_datatype($copy->{GRID}) == $Geo::Raster::INTEGER_GRID and $second =~ /^-?\d+$/) {
	    ral_grid_mult_integer($copy->{GRID},$second);
	} else {
	    ral_grid_mult_real($copy->{GRID},$second);
	}
    }
    return $copy;
}

## @method Geo::Raster over($value, $reversed)
#
# @brief Divides the cell values of this raster with a value.
#
# Example:
# @code
# $b = $a / 3.14159;
# @endcode
# is the same as
# @code
# $b = 1/(3.14159 / $a);
# @endcode
#
# @param[in] value The divisor.
# @param[in] reversed (optional) Whether to perform value / raster
# computation instead of raster / value. When operator '/' is used,
# this value is automatically set by Perl when appropriate.
# @return the resulting raster.

## @method Geo::Raster over(Geo::Raster second, $reversed)
#
# @brief Divides this raster with another raster.
#
# Example:
# @code
# $c = $a / $b;
# @endcode
# is the same as
# @code
# $c = $a->over($b); 
# @endcode
# The effect of raster division is
# @code
# for all cells: c[cell] = a[cell]/b[cell]
# @endcode
#
# @param[in] second A raster
# @param[in] reversed (optional) Whether to perform value / raster
# computation instead of raster / value. When operator '/' is used,
# this value is automatically set by Perl when appropriate.
# @return the resulting raster.
sub over {
    my($self, $second, $reversed) = @_;
    my $copy = new Geo::Raster datatype=>$Geo::Raster::REAL_GRID, copy=>$self;
    if (ref($second)) {
	($copy, $second) = ($second, $copy) if $reversed;
	ral_grid_div_grid($copy->{GRID}, $second->{GRID});
    } else {
	if ($reversed) {
	    if (ral_grid_get_datatype($copy->{GRID}) == $Geo::Raster::INTEGER_GRID and $second =~ /^-?\d+$/) {
		ral_integer_div_grid($second, $copy->{GRID});
	    } else {
		ral_real_div_grid($second, $copy->{GRID});
	    }
	} else {
	    if (ral_grid_get_datatype($copy->{GRID}) == $Geo::Raster::INTEGER_GRID and $second =~ /^-?\d+$/) {
		ral_grid_div_integer($copy->{GRID}, $second);
	    } else {
		ral_grid_div_real($copy->{GRID}, $second);
	    }
	}
    }
    return $copy;
}

## @ignore
sub over2 {
    my($self, $second, $reversed) = @_;
    my $copy;
    if($reversed) {
        $copy = new Geo::Raster datatype=>$Geo::Raster::REAL_GRID, copy=>$second;
    } else {
        $copy = new Geo::Raster datatype=>$Geo::Raster::REAL_GRID, copy=>$self;
    }
    
    if (ref($second)) {
	# ($copy, $second) = ($second, $copy) if $reversed;
	if($reversed) {
	    ral_grid_div_grid($copy->{GRID}, $self->{GRID});
	} els {
	     ral_grid_div_grid($copy->{GRID}, $second->{GRID});
	}
    } else {
	if ($reversed) {
	    if (ral_grid_get_datatype($copy->{GRID}) == $Geo::Raster::INTEGER_GRID and $second =~ /^-?\d+$/) {
		ral_integer_div_grid($second, $copy->{GRID});
	    } else {
		ral_real_div_grid($second, $copy->{GRID});
	    }
	} else {
	    if (ral_grid_get_datatype($copy->{GRID}) == $Geo::Raster::INTEGER_GRID and $second =~ /^-?\d+$/) {
		ral_grid_div_integer($copy->{GRID}, $second);
	    } else {
		ral_grid_div_real($copy->{GRID}, $second);
	    }
	}
    }
    return $copy;
}

## @method Geo::Raster modulo($value, $reversed)
#
# @brief Computes the modulus (remainder of division, Perl operator %)
# of this raster and an integer number.
#
# Example:
# @code
# $b = $a % 3;
# @endcode
# is the same as
# @code
# $b = $a->modulo(3);
# @endcode
#
# @param[in] value An integer number.
# @param[in] reversed (optional) Whether to perform value % raster
# computation instead of raster % value. When operator '%' is used,
# this value is automatically set by Perl when appropriate.
# @note This raster must be an integer raster.
# @return the resulting raster.

## @method Geo::Raster modulo(Geo::Raster second, $reversed)
#
# @brief Computes the modulus (remainder of division, Perl operator %)
# of this raster and an integer raster.
#
# Example:
# @code
# $c = $a % $b;
# @endcode
# is the same as
# @code
# $c = $a->modulo($b);
# @endcode
#
# @param[in] second An integer raster.
# @param[in] reversed (optional) Whether to perform second % raster
# computation instead of raster % second. When operator '%' is used,
# this value is automatically set by Perl when appropriate.
# @note This raster must be an integer raster.
# @return the resulting raster.
sub modulo {
    my($self, $second, $reversed) = @_;
    my $copy = new Geo::Raster($self);
    if (ref($second)) {
	($copy, $second) = ($second, $copy) if $reversed;
	ral_grid_modulus_grid($copy->{GRID}, $second->{GRID});
    } else {
	if ($reversed) {
	    ral_integer_modulus_grid($second, $copy->{GRID});
	} else {
	    ral_grid_modulus_integer($copy->{GRID}, $second);
	}
    }
    return $copy;
}

## @method Geo::Raster power($exponent, $reversed)
#
# @brief Computes the power (Perl operator **) of this raster and an
# exponent.
#
# Example:
# @code
# $b = $a ** 3.14159;
# @endcode
# is the same as
# @code
# $b = $a->power(3.14159);
# @endcode
#
# @param[in] exponent A number.
# @param[in] reversed (optional) Whether to perform exponent ** raster
# computation instead of raster ** exponent. When operator '**' is used,
# this value is automatically set by Perl when appropriate.
# @return the resulting raster.

## @method Geo::Raster power(Geo::Raster exponent, $reversed)
#
# @brief Computes the power (Perl operator **) of this raster an
# exponent raster.
#
# Example:
# @code
# $c = $a ** $b;
# @endcode
# is the same as
# @code
# $c = $a->power($b);
# @endcode
#
# @param[in] exponent A raster.
# @param[in] reversed (optional) Whether to perform exponent ** raster
# computation instead of raster ** exponent. When operator '**' is used,
# this value is automatically set by Perl when appropriate.
# @return the resulting raster.
sub power {
    my($self, $second, $reversed) = @_;
    my $datatype = $self->_typeconversion($second);
    return unless defined($datatype);
    my $copy = Geo::Raster->new(datatype=>$datatype, copy=>$self);
    if (ref($second)) {
	($copy, $second) = ($second, $copy) if $reversed;
	ral_grid_power_grid($copy->{GRID}, $second->{GRID});
    } else {
	if ($reversed) {
	    ral_realpower_grid($second, $copy->{GRID});
	} else {
	    ral_grid_power_real($copy->{GRID}, $second);
	}
    }
    return $copy;
}

## @method add($value)
#
# @brief Adds a number in-place to the cell values of this raster.
#
# Example:
# @code
# $a += 3.14159;
# @endcode
# is the same as
# @code
# $a->add(3.14159); 
# @endcode
#
# @param[in] value The number to add.

## @method Geo::Raster add(Geo::Raster second)
#
# @brief Adds another raster to this raster.
# 
# Example of addition
# @code
# $a += $b;
# @endcode
# is the same as
# @code
# $a->add($b); 
# @endcode
#
# @param[in] second A raster to add.
sub add {
    my($self, $second) = @_;
    my $datatype = $self->_typeconversion($second);
    return unless defined($datatype);
    $self->_new_grid(ral_grid_create_copy($self->{GRID}, $datatype)) 
    	if $datatype != ral_grid_get_datatype($self->{GRID});
    if (ref($second)) {
	ral_grid_add_grid($self->{GRID}, $second->{GRID});
    } else {
	if (ral_grid_get_datatype($self->{GRID}) == $Geo::Raster::INTEGER_GRID and $second =~ /^-?\d+$/) {
	    ral_grid_add_integer($self->{GRID}, $second);
	} else {
	    ral_grid_add_real($self->{GRID}, $second);
	}
    }
    return $self;
}

## @method Geo::Raster subtract($value)
#
# @brief Subtracts a number from the cell values.
#
# Example of subtraction
# @code
# $a -= 3.14159;
# @endcode
# is the same as
# @code
# $a->subtract(3.14159); 
# @endcode
#
# @param[in] value A number that is subtracted from all cells of this raster.

## @method Geo::Raster subtract(Geo::Raster second)
#
# @brief Subtracts from the cell value the respective cell values of the given raster.
#
# Example of subtraction
# @code
# $a -= $b;
# @endcode
# is the same as
# @code
# $a->subtract($b); 
# @endcode
#
# @param[in] second A raster, whose cell values are to be subtracted
# from the cell values of this raster.
sub subtract {
    my($self, $second) = @_;
    my $datatype = $self->_typeconversion($second);
    return unless defined($datatype);
    $self->_new_grid(ral_grid_create_copy($self->{GRID}, $datatype)) if $datatype != ral_grid_get_datatype($self->{GRID});
    if (ref($second)) {
	ral_grid_sub_grid($self->{GRID}, $second->{GRID});
    } else {
	if (ral_grid_get_datatype($self->{GRID}) == $Geo::Raster::INTEGER_GRID and $second =~ /^-?\d+$/) {
	    ral_grid_add_integer($self->{GRID}, -$second);
	} else {
	    ral_grid_add_real($self->{GRID}, -$second);
	}
    }
    return $self;
}

## @method Geo::Raster multiply_by($value)
#
# @brief Multiplies the cell values of this raster with the given number.
#
# Example:
# @code
# $a *= 3.14159;
# @endcode
# is the same as
# @code
# $a->multiply_by(3.14159); 
# @endcode
#
# @param[in] value The multiplier.

## @method Geo::Raster multiply_by(Geo::Raster second)
#
# @brief Multiplies the cell values of this raster with the respective
# cell values of the given raster.
#
# Example of multiplication
# @code
# $a *= $b;
# @endcode
# is the same as
# @code
# $a->multiply_by($b); 
# @endcode
#
# @param[in] second A raster.
sub multiply_by {
    my($self, $second) = @_;
    my $datatype = $self->_typeconversion($second);
    return unless defined($datatype);
    $self->_new_grid(ral_grid_create_copy($self->{GRID}, $datatype)) if $datatype != ral_grid_get_datatype($self->{GRID});
    if (ref($second)) {
	ral_grid_mult_grid($self->{GRID}, $second->{GRID});
    } else {
	if (ral_grid_get_datatype($self->{GRID}) == $Geo::Raster::INTEGER_GRID and $second =~ /^-?\d+$/) {
	    ral_grid_mult_integer($self->{GRID}, $second);
	} else {
	    ral_grid_mult_real($self->{GRID}, $second);
	}
    }
    return $self;
}

## @method Geo::Raster divide_by($value)
#
# @brief Divides the cell values of this raster with the given number.
#
# Example:
# @code
# $a /= 3.14159;
# @endcode
# is the same as
# @code
# $a->divide_by(3.14159); 
# @endcode
#
# @param[in] value A number.

## @method Geo::Raster divide_by(Geo::Raster second)
#
# @brief Divides the cell values of this raster with the respective
# cell values of the other raster.
#
# Example:
# @code
# $a /= $b;
# @endcode
# is the same as
# @code
# $a->divide_by($b); 
# @endcode
#
# @param[in] second A raster.
sub divide_by {
    my($self, $second) = @_;
    $self->_new_grid(ral_grid_create_copy($self->{GRID}, $Geo::Raster::REAL_GRID));
    if (ref($second)) {
	ral_grid_div_grid($self->{GRID}, $second->{GRID});
    } else {
	if (ral_grid_get_datatype($self->{GRID}) == $Geo::Raster::INTEGER_GRID and $second =~ /^-?\d+$/) {
	    ral_grid_div_integer($self->{GRID}, $second);
	} else {
	    ral_grid_div_real($self->{GRID}, $second);
	}
    }
    return $self;
}

## @method Geo::Raster modulus_with($value)
#
# @brief Computes the modulus of each cell value and the given number
# and assigns that to the cell.
#
# Example:
# @code
# $a %= 3;
# @endcode
# is the same as
# @code
# $a->modulus_with(3); 
# @endcode
#
# @param[in] value An integer number.
# @note Defined only for integer rasters.

## @method Geo::Raster modulus_with(Geo::Raster second)
#
# @brief Computes the modulus of each cell value of this raster and
# the respective cell value of the given integer raster.
#
# Example:
# @code
# $a %= $b;
# @endcode
# is the same as
# @code
# $a->modulus_with($b); 
# @endcode
#
# @param[in] second An integer raster.
# @note Defined only for integer rasters.
sub modulus_with {
    my($self, $second) = @_;
    if (ref($second)) {
	ral_grid_modulus_grid($self->{GRID}, $second->{GRID});
    } else {
	ral_grid_modulus_integer($self->{GRID}, $second);
    }
    return $self;
}

## @method Geo::Raster to_power_of($power)
#
# @brief Raises the cell values of this raster to the given power.
# 
# Example:
# @code
# $a **= 3.14159;
# @endcode
# is the same as
# @code
# $a->to_power_of(3.14159); 
# @endcode
#
# @param[in] power The exponent.

## @method Geo::Raster to_power_of(Geo::Raster second)
#
# @brief Raises the cell values to the power of the respective cell
# values of the given raster.
#
# Example:
# @code
# $a **= $b;
# @endcode
# is the same as
# @code
# $a->to_power_of($b); 
# @endcode
#
# @param[in] second A raster, whose cell values are used as exponents.
sub to_power_of {
    my($self, $second) = @_;
    my $datatype = $self->_typeconversion($second);
    return unless defined($datatype);
    $self->_new_grid(ral_grid_create_copy($self->{GRID}, $datatype)) if $datatype != ral_grid_get_datatype($self->{GRID});
    if (ref($second)) {
	ral_grid_power_grid($self->{GRID}, $second->{GRID});
    } else {
	ral_grid_power_real($self->{GRID}, $second);
    }
    return $self;
}

## @method Geo::Raster atan2(Geo::Raster second)
#
# @brief Calculates at each cell the arc-tangent of this and the
# second raster.
#
# @param[in] second A raster.
# @return a new raster. In void context changes this raster.
sub atan2 {
    my($self, $second) = @_;
    if (ref($self) and ref($second)) {
	if (defined wantarray) {
	    $self = new Geo::Raster datatype=>$Geo::Raster::REAL_GRID, copy=>$self;
	} elsif (ral_grid_get_datatype($self->{GRID}) == $Geo::Raster::INTEGER_GRID) {
	    $self->_new_grid(ral_grid_create_copy($self->{GRID}, $Geo::Raster::REAL_GRID));
	}
	ral_grid_atan2($self->{GRID}, $second->{GRID});
	return $self;
    } else {
	croak "don't mix scalars and rasters in atan2, please";
    }
}

## @method Geo::Raster cos()
#
# @brief Calculates the cosine at each cell.
#
# @return a new raster. In void context changes this raster.
# @note The resulting raster will always have as datatype real.
sub cos {
    my $self = shift;
    if (defined wantarray) {
	$self = new Geo::Raster datatype=>$Geo::Raster::REAL_GRID, copy=>$self;
    } elsif (ral_grid_get_datatype($self->{GRID}) == $Geo::Raster::INTEGER_GRID) {
	$self->_new_grid(ral_grid_create_copy($self->{GRID}, $Geo::Raster::REAL_GRID));
    }
    ral_grid_cos($self->{GRID});
    return $self;
}

## @method Geo::Raster sin()
#
# @brief Calculates the sine at each cell.
#
# @return a new raster. In void context changes this raster.
sub sin {
    my $self = shift;
    if (defined wantarray) {
	$self = new Geo::Raster datatype=>$Geo::Raster::REAL_GRID, copy=>$self;
    } elsif (ral_grid_get_datatype($self->{GRID}) == $Geo::Raster::INTEGER_GRID) {
	$self->_new_grid(ral_grid_create_copy($self->{GRID}, $Geo::Raster::REAL_GRID));
    }
    ral_grid_sin($self->{GRID});
    return $self;
}

## @method Geo::Raster exp()
#
# @brief Calculates the exponential function at each cell.
#
# @return a new raster. In void context changes this raster.
sub exp {
    my $self = shift;
    if (defined wantarray) {
	$self = new Geo::Raster datatype=>$Geo::Raster::REAL_GRID, copy=>$self;
    } elsif (ral_grid_get_datatype($self->{GRID}) == $Geo::Raster::INTEGER_GRID) {
	$self->_new_grid(ral_grid_create_copy($self->{GRID}, $Geo::Raster::REAL_GRID));
    }
    ral_grid_exp($self->{GRID});
    return $self;
}

## @method Geo::Raster abs()
#
# @brief Calculates the absolute value at each cell.
#
# @return a new raster. In void context changes this raster.
sub abs {
    my $self = shift;
    if (defined wantarray) {
	my $copy = new Geo::Raster($self);
	ral_grid_abs($copy->{GRID});
	return $copy;
    } else {
	ral_grid_abs($self->{GRID});
    }
}

## @method Geo::Raster sqrt()
#
# @brief Calculates the square root at each cell.
#
# @return a new raster. In void context changes this raster.
sub sqrt {
    my $self = shift;
    if (defined wantarray) {
	$self = new Geo::Raster datatype=>$Geo::Raster::REAL_GRID, copy=>$self;
    } elsif (ral_grid_get_datatype($self->{GRID}) == $Geo::Raster::INTEGER_GRID) {
	$self->_new_grid(ral_grid_create_copy($self->{GRID}, $Geo::Raster::REAL_GRID));
    }
    ral_grid_sqrt($self->{GRID});
    return $self;
}

## @method Geo::Raster round()
#
# @brief Rounds the value at each cell.
#
# @return a new integer raster. In void context changes this raster.
sub round {
    my $self = shift;
    if (ref($self)) {
	my $grid = ral_grid_round($self->{GRID});
	return unless $grid;
	if (defined wantarray) {
	    my $new = new Geo::Raster $grid;
	    return $new;
	} else {
	    $self->_new_grid($grid);
	}
    } else {
	return $self < 0 ? POSIX::floor($self - 0.5) : POSIX::floor($self + 0.5);
    }
}

{
    no warnings 'redefine';

## @method Geo::Raster acos()
#
# @brief Calculates the arc-cosine at each cell.
#
# @return a new raster. In void context changes this raster.
sub acos {
    my $self = shift;
    if (defined wantarray) {
	$self = new Geo::Raster datatype=>$Geo::Raster::REAL_GRID, copy=>$self;
    } elsif (ral_grid_get_datatype($self->{GRID}) == $Geo::Raster::INTEGER_GRID) {
	$self->_new_grid(ral_grid_create_copy($self->{GRID}, $Geo::Raster::REAL_GRID));
    }
    ral_grid_acos($self->{GRID});
    return $self;
}

## @method Geo::Raster atan()
#
# @brief Calculates the arc-tangent at each cell.
#
# @return a new raster. In void context changes this raster.
sub atan {
    my $self = shift;
    if (defined wantarray) {
	$self = new Geo::Raster datatype=>$Geo::Raster::REAL_GRID, copy=>$self;
    } elsif (ral_grid_get_datatype($self->{GRID}) == $Geo::Raster::INTEGER_GRID) {
	$self->_new_grid(ral_grid_create_copy($self->{GRID}, $Geo::Raster::REAL_GRID));
    }
    ral_grid_atan($self->{GRID});
    return $self;
}

## @method Geo::Raster ceil()
#
# @brief Calculates at each cell the smallest integer not less than
# the value.
#
# @return a new integer raster. In void context changes this raster.
sub ceil {
    my $self = shift;
    if (ref($self)) {
	$self = new Geo::Raster($self) if defined wantarray;
	ral_grid_ceil($self->{GRID});
	return $self;
    } else {
	return POSIX::ceil($self);
    }
}

## @method Geo::Raster cosh()
#
# @brief Calculates at each cell the hyperbolic cosine of the value.
#
# @return a new raster. In void context changes this raster.
sub cosh {
    my $self = shift;
    if (defined wantarray) {
	$self = new Geo::Raster datatype=>$Geo::Raster::REAL_GRID, copy=>$self;
    } elsif (ral_grid_get_datatype($self->{GRID}) == $Geo::Raster::INTEGER_GRID) {
	$self->_new_grid(ral_grid_create_copy($self->{GRID}, $Geo::Raster::REAL_GRID));
    }
    ral_grid_cosh($self->{GRID});
    return $self;
}

## @method Geo::Raster floor()
#
# @brief Calculates at each cell the largest integer less than or
# equal to the value.
#
# @return a new integer raster. In void context changes this raster.
sub floor {
    my $self = shift;
    if (ref($self)) {
	$self = new Geo::Raster($self) if defined wantarray;
	ral_grid_floor($self->{GRID});
	return $self;
    } else {
	return POSIX::floor($self);
    }
}

## @method Geo::Raster log()
#
# @brief Calculates the logarithm at each cell.
#
# @return a new raster. In void context changes this raster.
sub log {
    my $self = shift;
    if (defined wantarray) {
	$self = new Geo::Raster datatype=>$Geo::Raster::REAL_GRID, copy=>$self;
    } elsif (ral_grid_get_datatype($self->{GRID}) == $Geo::Raster::INTEGER_GRID) {
	$self->_new_grid(ral_grid_create_copy($self->{GRID}, $Geo::Raster::REAL_GRID));
    }
    ral_grid_log($self->{GRID});
    return $self;
}

## @method Geo::Raster log10()
#
# @brief Calculates the base-10 logarithm at each cell.
#
# @return a new raster. In void context changes this raster.
sub log10 {
    my $self = shift;
    if (defined wantarray) {
	$self = new Geo::Raster datatype=>$Geo::Raster::REAL_GRID, copy=>$self;
    } elsif (ral_grid_get_datatype($self->{GRID}) == $Geo::Raster::INTEGER_GRID) {
	$self->_new_grid(ral_grid_create_copy($self->{GRID}, $Geo::Raster::REAL_GRID));
    }
    ral_grid_log10($self->{GRID});
    return $self;
}

## @fn log_base($base, $value)
#
# @brief Calculates the logarithm with a desired base.
# @param base Desired logarithm base.
# @param value Value for which the logarithm is calculated.
# @return the result of the logarithm function.
sub log_base {
    my ($base, $value) = @_;
    return CORE::log($value)/CORE::log($base);
}

## @method Geo::Raster sinh()
#
# @brief Calculates the hyperbolic sine at each cell.
#
# @return a new raster. In void context changes this raster.
sub sinh {
    my $self = shift;
    if (defined wantarray) {
	$self = new Geo::Raster datatype=>$Geo::Raster::REAL_GRID, copy=>$self;
    } elsif (ral_grid_get_datatype($self->{GRID}) == $Geo::Raster::INTEGER_GRID) {
	$self->_new_grid(ral_grid_create_copy($self->{GRID}, $Geo::Raster::REAL_GRID));
    }
    ral_grid_sinh($self->{GRID});
    return $self;
}

## @method Geo::Raster tan()
#
# @brief Calculates the tangent at each cell.
#
# @return a new raster. In void context changes this raster.
sub tan {
    my $self = shift;
    if (defined wantarray) {
	$self = new Geo::Raster datatype=>$Geo::Raster::REAL_GRID, copy=>$self;
    } elsif (ral_grid_get_datatype($self->{GRID}) == $Geo::Raster::INTEGER_GRID) {
	$self->_new_grid(ral_grid_create_copy($self->{GRID}, $Geo::Raster::REAL_GRID));
    }
    ral_grid_tan($self->{GRID});
    return $self;
}

## @method Geo::Raster tanh()
#
# @brief Calculates the hyperbolic tangent at each cell.
#
# @return a new raster. In void context changes this raster.
sub tanh {
    my $self = shift;
    if (defined wantarray) {
	$self = new Geo::Raster datatype=>$Geo::Raster::REAL_GRID, copy=>$self;
    } elsif (ral_grid_get_datatype($self->{GRID}) == $Geo::Raster::INTEGER_GRID) {
	$self->_new_grid(ral_grid_create_copy($self->{GRID}, $Geo::Raster::REAL_GRID));
    }
    ral_grid_tanh($self->{GRID});
    return $self;
}
}

## @method Geo::Raster lt($second, $reversed)
#
# @brief Performs at each cell the "less than" comparison
# on this raster and a number.
#
# Example:
# @code
# $b = $a < 3.14159;
# @endcode
# is the same as
# @code
# $b = $a->lt(3); 
# @endcode
#
# @param[in] second A number to compare against.
# @param[in] reversed (optional) Whether to perform this < second
# computation instead of second < this. When operator '<' is used,
# this value is automatically set by Perl when appropriate.
# @return a new integer raster, which is 0 where this raster is greater
# than or equal to the second, and 1 where it is less than the
# second. In void context changes this raster.

## @method Geo::Raster lt(Geo::Raster second, $reversed)
#
# @brief Performs at each cell the "less than" comparison
# on this and the second raster.
#
# Example:
# @code
# $c = $a < $b;
# @endcode
# is the same as
# @code
# $c = $a->lt($b); 
# @endcode
#
# @param[in] second A raster to compare against.
# @param[in] reversed (optional) Whether to perform this < second
# computation instead of second < this. When operator '<' is used,
# this value is automatically set by Perl when appropriate.
# @return a new integer raster, which is 0 where this raster is greater
# than or equal to the second, and 1 where it is less than the
# second. In void context changes this raster.
sub lt {
    my($self, $second, $reversed) = @_;    
    $self = Geo::Raster->new($self) if defined wantarray;
    if (ref($second)) {
	ral_grid_lt_grid($self->{GRID}, $second->{GRID});
    } else {
	if ($reversed) {
	    if (ral_grid_get_datatype($self->{GRID}) == $Geo::Raster::INTEGER_GRID and $second =~ /^-?\d+$/) {
		ral_grid_gt_integer($self->{GRID}, $second);
	    } else {
		ral_grid_gt_real($self->{GRID}, $second);
	    }
	} else {
	    if (ral_grid_get_datatype($self->{GRID}) == $Geo::Raster::INTEGER_GRID and $second =~ /^-?\d+$/) {
		ral_grid_lt_integer($self->{GRID}, $second);
	    } else {
		ral_grid_lt_real($self->{GRID}, $second);
	    }
	}
    }
    return $self if defined wantarray;
}

## @method Geo::Raster gt($second, $reversed)
#
# @brief Performs at each cell the "greater than" comparison
# on this raster and a number.
#
# Example:
# @code
# $b = $a > 3.14159;
# @endcode
# is the same as
# @code
# $b = $a->gt(3); 
# @endcode
#
# @param[in] second A number to compare against.
# @param[in] reversed (optional) Whether to perform this > second
# computation instead of second > this. When operator '>' is used,
# this value is automatically set by Perl when appropriate.
# @return a new integer raster, which is 0 where this raster is less
# than or equal to the second, and 1 where it is greater than the
# second. In void context changes this raster.

## @method Geo::Raster gt(Geo::Raster second, $reversed)
#
# @brief Performs at each cell the "greater than" comparison
# on this and the second raster.
#
# Example:
# @code
# $c = $a > $b;
# @endcode
# is the same as
# @code
# $c = $a->gt($b); 
# @endcode
#
# @param[in] second A raster to compare against.
# @param[in] reversed (optional) Whether to perform this > second
# computation instead of second > this. When operator '>' is used,
# this value is automatically set by Perl when appropriate.
# @return a new integer raster, which is 0 where this raster is less
# than or equal to the second, and 1 where it is greater than the
# second. In void context changes this raster.
sub gt {
    my($self, $second, $reversed) = @_;
    $self = Geo::Raster->new($self) if defined wantarray;
    if (ref($second)) {
	ral_grid_gt_grid($self->{GRID}, $second->{GRID});
    } else {
	if ($reversed) {
	    if (ral_grid_get_datatype($self->{GRID}) == $Geo::Raster::INTEGER_GRID and $second =~ /^-?\d+$/) {
		ral_grid_lt_integer($self->{GRID}, $second);
	    } else {
		ral_grid_lt_real($self->{GRID}, $second);
	    }
	} else {
	    if (ral_grid_get_datatype($self->{GRID}) == $Geo::Raster::INTEGER_GRID and $second =~ /^-?\d+$/) {
		ral_grid_gt_integer($self->{GRID}, $second);
	    } else {
		ral_grid_gt_real($self->{GRID}, $second);
	    }
	}
    }
    return $self if defined wantarray;
}

## @method Geo::Raster le($second, $reversed)
#
# @brief Performs at each cell the "less than or equal to" comparison
# on this raster and a number.
#
# Example:
# @code
# $b = $a <= 3.14159;
# @endcode
# is the same as
# @code
# $b = $a->le(3); 
# @endcode
#
# @param[in] second A number to compare against.
# @param[in] reversed (optional) Whether to perform this <= second
# computation instead of second <= this. When operator '<=' is used,
# this value is automatically set by Perl when appropriate.
# @return a new integer raster, which is 0 where this raster is greater
# than the second, and 1 where it is less than or equal to the second. In void
# context changes this raster.

## @method Geo::Raster le(Geo::Raster second, $reversed)
#
# @brief Performs at each cell the "greater than or equal to" comparison
# on this and the second raster.
#
# Example:
# @code
# $c = $a <= $b;
# @endcode
# is the same as
# @code
# $c = $a->le($b); 
# @endcode
#
# @param[in] second A raster to compare against.
# @param[in] reversed (optional) Whether to perform this <= second
# computation instead of second <= this. When operator '<=' is used,
# this value is automatically set by Perl when appropriate.
# @return a new integer raster, which is 0 where this raster is greater
# than the second, and 1 where it is less than or equal to the second. In void
# context changes this raster.
sub le {
    my($self, $second, $reversed) = @_;
    $self = Geo::Raster->new($self) if defined wantarray;
    if (ref($second)) {
	ral_grid_le_grid($self->{GRID}, $second->{GRID});
    } else {
	if ($reversed) {
	    if (ral_grid_get_datatype($self->{GRID}) == $Geo::Raster::INTEGER_GRID and $second =~ /^-?\d+$/) {
		ral_grid_ge_integer($self->{GRID}, $second);
	    } else {
		ral_grid_ge_real($self->{GRID}, $second);
	    }
	} else {
	    if (ral_grid_get_datatype($self->{GRID}) == $Geo::Raster::INTEGER_GRID and $second =~ /^-?\d+$/) {
		ral_grid_le_integer($self->{GRID}, $second);
	    } else {
		ral_grid_le_real($self->{GRID}, $second);
	    }
	}
    }
    return $self if defined wantarray;
}

## @method Geo::Raster ge($second, $reversed)
#
# @brief Performs at each cell the "greater than or equal to" comparison
# on this raster and a number.
#
# Example:
# @code
# $b = $a >= 3.14159;
# @endcode
# is the same as
# @code
# $b = $a->ge(3); 
# @endcode
#
# @param[in] second A number to compare against.
# @param[in] reversed (optional) Whether to perform this >= second
# computation instead of second >= this. When operator '>=' is used,
# this value is automatically set by Perl when appropriate.
# @return a new integer raster, which is 0 where this raster is less
# than the second, and 1 where it is greater than the second. In void
# context changes this raster.

## @method Geo::Raster ge(Geo::Raster second, $reversed)
#
# @brief Performs at each cell the "greater than or equal to" comparison
# on this and the second raster.
#
# Example:
# @code
# $c = $a >= $b;
# @endcode
# is the same as
# @code
# $c = $a->ge($b); 
# @endcode
#
# @param[in] second A raster to compare against.
# @param[in] reversed (optional) Whether to perform this >= second
# computation instead of second >= this. When operator '>=' is used,
# this value is automatically set by Perl when appropriate.
# @return a new integer raster, which is 0 where this raster is less
# than the second, and 1 where it is greater than the second. In void
# context changes this raster.
sub ge {
    my($self, $second, $reversed) = @_;
    $self = Geo::Raster->new($self) if defined wantarray;
    if (ref($second)) {
	ral_grid_ge_grid($self->{GRID}, $second->{GRID});
    } else {
	if ($reversed) {
	    if (ral_grid_get_datatype($self->{GRID}) == $Geo::Raster::INTEGER_GRID and $second =~ /^-?\d+$/) {
		ral_grid_le_integer($self->{GRID}, $second);
	    } else {
		ral_grid_le_real($self->{GRID}, $second);
	    }
	} else {
	    if (ral_grid_get_datatype($self->{GRID}) == $Geo::Raster::INTEGER_GRID and $second =~ /^-?\d+$/) {
		ral_grid_ge_integer($self->{GRID}, $second);
	    } else {
		ral_grid_ge_real($self->{GRID}, $second);
	    }
	}
    }
    return $self if defined wantarray;
}

## @method Geo::Raster eq($second)
#
# @brief Performs at each cell the "equal to" comparison on this raster
# and a number.
#
# Example:
# @code
# $b = $a == 3;
# @endcode
# is the same as
# @code
# $b = $a->eq(3); 
# @endcode
#
# @param[in] second A number to compare against.
# @return a new integer raster, which is 0 where this raster is not equal
# to the second, and 1 where they are equal. In void context
# changes this raster.

## @method Geo::Raster eq(Geo::Raster second)
#
# @brief Performs at each cell the "equal to" comparison on this and the second
# raster.
#
# Example:
# @code
# $c = $a == $b;
# @endcode
# is the same as
# @code
# $c = $a->eq($b); 
# @endcode
#
# @param[in] second A raster to compare against.
# @return a new integer raster, which is 0 where this raster is not equal
# ot the second, and 1 where they are equal. In void context
# changes this raster.
sub eq {
    my $self = shift;
    my $second = shift;
    $self = Geo::Raster->new($self) if defined wantarray;
    if (ref($second)) {
	ral_grid_eq_grid($self->{GRID}, $second->{GRID});
    } else {
	if (ral_grid_get_datatype($self->{GRID}) == $Geo::Raster::INTEGER_GRID and $second =~ /^-?\d+$/) {
	    ral_grid_eq_integer($self->{GRID}, $second);
	} else {
	    ral_grid_eq_real($self->{GRID}, $second);
	}
    }
    return $self if defined wantarray;
}

## @method Geo::Raster ne($second)
#
# @brief Performs at each cell the "not equal to" comparison on this raster
# and a number.
#
# Example:
# @code
# $b = $a != 3;
# @endcode
# is the same as
# @code
# $b = $a->ne(3); 
# @endcode
#
# @param[in] second A number to compare against.
# @return a new integer raster, which is 0 where this raster is equal
# to the second, and 1 where they are not equal. In void context
# changes this raster.

## @method Geo::Raster ne(Geo::Raster second)
#
# @brief Performs at each cell the "not equal to" comparison on this and the second
# raster.
#
# Example:
# @code
# $c = $a != $b;
# @endcode
# is the same as
# @code
# $c = $a->ne($b); 
# @endcode
#
# @param[in] second A raster to compare against.
# @return a new integer raster, which is 0 where this raster is equal
# to the second, and 1 where they are not equal. In void context
# changes this raster.
sub ne {
    my $self = shift;
    my $second = shift;
    $self = Geo::Raster->new($self) if defined wantarray;
    if (ref($second)) {
	ral_grid_ne_grid($self->{GRID}, $second->{GRID});
    } else {
	if (ral_grid_get_datatype($self->{GRID}) == $Geo::Raster::INTEGER_GRID and $second =~ /^-?\d+$/) {
	    ral_grid_ne_integer($self->{GRID}, $second);
	} else {
	    ral_grid_ne_real($self->{GRID}, $second);
	}
    }
    return $self if defined wantarray;
}

## @method Geo::Raster cmp($second, $reversed)
#
# @brief Performs at each cell the numeric comparison on this raster
# and a number.
#
# Example:
# @code
# $b = $a <=> 3.14159;
# @endcode
# is the same as
# @code
# $b = $a->cmp(3.14159); 
# @endcode
#
# @param[in] second A number to compare against.
# @param[in] reversed (optional) Whether to perform this <=> second
# computation instead of second <=> this. When operator '<=>' is used,
# this value is automatically set by Perl when appropriate.
# @return a new integer raster, which is -1 where this raster is
# smaller than the second, 0 where they are equal, and 1 where the
# second is larger. In void context changes this raster.

## @method Geo::Raster cmp(Geo::Raster second, $reversed)
#
# @brief Performs at each cell the numeric comparison on this and the second
# raster.
#
# Example:
# @code
# $c = $a <=> $b;
# @endcode
# is the same as
# @code
# $c = $a->cmp($b); 
# @endcode
#
# @param[in] second A raster to compare against.
# @param[in] reversed (optional) Whether to perform this <=> second
# computation instead of second <=> this. When operator '<=>' is used,
# this value is automatically set by Perl when appropriate.
# @return a new integer raster, which is -1 where this raster is
# smaller than the second, 0 where they are equal, and 1 where the
# second is larger. In void context changes this raster.
sub cmp {
    my($self, $second, $reversed) = @_;
    $self = Geo::Raster->new($self) if defined wantarray;
    if (ref($second)) {
	ral_grid_cmp_grid($self->{GRID}, $second->{GRID});
    } else {
	if (ral_grid_get_datatype($self->{GRID}) == $Geo::Raster::INTEGER_GRID and $second =~ /^-?\d+$/) {
	    ral_grid_cmp_integer($self->{GRID}, $second);
	} else {
	    ral_grid_cmp_real($self->{GRID}, $second);
	}
	if ($reversed) {
	    if (ral_grid_get_datatype($self->{GRID}) == $Geo::Raster::INTEGER_GRID and $second =~ /^-?\d+$/) {
		ral_grid_mult_integer($self->{GRID}, -1);
	    } else {
		ral_grid_mult_real($self->{GRID}, -1);
	    }
	}
    }
    return $self if defined wantarray;
}

## @method Geo::Raster not()
#
# @brief Evaluate at each cell the logical not.
#
# @return a new raster. In void context changes this raster.
# @note Defined only for integer rasters.
sub not {
    my $self = shift;
    $self = Geo::Raster->new($self) if defined wantarray;
    ral_grid_not($self->{GRID});
    return $self if defined wantarray;
}

## @method Geo::Raster and(Geo::Raster second)
#
# @brief Evaluate at each cell the logical and on this and the second
# raster.
#
# The truth table of logical and:
#<table>
#<tr><th>this</th><th>second</th><th>result</th></tr>
#<tr><td>false</td><td>false</td><td>false</td></tr>
#<tr><td>false</td><td>true</td><td>false</td></tr>
#<tr><td>true</td><td>false</td><td>false</td></tr>
#<tr><td>true</td><td>true</td><td>true</td></tr>
#</table>
# If either cell has nodata (undefined) value, the result is undefined.
#
# @param[in] second A raster.
# @return a new raster. In void context changes this raster.
# @note Defined only for integer rasters.
sub and {
    my $self = shift;
    my $second = shift;
    $self = Geo::Raster->new($self) if defined wantarray;
    ral_grid_and_grid($self->{GRID}, $second->{GRID});
    return $self if defined wantarray;
}

## @method Geo::Raster or(Geo::Raster second)
#
# @brief Evaluate at each cell the logical or on this and the second
# raster.
#
# The truth table of logical or:
#<table>
#<tr><th>this</th><th>second</th><th>result</th></tr>
#<tr><td>false</td><td>false</td><td>false</td></tr>
#<tr><td>false</td><td>true</td><td>true</td></tr>
#<tr><td>true</td><td>false</td><td>true</td></tr>
#<tr><td>true</td><td>true</td><td>true</td></tr>
#</table>
# If either cell has nodata (undefined) value, the result is undefined.
#
# @param[in] second A raster.
# @return a new raster. In void context changes this raster.
# @note Defined only for integer rasters.
sub or {
    my $self = shift;
    my $second = shift;
    $self = Geo::Raster->new($self) if defined wantarray;
    ral_grid_or_grid($self->{GRID}, $second->{GRID});
    return $self if defined wantarray;
}

## @method Geo::Raster nor($second)
#
# @brief Evaluates at each cell the logical nor on this and the second
# raster.
#
# The truth table of logical nor:
#<table>
#<tr><th>this</th><th>second</th><th>result</th></tr>
#<tr><td>false</td><td>false</td><td>true</td></tr>
#<tr><td>false</td><td>true</td><td>false</td></tr>
#<tr><td>true</td><td>false</td><td>false</td></tr>
#<tr><td>true</td><td>true</td><td>false</td></tr>
#</table>
# If either cell has nodata (undefined) value, the result is undefined.
#
# @param[in] second A raster, whose cell values are used to calculate
# the logical inverse of disjunction.
# @return a new raster. In void context changes this raster.
# @note Defined only for integer rasters.
sub nor {
    my $self = shift;
    my $second = shift;
    $self = Geo::Raster->new($self) if defined wantarray;
    ral_grid_or_grid($self->{GRID}, $second->{GRID});
    $self->not();
    return $self if defined wantarray;
}

1;
