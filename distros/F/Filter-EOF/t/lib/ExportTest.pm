package ExportTest;
use strict;
use Filter::EOF qw( on_eof_call );

our $DONE;

sub import {
    on_eof_call { $DONE++ };
}

1;
