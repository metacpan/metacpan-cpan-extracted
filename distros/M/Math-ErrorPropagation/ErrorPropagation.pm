package Math::ErrorPropagation;

our $VERSION = '0.01';

use 5.006;
use strict;
use warnings;
use Carp;

use overload 
    '+' => \&plus, 
    '-' => \&minus,
    '/' => \&divide,
    '*' => \&times,
    '**' => \&power,
    'exp' => \&eexp,
    'log' => \&elog,
    'sin' => \&esin,
    'cos' => \&ecos,
    'sqrt' => \&esqrt,
    '=' => \&copy;

sub datum{
    my $caller = shift;
    my $class = ref($caller)||$caller;
    my $self = {
	var => 0.0,
	value => undef,
	@_,
    };
    return bless $self, $class;
}

sub copy{
    my $caller = shift;
    my $self = $caller->datum(%$caller);
    return $self;
}


sub central_value{
    my $self = shift;
    if(@_){$self->{value} = shift}
    return $self->{value};
}

sub sd{
    my $self = shift;
    if(@_){
	my $sd = shift;
	$self->{var} = $sd*$sd;
    }
    return sqrt($self->{var});
}

sub variance{
    my $self = shift;
    if(@_){	
	$self->{var} = shift;
	croak "Given negative value $self->{var} for variance.\n"
	    if($self->{var}<0.0);
    }
    return $self->{var}; 
} 

sub add{
    my ($caller, $x, $y) = @_; 
    my $class = ref($caller)||$caller;
    return $class->datum(value=>$x->{value}+$y->{value}, 
		       var=>$x->{var}+$y->{var}); 
} 


# Handles for overloaded operators:

# For the binary operators, we assume at least one argument, $x, is an object.
# If $y is a ref we assume it is also an Errdatum object;  otherwise we 
# assume it is a number.                

sub plus{
    my ($x,$y) = @_;
    my $class = ref($x); 

    return $class->datum(value=>$x->{value}+$y->{value}, 
		       var=>$x->{var}+$y->{var}) if ref($y);
    return $class->datum(value=>$x->{value}+$y, var=>$x->{var}); 
}

sub minus{
    my ($x,$y, $swapped) = @_;
    my $class = ref($x);
    my $newvar = $x->{var};
    my $newval = $x->{value};

    if (ref($y)){
	$newval -= $y->{value} ;
	$newvar += $y->{var};
    }else{
	$newval -= $y;
	if($swapped){ $newval = -$newval;}
    }

    return $class->datum(value=>$newval, var=>$newvar);
}

sub times{
    my ($x,$y) = @_;
    my $class = ref($x); 

    return $class->datum(value=>$x->{value}*$y->{value}, 
		       var=> $y->{value}*$y->{value}*$x->{var} +
		       $x->{value}*$x->{value}*$y->{var}) if ref($y); 

    return $class->datum(value=>$x->{value}*$y, var=>$y*$y*$x->{var}); 
}

sub divide{
    my ($x,$y, $swapped) = @_;
    my $class = ref($x);
    my ($newvar, $newval);
   
    if (ref($y)){
	$newval = $x->{value}/$y->{value};
	$newvar = ($x->{var}+$newval*$newval*$y->{var})/($y->{value}*$y->{value});
    }else{
	if($swapped){
	    $newval = $y/$x->{value};
	    $newvar = ($newval*$newval*$x->{var})/($x->{value}*$x->{value});
	}else{
	    $newval = $x->{value}/$y;	    
	    $newvar = $x->{var}/($y*$y);	    
	}
    }

    return $class->datum(value=>$newval, var=>$newvar);
}

sub power{
    my ($x,$y, $swapped) = @_;
    my $class = ref($x);
    my ($newvar, $newval);
   
    if (ref($y)){
	$newval = $x->{value}**$y->{value};
	$newvar = $y->{value}*$newval/$x->{value};
	$newvar *= $newvar*$x->{var};
	my $otherbit = log($x->{value})*$newval;
	$newvar += $otherbit*$otherbit*$y->{var};
    }else{
	if($swapped){
	    $newval = $y**$x->{value};
	    $newvar = log($y)*$newval;
	    $newvar *= $newvar*$x->{var};
	}else{
	    $newval = $x->{value}**$y;
	    $newvar = $y*$newval/$x->{value};
	    $newvar *= $newvar*$x->{var};	    
	}
    }

    return $class->datum(value=>$newval, var=>$newvar);
}

sub eexp{
    my $x = shift;
    my $class = ref($x); 
    my $newval = exp($x->{value});
    return $class->datum(value=>$newval,
		       var=>$x->{var}*$newval*$newval);
}

sub elog{
    my $x = shift;
    my $class = ref($x); 

    return $class->datum(value=>log($x->{value}),,
		       var=>$x->{var}/($x->{value}*$x->{value}));
}

sub esin{
    my $x = shift;
    my $class = ref($x); 

    my $newval = sin($x->{value});
    my $newvar = $newval*cos($x->{value});

    return $class->datum(value=>$newval,
		       var=>$x->{var}*$newvar*$newvar);
}

sub ecos{
    my $x = shift;
    my $class = ref($x); 

    my $newval = cos($x->{value});
    my $newvar = $newval*sin($x->{value});
    
    return $class->datum(value=>$newval,
		       var=>$x->{var}*$newvar*$newvar);
}

sub esqrt{
    my $x = shift;
    my $class = ref($x); 
    
    return $class->datum(value=>sqrt($x->{value}),
		       var=>$x->{var}/(4.0*$x->{value}));

}


1;

__END__

=head1 NAME

Math::ErrorPropagation - Computes the error of a function of statistical data

=head1 SYNOPSIS

use ErrorPropagation;

$x1 = Math::ErrorPropagation->datum(value=>1.2, var=>0.1);   
$x2 = Math::ErrorPropagation->datum(value=>2.3, var=>0.12);   
$x3 = Math::ErrorPropagation->datum(value=>3.5);   
$x3->sd(0.23);

$f = sin(0.5*$x1)/($x2**3)+log($x3);
printf ("f = %f +/- %f", $f->central_value(), $f-sd());

=head1 DESCRIPTION

A function I<f({X_i})> of a set of n independent stochastic variables 
I<{X_i}={X_0, X_1, ..., X_(n-1)}>
with means I<{x_i}={x_0, x_1, ..., x_(n-1)}>
and corresponding variances I<{var_i}={var_0, var_1, ..., var_(n-1)}>, 
has mean I<f({x_i})> and a variance I<var_f> which is the sum 
of the squared partial derivatives multiplied by the variances 

I<var_f  = (df/dx_i)**2 var_i>

This package allows the propagation of errors on the variables through
various simple mathematical operations to automatically compute the error of 
the function. Use it to define data each with a central (mean) value and 
either the variance or standard deviation (square root of the variance), 
then apply perls mathematical operators to them to calculate your function 
I<f>. These operators are overloaded so that I<f> automatically has the correct
variance.

=head2 METHODS

=over 35

=item $x = Math::ErrorPropagation->datum(value=>1.2, var=>0.1);   

initialise a datum with mean 1.2 and variance 0.1

=item $x = Math::ErrorPropagation->datum();   

initialise an empty datum

=item $x->central_value(2.3);           

assign a central value  

=item $x->variance(0.25);               

assign a variance

=item $x->sd(0.5);                      

assign a standard deviation

=item $m = $x->central_value(2.3);      

read the central value  

=item $v = $x->variance(0.25);          

read the variance

=item $s = $x->sd(0.5);                 

read the standard deviation

=item $y = copy $x;                     

copy a datum

=item $z = 1.2+$y;

=item $z = $y+$x;
             
=item $z = $y+2.3;

=item $z += $x;

add data

=item $z++;                             

increment datum

=item $z = $y-$x;                    

=item $z = $y-2.3;

=item $z = 1.2-$y;

=item $z -= $x;

subtract data

=item $z--;                             

decrement datum

=item $z = $y*$x;

=item $z = $y*2.3;

=item $z = 1.2*$y;

=item $z *= $x;

multiply data

=item $z = $y/$x;

=item $z = $y/2.3;

=item $z = 1.2/$y;

=item $z /= $x;

divide data

=item $z = $y**$x;

=item $z = $y**2.3;

=item $z = 1.2**$y;

powers

=item $z = exp($x);

=item $z = sin($x);

=item $z = cos($x);

=item $z = log($x);

=item $z = sqrt($x);

some mathematical functions

=back

=head1 THINGS TO DO

Find bugs/flakiness.

Add more mathematical functions, particularly some of those in Math::Trig

=head1 AUTHOR

Z. Sroczynski <zs@theorie.physik.uni-wuppertal.de>

=head1 SEE ALSO

L<perl>.

=cut
