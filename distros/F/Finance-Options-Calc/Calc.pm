package Finance::Options::Calc;

use strict;
use Carp;
use constant PI => 4 * atan2(1,1);
use vars qw(@EXPORT @ISA $VERSION $s $k $r $vol $t $d1 $d2 $nd1);
require Exporter;
$VERSION = 0.90;
@ISA     = qw( Exporter );

=head1 NAME

C<Finance::Options::Calc> - Option analysis based on different option pricing models.

=head1 SYNOPSIS

    use Finance::Options::Calc;
 
    print b_s_call(90, 80, 20, 30, 4.5);
    print b_s_put (90, 80, 20, 30, 4.5);
    print call_delta(90, 80, 20, 30, 4.5); 
    print put_delta(90, 80, 20, 30, 4.5);
    print call_theta(90, 80, 20, 30, 4.5);
    print put_theta(90, 80, 20, 30, 4.5); 
    print gamma(90, 80, 20, 30, 4.5);
    print vega(90, 80, 20, 30, 4.5);
    print call_rho(90, 80, 20, 30, 4.5);
    print put_rho(90, 80, 20, 30, 4.5);


=head1 DESCRIPTION

b_s_call() subroutines returns theorical value of the call option based on
Black_Scholes model. The arguments are current stock price,
strike price, time to expiration (calender days, note this module
does NOT use business days), volatility(%), annual interest rate(%) in order. 

b_s_put() subroutines returns theorical value of the put option based on
Black_Scholes model. The arguments are current stock price,
strike price, time to expiration (calender days, note this module 
does NOT use business days), volatility(%), annual interest rate(%) in order.

call_delta() returns call delta.

put_delta() returns put delta.

Other methods are similar.

=head1 TODO

more calculation models will be included.

=head1 AUTHOR

Chicheng Zhang

chichengzhang@hotmail.com

=cut

@EXPORT = qw(b_s_call b_s_put call_delta put_delta vega 
	     call_rho put_rho call_theta put_theta gamma);

sub _variables {
    
        croak "Not enough arguments.\n" unless $#_ == 4;

        ## s   -- current price
	## k   -- strike price
	## t   -- time remains
	## vol -- volatility
        ## r   -- interest rate

	($s, $k, $t, $vol, $r) = @_;
        $r   /= 100;
        $vol /= 100;
        $t   /= 365;
	$d1   = (log($s / $k) + ( $r + $vol * $vol / 2 ) * $t) / ($vol * (sqrt $t));
	$d2   = $d1 - $vol * (sqrt $t);
	$nd1  = exp( - $d1 * $d1 / 2 ) / sqrt( 2 * PI );
}

sub call_delta {
        _variables(@_);
    	return sprintf "%5.5f", _norm($d1);
}

sub put_delta {
        _variables(@_);
        return sprintf "%5.5f", _norm($d1) - 1;
}

sub call_theta {
        _variables(@_);
        my $theta_c = - $s * $nd1 * $vol / (2 * sqrt($t)) - $r * $k * exp( - $r * $t ) * _norm($d2);
        return sprintf "%5.5f", $theta_c / 365;
}

sub put_theta {
        _variables(@_);
	my $theta_p = - $s * $nd1 * $vol / (2 * sqrt($t)) + $r * $k * exp( - $r * $t ) * _norm(-$d2);
        return sprintf "%5.5f", $theta_p / 365;
}

sub call_rho {
        _variables(@_);
        my $rho = $k * $t * exp( - $r * $t ) * _norm($d2);
        return sprintf "%5.5f", $rho / 100;
}

sub put_rho {
        _variables(@_);
	my $rho = - $k * $t * exp( - $r * $t ) * _norm(-$d2);
        return sprintf "%5.5f", $rho / 100; 
}

sub vega {
        _variables(@_);
	my $vega = $s * sqrt($t) * $nd1;
        return sprintf "%5.5f", $vega / 100;
}

sub gamma {
        _variables(@_);
        my $gamma= $nd1 / ( $s * $vol * sqrt($t) );
        return sprintf "%5.5f", $gamma;
}

sub b_s_call {
        _variables(@_);
	my $c   = $s * _norm($d1) - $k * (exp (-$r*$t)) * _norm($d2);
	return sprintf "%5.5f", $c;
}

sub b_s_put {
        _variables(@_);
	my $p   = $k * (exp (-$r*$t)) * _norm(-$d2) - $s * _norm(-$d1);
	return sprintf "%5.5f", $p;
}

sub _norm {

	my $d    = shift;
        my $step = 0.01;
        my $sum  = 0;
        my $x    = -5 + $step / 2;

        while ( ($x < $d) && ($x < 4) )
        {
                $sum += exp(- $x * $x / 2) * $step;
                $x   += $step;
        }
        return $sum / sqrt(2 * PI);
}

1;

