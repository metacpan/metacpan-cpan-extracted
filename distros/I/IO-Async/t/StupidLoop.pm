package t::StupidLoop;

use strict;
use base qw( IO::Async::Loop );

sub new { return bless {}, shift; }

1;
