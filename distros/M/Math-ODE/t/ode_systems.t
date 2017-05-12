use Test::More tests => 6;
use File::Spec;
use lib File::Spec->catfile("..","lib");
use Math::ODE;
use Data::Dumper;
use strict;
use warnings;

my ($o, $ok, $sol, $error, @vals, $res);
my @steps = qw(0.1 0.09 0.08 0.05 0.01 0.005);

# ODEs: f'' - g' = 0        
#       g'' + f*g' + f'*g = 0
#       f(0)=0,f'(0)=1,f''(0)=-1,g(0)=1
# Solution: f(x) = 1 - exp(-x)
#           g(x) = exp(-x)

for my $step (@steps){
    $o = new Math::ODE ( step => $step,
                        initial => [0,1,-1,1],
                        ODE => [ \&DE1, \&DE2 , \&DE3, \&DE4 ],
                        t0 => 0,
                        tf => 10 );
    if ($o->evolve){
        my $sol1 = sub { my $x=shift; 1 - exp(-$x)  };
        my $sol2 = sub { my $x=shift; exp(-$x)      };

        my $maxerr = $o->max_error([ $sol1, $sol2 ]);

        ok( $maxerr < $o->error  , 
            "coupled system 1\nstep=$step, max error=$maxerr, expected error=" .$o->error); 

    } else {
        ok(0, 'numerical apocalypse');
    }
}

sub DE1 { my ($t,$y) = @_; return $y->[1]; }
sub DE2 { my ($t,$y) = @_; return $y->[2]; }
sub DE3 { my ($t,$y) = @_; return $y->[1] * $y->[3] - $y->[0] * $y->[2]; }
sub DE4 { my ($t,$y) = @_; return $y->[2]; }

