package l4ptrapper;
use strict;
use warnings;

use Carp;
use Log::Log4perl;

our ($package, $filename, $line);

sub set_trap {
    my $code = \&Log::Log4perl::easy_init;
    no warnings 'redefine';
    *Log::Log4perl::easy_init = sub {
        if(Log::Log4perl->initialized) {
            carp( "Log::Log4perl already initialised with easy_init() [at $filename, line $line]" );
        }
        else {
            # store our first initialisation
            ($package, $filename, $line) = caller;
        }
        # run the original function
        &$code;
    };
}

1;
