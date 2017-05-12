package IO::Framed::ReadWrite::NonBlocking;

use strict;
use warnings;

use parent qw(
    IO::Framed::ReadWrite
    IO::Framed::Write::NonBlocking
);

sub new {
    $_[0]->SUPER::new( @_[ 1 .. $#_ ] )->enable_write_queue();
}

1;
