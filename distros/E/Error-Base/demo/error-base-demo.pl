#!/usr/bin/env perl
#       error-base-demo.pl
#       = Copyright 2011, 2013 Xiong Changnian <xiong@cpan.org> =
#       = Free Software = Artistic License 2.0 = NO WARRANTY =

use 5.008008;
use strict;
use warnings;

use lib 'lib';
use Error::Base;

use Devel::Comments '###';
# You might like to re-enable the dumps after cuss() and crank(). 

#----------------------------------------------------------------------------#

my $err     = Error::Base->new( -base => 'Demo:' );
Pkunk::fury($err);
exit;

package Pkunk;

sub fury {
    my $err     = shift;
    $err->cuss( 
        _private    => 'foo',
        -type       => 'cussing in fury', 
    );
#~     ### $err
    Spathi::eluder($err);
};

package Spathi;

sub eluder {
    my $err     = shift;
    $err->crank( 
        -type       => 'cranking in eluder', 
    );
#~     ### $err
    Shofixti::scout($err);
};

package Shofixti;

sub scout {
    my $err     = shift;
    print "\n";
    eval { $err->crash( 
            -type       => 'crashing in scout', 
        );
    };
    my $trap    = $@;
    print $trap;
    ### $trap
};

__END__
