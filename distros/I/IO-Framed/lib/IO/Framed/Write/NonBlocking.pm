package IO::Framed::Write::NonBlocking;

use strict;
use warnings;

use parent qw( IO::Framed::Write );

sub new {
    $_[0]->SUPER::new(@_[ 1 .. $#_ ])->enable_write_queue();
}

1;
