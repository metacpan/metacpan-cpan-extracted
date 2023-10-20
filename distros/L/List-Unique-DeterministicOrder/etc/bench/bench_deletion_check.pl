use 5.020;
use strict;
use warnings;
use Benchmark qw {:all};

use constant _ARRAY => 0;
use constant _HASH  => 1;

my $self = [[1,2,3],{1 => 1, 2 => 2, 3 => 3}];


cmpthese (
    10000000,
        {
            notequals => sub {notequals($self, "1")},
            arrlen    => sub {arrlen($self, "1")},
        }
    );



sub notequals {
    my ($self, $key) = @_;
        
    my $x;
    my $move_key = $self->[_ARRAY][-1];
    
    if ($move_key ne $key) {
        $x++;
    }
    
    return $x;
}

sub arrlen {
    my ($self, $key) = @_;
        
    my $x;
    
    if (@{$self->[_ARRAY]} > 1) {
        my $move_key = $self->[_ARRAY][-1];
        $x++;
    }
    
    return $x;
}
