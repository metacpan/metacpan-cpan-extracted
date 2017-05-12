package Mail::Lite::Processor::Last;

use strict;
use warnings;

use Mail::Lite::Constants;
use Smart::Comments -ENV;



sub process { 
    return STOP_RULE;
}



1;
