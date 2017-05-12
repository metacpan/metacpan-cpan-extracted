use Test::More tests => 30;
use File::Spec;
use lib File::Spec->catfile("..","lib");
use Math::ODE;
use Data::Dumper;
use strict;
use warnings;

my @steps = qw(0.2 0.1 0.05 0.01 0.005 0.001);
my %ODES = ( 
              "y'=y, y(0)=2, y(x) = 2 e^{-x}" => 
                    [ 
                        { initial => [2], ODE => [ \&DE1 ], t0 => 0, tf => 2 },
                        sub { my $t=shift; 2 * exp(-$t) },
                    ], 

             "y'=y^2, y(0)=1, y(x)=-1/(x-1)" =>
                    [ 
                        { initial => [1], ODE => [ \&DE2 ], t0 => 0, tf => 0.5 },
                        sub { my $t=shift; -1/($t-1) },
                    ],
             "y'=-2 x exp(-x^2), y(0) = 1, y(x) = exp(-x^2)" =>
                    [ 
                        { initial => [1], ODE => [ \&DEgauss ], t0 => 0, tf => 2 },
                        sub { my $t=shift;  exp(-$t**2) },
                     ],
             "y' = x^-1, y(1) = 1, y(x) = ln(x)" =>
                    [   
                        { initial => [0], ODE => [ \&DElog ], t0 => 1, tf => 2 },
                        sub { log(shift) },
                    ],
             "y' = y^2+1, y(0) = 0, y(x) = tan(x)" =>
                    [   
                        # singularity at pi/2 = 1.57...
                        { initial => [0], ODE => [ \&DEtan ], t0 => 0, tf => 1 },
                        sub { tan(shift) },
                    ],
           );

for my $ode (keys %ODES) {
    verify_ode($ode, $ODES{$ode});
}

### 

sub verify_ode
{
    my ($description,$ode) = @_;
    my($args,$solution) = @$ode;


    for my $step (@steps){
        my $o = Math::ODE->new(%$args, step => $step);
        if( $o->evolve ){
            my $error  = $o->max_error([$solution]); 
            my $output = $description."\n\t\tstep=$step, max error=$error, expected error=" . $o->error;
            ok( $error < $o->error, $output );
        } else { 
            ok(0, "Numerical badness for $description at step=$step");
        }
    }
}
sub DEgauss { my ($t,$y) = @_; - 2 * $t * exp ( - $t ** 2 ); }
sub DE1     { my ($t,$y) = @_; -$y->[0]; }
sub DE2     { my ($t,$y) = @_; $y->[0] ** 2; }
sub DElog   { my ($t,$y) = @_; 1/$t; }
sub DEtan   { my ($t,$y) = @_; $y->[0] ** 2 + 1; }
sub tan     { my $t=shift; sin($t)/cos($t); }
