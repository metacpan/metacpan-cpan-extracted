package t::StupidLoop;

use v5.14;
use warnings;
use base qw( IO::Async::Loop );

sub new { return bless {}, shift; }

1;
