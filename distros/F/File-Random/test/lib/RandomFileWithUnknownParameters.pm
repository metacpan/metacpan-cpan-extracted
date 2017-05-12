package RandomFileWithUnknownParameters;
use base qw/RandomFileMethodBase/;
use TestConstants;

use strict;
use warnings;

use Test::More;
use Test::Warn;

use constant UNKNOWN_PARAMS => (-verzeichnis => SIMPLE_DIR,
                                -ueberpruefe => qr/deutsch/,
                                -DIR         => SIMPLE_DIR,
                                dir          => SIMPLE_DIR,
                                -Check       => sub {1},
                                check        => sub {1},
                                -RECURSIVE   => 1,
                                recursive    => 1);
                                
sub warning_when_unknown_param : Test(8) {
    my $self = shift;
    my %params = UNKNOWN_PARAMS;
    while (my @args = each %params) {
        warning_like {$self->random_file(@args)} 
                     [{carped => qr/unknown option/i}],
                     "Arguments: @args"; 
    }
}

1;
