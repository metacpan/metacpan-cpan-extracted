package Lab::Connection::Socket::Trace;
use 5.010;
use warnings;
use strict;

use parent 'Lab::Connection::Socket';

use Role::Tiny::With;
use Carp;
use autodie;

our $VERSION = '3.542';

our %fields = (
    logfile   => undef,
    log_index => 0,
);

with 'Lab::Connection::Trace';

1;

