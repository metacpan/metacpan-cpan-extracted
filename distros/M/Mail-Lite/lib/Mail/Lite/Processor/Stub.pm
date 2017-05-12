package Mail::Lite::Processor::Stub;

use strict;
use warnings;

use Mail::Lite::Constants;
use Smart::Comments -ENV;



sub process {
    my $args_ref = shift;

    ${ $args_ref->{ output } } = $args_ref->{ input };
    return OK;
}



1;
