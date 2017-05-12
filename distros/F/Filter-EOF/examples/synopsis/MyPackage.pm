package MyPackage;
use warnings;
use strict;

use Filter::EOF;

sub import {
    my ($class, @args) = @_;
    my $caller = scalar caller;

    # set the COMPILE_TIME package var to a false value
    # when the file was compiled
    Filter::EOF->on_eof_call(sub {
        no strict 'refs';
        ${ $caller . '::COMPILE_TIME' } = 0;
    });

    # set the COMPILE_TIME package var to a true value when
    # we start compiling it.
    {   no strict 'refs';
        ${ $caller . '::COMPILE_TIME' } = 1;
    }
}

1;

